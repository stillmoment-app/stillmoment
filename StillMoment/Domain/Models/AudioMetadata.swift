//
//  AudioMetadata.swift
//  Still Moment
//
//  Domain Model - Audio Metadata
//

import Foundation

/// Represents metadata extracted from an audio file (typically MP3 ID3 tags)
///
/// This value type contains information read from audio file metadata,
/// which can be used to populate GuidedMeditation properties.
struct AudioMetadata: Equatable {
    // MARK: Lifecycle

    /// Initializes audio metadata
    ///
    /// - Parameters:
    ///   - artist: Artist name from ID3 tag
    ///   - title: Title from ID3 tag
    ///   - duration: Duration in seconds
    ///   - album: Optional album name
    init(
        artist: String?,
        title: String?,
        duration: TimeInterval,
        album: String? = nil
    ) {
        self.artist = artist
        self.title = title
        self.duration = duration
        self.album = album
    }

    // MARK: Internal

    /// Artist name (typically used as teacher/guide)
    let artist: String?

    /// Title/Track name (typically used as meditation name)
    let title: String?

    /// Duration in seconds
    let duration: TimeInterval

    /// Album name (optional, for potential future use)
    let album: String?
}
