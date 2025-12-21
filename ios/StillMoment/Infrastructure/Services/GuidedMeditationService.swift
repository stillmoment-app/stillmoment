//
//  GuidedMeditationService.swift
//  Still Moment
//
//  Infrastructure - Guided Meditation Management Service
//

import Foundation
import OSLog

/// Concrete implementation of GuidedMeditationServiceProtocol
///
/// Manages guided meditation library with UserDefaults persistence.
/// Audio files are copied to Application Support/Meditations/.
/// Legacy bookmarks are migrated on first load after update.
final class GuidedMeditationService: GuidedMeditationServiceProtocol {
    // MARK: Lifecycle

    /// Initializes the service with optional custom UserDefaults and FileManager
    ///
    /// - Parameters:
    ///   - userDefaults: UserDefaults instance (defaults to .standard)
    ///   - fileManager: FileManager instance (defaults to .default)
    init(userDefaults: UserDefaults = .standard, fileManager: FileManager = .default) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
    }

    // MARK: Internal

    func loadMeditations() throws -> [GuidedMeditation] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            self.meditations = []
            return self.meditations
        }

        do {
            let decoder = JSONDecoder()
            self.meditations = try decoder.decode([GuidedMeditation].self, from: data)

            // Migrate legacy bookmarks if needed
            if !self.isMigrationCompleted(), self.hasMeditationsWithBookmarks() {
                self.meditations = try self.performMigration()
            }

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
        let meditationId = UUID()

        // Copy file to local storage
        let localPath = try copyFileToMeditationsDirectory(from: url, meditationId: meditationId)

        // Create meditation with local path
        let meditation = GuidedMeditation(
            id: meditationId,
            localFilePath: localPath,
            fileName: url.lastPathComponent,
            duration: metadata.duration,
            teacher: metadata.artist ?? "Unknown Artist",
            name: metadata.title ?? url.deletingPathExtension().lastPathComponent
        )

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

        let meditation = self.meditations[index]

        // Delete local file if exists
        if let fileURL = meditation.fileURL {
            try? self.fileManager.removeItem(at: fileURL)
            Logger.audio.debug("Deleted local file: \(fileURL.path)")
        }

        self.meditations.remove(at: index)
        try self.saveMeditations(self.meditations)
    }

    func getMeditationsDirectory() -> URL {
        // Application Support directory is guaranteed to exist on iOS
        // swiftlint:disable:next force_unwrapping
        let appSupport = self.fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Meditations")
    }

    func needsMigration() -> Bool {
        // Check if migration was already completed
        guard !self.isMigrationCompleted() else {
            return false
        }

        // Check if there are meditations with legacy bookmarks
        guard let data = userDefaults.data(forKey: storageKey) else {
            return false
        }

        do {
            let decoder = JSONDecoder()
            let storedMeditations = try decoder.decode([GuidedMeditation].self, from: data)
            return storedMeditations.contains { $0.needsMigration }
        } catch {
            return false
        }
    }

    // MARK: Private

    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    private let storageKey = "guidedMeditationsLibrary"
    private let migrationKey = "guidedMeditationsMigratedToLocalFiles_v1"

    private var meditations: [GuidedMeditation] = []

    // MARK: - Migration

    private func isMigrationCompleted() -> Bool {
        self.userDefaults.bool(forKey: self.migrationKey)
    }

    private func markMigrationCompleted() {
        self.userDefaults.set(true, forKey: self.migrationKey)
    }

    private func hasMeditationsWithBookmarks() -> Bool {
        self.meditations.contains { $0.needsMigration }
    }

    private func performMigration() throws -> [GuidedMeditation] {
        Logger.audio.info("Starting migration of \(self.meditations.count) meditations")
        var migrated: [GuidedMeditation] = []
        var removedCount = 0

        for meditation in self.meditations {
            // Already migrated?
            if meditation.localFilePath != nil {
                migrated.append(meditation)
                continue
            }

            // Has bookmark?
            guard let bookmark = meditation.fileBookmark else {
                Logger.audio.warning("Meditation without bookmark or local path, removing: \(meditation.id)")
                removedCount += 1
                continue
            }

            // Try to resolve and copy
            do {
                let url = try resolveBookmark(bookmark)
                let didStart = url.startAccessingSecurityScopedResource()
                defer {
                    if didStart {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let localPath = try copyFileToMeditationsDirectory(from: url, meditationId: meditation.id)
                let migratedMeditation = meditation.withLocalFilePath(localPath)
                migrated.append(migratedMeditation)
                Logger.audio.info("Migrated meditation: \(meditation.effectiveName)")
            } catch {
                Logger.audio
                    .error("Failed to migrate meditation \(meditation.effectiveName): \(error.localizedDescription)")
                removedCount += 1
            }
        }

        if removedCount > 0 {
            Logger.audio.warning("Removed \(removedCount) meditations due to unresolvable bookmarks")
        }

        try self.saveMeditations(migrated)
        self.markMigrationCompleted()
        Logger.audio.info("Migration completed: \(migrated.count) migrated, \(removedCount) removed")

        return migrated
    }

    /// Resolves a security-scoped bookmark to a file URL (for migration only)
    private func resolveBookmark(_ bookmark: Data) throws -> URL {
        var isStale = false
        do {
            return try URL(
                resolvingBookmarkData: bookmark,
                options: .withoutUI,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        } catch {
            throw GuidedMeditationError.migrationFailed(reason: "Bookmark resolution failed")
        }
    }

    // MARK: - File Operations

    private func copyFileToMeditationsDirectory(from sourceURL: URL, meditationId: UUID) throws -> String {
        let meditationsDir = self.getMeditationsDirectory()

        // Create directory if needed
        if !self.fileManager.fileExists(atPath: meditationsDir.path) {
            try self.fileManager.createDirectory(at: meditationsDir, withIntermediateDirectories: true)
        }

        // Use UUID + original extension as filename
        let fileExtension = sourceURL.pathExtension.isEmpty ? "mp3" : sourceURL.pathExtension
        let fileName = "\(meditationId.uuidString).\(fileExtension)"
        let destinationURL = meditationsDir.appendingPathComponent(fileName)

        // Remove existing file if present
        if self.fileManager.fileExists(atPath: destinationURL.path) {
            try self.fileManager.removeItem(at: destinationURL)
        }

        // Copy file
        do {
            try self.fileManager.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw GuidedMeditationError.fileCopyFailed(reason: error.localizedDescription)
        }

        return fileName
    }

    // MARK: - Sorting

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
