package com.stillmoment.domain.models

/**
 * What went wrong when importing a shared link — decides which message the
 * user sees and whether "Retry" is offered (shared-128).
 *
 * Podcast import (Apple Podcasts links) only ever ends in
 * [PodcastWithoutEpisode], [NotReachable] or [EpisodeUnavailable]; the ordinary
 * link import additionally knows [NotAudio] and [DownloadFailed].
 */
sealed class LinkImportFailure {

    /** "Retry" is only offered when another attempt can change the outcome. */
    abstract val canRetry: Boolean

    /** The link points to a whole podcast instead of a single episode. */
    data object PodcastWithoutEpisode : LinkImportFailure() {
        override val canRetry = false
    }

    /** No connection, timeout, or Apple's lookup service is overloaded. */
    data object NotReachable : LinkImportFailure() {
        override val canRetry = true
    }

    /** Episode not found, video, paid, gone at the provider, unexpected answer. */
    data object EpisodeUnavailable : LinkImportFailure() {
        override val canRetry = false
    }

    /** Ordinary link import: the address does not lead to an audio file. */
    data object NotAudio : LinkImportFailure() {
        override val canRetry = false
    }

    /** Ordinary link import: the server answered with an error status. */
    data object DownloadFailed : LinkImportFailure() {
        override val canRetry = true
    }
}
