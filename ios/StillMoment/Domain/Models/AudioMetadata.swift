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

    /// Returns metadata where non-empty suggestions replace title and artist from the file.
    ///
    /// Used when a better source than the file's tags is known (shared-128: podcast directory).
    /// Missing or empty suggestions keep the file's values; duration and album stay unchanged.
    func preferring(title preferredTitle: String?, artist preferredArtist: String?) -> AudioMetadata {
        AudioMetadata(
            artist: Self.nonEmpty(preferredArtist) ?? self.artist,
            title: Self.nonEmpty(preferredTitle) ?? self.title,
            duration: self.duration,
            album: self.album
        )
    }

    // MARK: Private

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return value
    }
}
