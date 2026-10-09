package com.stillmoment.domain.models

/**
 * A shared Apple Podcasts link (shared-128).
 *
 * Form: `https://podcasts.apple.com/<country>/podcast/<short-name>/id<podcastId>?i=<episodeId>`.
 * With a numeric `i` the link points to a single episode, without it to the
 * whole podcast. The short name is ignored. The country segment is kept
 * (lowercased) so the lookup can search the matching store.
 *
 * IDs are [Long]: episode IDs like `1000792422344` exceed `Int.MAX_VALUE`.
 *
 * 1:1 counterpart of the iOS `ApplePodcastsLink`.
 */
sealed class ApplePodcastsLink {
    abstract val country: String
    abstract val podcastId: Long

    data class Episode(
        override val country: String,
        override val podcastId: Long,
        val episodeId: Long
    ) : ApplePodcastsLink()

    data class Podcast(
        override val country: String,
        override val podcastId: Long
    ) : ApplePodcastsLink()

    companion object {
        private const val GROUP_COUNTRY = 1
        private const val GROUP_PODCAST_ID = 2
        private const val GROUP_QUERY = 3

        private val LINK_REGEX = Regex(
            """^https?://podcasts\.apple\.com/([a-z]{2})/podcast/(?:[^/?#]+/)?id(\d+)/?(?:\?([^#]*))?(?:#.*)?$""",
            RegexOption.IGNORE_CASE
        )

        /**
         * Parses [url]; returns `null` when it is not an Apple Podcasts podcast
         * or episode link (the caller then treats it as an ordinary link).
         * An empty, non-numeric or out-of-range `i` counts as "whole podcast".
         */
        fun parse(url: String): ApplePodcastsLink? {
            val match = LINK_REGEX.matchEntire(url.trim()) ?: return null
            val country = match.groupValues[GROUP_COUNTRY].lowercase()
            val podcastId = match.groupValues[GROUP_PODCAST_ID].toLongOrNull() ?: return null
            val episodeId = episodeIdFromQuery(match.groupValues[GROUP_QUERY])
            return if (episodeId != null) {
                Episode(country = country, podcastId = podcastId, episodeId = episodeId)
            } else {
                Podcast(country = country, podcastId = podcastId)
            }
        }

        private fun episodeIdFromQuery(query: String): Long? {
            return query.split('&')
                .firstOrNull { it.startsWith("i=") }
                ?.removePrefix("i=")
                ?.takeIf { value -> value.isNotEmpty() && value.all { it.isDigit() } }
                ?.toLongOrNull()
        }
    }
}
