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
        searchHistoryStore: SearchHistoryStore = UserDefaultsSearchHistoryStore(),
        waveformProvider: WaveformProviderProtocol = WaveformProvider()
    ) {
        self.meditationService = meditationService
        self.metadataService = metadataService
        self.audioService = audioService
        self.meditationSourceRepository = meditationSourceRepository
        self.searchHistoryStore = searchHistoryStore
        self.waveformProvider = waveformProvider
        self.searchHistory = searchHistoryStore.load()

        // Mirror the running preview's playback state for the UI scrub-slider (shared-098).
        audioService.meditationPreviewPositionPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$previewCurrentTime)
        audioService.meditationPreviewDurationPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$previewDuration)

        // Natural end of a preview must flip Stop-Button back to Play and hide the slider.
        // The service-side stop already resets position/duration; we only own the id here.
        audioService.meditationPreviewCompletionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.previewingMeditationId = nil
            }
            .store(in: &self.cancellables)
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

    /// Aktuelle Wiedergabeposition der laufenden Vorhoer-Wiedergabe in Sekunden.
    /// Wird vom AudioService gefuettert, Ruecksetzung auf 0 bei Stop.
    @Published var previewCurrentTime: TimeInterval = 0
    /// Gesamtdauer der laufenden Vorhoer-Wiedergabe in Sekunden. 0 falls keine Preview laeuft.
    @Published var previewDuration: TimeInterval = 0

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

    /// Der Suchbegriff ohne umgebende Leerzeichen — die Fassung, die tatsaechlich sucht
    /// und die der „Kein Treffer"-Text zitiert.
    var trimmedSearchQuery: String {
        self.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Aktuell sichtbare Trefferliste fuer die Eingabe.
    var searchResults: [GuidedMeditation] {
        LibrarySearchEngine.search(meditations: self.meditations, query: self.searchQuery)
    }

    /// Abgeleiteter Ansichtszustand der Suche.
    var searchState: LibrarySearchState {
        if !self.hasQuery {
            if self.isSearching {
                return .history
            }
            if !self.isFilterActive {
                return .idle
            }
            return self.visibleMeditations.isEmpty ? .empty : .filtered
        }
        return self.visibleMeditations.isEmpty ? .empty : .results
    }

    // MARK: - Dauer-Filter (shared-081)

    /// Aktive Dauer-Stufe. `all` bedeutet: kein Filter, die Liste bleibt gruppiert.
    @Published var durationFilter: DurationFilter = .all

    /// Ob eine Stufe ausser `Alle` gewaehlt ist.
    var isFilterActive: Bool {
        self.durationFilter != .all
    }

    /// Ob der Header die kompakte Chip-Variante zeigt statt der vollen Filterzeile.
    ///
    /// Ein vorhandener Suchtext genuegt — die Trefferliste gibt beim Scrollen den
    /// Fokus ab (`scrollDismissesKeyboard`), der Chip muss aber weiter erklaeren,
    /// warum eine Meditation fehlt.
    var isSearchModeActive: Bool {
        self.isSearching || self.hasQuery
    }

    /// Die Meditationen, die Suche **und** Filter gemeinsam erfuellen.
    ///
    /// Ohne Suchtext folgt die Reihenfolge der gruppierten Ansicht (Lehrer:in
    /// alphabetisch), mit Suchtext der Relevanz-Rangfolge der Suche.
    var visibleMeditations: [GuidedMeditation] {
        self.durationFilter.apply(to: self.searchScopedMeditations)
    }

    /// Die Stufen, die mindestens eine Meditation der Bibliothek enthalten.
    ///
    /// Bewusst gegen den Gesamtbestand berechnet, nicht gegen `visibleMeditations` —
    /// sonst wuerde eine gesetzte Stufe alle anderen blass schalten und der Filter
    /// waere eine Einbahnstrasse. Der Suchtext spielt keine Rolle: sobald welcher im
    /// Feld steht, ist die Stufenzeile ohnehin dem Chip gewichen.
    var availableDurationSteps: Set<DurationFilter> {
        DurationFilter.availableSteps(in: self.meditations)
    }

    /// Waehlt eine Stufe. Erneutes Tippen auf die aktive Stufe kehrt zu `Alle` zurueck.
    /// Blasse (unbelegte) Stufen reagieren nicht.
    func selectDurationFilter(_ step: DurationFilter) {
        guard self.availableDurationSteps.contains(step) else {
            return
        }
        self.durationFilter = self.durationFilter == step ? .all : step
    }

    /// Entfernt den Dauer-Filter, laesst den Suchtext unberuehrt.
    func resetDurationFilter() {
        self.durationFilter = .all
    }

    /// Raeumt Suchtext und Filter gemeinsam ab — ein Tap im „Kein Treffer"-Zustand.
    func resetSearchAndFilter() {
        self.resetSearch()
        self.resetDurationFilter()
    }

    /// Returns unique teacher names sorted alphabetically for autocomplete
    var uniqueTeachers: [String] {
        let teachers = Set(meditations.map(\.teacher))
        return teachers.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    /// Shared audio service for the trim editor, so editor preview and library preview use
    /// the same instance (shared-107). Read-only — the editor receives it via constructor injection.
    var editorAudioService: AudioServiceProtocol {
        self.audioService
    }

    /// Shared waveform provider for the trim editor and the edit-sheet mini waveform (shared-107).
    var editorWaveformProvider: WaveformProviderProtocol {
        self.waveformProvider
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
            let imported = try self.meditationService.addMeditation(
                from: pending.url,
                metadata: pending.metadata,
                teacher: edited.teacher,
                name: edited.name
            )
            self.meditations = try self.meditationService.loadMeditations()
            // Precompute the waveform in the background so the trim editor opens instantly
            // later (shared-107). Fire-and-forget — the import does not wait for it.
            self.waveformProvider.precompute(for: imported)
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
            // Drop the cached waveform alongside the audio file (shared-107).
            self.waveformProvider.removeCached(id: meditation.id)
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

    /// Springt die laufende Vorhoer-Wiedergabe an eine neue Position.
    ///
    /// - Parameter time: Zielposition in Sekunden. Wird im Service auf die Audio-Laenge geklemmt.
    func seekPreview(to time: TimeInterval) {
        self.audioService.seekMeditationPreview(to: time)
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
    ///
    /// Massgeblich ist die **sichtbare** Liste: raeumt der Dauer-Filter alle Treffer weg,
    /// sieht der User „Nichts gefunden" und soll den Begriff nicht in der Historie wiederfinden.
    func submitSearch() {
        guard !self.visibleMeditations.isEmpty else {
            return
        }
        self.commitCurrentQueryToHistory()
    }

    /// Treffer-Tap — fuegt den Begriff der Historie hinzu und setzt die Suche zurueck.
    ///
    /// Wie `submitSearch()` massgeblich ist die **sichtbare** Liste, nicht die reinen Suchtreffer.
    func recordSearchCommittedByOpening() {
        if !self.visibleMeditations.isEmpty {
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

    /// Ob eine nicht-leere Eingabe im Suchfeld steht.
    private var hasQuery: Bool {
        !self.trimmedSearchQuery.isEmpty
    }

    /// Die Menge, auf die **nur** der Suchtext wirkt — Basis fuer den Dauer-Filter.
    ///
    /// Ohne Suchtext ist das die Bibliothek in der Reihenfolge der gruppierten Ansicht,
    /// damit die flache Liste dieselbe Ordnung zeigt wie die gruppierte darueber.
    private var searchScopedMeditations: [GuidedMeditation] {
        guard self.hasQuery else {
            return self.meditationsByTeacher().flatMap(\.meditations)
        }
        return self.searchResults
    }

    private let meditationService: GuidedMeditationServiceProtocol
    private let metadataService: AudioMetadataServiceProtocol
    private let audioService: AudioServiceProtocol
    private let meditationSourceRepository: MeditationSourceRepositoryProtocol
    private let searchHistoryStore: SearchHistoryStore
    private let waveformProvider: WaveformProviderProtocol
    private var cancellables = Set<AnyCancellable>()
}
