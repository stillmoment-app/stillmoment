package com.stillmoment.domain.services

import com.stillmoment.domain.models.ApplePodcastsLink
import com.stillmoment.domain.models.PodcastEpisode

/**
 * Resolves a shared Apple Podcasts episode link to the episode's audio file
 * and metadata (shared-128).
 */
interface PodcastEpisodeResolverProtocol {

    /**
     * Looks up [link] at Apple's lookup service.
     *
     * On failure the [Throwable] is one of
     * [com.stillmoment.domain.models.PodcastEpisodeResolveError.NotReachable],
     * [com.stillmoment.domain.models.PodcastEpisodeResolveError.Unavailable], or
     * [kotlinx.coroutines.CancellationException] (user-initiated cancel).
     */
    suspend fun resolveEpisode(link: ApplePodcastsLink.Episode): Result<PodcastEpisode>

    /** Cancels an active lookup, if any. No-op when no lookup is running. */
    fun cancel()
}
