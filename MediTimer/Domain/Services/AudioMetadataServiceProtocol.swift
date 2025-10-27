//
//  AudioMetadataServiceProtocol.swift
//  MediTimer
//
//  Domain Service Protocol - Audio Metadata Extraction
//

import Foundation

/// Errors that can occur during audio metadata extraction
enum AudioMetadataError: Error, LocalizedError {
    case fileNotAccessible
    case invalidAudioFile
    case metadataNotAvailable
    case durationNotAvailable

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .fileNotAccessible:
            "Could not access audio file"
        case .invalidAudioFile:
            "File is not a valid audio file"
        case .metadataNotAvailable:
            "Could not read metadata from audio file"
        case .durationNotAvailable:
            "Could not determine audio duration"
        }
    }
}

/// Service for extracting metadata from audio files
///
/// This service reads ID3 tags and other metadata from audio files (primarily MP3),
/// extracting information like artist, title, and duration.
protocol AudioMetadataServiceProtocol {
    /// Extracts metadata from an audio file at the given URL
    ///
    /// - Parameter url: URL to the audio file
    /// - Returns: AudioMetadata containing extracted information
    /// - Throws: AudioMetadataError if metadata cannot be extracted
    func extractMetadata(from url: URL) async throws -> AudioMetadata
}
