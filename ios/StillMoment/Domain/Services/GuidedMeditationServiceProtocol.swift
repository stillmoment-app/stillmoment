//
//  GuidedMeditationServiceProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Guided Meditation Management
//

import Foundation

/// Errors that can occur during guided meditation management
enum GuidedMeditationError: Error, LocalizedError {
    case persistenceFailed(reason: String)
    case fileCopyFailed(reason: String)
    case fileNotFound
    case meditationNotFound(id: UUID)
    case migrationFailed(reason: String)

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case let .persistenceFailed(reason):
            "Failed to persist meditation library: \(reason)"
        case let .fileCopyFailed(reason):
            "Failed to copy audio file: \(reason)"
        case .fileNotFound:
            "Audio file not found"
        case let .meditationNotFound(id):
            "Meditation with ID \(id) not found"
        case let .migrationFailed(reason):
            "Migration failed: \(reason)"
        }
    }
}

/// Service for managing guided meditation library
///
/// This service handles CRUD operations for guided meditations, including:
/// - Loading/saving from/to persistent storage (UserDefaults)
/// - Copying audio files to the app's local storage
/// - Migrating legacy bookmarks to local files
protocol GuidedMeditationServiceProtocol {
    /// Loads all guided meditations from persistent storage
    ///
    /// On first launch after update, this will migrate any legacy bookmarks
    /// to local file copies.
    ///
    /// - Returns: Array of guided meditations, sorted by teacher then name
    /// - Throws: GuidedMeditationError if loading fails
    func loadMeditations() throws -> [GuidedMeditation]

    /// Saves all guided meditations to persistent storage
    ///
    /// - Parameter meditations: Array of meditations to save
    /// - Throws: GuidedMeditationError if saving fails
    func saveMeditations(_ meditations: [GuidedMeditation]) throws

    /// Adds a new guided meditation from a file URL
    ///
    /// Copies the file to Application Support/Meditations/ and creates a meditation entry.
    ///
    /// - Parameters:
    ///   - url: URL to the audio file (must have read access)
    ///   - metadata: Audio metadata (artist, title, duration)
    /// - Returns: The newly created GuidedMeditation
    /// - Throws: GuidedMeditationError if file copy fails
    func addMeditation(from url: URL, metadata: AudioMetadata) throws -> GuidedMeditation

    /// Updates an existing guided meditation
    ///
    /// - Parameter meditation: Updated meditation
    /// - Throws: GuidedMeditationError if update fails
    func updateMeditation(_ meditation: GuidedMeditation) throws

    /// Deletes a guided meditation and its local file
    ///
    /// - Parameter id: ID of meditation to delete
    /// - Throws: GuidedMeditationError if deletion fails
    func deleteMeditation(id: UUID) throws

    /// Returns the directory where meditation files are stored
    ///
    /// - Returns: URL to Application Support/Meditations/
    func getMeditationsDirectory() -> URL

    /// Checks if migration from legacy bookmarks is needed
    ///
    /// Returns true if there are meditations with bookmarks that haven't
    /// been migrated to local files yet.
    ///
    /// - Returns: True if migration is pending
    func needsMigration() -> Bool
}
