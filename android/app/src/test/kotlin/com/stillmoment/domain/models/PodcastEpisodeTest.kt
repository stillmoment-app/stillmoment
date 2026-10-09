package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * shared-128: Suggestions for the edit sheet from a podcast episode.
 */
class PodcastEpisodeTest {

    private fun episode(
        title: String? = "MBCT - Achtsame Therapie gegen Depressionen",
        podcastAuthor: String? = "Deutschlandfunk Nova",
        podcastName: String? = "Achtsam - Deutschlandfunk Nova"
    ) = PodcastEpisode(
        audioUrl = "https://podcast-mp3.dradio.de/folge.mp3",
        title = title,
        podcastAuthor = podcastAuthor,
        podcastName = podcastName
    )

    @Nested
    inner class TeacherSuggestion {

        @Test
        fun `podcast author is suggested as teacher`() {
            assertEquals("Deutschlandfunk Nova", episode().teacherSuggestion)
        }

        @Test
        fun `podcast name is suggested when author is missing`() {
            assertEquals("Achtsam - Deutschlandfunk Nova", episode(podcastAuthor = null).teacherSuggestion)
        }

        @Test
        fun `blank author counts as missing`() {
            assertEquals("Achtsam - Deutschlandfunk Nova", episode(podcastAuthor = "  ").teacherSuggestion)
        }

        @Test
        fun `no suggestion when author and podcast name are missing`() {
            assertNull(episode(podcastAuthor = "", podcastName = null).teacherSuggestion)
        }
    }

    @Nested
    inner class ImportSuggestion {

        @Test
        fun `episode title and teacher become the import suggestion`() {
            assertEquals(
                ImportPrefill(teacher = "Deutschlandfunk Nova", name = "MBCT - Achtsame Therapie gegen Depressionen"),
                episode().importSuggestion()
            )
        }

        @Test
        fun `episode title is kept verbatim, nothing is cut off`() {
            assertEquals("Body Scan (20:34 Min.)", episode(title = "  Body Scan (20:34 Min.) ").importSuggestion().name)
        }

        @Test
        fun `blank title gives no title suggestion`() {
            assertNull(episode(title = " ").importSuggestion().name)
        }
    }

    @Nested
    inner class UpgradeToHttps {

        @Test
        fun `http address is loaded via https`() {
            assertEquals(
                "https://anbieter.example/folge.mp3",
                PodcastEpisode.upgradeToHttps("http://anbieter.example/folge.mp3")
            )
        }

        @Test
        fun `https address stays unchanged`() {
            assertEquals(
                "https://anbieter.example/folge.mp3",
                PodcastEpisode.upgradeToHttps("https://anbieter.example/folge.mp3")
            )
        }
    }
}
