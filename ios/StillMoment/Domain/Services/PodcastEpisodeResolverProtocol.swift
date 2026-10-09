//
//  PodcastEpisodeResolverProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Resolves a shared podcast episode to its audio file (shared-128)
//

import Foundation

/// Finds a podcast episode in the podcast directory and returns its audio file address.
protocol PodcastEpisodeResolverProtocol {
    /// Resolves an episode of a podcast.
    ///
    /// - Throws: `PodcastEpisodeResolveError`
    func resolveEpisode(country: String, podcastId: Int64, episodeId: Int64) async throws -> PodcastEpisode

    /// Cancels a running lookup
    func cancel()
}
