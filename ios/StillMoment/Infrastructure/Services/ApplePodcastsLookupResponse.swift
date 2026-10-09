//
//  ApplePodcastsLookupResponse.swift
//  Still Moment
//
//  Infrastructure - Answer of Apple's podcast directory lookup (shared-128)
//

import Foundation

/// Answer of `itunes.apple.com/lookup?id=<Podcast-ID>&entity=podcastEpisode`.
///
/// Contains the podcast entry (`kind == "podcast"`) and up to 200 of its newest episodes
/// (`wrapperType == "podcastEpisode"`). Order is not relied upon.
struct ApplePodcastsLookupResponse: Decodable {
    struct Entry: Decodable {
        let wrapperType: String?
        let kind: String?
        let trackId: Int64?
        let trackName: String?
        let artistName: String?
        let collectionName: String?
        let episodeUrl: String?
        let episodeContentType: String?
    }

    let results: [Entry]

    // MARK: Internal

    /// Finds the episode with the given ID in a lookup answer.
    ///
    /// - Throws: `PodcastEpisodeResolveError.unavailable` if the answer is unexpected, the episode is
    ///   missing (older than the newest ~200), is a video, or has no web address for its audio file.
    static func episode(withId episodeId: Int64, from data: Data) throws -> PodcastEpisode {
        guard let response = try? JSONDecoder().decode(Self.self, from: data) else {
            throw PodcastEpisodeResolveError.unavailable
        }
        guard let entry = response.results.first(where: { $0.isEpisode && $0.trackId == episodeId }),
              entry.episodeContentType?.lowercased() != "video",
              let audioURL = Self.webAudioURL(entry.episodeUrl)
        else {
            throw PodcastEpisodeResolveError.unavailable
        }

        let podcast = response.results.first { $0.kind == "podcast" }
        return PodcastEpisode(
            audioURL: audioURL,
            title: entry.trackName?.nonBlankTrimmed,
            podcastAuthor: podcast?.artistName,
            podcastName: podcast?.collectionName?.nonBlankTrimmed ?? entry.collectionName
        )
    }

    // MARK: Private

    /// Accepts `http`/`https` only; `http` is rewritten to `https` (App Transport Security blocks `http`).
    private static func webAudioURL(_ raw: String?) -> URL? {
        guard let raw,
              let url = URL(string: raw),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              components.host != nil
        else {
            return nil
        }
        components.scheme = "https"
        return components.url
    }
}

private extension ApplePodcastsLookupResponse.Entry {
    var isEpisode: Bool {
        self.wrapperType == "podcastEpisode"
    }
}
