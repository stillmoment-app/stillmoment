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
        metadataService: AudioMetadataServiceProtocol = AudioMetadataService()
    ) {
        self.meditationService = meditationService
        self.metadataService = metadataService
    }

    // MARK: Internal

    // MARK: - Published Properties

    @Published var meditations: [GuidedMeditation] = []
    @Published var isLoading = false
    @Published var isMigrating = false
    @Published var errorMessage: String?
    @Published var showingDocumentPicker = false
    @Published var showingEditSheet = false
    @Published var meditationToEdit: GuidedMeditation?

    /// Returns unique teacher names sorted alphabetically for autocomplete
    ///
    /// Uses `effectiveTeacher` to respect custom teacher overrides.
    var uniqueTeachers: [String] {
        let teachers = Set(meditations.map(\.effectiveTeacher))
        return teachers.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    // MARK: - Public Methods

    /// Loads meditations from persistent storage
    ///
    /// If legacy bookmarks need migration, shows a migration overlay
    /// while copying files to local storage.
    func loadMeditations() {
        // Check if migration is needed before loading
        if self.meditationService.needsMigration() {
            self.isMigrating = true
            Logger.guidedMeditation.info("Migration needed, starting async migration")

            // Run migration in a task so the UI can update
            Task {
                // Small delay to ensure the overlay is visible
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s

                await self.performLoad()
                self.isMigrating = false
            }
        } else {
            Task {
                await self.performLoad()
            }
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
            self.errorMessage = "Failed to load meditations: \(error.localizedDescription)"
        }

        self.isLoading = false
    }

    /// Handles importing a meditation from a selected file URL
    ///
    /// - Parameter url: URL to the selected audio file
    func importMeditation(from url: URL) async {
        self.isLoading = true
        self.errorMessage = nil

        Logger.guidedMeditation.info("Importing meditation", metadata: ["file": url.lastPathComponent])

        // Start accessing the security-scoped resource IMMEDIATELY
        // This is required for files from the Files app / DocumentPicker
        let didStartAccessing = url.startAccessingSecurityScopedResource()

        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            // Extract metadata from audio file
            let metadata = try await metadataService.extractMetadata(from: url)

            Logger.guidedMeditation.debug(
                "Extracted metadata",
                metadata: [
                    "artist": metadata.artist ?? "none",
                    "title": metadata.title ?? "none",
                    "duration": metadata.duration
                ]
            )

            // Add meditation to library
            let meditation = try meditationService.addMeditation(from: url, metadata: metadata)

            // Reload meditations to get sorted list
            self.meditations = try self.meditationService.loadMeditations()

            Logger.guidedMeditation.info("Successfully imported meditation", metadata: ["id": meditation.id.uuidString])
        } catch {
            Logger.guidedMeditation.error("Failed to import meditation", error: error)
            self.errorMessage = "Failed to import meditation: \(error.localizedDescription)"
        }

        self.isLoading = false
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
            self.errorMessage = "Failed to delete meditation: \(error.localizedDescription)"
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
            self.errorMessage = "Failed to update meditation: \(error.localizedDescription)"
        }
    }

    /// Groups meditations by teacher for display
    ///
    /// - Returns: Dictionary mapping teacher names to their meditations
    func meditationsByTeacher() -> [(teacher: String, meditations: [GuidedMeditation])] {
        let grouped = Dictionary(grouping: meditations) { $0.effectiveTeacher }
        return grouped.map { (teacher: $0.key, meditations: $0.value) }
            .sorted { $0.teacher.localizedCaseInsensitiveCompare($1.teacher) == .orderedAscending }
    }

    // MARK: Private

    // MARK: - Dependencies

    private let meditationService: GuidedMeditationServiceProtocol
    private let metadataService: AudioMetadataServiceProtocol
}
