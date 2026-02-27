package com.stillmoment.data.repositories

import com.stillmoment.domain.models.BackgroundSound
import kotlinx.serialization.SerializationException
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for SoundCatalogRepositoryImpl.
 *
 * Tests JSON parsing logic via the companion object's parseSoundsJson() method,
 * which does not require Android Context.
 */
class SoundCatalogRepositoryImplTest {

    companion object {
        /** Valid JSON matching the production sounds.json structure. */
        private val VALID_SOUNDS_JSON = """
            {
              "sounds": [
                {
                  "id": "silent",
                  "filename": "silence.m4a",
                  "name": { "en": "Silence", "de": "Stille" },
                  "description": { "en": "Meditate in silence.", "de": "Meditiere in Stille." },
                  "volume": 0.15
                },
                {
                  "id": "forest",
                  "filename": "forest-ambience.mp3",
                  "name": { "en": "Forest Ambience", "de": "Waldatmosph\u00e4re" },
                  "description": { "en": "Natural forest sounds", "de": "Nat\u00fcrliche Waldger\u00e4usche" },
                  "volume": 0.15
                },
                {
                  "id": "rain",
                  "filename": "rain-ambience.mp3",
                  "name": { "en": "Rain", "de": "Regen" },
                  "description": { "en": "Gentle rain sounds", "de": "Sanfte Regengeräusche" },
                  "volume": 0.15
                },
                {
                  "id": "ocean",
                  "filename": "ocean-waves.mp3",
                  "name": { "en": "Ocean Waves", "de": "Meeresrauschen" },
                  "description": { "en": "Calming ocean waves", "de": "Beruhigendes Meeresrauschen" },
                  "volume": 0.15
                },
                {
                  "id": "birds",
                  "filename": "birds-chirping.mp3",
                  "name": { "en": "Birds", "de": "Vogelgezwitscher" },
                  "description": { "en": "Peaceful birds chirping", "de": "Friedliches Vogelgezwitscher" },
                  "volume": 0.15
                }
              ]
            }
        """.trimIndent()
    }

    // MARK: - JSON Parsing Tests

    @Nested
    inner class ParseSoundsJson {
        @Test
        fun `catalog has more than 2 entries`() {
            // When
            val sounds = SoundCatalogRepositoryImpl.parseSoundsJson(VALID_SOUNDS_JSON)

            // Then — the old hardcoded catalog only had 2 entries (silent + forest)
            assertTrue(sounds.size > 2, "Expected more than 2 sounds, got ${sounds.size}")
        }

        @Test
        fun `first entry is silent`() {
            // When
            val sounds = SoundCatalogRepositoryImpl.parseSoundsJson(VALID_SOUNDS_JSON)

            // Then
            assertEquals(BackgroundSound.SILENT_ID, sounds.first().id)
        }

        @Test
        fun `forest sound is present in catalog`() {
            // When
            val sounds = SoundCatalogRepositoryImpl.parseSoundsJson(VALID_SOUNDS_JSON)

            // Then
            assertTrue(sounds.any { it.id == "forest" }, "Expected 'forest' in the catalog")
        }

        @Test
        fun `all entries have non-empty nameEnglish and nameGerman`() {
            // When
            val sounds = SoundCatalogRepositoryImpl.parseSoundsJson(VALID_SOUNDS_JSON)

            // Then
            sounds.forEach { sound ->
                assertTrue(
                    sound.nameEnglish.isNotEmpty(),
                    "Sound '${sound.id}' has empty nameEnglish"
                )
                assertTrue(
                    sound.nameGerman.isNotEmpty(),
                    "Sound '${sound.id}' has empty nameGerman"
                )
            }
        }

        @Test
        fun `all entries have non-empty descriptions`() {
            // When
            val sounds = SoundCatalogRepositoryImpl.parseSoundsJson(VALID_SOUNDS_JSON)

            // Then
            sounds.forEach { sound ->
                assertTrue(
                    sound.descriptionEnglish.isNotEmpty(),
                    "Sound '${sound.id}' has empty descriptionEnglish"
                )
                assertTrue(
                    sound.descriptionGerman.isNotEmpty(),
                    "Sound '${sound.id}' has empty descriptionGerman"
                )
            }
        }
    }

    // MARK: - Silent Sound Tests

    @Nested
    inner class SilentSound {
        @Test
        fun `silent sound has isSilent true`() {
            // When
            val sounds = SoundCatalogRepositoryImpl.parseSoundsJson(VALID_SOUNDS_JSON)
            val silent = sounds.find { it.id == BackgroundSound.SILENT_ID }

            // Then
            assertNotNull(silent, "Expected 'silent' sound in catalog")
            assertTrue(silent!!.isSilent, "Silent sound should have isSilent = true")
        }

        @Test
        fun `silent sound has empty rawResourceName`() {
            // When
            val sounds = SoundCatalogRepositoryImpl.parseSoundsJson(VALID_SOUNDS_JSON)
            val silent = sounds.find { it.id == BackgroundSound.SILENT_ID }

            // Then
            assertNotNull(silent)
            assertTrue(
                silent!!.rawResourceName.isEmpty(),
                "Silent sound should have empty rawResourceName"
            )
        }
    }

    // MARK: - Non-Silent Sounds Tests

    @Nested
    inner class NonSilentSounds {
        @Test
        fun `all non-silent sounds have non-empty rawResourceName`() {
            // When
            val sounds = SoundCatalogRepositoryImpl.parseSoundsJson(VALID_SOUNDS_JSON)
            val nonSilent = sounds.filter { it.id != BackgroundSound.SILENT_ID }

            // Then
            assertTrue(nonSilent.isNotEmpty(), "Expected at least one non-silent sound")
            nonSilent.forEach { sound ->
                assertTrue(
                    sound.rawResourceName.isNotEmpty(),
                    "Non-silent sound '${sound.id}' should have a rawResourceName"
                )
            }
        }

        @Test
        fun `rawResourceName converts filename correctly`() {
            // When
            val sounds = SoundCatalogRepositoryImpl.parseSoundsJson(VALID_SOUNDS_JSON)
            val forest = sounds.find { it.id == "forest" }

            // Then — "forest-ambience.mp3" → "forest_ambience"
            assertNotNull(forest)
            assertEquals("forest_ambience", forest!!.rawResourceName)
        }
    }

    // MARK: - Invalid JSON Tests

    @Nested
    inner class InvalidJson {
        @Test
        fun `invalid JSON throws SerializationException`() {
            // Given
            val invalidJson = "not valid json"

            // When / Then
            assertThrows(SerializationException::class.java) {
                SoundCatalogRepositoryImpl.parseSoundsJson(invalidJson)
            }
        }

        @Test
        fun `missing required fields throws SerializationException`() {
            // Given — missing "name" field
            val incompleteJson = """
                {
                  "sounds": [
                    {
                      "id": "test",
                      "filename": "test.mp3",
                      "description": { "en": "Test", "de": "Test" }
                    }
                  ]
                }
            """.trimIndent()

            // When / Then
            assertThrows(SerializationException::class.java) {
                SoundCatalogRepositoryImpl.parseSoundsJson(incompleteJson)
            }
        }
    }
}
