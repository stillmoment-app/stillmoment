package com.stillmoment.domain.models

/**
 * Failure cases of [com.stillmoment.domain.services.PodcastEpisodeResolverProtocol] (shared-128).
 *
 * Only the two outcomes that matter to the user. Cancellation stays on its own
 * channel via [kotlinx.coroutines.CancellationException].
 */
sealed class PodcastEpisodeResolveError(message: String) : Throwable(message) {

    /** No connection, timeout, or Apple's lookup service is overloaded (HTTP 403/429). Retry may help. */
    object NotReachable : PodcastEpisodeResolveError("Lookup service not reachable")

    /** Episode not found, video, no audio address, unexpected answer. Retry won't help. */
    object Unavailable : PodcastEpisodeResolveError("Episode cannot be imported")
}
