package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.ValueSource

/**
 * shared-128: Recognising Apple Podcasts links — single episode, whole podcast,
 * or something else entirely.
 */
class ApplePodcastsLinkTest {

    private val podcastId = 1528936478L
    private val episodeId = 1000792422344L

    @Nested
    inner class Episode {

        @Test
        fun `shared episode link is recognised as episode`() {
            val link = ApplePodcastsLink.parse(
                "https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478?i=1000792422344"
            )

            assertEquals(ApplePodcastsLink.Episode(country = "de", podcastId = podcastId, episodeId = episodeId), link)
        }

        @Test
        fun `episode link without podcast short name is recognised`() {
            val link = ApplePodcastsLink.parse("https://podcasts.apple.com/de/podcast/id1528936478?i=1000792422344")

            assertEquals(ApplePodcastsLink.Episode(country = "de", podcastId = podcastId, episodeId = episodeId), link)
        }

        @ParameterizedTest
        @ValueSource(strings = ["de", "us", "gb", "at"])
        fun `every country variant is recognised`(country: String) {
            val link = ApplePodcastsLink.parse(
                "https://podcasts.apple.com/$country/podcast/achtsam/id1528936478?i=1000792422344"
            )

            assertEquals(
                ApplePodcastsLink.Episode(country = country, podcastId = podcastId, episodeId = episodeId),
                link
            )
        }

        @Test
        fun `host and country in capitals are recognised, country is lowercased`() {
            val link = ApplePodcastsLink.parse("https://Podcasts.Apple.com/US/podcast/x/id1528936478?i=1000792422344")

            assertEquals(ApplePodcastsLink.Episode(country = "us", podcastId = podcastId, episodeId = episodeId), link)
        }

        @Test
        fun `additional query parameters in any order are ignored`() {
            val link = ApplePodcastsLink.parse(
                "https://podcasts.apple.com/de/podcast/achtsam/id1528936478?l=en&i=1000792422344"
            )

            assertEquals(ApplePodcastsLink.Episode(country = "de", podcastId = podcastId, episodeId = episodeId), link)
        }

        @Test
        fun `episode link without country segment is recognised without country`() {
            val link = ApplePodcastsLink.parse(
                "https://podcasts.apple.com/podcast/achtsam/id1528936478?i=1000792422344"
            )

            assertEquals(ApplePodcastsLink.Episode(country = null, podcastId = podcastId, episodeId = episodeId), link)
        }

        @Test
        fun `episode ids beyond Int range are kept exactly`() {
            val link = ApplePodcastsLink.parse("https://podcasts.apple.com/us/podcast/x/id9999999999?i=9000000000001")

            assertEquals(
                ApplePodcastsLink.Episode(country = "us", podcastId = 9_999_999_999L, episodeId = 9_000_000_000_001L),
                link
            )
        }
    }

    @Nested
    inner class WholePodcast {

        @Test
        fun `link without episode is a whole podcast`() {
            val link = ApplePodcastsLink.parse(
                "https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478"
            )

            assertEquals(ApplePodcastsLink.Podcast(country = "de", podcastId = podcastId), link)
        }

        @Test
        fun `whole podcast link without country segment is recognised without country`() {
            val link = ApplePodcastsLink.parse("https://podcasts.apple.com/podcast/achtsam/id1528936478")

            assertEquals(ApplePodcastsLink.Podcast(country = null, podcastId = podcastId), link)
        }

        @Test
        fun `empty or non-numeric episode parameter counts as whole podcast`() {
            assertEquals(
                ApplePodcastsLink.Podcast(country = "de", podcastId = podcastId),
                ApplePodcastsLink.parse("https://podcasts.apple.com/de/podcast/achtsam/id1528936478?i=")
            )
            assertEquals(
                ApplePodcastsLink.Podcast(country = "de", podcastId = podcastId),
                ApplePodcastsLink.parse("https://podcasts.apple.com/de/podcast/achtsam/id1528936478?i=abc")
            )
        }

        @Test
        fun `episode id too long for any number does not crash`() {
            val link = ApplePodcastsLink.parse(
                "https://podcasts.apple.com/de/podcast/achtsam/id1528936478?i=1234567890123456789012345"
            )

            assertEquals(ApplePodcastsLink.Podcast(country = "de", podcastId = podcastId), link)
        }
    }

    @Nested
    inner class NotApplePodcasts {

        @ParameterizedTest
        @ValueSource(
            strings = [
                "https://example.com/podcast/id123?i=456",
                "https://example.com/meditation.mp3",
                "https://podcasts.apple.com.evil.example/de/podcast/x/id1?i=2",
                "https://podcasts.apple.com/de/browse",
                "https://music.apple.com/de/album/x/id1528936478?i=1000792422344",
                "https://podcasts.apple.com/de/podcast/x/id1234567890123456789012345?i=1"
            ]
        )
        fun `other links are not Apple Podcasts links`(url: String) {
            assertNull(ApplePodcastsLink.parse(url))
        }
    }
}
