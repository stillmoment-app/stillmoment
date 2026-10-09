//
//  AudioContentType.swift
//  Still Moment
//
//  Domain Model - File types accepted when loading audio from a shared link (shared-131)
//

import Foundation

/// The file types (server `Content-Type`) that link import and podcast import accept.
///
/// Identical on iOS and Android. This is an acceptance list for downloading only —
/// which formats the library can play (MP3, M4A) is decided elsewhere.
enum AudioContentType {
    // MARK: Internal

    /// Whether a file with the given server-reported type is accepted.
    ///
    /// Case and parameters after `;` (e.g. `charset=…`) are ignored, the comparison is exact
    /// (`audio/mpegurl` is a playlist, not `audio/mpeg`). A missing type is accepted — many
    /// servers omit it. An empty type is rejected, like on Android.
    static func isAccepted(_ contentType: String?) -> Bool {
        guard let contentType else {
            return true
        }
        let mediaType = contentType
            .split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init) ?? ""
        return self.acceptedTypes.contains(mediaType.trimmingCharacters(in: .whitespaces).lowercased())
    }

    // MARK: Private

    /// "audio/mp3", "audio/x-mpeg", "audio/mpeg3" are non-standard but sent by real servers
    /// (e.g. audiodharma's S3 backend). "application/octet-stream" covers servers that don't
    /// name a specific audio type.
    private static let acceptedTypes: Set<String> = [
        "audio/mpeg",
        "audio/mp3",
        "audio/x-mpeg",
        "audio/mpeg3",
        "audio/mp4",
        "audio/x-m4a",
        "audio/m4a",
        "application/octet-stream"
    ]
}
