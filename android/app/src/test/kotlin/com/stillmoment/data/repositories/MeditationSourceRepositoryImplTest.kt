package com.stillmoment.data.repositories

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
        private val VALID_JSON = """
            {
              "de": [
                {
                  "id": "mangold",
                  "name": "Achtsamkeit & Selbstmitgefühl",
                  "author": "Jörg Mangold",
                  "description": "MBSR, MSC, Körperscans.",
                  "host": "podcast",
                  "url": "https://example.de/mangold"
                },
                {
                  "id": "koeln",
                  "name": "Zentrum für Achtsamkeit Köln",
                  "author": null,
                  "description": "MBSR Body Scan, Sitzmeditation.",
                  "host": "achtsamkeit-koeln.de",
                  "url": "https://example.de/koeln"
                }
              ],
              "en": [
                {
                  "id": "tara-brach",
                  "name": "Tara Brach",
                  "author": null,
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
        fun `entry with author preserves it`() {
            val catalog = MeditationSourceRepositoryImpl.parseSourcesJson(VALID_JSON)
            val mangold = catalog["de"]?.firstOrNull { it.id == "mangold" }
            assertNotNull(mangold)
            assertEquals("Jörg Mangold", mangold!!.author)
        }

        @Test
        fun `null author becomes null in domain`() {
            val catalog = MeditationSourceRepositoryImpl.parseSourcesJson(VALID_JSON)
            val koeln = catalog["de"]?.firstOrNull { it.id == "koeln" }
            assertNotNull(koeln)
            assertNull(koeln!!.author)
        }

        @Test
        fun `empty author becomes null in domain`() {
            val json = """
                {
                  "en": [
                    {
                      "id": "x",
                      "name": "X",
                      "author": "   ",
                      "description": "d",
                      "host": "h",
                      "url": "https://example.com/"
                    }
                  ]
                }
            """.trimIndent()
            val catalog = MeditationSourceRepositoryImpl.parseSourcesJson(json)
            assertNull(catalog["en"]?.first()?.author)
        }

        @Test
        fun `non-http url is rejected`() {
            val json = """
                {
                  "en": [
                    {
                      "id": "bad",
                      "name": "Bad",
                      "author": null,
                      "description": "d",
                      "host": "h",
                      "url": "javascript:alert(1)"
                    },
                    {
                      "id": "good",
                      "name": "Good",
                      "author": null,
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
            assertNotNull(tara)
            assertEquals("Tara Brach", tara!!.name)
            assertEquals("Guided meditations, RAIN practice.", tara.description)
            assertEquals("tarabrach.com", tara.host)
            assertEquals("https://example.com/tara", tara.url)
        }
    }
}
