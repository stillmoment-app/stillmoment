package com.stillmoment.infrastructure.network

import com.stillmoment.domain.models.PodcastEpisode
import com.stillmoment.domain.models.PodcastEpisodeResolveError
import kotlinx.serialization.SerializationException
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows

/**
 * shared-128: Finding the shared episode in Apple's lookup answer.
 *
 * Test data is a shortened real answer (`itunes.apple.com/lookup?id=1528936478
 * &entity=podcastEpisode&limit=200`, 2026-10-09) with the real field names.
 */
class ApplePodcastsLookupResponseTest {

    private val episodeId = 1000792422344L

    private val podcastEntry = """
        {"wrapperType":"track","kind":"podcast","collectionId":1528936478,"trackId":1528936478,
         "artistName":"Deutschlandfunk Nova","collectionName":"Achtsam - Deutschlandfunk Nova",
         "trackName":"Achtsam - Deutschlandfunk Nova","feedUrl":"https://www.deutschlandfunknova.de/podcast/achtsam"}
    """.trimIndent()

    private fun episodeEntry(
        trackId: String = "1000792422344",
        trackName: String = "\"MBCT - Achtsame Therapie gegen Depressionen\"",
        episodeUrl: String? = "\"https://podcast-mp3.dradio.de/podcast/2026/10/01/achtsam_mbct.mp3\"",
        contentType: String = "\"audio\""
    ): String {
        val urlField = episodeUrl?.let { ""","episodeUrl":$it""" }.orEmpty()
        return """
            {"wrapperType":"podcastEpisode","kind":"podcast-episode","collectionId":1528936478,
             "trackId":$trackId,"trackName":$trackName,"collectionName":"Achtsam - Deutschlandfunk Nova",
             "episodeContentType":$contentType,"episodeFileExtension":"mp3"$urlField}
        """.trimIndent()
    }

    private fun response(vararg entries: String) =
        """{"resultCount":${entries.size},"results":[${entries.joinToString(",")}]}"""

    private fun assertUnavailable(result: Result<PodcastEpisode>) {
        assertTrue(result.exceptionOrNull() is PodcastEpisodeResolveError.Unavailable) {
            "Expected Unavailable, got $result"
        }
    }

    @Nested
    inner class FindsEpisode {

        @Test
        fun `shared episode is found with audio address, title and podcast author`() {
            val other = episodeEntry(trackId = "1000792000000", trackName = "\"Andere Folge\"")

            val result = ApplePodcastsLookupResponse.parse(
                response(podcastEntry, other, episodeEntry()),
                episodeId
            )

            assertEquals(
                PodcastEpisode(
                    audioUrl = "https://podcast-mp3.dradio.de/podcast/2026/10/01/achtsam_mbct.mp3",
                    title = "MBCT - Achtsame Therapie gegen Depressionen",
                    podcastAuthor = "Deutschlandfunk Nova",
                    podcastName = "Achtsam - Deutschlandfunk Nova"
                ),
                result.getOrNull()
            )
        }

        @Test
        fun `podcast entry with same id is not mistaken for the episode`() {
            // The podcast entry's trackId equals the podcast id — only episodes count
            val result = ApplePodcastsLookupResponse.parse(response(podcastEntry), 1528936478L)

            assertUnavailable(result)
        }

        @Test
        fun `missing podcast author leaves author empty, podcast name stays`() {
            val podcastWithoutAuthor = """
                {"wrapperType":"track","kind":"podcast","trackId":1528936478,
                 "collectionName":"Achtsam - Deutschlandfunk Nova"}
            """.trimIndent()

            val episode = ApplePodcastsLookupResponse.parse(
                response(podcastWithoutAuthor, episodeEntry()),
                episodeId
            ).getOrNull()

            assertEquals(null, episode?.podcastAuthor)
            assertEquals("Achtsam - Deutschlandfunk Nova", episode?.teacherSuggestion)
        }

        @Test
        fun `empty podcast name falls back to the name at the episode`() {
            // Same as iOS: an empty name at the podcast entry counts as missing
            val podcastWithEmptyName = """
                {"wrapperType":"track","kind":"podcast","trackId":1528936478,"collectionName":" "}
            """.trimIndent()

            val episode = ApplePodcastsLookupResponse.parse(
                response(podcastWithEmptyName, episodeEntry()),
                episodeId
            ).getOrNull()

            assertEquals("Achtsam - Deutschlandfunk Nova", episode?.teacherSuggestion)
        }

        @Test
        fun `http audio address is accepted`() {
            val result = ApplePodcastsLookupResponse.parse(
                response(podcastEntry, episodeEntry(episodeUrl = "\"http://anbieter.example/folge.mp3\"")),
                episodeId
            )

            assertEquals("http://anbieter.example/folge.mp3", result.getOrNull()?.audioUrl)
        }
    }

    @Nested
    inner class CannotBeImported {

        @Test
        fun `older episode not in the answer cannot be imported`() {
            assertUnavailable(ApplePodcastsLookupResponse.parse(response(podcastEntry, episodeEntry()), 42L))
        }

        @Test
        fun `video episode cannot be imported`() {
            assertUnavailable(
                ApplePodcastsLookupResponse.parse(
                    response(podcastEntry, episodeEntry(contentType = "\"video\"")),
                    episodeId
                )
            )
        }

        @Test
        fun `video episode cannot be imported regardless of spelling`() {
            assertUnavailable(
                ApplePodcastsLookupResponse.parse(
                    response(podcastEntry, episodeEntry(contentType = "\"Video\"")),
                    episodeId
                )
            )
        }

        @Test
        fun `episode without audio address cannot be imported`() {
            assertUnavailable(
                ApplePodcastsLookupResponse.parse(response(podcastEntry, episodeEntry(episodeUrl = null)), episodeId)
            )
        }

        @Test
        fun `episode with non-web audio address cannot be imported`() {
            assertUnavailable(
                ApplePodcastsLookupResponse.parse(
                    response(podcastEntry, episodeEntry(episodeUrl = "\"ftp://anbieter.example/folge.mp3\"")),
                    episodeId
                )
            )
        }

        @Test
        fun `broken json is reported as malformed`() {
            // The resolver logs this and maps it to "cannot be imported"
            assertThrows<SerializationException> {
                ApplePodcastsLookupResponse.parse("{\"results\": [", episodeId)
            }
        }

        @Test
        fun `answer without results cannot be imported`() {
            assertUnavailable(ApplePodcastsLookupResponse.parse("{\"resultCount\":0}", episodeId))
        }

        @Test
        fun `answer that is not an object cannot be imported`() {
            assertUnavailable(ApplePodcastsLookupResponse.parse("[1,2,3]", episodeId))
        }

        @Test
        fun `track id too long for any number does not crash`() {
            val result = ApplePodcastsLookupResponse.parse(
                response(podcastEntry, episodeEntry(trackId = "1234567890123456789012345")),
                episodeId
            )

            assertUnavailable(result)
        }
    }
}
