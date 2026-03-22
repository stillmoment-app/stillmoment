package com.stillmoment.domain.models

import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for Attunement domain model.
 */
class AttunementTest {
    @AfterEach
    fun tearDown() {
        Attunement.languageOverride = null
    }

    // MARK: - Registry Tests

    @Test
    fun `allAttunements contains breath`() {
        val ids = Attunement.allAttunements.map { it.id }
        assertTrue(ids.contains("breath"))
    }

    @Test
    fun `allAttunements have unique IDs`() {
        val ids = Attunement.allAttunements.map { it.id }
        assertEquals(ids.size, ids.distinct().size)
    }

    @Test
    fun `allAttunements have both English and German names`() {
        for (intro in Attunement.allAttunements) {
            assertTrue(intro.nameEnglish.isNotBlank(), "Intro ${intro.id} has blank English name")
            assertTrue(intro.nameGerman.isNotBlank(), "Intro ${intro.id} has blank German name")
        }
    }

    // MARK: - Breath Attunement Tests

    @Test
    fun `breath has correct properties`() {
        val breath = Attunement.allAttunements.first { it.id == "breath" }

        assertEquals("breath", breath.id)
        assertEquals(95, breath.durationSeconds)
        assertEquals(listOf("de", "en"), breath.availableLanguages)
    }

    @Test
    fun `breath formatted duration is 1 colon 35`() {
        val breath = Attunement.allAttunements.first { it.id == "breath" }
        assertEquals("1:35", breath.formattedDuration)
    }

    // MARK: - Language Filtering Tests

    @Nested
    inner class LanguageFiltering {
        @Test
        fun `availableForCurrentLanguage returns breath for German`() {
            Attunement.languageOverride = "de"

            val available = Attunement.availableForCurrentLanguage()

            assertEquals(1, available.size)
            assertEquals("breath", available.first().id)
        }

        @Test
        fun `availableForCurrentLanguage returns breath for English`() {
            Attunement.languageOverride = "en"

            val available = Attunement.availableForCurrentLanguage()

            assertEquals(1, available.size)
            assertEquals("breath", available.first().id)
        }

        @Test
        fun `hasAvailableAttunements is true for German`() {
            Attunement.languageOverride = "de"
            assertTrue(Attunement.hasAvailableAttunements)
        }

        @Test
        fun `hasAvailableAttunements is true for English`() {
            Attunement.languageOverride = "en"
            assertTrue(Attunement.hasAvailableAttunements)
        }

        @Test
        fun `hasAvailableAttunements is false for unsupported language`() {
            Attunement.languageOverride = "fr"
            assertFalse(Attunement.hasAvailableAttunements)
        }
    }

    // MARK: - Find Tests

    @Test
    fun `find returns correct attunement for valid ID`() {
        val intro = Attunement.find("breath")

        assertNotNull(intro)
        assertEquals("breath", intro?.id)
    }

    @Test
    fun `find returns null for unknown ID`() {
        assertNull(Attunement.find("nonexistent"))
    }

    @Test
    fun `find returns null for empty ID`() {
        assertNull(Attunement.find(""))
    }

    // MARK: - Language Availability Tests

    @Test
    fun `isAvailableForCurrentLanguage returns true for breath in German`() {
        Attunement.languageOverride = "de"
        assertTrue(Attunement.isAvailableForCurrentLanguage("breath"))
    }

    @Test
    fun `isAvailableForCurrentLanguage returns true for breath in English`() {
        Attunement.languageOverride = "en"
        assertTrue(Attunement.isAvailableForCurrentLanguage("breath"))
    }

    @Test
    fun `isAvailableForCurrentLanguage returns false for unknown ID`() {
        Attunement.languageOverride = "de"
        assertFalse(Attunement.isAvailableForCurrentLanguage("nonexistent"))
    }

    // MARK: - Audio Filename Tests

    @Test
    fun `audioFilenameForCurrentLanguage returns filename for breath in German`() {
        Attunement.languageOverride = "de"
        val filename = Attunement.audioFilenameForCurrentLanguage("breath")
        assertNotNull(filename)
        assertEquals("intro_breath_de", filename)
    }

    @Test
    fun `audioFilenameForCurrentLanguage returns filename for breath in English`() {
        Attunement.languageOverride = "en"
        assertEquals("intro_breath_en", Attunement.audioFilenameForCurrentLanguage("breath"))
    }

    @Test
    fun `audioFilenameForCurrentLanguage returns null for unknown ID`() {
        Attunement.languageOverride = "de"
        assertNull(Attunement.audioFilenameForCurrentLanguage("nonexistent"))
    }

    // MARK: - Localized Name Tests

    @Test
    fun `localizedName returns German name for German locale`() {
        Attunement.languageOverride = "de"
        val breath = Attunement.allAttunements.first { it.id == "breath" }
        assertEquals(breath.nameGerman, breath.localizedName)
    }

    @Test
    fun `localizedName returns English name for English locale`() {
        Attunement.languageOverride = "en"
        val breath = Attunement.allAttunements.first { it.id == "breath" }
        assertEquals(breath.nameEnglish, breath.localizedName)
    }

    // MARK: - Formatted Duration Tests

    @Test
    fun `formattedDuration formats correctly for various durations`() {
        val intro = Attunement(
            id = "test",
            nameEnglish = "Test",
            nameGerman = "Test",
            durationSeconds = 60,
            availableLanguages = listOf("en"),
            filenamePattern = "test_{lang}"
        )
        assertEquals("1:00", intro.formattedDuration)
    }

    @Test
    fun `formattedDuration pads seconds with leading zero`() {
        val intro = Attunement(
            id = "test",
            nameEnglish = "Test",
            nameGerman = "Test",
            durationSeconds = 65,
            availableLanguages = listOf("en"),
            filenamePattern = "test_{lang}"
        )
        assertEquals("1:05", intro.formattedDuration)
    }
}
