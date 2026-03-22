//
//  CustomAudioRepositoryProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Custom Audio Repository
//

import Foundation

/// Errors thrown by CustomAudioRepository operations
enum CustomAudioError: Error, LocalizedError {
    /// File format is not supported (e.g. .ogg, .flac)
    case unsupportedFormat(String)
    /// File could not be copied to local storage
    case fileCopyFailed(String)
    /// Metadata persistence failed
    case persistenceFailed(String)
    /// No file found for the given ID
    case fileNotFound(UUID)

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case let .unsupportedFormat(ext):
            String(
                format: NSLocalizedString("custom.audio.error.unsupportedFormat", comment: ""),
                ext
            )
        case .fileCopyFailed:
            NSLocalizedString("custom.audio.error.fileCopyFailed", comment: "")
        case .persistenceFailed:
            NSLocalizedString("custom.audio.error.persistenceFailed", comment: "")
        case .fileNotFound:
            NSLocalizedString("custom.audio.error.fileNotFound", comment: "")
        }
    }
}

/// Protocol for managing custom audio file persistence
///
/// Implementations copy imported files to local app storage, persist metadata,
/// and provide lookup by ID or type. Supports both soundscapes (background loops)
/// and attunements (one-shot attunement audio).
protocol CustomAudioRepositoryProtocol {
    /// Returns all stored custom audio files of the given type, sorted by dateAdded descending.
    func loadAll(type: CustomAudioType) -> [CustomAudioFile]

    /// Imports an audio file from the given URL.
    ///
    /// Copies the file to local storage, detects duration, creates metadata record.
    /// Supported formats: mp3, m4a, wav.
    /// - Throws: `CustomAudioError.unsupportedFormat` if the format is not supported.
    /// - Throws: `CustomAudioError.fileCopyFailed` if the file cannot be copied.
    func importFile(from url: URL, type: CustomAudioType) throws -> CustomAudioFile

    /// Deletes the custom audio file with the given ID.
    ///
    /// Removes the file from local storage and deletes the metadata record.
    /// - Throws: `CustomAudioError.fileNotFound` if no file exists with the given ID.
    func delete(id: UUID) throws

    /// Returns the local file URL for the given custom audio file, or nil if the file is missing.
    func fileURL(for audioFile: CustomAudioFile) -> URL?

    /// Finds a custom audio file by ID across all types, or nil if not found.
    func findFile(byId id: UUID) -> CustomAudioFile?

    /// Updates an existing custom audio file's metadata (e.g. display name).
    ///
    /// Only metadata is updated — the file on disk is not moved or renamed.
    /// - Throws: `CustomAudioError.fileNotFound` if no file exists with the given ID.
    func update(_ file: CustomAudioFile) throws
}
