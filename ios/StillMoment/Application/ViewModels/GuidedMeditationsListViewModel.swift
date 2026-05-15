//
//  GuidedMeditationsListViewModel.swift
//  Still Moment
//
//  Application Layer - Guided Meditations List ViewModel
//

import Combine
import Foundation
import OSLog

/// ViewModel for the Guided Meditations List View
///
/// Manages:
/// - Loading and displaying meditation library
/// - Importing new meditations via DocumentPicker
/// - Deleting meditations
/// - Navigating to editor and player
@MainActor
final class GuidedMeditationsListViewModel: ObservableObject {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(
        meditationService: GuidedMeditationServiceProtocol = GuidedMeditationService(),
        metadataService: AudioMetadataServiceProtocol = AudioMetadataService(),
        audioService: AudioServiceProtocol = AudioService(),
        meditationSourceRepository: MeditationSourceRepositoryProtocol = MeditationSourceRepository(),
        searchHistoryStore: SearchHistoryStore = UserDefaultsSearchHistoryStore()
    ) {
        self.meditationService = meditationService
        self.metadataService = metadataService
        self.audioService = audioService
        self.meditationSourceRepository = meditationSourceRepository
        self.searchHistoryStore = searchHistoryStore
        self.searchHistory = searchHistoryStore.load()
    }

    // MARK: Internal

    // MARK: - Published Properties

    @Published var meditations: [GuidedMeditation] = []
    @Published var isLoading = false
    @Published var isMigrating = false
    @Published var errorMessage: String?
    @Published var showingDocumentPicker = false
    @Published var showingEditSheet = false
    @Published var showingGuideSheet = false
    @Published var guideSources: [MeditationSource] = []
    @Published var meditationToEdit: GuidedMeditation?
    @Published var previewingMeditationId: UUID?

    /// Zwischenstand zwischen Import und Save im Edit-Sheet (ios-043).
    ///
    /// Solange `pendingImport != nil`, ist eine Audiodatei extrahiert, aber **noch nicht
    /// persistiert** — die Datei-Kopie und der `addMeditation`-Aufruf erfolgen erst beim
    /// Save im Edit-Sheet. Cancel verwirft den Pending-State ohne Persistenz.
    @Published var pendingImport: PendingImport?

    // MARK: - Suche (ios-041)

    @Published var searchQuery: String = ""
    @Published var searchHistory: [String] = []
    @Published var isSearching: Bool = false

    static let searchHistoryLimit = 6

    /// Aktuell sichtbare Trefferliste fuer die Eingabe.
    var searchResults: [GuidedMeditation] {
        LibrarySearchEngine.search(meditations: self.meditations, query: self.searchQuery)
    }

    /// Abgeleiteter Ansichtszustand der Suche.
    var searchState: LibrarySearchState {
        let trimmed = self.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return self.isSearching ? .history : .idle
        }
        return self.searchResults.isEmpty ? .empty : .results
    }

    /// Returns unique teacher names sorted alphabetically for autocomplete
    var uniqueTeachers: [String] {
        let teachers = Set(meditations.map(\.teacher))
        return teachers.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    // MARK: - Public Methods

    /// Loads meditations from persistent storage
    ///
    /// If legacy bookmarks need migration, shows a migration overlay
    /// while copying files to local storage.
    func loadMeditations() async {
        if self.meditationService.needsMigration() {
            self.isMigrating = true
            Logger.guidedMeditation.info("Migration needed, starting async migration")
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s — overlay sichtbar machen
            await self.performLoad()
            self.isMigrating = false
        } else {
            await self.performLoad()
        }
    }

    /// Performs the actual load operation
    private func performLoad() async {
        self.isLoading = true
        self.errorMessage = nil

        do {
            self.meditations = try self.meditationService.loadMeditations()
            Logger.guidedMeditation.info("Loaded \(self.meditations.count) meditations")
        } catch {
            Logger.guidedMeditation.error("Failed to load meditations", error: error)
            self.errorMessage = NSLocalizedString("error.meditationsLoadFailed", comment: "Failed to load meditations")
        }

        self.isLoading = false
    }

    /// Startet einen Import via DocumentPicker.
    ///
    /// Extrahiert Metadaten und uebergibt an `beginImport` — die Persistenz erfolgt
    /// erst beim Save im Edit-Sheet (`handleEditSheetSave`).
    func importMeditation(from url: URL) async {
        self.isLoading = true
        self.errorMessage = nil

        Logger.guidedMeditation.info("Importing meditation", metadata: ["file": url.lastPathComponent])

        let didStartAccessing = url.startAccessingSecurityScopedResource()

        do {
            let metadata = try await metadataService.extractMetadata(from: url)
            Logger.guidedMeditation.debug(
                "Extracted metadata",
                metadata: [
                    "artist": metadata.artist ?? "none",
                    "title": metadata.title ?? "none",
                    "duration": metadata.duration
                ]
            )
            self.beginImport(url: url, metadata: metadata, didStartAccessing: didStartAccessing)
        } catch {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
            Logger.guidedMeditation.error("Failed to import meditation", error: error)
            self.errorMessage = NSLocalizedString("error.importFailed", comment: "Failed to import meditation")
        }

        self.isLoading = false
    }

    /// Oeffnet das Edit-Sheet mit einem Draft fuer einen ausstehenden Import.
    ///
    /// Wird sowohl vom DocumentPicker-Pfad (`importMeditation(from:)`) als auch vom
    /// FileOpenHandler-Pfad (Share/Open-in) aufgerufen.
    func beginImport(url: URL, metadata: AudioMetadata, didStartAccessing: Bool) {
        let prefill = ImportPrefill.compute(
            metadata: metadata,
            fileName: url.lastPathComponent,
            knownTeachers: Array(Set(self.meditations.map(\.teacher)))
        )
        let draft = GuidedMeditation(
            localFilePath: "",
            fileName: url.lastPathComponent,
            duration: metadata.duration,
            teacher: prefill.teacher ?? "",
            name: prefill.name ?? ""
        )
        self.pendingImport = PendingImport(
            url: url,
            metadata: metadata,
            didStartAccessing: didStartAccessing,
            draftId: draft.id
        )
        self.meditationToEdit = draft
        self.showingEditSheet = true
    }

    /// Cancel im Edit-Sheet im Import-Modus: verwirft Draft, gibt Security-Scope frei.
    func cancelImport() {
        guard let pending = self.pendingImport else {
            return
        }
        if pending.didStartAccessing {
            pending.url.stopAccessingSecurityScopedResource()
        }
        self.pendingImport = nil
        self.meditationToEdit = nil
        self.showingEditSheet = false
    }

    /// Save im Edit-Sheet — verzweigt zwischen Import (persistiert via `addMeditation`)
    /// und regulaerem Edit (`updateMeditation`).
    func handleEditSheetSave(_ edited: GuidedMeditation) {
        if let pending = self.pendingImport, pending.draftId == edited.id {
            self.saveImportedMeditation(edited, pending: pending)
        } else {
            self.updateMeditation(edited)
            self.showingEditSheet = false
        }
    }

    private func saveImportedMeditation(_ edited: GuidedMeditation, pending: PendingImport) {
        defer {
            if pending.didStartAccessing {
                pending.url.stopAccessingSecurityScopedResource()
            }
            self.pendingImport = nil
            self.showingEditSheet = false
        }
        do {
            _ = try self.meditationService.addMeditation(
                from: pending.url,
                metadata: pending.metadata,
                teacher: edited.teacher,
                name: edited.name
            )
            self.meditations = try self.meditationService.loadMeditations()
            Logger.guidedMeditation.info(
                "Successfully imported meditation",
                metadata: ["fileName": pending.url.lastPathComponent]
            )
        } catch {
            Logger.guidedMeditation.error("Failed to persist imported meditation", error: error)
            self.errorMessage = NSLocalizedString("error.importFailed", comment: "Failed to import meditation")
        }
    }

    /// Deletes a meditation from the library
    ///
    /// - Parameter meditation: Meditation to delete
    func deleteMeditation(_ meditation: GuidedMeditation) {
        do {
            try self.meditationService.deleteMeditation(id: meditation.id)
            self.meditations.removeAll { $0.id == meditation.id }
            Logger.guidedMeditation.info("Deleted meditation", metadata: ["id": meditation.id.uuidString])
        } catch {
            Logger.guidedMeditation.error("Failed to delete meditation", error: error)
            self.errorMessage = NSLocalizedString("error.deleteFailed", comment: "Failed to delete meditation")
        }
    }

    /// Shows the document picker for importing
    func showDocumentPicker() {
        self.showingDocumentPicker = true
    }

    /// Shows the edit sheet for a meditation
    ///
    /// - Parameter meditation: Meditation to edit
    func showEditSheet(for meditation: GuidedMeditation) {
        self.meditationToEdit = meditation
        self.showingEditSheet = true
    }

    /// Updates a meditation with new metadata
    ///
    /// - Parameter meditation: Updated meditation
    func updateMeditation(_ meditation: GuidedMeditation) {
        do {
            try self.meditationService.updateMeditation(meditation)
            // Reload to get sorted list
            self.meditations = try self.meditationService.loadMeditations()
            Logger.guidedMeditation.info("Updated meditation", metadata: ["id": meditation.id.uuidString])
        } catch {
            Logger.guidedMeditation.error("Failed to update meditation", error: error)
            self.errorMessage = NSLocalizedString("error.updateFailed", comment: "Failed to update meditation")
        }
    }

    /// Starts audio preview for a meditation (press-and-hold)
    ///
    /// - Parameter meditation: Meditation to preview
    func startPreview(for meditation: GuidedMeditation) {
        guard let fileURL = meditationService.fileURL(for: meditation) else {
            Logger.guidedMeditation.warning(
                "Cannot preview meditation — file not found",
                metadata: ["id": meditation.id.uuidString]
            )
            return
        }

        do {
            try self.audioService.playMeditationPreview(fileURL: fileURL)
            self.previewingMeditationId = meditation.id
            Logger.guidedMeditation.info(
                "Started meditation preview",
                metadata: ["id": meditation.id.uuidString]
            )
        } catch {
            Logger.guidedMeditation.error("Failed to start meditation preview", error: error)
        }
    }

    /// Stops the currently playing meditation preview
    func stopPreview() {
        guard self.previewingMeditationId != nil else {
            return
        }
        self.audioService.stopMeditationPreview()
        self.previewingMeditationId = nil
    }

    /// Loads curated meditation sources for the given language and shows the guide sheet.
    ///
    /// - Parameter languageCode: Active language code (`"de"`, `"en"`, …). Falls back to English when unknown.
    func openGuideSheet(languageCode: String) {
        self.guideSources = self.meditationSourceRepository.sources(for: languageCode)
        self.showingGuideSheet = true
    }

    /// Hides the Content Guide sheet.
    func closeGuideSheet() {
        self.showingGuideSheet = false
    }

    // MARK: - Suche (ios-041)

    /// Bestaetigung via Return-Taste — fuegt den Begriff der Historie hinzu, wenn Treffer existieren.
    func submitSearch() {
        guard !self.searchResults.isEmpty else {
            return
        }
        self.commitCurrentQueryToHistory()
    }

    /// Treffer-Tap — fuegt den Begriff der Historie hinzu und setzt die Suche zurueck.
    func recordSearchCommittedByOpening() {
        if !self.searchResults.isEmpty {
            self.commitCurrentQueryToHistory()
        }
        self.resetSearch()
    }

    /// Setzt das Suchfeld auf einen Historie-Eintrag.
    func selectHistoryEntry(_ term: String) {
        self.searchQuery = term
    }

    /// Loescht die Suchhistorie komplett.
    func clearHistory() {
        self.searchHistory = []
        self.searchHistoryStore.save([])
    }

    /// Leert das Suchfeld und beendet den Fokus-Zustand.
    func resetSearch() {
        self.searchQuery = ""
        self.isSearching = false
    }

    private func commitCurrentQueryToHistory() {
        let updated = SearchHistory.prepend(
            history: self.searchHistory,
            term: self.searchQuery,
            limit: Self.searchHistoryLimit
        )
        guard updated != self.searchHistory else {
            return
        }
        self.searchHistory = updated
        self.searchHistoryStore.save(updated)
    }

    /// Groups meditations by teacher for display
    ///
    /// - Returns: Dictionary mapping teacher names to their meditations
    func meditationsByTeacher() -> [(teacher: String, meditations: [GuidedMeditation])] {
        let grouped = Dictionary(grouping: meditations) { $0.teacher }
        return grouped.map { (teacher: $0.key, meditations: $0.value) }
            .sorted { $0.teacher.localizedCaseInsensitiveCompare($1.teacher) == .orderedAscending }
    }

    // MARK: Private

    // MARK: - Dependencies

    private let meditationService: GuidedMeditationServiceProtocol
    private let metadataService: AudioMetadataServiceProtocol
    private let audioService: AudioServiceProtocol
    private let meditationSourceRepository: MeditationSourceRepositoryProtocol
    private let searchHistoryStore: SearchHistoryStore
}
