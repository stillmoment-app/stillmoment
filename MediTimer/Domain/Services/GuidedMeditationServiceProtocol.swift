//
//  GuidedMeditationServiceProtocol.swift
//  MediTimer
//
//  Domain Service Protocol - Guided Meditation Management
//

import Foundation

/// Errors that can occur during guided meditation management
enum GuidedMeditationError: Error, LocalizedError {
    case persistenceFailed(reason: String)
    case bookmarkCreationFailed
    case bookmarkResolutionFailed
    case fileAccessDenied
    case meditationNotFound(id: UUID)

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .persistenceFailed(let reason):
            "Failed to persist meditation library: \(reason)"
        case .bookmarkCreationFailed:
            "Failed to create security-scoped bookmark for file"
        case .bookmarkResolutionFailed:
            "Failed to resolve security-scoped bookmark"
        case .fileAccessDenied:
            "Access to file denied"
        case .meditationNotFound(let id):
            "Meditation with ID \(id) not found"
        }
    }
}

/// Service for managing guided meditation library
///
/// This service handles CRUD operations for guided meditations, including:
/// - Loading/saving from/to persistent storage (UserDefaults)
/// - Creating security-scoped bookmarks for external files
/// - Resolving bookmarks to access files
protocol GuidedMeditationServiceProtocol {
    /// Loads all guided meditations from persistent storage
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
    /// Creates a security-scoped bookmark for the file and adds it to the library.
    ///
    /// - Parameters:
    ///   - url: URL to the audio file
    ///   - metadata: Audio metadata (artist, title, duration)
    /// - Returns: The newly created GuidedMeditation
    /// - Throws: GuidedMeditationError if bookmark creation fails
    func addMeditation(from url: URL, metadata: AudioMetadata) throws -> GuidedMeditation

    /// Updates an existing guided meditation
    ///
    /// - Parameter meditation: Updated meditation
    /// - Throws: GuidedMeditationError if update fails
    func updateMeditation(_ meditation: GuidedMeditation) throws

    /// Deletes a guided meditation
    ///
    /// - Parameter id: ID of meditation to delete
    /// - Throws: GuidedMeditationError if deletion fails
    func deleteMeditation(id: UUID) throws

    /// Resolves a security-scoped bookmark to a file URL
    ///
    /// - Parameter bookmark: Security-scoped bookmark data
    /// - Returns: URL to the file
    /// - Throws: GuidedMeditationError if resolution fails
    func resolveBookmark(_ bookmark: Data) throws -> URL

    /// Starts accessing a security-scoped resource
    ///
    /// Must be called before accessing a file resolved from a bookmark.
    /// Call `stopAccessingSecurityScopedResource` when done.
    ///
    /// - Parameter url: URL returned from resolveBookmark
    /// - Returns: True if access was granted
    func startAccessingSecurityScopedResource(_ url: URL) -> Bool

    /// Stops accessing a security-scoped resource
    ///
    /// Must be called after finishing with a file accessed via bookmark.
    ///
    /// - Parameter url: URL returned from resolveBookmark
    func stopAccessingSecurityScopedResource(_ url: URL)
}
