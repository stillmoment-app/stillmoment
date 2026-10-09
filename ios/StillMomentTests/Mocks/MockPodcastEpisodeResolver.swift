//
//  MockPodcastEpisodeResolver.swift
//  Still Moment
//

import Foundation
@testable import StillMoment

final class MockPodcastEpisodeResolver: PodcastEpisodeResolverProtocol {
    struct Request: Equatable {
        let country: String
        let podcastId: Int64
        let episodeId: Int64
    }

    /// Returned on success. If `nil`, a default episode is returned.
    var episodeToReturn: PodcastEpisode?
    /// Wenn gesetzt, wirft `resolveEpisode` diesen Fehler.
    var errorToThrow: PodcastEpisodeResolveError?
    /// Laeuft, waehrend die Suche "unterwegs" ist — z.B. um dort Abbrechen zu tippen.
    /// Wurde dabei abgebrochen, wirft die Suche wie der echte Resolver `.cancelled`.
    var whileResolving: (@MainActor () -> Void)?
    /// Laeuft, nachdem die Suche fertig ist (das Ergebnis steht schon fest).
    var afterResolved: (@MainActor () -> Void)?

    private(set) var requests: [Request] = []
    private(set) var cancelCalled = false

    func resolveEpisode(country: String, podcastId: Int64, episodeId: Int64) async throws -> PodcastEpisode {
        self.requests.append(Request(country: country, podcastId: podcastId, episodeId: episodeId))
        if let whileResolving {
            await whileResolving()
        }
        if self.cancelCalled {
            throw PodcastEpisodeResolveError.cancelled
        }
        if let errorToThrow {
            throw errorToThrow
        }
        let episode = try self.episodeToReturn ?? Self.defaultEpisode()
        if let afterResolved {
            await afterResolved()
        }
        return episode
    }

    func cancel() {
        self.cancelCalled = true
    }

    private static func defaultEpisode() throws -> PodcastEpisode {
        guard let url = URL(string: "https://anbieter.example/folge.mp3") else {
            throw PodcastEpisodeResolveError.unavailable
        }
        return PodcastEpisode(audioURL: url, title: "Folge", podcastAuthor: "Autor", podcastName: "Podcast")
    }
}
