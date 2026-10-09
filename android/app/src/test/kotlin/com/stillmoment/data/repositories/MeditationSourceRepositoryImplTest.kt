package com.stillmoment.data.repositories

import com.stillmoment.domain.models.MeditationSource
import java.io.File
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for MeditationSourceRepositoryImpl.
 *
 * Tests JSON parsing and locale selection via the companion object's
 * parseSourcesJson() method, which does not require Android Context.
 */
class MeditationSourceRepositoryImplTest {

    companion object {
        /** Unit-test working dir is the app module. */
        private const val SHIPPED_JSON_PATH = "src/main/assets/meditation_sources.json"

        private val VALID_JSON = """
            {
              "de": [
                {
                  "id": "mangold",
                  "name": "Jörg Mangold",
                  "offer": "Achtsamkeit & Selbstmitgefühl",
                  "description": "MBSR, MSC, Körperscans.",
                  "host": "podcast",
                  "url": "https://example.de/mangold"
                },
                {
                  "id": "koeln",
                  "name": "Zentrum für Achtsamkeit Köln",
                  "offer": null,
                  "description": "MBSR Body Scan, Sitzmeditation.",
                  "host": "achtsamkeit-koeln.de",
                  "url": "https://example.de/koeln"
                }
              ],
              "en": [
                {
                  "id": "tara-brach",
                  "name": "Tara Brach",
                  "offer": null,
                  "description": "Guided meditations, RAIN practice.",
                  "host": "tarabrach.com",
                  "url": "https://example.com/tara"
                }
              ]
            }
        """.trimIndent()
    }

    @Nested
    inner class ParseSourcesJson {
        @Test
        fun `de catalog has expected entries`() {
            val catalog = MeditationSourceRepositoryImpl.parseSourcesJson(VALID_JSON)
            assertEquals(2, catalog["de"]?.size)
        }

        @Test
        fun `en catalog has expected entries`() {
            val catalog = MeditationSourceRepositoryImpl.parseSourcesJson(VALID_JSON)
            assertEquals(1, catalog["en"]?.size)
        }

        @Test
        fun `de and en lists are independent`() {
            val catalog = MeditationSourceRepositoryImpl.parseSourcesJson(VALID_JSON)
            val deIds = catalog["de"]?.map { it.id }.orEmpty()
            val enIds = catalog["en"]?.map { it.id }.orEmpty()
            assertTrue(deIds.intersect(enIds.toSet()).isEmpty())
        }

        @Test
        fun `entry with offer preserves it`() {
            val catalog = MeditationSourceRepositoryImpl.parseSourcesJson(VALID_JSON)
            val mangold = catalog["de"]?.firstOrNull { it.id == "mangold" }
            assertEquals("Achtsamkeit & Selbstmitgefühl", mangold?.offer)
        }

        @Test
        fun `null offer becomes null in domain`() {
            val catalog = MeditationSourceRepositoryImpl.parseSourcesJson(VALID_JSON)
            val koeln = catalog["de"]?.firstOrNull { it.id == "koeln" }
            assertNotNull(koeln)
            assertNull(koeln?.offer)
        }

        @Test
        fun `empty offer becomes null in domain`() {
            val json = """
                {
                  "en": [
                    {
                      "id": "x",
                      "name": "X",
                      "offer": "   ",
                      "description": "d",
                      "host": "h",
                      "url": "https://example.com/"
                    }
                  ]
                }
            """.trimIndent()
            val catalog = MeditationSourceRepositoryImpl.parseSourcesJson(json)
            assertNull(catalog["en"]?.first()?.offer)
        }

        @Test
        fun `non-http url is rejected`() {
            val json = """
                {
                  "en": [
                    {
                      "id": "bad",
                      "name": "Bad",
                      "offer": null,
                      "description": "d",
                      "host": "h",
                      "url": "javascript:alert(1)"
                    },
                    {
                      "id": "good",
                      "name": "Good",
                      "offer": null,
                      "description": "d",
                      "host": "h",
                      "url": "https://example.com/"
                    }
                  ]
                }
            """.trimIndent()
            val catalog = MeditationSourceRepositoryImpl.parseSourcesJson(json)
            assertEquals(1, catalog["en"]?.size)
            assertEquals("good", catalog["en"]?.first()?.id)
        }

        @Test
        fun `parsed entries expose name description host and url`() {
            val catalog = MeditationSourceRepositoryImpl.parseSourcesJson(VALID_JSON)
            val tara = catalog["en"]?.first()
            assertEquals("Tara Brach", tara?.name)
            assertEquals("Guided meditations, RAIN practice.", tara?.description)
            assertEquals("tarabrach.com", tara?.host)
            assertEquals("https://example.com/tara", tara?.url)
        }
    }

    /** The catalog that ships with the app (`assets/meditation_sources.json`, shared-137). */
    @Nested
    inner class ShippedCatalog {
        private val shipped: Map<String, List<MeditationSource>> by lazy {
            MeditationSourceRepositoryImpl.parseSourcesJson(File(SHIPPED_JSON_PATH).readText())
        }

        private fun source(id: String): MeditationSource? = shipped.values.flatten().firstOrNull { it.id == id }

        @Test
        fun `ships four German and four English sources`() {
            assertEquals(listOf("koeln", "braehler", "mangold", "gein"), shipped["de"]?.map { it.id })
            assertEquals(
                listOf("audio-dharma", "tara-brach", "ucla-mindful", "free-mindfulness"),
                shipped["en"]?.map { it.id }
            )
        }

        @Test
        fun `each source names the teacher and the offer only when it has a name of its own`() {
            val expected = listOf(
                Triple("koeln", "Kirsten Tofahrn", "Zentrum für Achtsamkeit Köln"),
                Triple("braehler", "Christine Brähler", null),
                Triple("mangold", "Jörg Mangold", "Achtsamkeit & Selbstmitgefühl"),
                Triple("gein", "Melissa Gein", "Podcast \u201EEinfach meditieren\u201C"),
                Triple("tara-brach", "Tara Brach", null),
                Triple("audio-dharma", "Audio Dharma", "Insight Meditation Center"),
                Triple("ucla-mindful", "UCLA Mindful", "UCLA Health"),
                Triple("free-mindfulness", "Free Mindfulness Project", null)
            )
            expected.forEach { (id, name, offer) ->
                val source = source(id)
                assertEquals(name, source?.name, "name of $id")
                assertEquals(offer, source?.offer, "offer of $id")
            }
        }

        @Test
        fun `no description credits the teacher with Von`() {
            val credited = shipped.values.flatten().filter { it.description.contains("Von ") }
            assertTrue(credited.isEmpty(), "descriptions with 'Von ': ${credited.map { it.id }}")
        }

        @Test
        fun `Melissa Gein links to her podcast on Apple Podcasts`() {
            val gein = source("gein")
            assertEquals(
                "https://podcasts.apple.com/de/podcast/einfach-meditieren-einfach-achtsam-leben/id1588419775",
                gein?.url
            )
            assertEquals("podcasts.apple.com", gein?.host)
        }
    }
}
