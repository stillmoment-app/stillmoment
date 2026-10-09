//
//  ShareOutcome.swift
//  Still Moment
//
//  Domain Model - What the Share Extension shows after sharing (ios-059)
//

import Foundation

/// The content the Share Extension received from the system Share Sheet.
enum SharedContent: Equatable {
    /// An audio file shared directly (e.g. from Files, Mail). The URL carries the file name.
    case audioFile(URL)
    /// A link shared from Safari or another app.
    case link(URL)
    /// No attachment, an attachment that is neither audio nor link, or one that could not be loaded.
    case nothing
}

/// What the Share Extension shows after sharing: the confirmation or a message.
///
/// Lives in the app's Domain layer so `StillMomentTests` can test it; the file is also a
/// member of the Share Extension target, which is its only user. The app itself does not
/// use this type — the import (incl. checking whether a link really points to audio)
/// happens later in the app.
enum ShareOutcome: Equatable {
    /// The content was accepted and lands in the inbox; the app imports it on next open.
    case confirmation
    /// An audio file in a format other than MP3/M4A.
    case unsupportedFormat
    /// A link that is not a web address (e.g. `mailto:`, `tel:`).
    case noLink
    /// Missing or unreadable content, or writing to the inbox failed.
    case unreadable

    // MARK: Internal

    /// File extensions the app can import (case-insensitive).
    static let supportedFileExtensions: Set<String> = ["mp3", "m4a"]

    /// Link schemes the app can download from (case-insensitive).
    static let supportedLinkSchemes: Set<String> = ["http", "https"]

    /// Decides what the Share Extension shows for the shared content.
    ///
    /// Writing to the inbox is not part of this decision: if it fails after `.confirmation`,
    /// the extension shows `.unreadable`.
    static func evaluate(_ content: SharedContent) -> ShareOutcome {
        switch content {
        case let .audioFile(url):
            self.supportedFileExtensions.contains(url.pathExtension.lowercased())
                ? .confirmation
                : .unsupportedFormat
        case let .link(url):
            self.supportedLinkSchemes.contains(url.scheme?.lowercased() ?? "")
                ? .confirmation
                : .noLink
        case .nothing:
            .unreadable
        }
    }
}
