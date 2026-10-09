//
//  ApplePodcastsEpisodeResolver.swift
//  Still Moment
//
//  Infrastructure - Resolves an Apple Podcasts episode to its audio file (shared-128)
//

import Foundation
import OSLog

/// Looks up a podcast's newest episodes in Apple's public podcast directory
/// (`itunes.apple.com/lookup`, no key) and finds the shared episode.
///
/// Called only after the user shared a link (or tapped Retry). The request carries
/// no extra headers and no cookies.
final class ApplePodcastsEpisodeResolver: PodcastEpisodeResolverProtocol {
    // MARK: Lifecycle

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: Internal

    /// Builds the lookup request: newest episodes (max. 200) of a podcast in the shared store country.
    /// Links without a store country omit the `country` parameter (Apple then uses its default store).
    static func lookupRequest(country: String?, podcastId: Int64) -> URLRequest? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "itunes.apple.com"
        components.path = "/lookup"
        var queryItems = [
            URLQueryItem(name: "id", value: String(podcastId)),
            URLQueryItem(name: "entity", value: "podcastEpisode"),
            URLQueryItem(name: "limit", value: String(Self.episodeLimit))
        ]
        if let country {
            queryItems.append(URLQueryItem(name: "country", value: country))
        }
        components.queryItems = queryItems
        guard let url = components.url else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpShouldHandleCookies = false
        return request
    }

    func resolveEpisode(country: String?, podcastId: Int64, episodeId: Int64) async throws -> PodcastEpisode {
        guard let request = Self.lookupRequest(country: country, podcastId: podcastId) else {
            throw PodcastEpisodeResolveError.unavailable
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await self.session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw PodcastEpisodeResolveError.cancelled
        } catch is CancellationError {
            throw PodcastEpisodeResolveError.cancelled
        } catch {
            Logger.infrastructure.info("Podcast lookup not reachable: \(error.localizedDescription)")
            throw PodcastEpisodeResolveError.notReachable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PodcastEpisodeResolveError.unavailable
        }
        switch httpResponse.statusCode {
        case 200...299:
            return try ApplePodcastsLookupResponse.episode(withId: episodeId, from: data)
        case 403,
             429:
            Logger.infrastructure.info("Podcast lookup rate limited: HTTP \(httpResponse.statusCode)")
            throw PodcastEpisodeResolveError.notReachable
        default:
            Logger.infrastructure.error("Podcast lookup failed: HTTP \(httpResponse.statusCode)")
            throw PodcastEpisodeResolveError.unavailable
        }
    }

    /// Note: Cancels all tasks on the session, like `AudioDownloadService.cancelDownload()`.
    /// Safe because only one share is processed at a time (enforced by InboxHandler).
    func cancel() {
        self.session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }

    // MARK: Private

    private static let episodeLimit = 200

    private let session: URLSession
}
