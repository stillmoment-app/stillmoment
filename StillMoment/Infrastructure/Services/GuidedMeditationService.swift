//
//  GuidedMeditationService.swift
//  Still Moment
//
//  Infrastructure - Guided Meditation Management Service
//

import Foundation

/// Concrete implementation of GuidedMeditationServiceProtocol
///
/// Manages guided meditation library with UserDefaults persistence
/// and security-scoped bookmark handling for external file access.
final class GuidedMeditationService: GuidedMeditationServiceProtocol {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initializes the service with optional custom UserDefaults
    ///
    /// - Parameter userDefaults: UserDefaults instance (defaults to .standard)
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: Internal

    // MARK: - GuidedMeditationServiceProtocol

    func loadMeditations() throws -> [GuidedMeditation] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            // No data stored yet, return empty array
            self.meditations = []
            return self.meditations
        }

        do {
            let decoder = JSONDecoder()
            self.meditations = try decoder.decode([GuidedMeditation].self, from: data)
            return self.sortedMeditations()
        } catch {
            throw GuidedMeditationError.persistenceFailed(reason: error.localizedDescription)
        }
    }

    func saveMeditations(_ meditations: [GuidedMeditation]) throws {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(meditations)
            self.userDefaults.set(data, forKey: self.storageKey)
            self.meditations = meditations
        } catch {
            throw GuidedMeditationError.persistenceFailed(reason: error.localizedDescription)
        }
    }

    func addMeditation(from url: URL, metadata: AudioMetadata) throws -> GuidedMeditation {
        // Create security-scoped bookmark
        // On iOS, security-scoped bookmarks are created automatically for external files
        let bookmarkData: Data
        do {
            bookmarkData = try url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            throw GuidedMeditationError.bookmarkCreationFailed
        }

        // Create meditation with metadata
        let meditation = GuidedMeditation(
            fileBookmark: bookmarkData,
            fileName: url.lastPathComponent,
            duration: metadata.duration,
            teacher: metadata.artist ?? "Unknown Artist",
            name: metadata.title ?? url.deletingPathExtension().lastPathComponent
        )

        // Add to collection and save
        self.meditations.append(meditation)
        try self.saveMeditations(self.meditations)

        return meditation
    }

    func updateMeditation(_ meditation: GuidedMeditation) throws {
        guard let index = meditations.firstIndex(where: { $0.id == meditation.id }) else {
            throw GuidedMeditationError.meditationNotFound(id: meditation.id)
        }

        self.meditations[index] = meditation
        try self.saveMeditations(self.meditations)
    }

    func deleteMeditation(id: UUID) throws {
        guard let index = meditations.firstIndex(where: { $0.id == id }) else {
            throw GuidedMeditationError.meditationNotFound(id: id)
        }

        self.meditations.remove(at: index)
        try self.saveMeditations(self.meditations)
    }

    func resolveBookmark(_ bookmark: Data) throws -> URL {
        var isStale = false

        do {
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: .withoutUI,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            // Note: If bookmark is stale, we could recreate it here
            // For now, we just return the URL
            return url
        } catch {
            throw GuidedMeditationError.bookmarkResolutionFailed
        }
    }

    func startAccessingSecurityScopedResource(_ url: URL) -> Bool {
        url.startAccessingSecurityScopedResource()
    }

    func stopAccessingSecurityScopedResource(_ url: URL) {
        url.stopAccessingSecurityScopedResource()
    }

    // MARK: Private

    private let userDefaults: UserDefaults
    private let storageKey = "guidedMeditationsLibrary"

    // In-memory cache of meditations
    private var meditations: [GuidedMeditation] = []

    // MARK: - Private Helpers

    /// Returns meditations sorted by teacher (primary) then name (secondary)
    private func sortedMeditations() -> [GuidedMeditation] {
        self.meditations.sorted { lhs, rhs in
            let teacherComparison = lhs.effectiveTeacher.localizedCaseInsensitiveCompare(rhs.effectiveTeacher)
            if teacherComparison == .orderedSame {
                return lhs.effectiveName.localizedCaseInsensitiveCompare(rhs.effectiveName) == .orderedAscending
            }
            return teacherComparison == .orderedAscending
        }
    }
}
