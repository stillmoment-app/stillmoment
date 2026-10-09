//
//  ApplePodcastsLink.swift
//  Still Moment
//
//  Domain Model - Recognizes shared Apple Podcasts links (shared-128)
//

import Foundation

/// A link shared from Apple Podcasts.
///
/// Form: `https://podcasts.apple.com/<land>/podcast/<kurzname>/id<Podcast-ID>?i=<Folgen-ID>`.
/// The link names the podcast, not the episode — the episode is resolved separately.
enum ApplePodcastsLink: Equatable {
    /// A single episode (`?i=<Folgen-ID>` present)
    case episode(country: String, podcastId: Int64, episodeId: Int64)
    /// A whole podcast without a single episode
    case podcast(country: String, podcastId: Int64)

    // MARK: Internal

    /// Recognizes an Apple Podcasts link.
    ///
    /// - Returns: `nil` if the URL is not an Apple Podcasts podcast/episode link — then the
    ///   regular link import applies.
    static func parse(_ url: URL) -> ApplePodcastsLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              components.host?.lowercased() == Self.host
        else {
            return nil
        }

        let segments = url.pathComponents.filter { $0 != "/" }
        guard segments.count >= 3,
              let country = Self.country(from: segments[0]),
              segments[1].lowercased() == "podcast",
              let lastSegment = segments.last,
              let podcastId = Self.numericId(lastSegment.lowercased(), prefix: "id")
        else {
            return nil
        }

        let episodeValue = components.queryItems?.first { $0.name == "i" }?.value
        if let episodeValue, let episodeId = Self.numericId(episodeValue, prefix: "") {
            return .episode(country: country, podcastId: podcastId, episodeId: episodeId)
        }
        return .podcast(country: country, podcastId: podcastId)
    }

    // MARK: Private

    private static let host = "podcasts.apple.com"

    /// Two-letter store country (`de`, `us`, …), lowercased.
    private static func country(from segment: String) -> String? {
        let lowered = segment.lowercased()
        guard lowered.count == 2, lowered.allSatisfy({ $0.isASCII && $0.isLetter }) else {
            return nil
        }
        return lowered
    }

    /// Parses `<prefix><digits>` into a number; rejects anything else.
    private static func numericId(_ value: String, prefix: String) -> Int64? {
        guard value.hasPrefix(prefix) else {
            return nil
        }
        let digits = value.dropFirst(prefix.count)
        guard !digits.isEmpty, digits.allSatisfy({ $0.isASCII && $0.isNumber }) else {
            return nil
        }
        return Int64(digits)
    }
}
