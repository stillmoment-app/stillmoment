package com.stillmoment.domain.models

import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for Introduction domain model.
 */
class IntroductionTest {
    @AfterEach
    fun tearDown() {
        Introduction.languageOverride = null
    }

    // MARK: - Registry Tests

    @Test
    fun `allIntroductions contains breath`() {
        val ids = Introduction.allIntroductions.map { it.id }
        assertTrue(ids.contains("breath"))
    }

    @Test
    fun `allIntroductions have unique IDs`() {
        val ids = Introduction.allIntroductions.map { it.id }
        assertEquals(ids.size, ids.distinct().size)
    }

    @Test
    fun `allIntroductions have both English and German names`() {
        for (intro in Introduction.allIntroductions) {
            assertTrue(intro.nameEnglish.isNotBlank(), "Intro ${intro.id} has blank English name")
            assertTrue(intro.nameGerman.isNotBlank(), "Intro ${intro.id} has blank German name")
        }
    }

    // MARK: - Breath Introduction Tests

    @Test
    fun `breath has correct properties`() {
        val breath = Introduction.allIntroductions.first { it.id == "breath" }

        assertEquals("breath", breath.id)
        assertEquals(95, breath.durationSeconds)
        assertEquals(listOf("de"), breath.availableLanguages)
    }

    @Test
    fun `breath formatted duration is 1 colon 35`() {
        val breath = Introduction.allIntroductions.first { it.id == "breath" }
        assertEquals("1:35", breath.formattedDuration)
    }

    // MARK: - Language Filtering Tests

    @Nested
    inner class LanguageFiltering {
        @Test
        fun `availableForCurrentLanguage returns breath for German`() {
            Introduction.languageOverride = "de"

            val available = Introduction.availableForCurrentLanguage()

            assertEquals(1, available.size)
            assertEquals("breath", available.first().id)
        }

        @Test
        fun `availableForCurrentLanguage returns empty for English`() {
            Introduction.languageOverride = "en"

            val available = Introduction.availableForCurrentLanguage()

            assertTrue(available.isEmpty())
        }

        @Test
        fun `hasAvailableIntroductions is true for German`() {
            Introduction.languageOverride = "de"
            assertTrue(Introduction.hasAvailableIntroductions)
        }

        @Test
        fun `hasAvailableIntroductions is false for English`() {
            Introduction.languageOverride = "en"
            assertFalse(Introduction.hasAvailableIntroductions)
        }

        @Test
        fun `hasAvailableIntroductions is false for unsupported language`() {
            Introduction.languageOverride = "fr"
            assertFalse(Introduction.hasAvailableIntroductions)
        }
    }

    // MARK: - Find Tests

    @Test
    fun `find returns correct introduction for valid ID`() {
        val intro = Introduction.find("breath")

        assertNotNull(intro)
        assertEquals("breath", intro?.id)
    }

    @Test
    fun `find returns null for unknown ID`() {
        assertNull(Introduction.find("nonexistent"))
    }

    @Test
    fun `find returns null for empty ID`() {
        assertNull(Introduction.find(""))
    }

    // MARK: - Language Availability Tests

    @Test
    fun `isAvailableForCurrentLanguage returns true for breath in German`() {
        Introduction.languageOverride = "de"
        assertTrue(Introduction.isAvailableForCurrentLanguage("breath"))
    }

    @Test
    fun `isAvailableForCurrentLanguage returns false for breath in English`() {
        Introduction.languageOverride = "en"
        assertFalse(Introduction.isAvailableForCurrentLanguage("breath"))
    }

    @Test
    fun `isAvailableForCurrentLanguage returns false for unknown ID`() {
        Introduction.languageOverride = "de"
        assertFalse(Introduction.isAvailableForCurrentLanguage("nonexistent"))
    }

    // MARK: - Audio Filename Tests

    @Test
    fun `audioFilenameForCurrentLanguage returns filename for breath in German`() {
        Introduction.languageOverride = "de"
        val filename = Introduction.audioFilenameForCurrentLanguage("breath")
        assertNotNull(filename)
        assertEquals("intro_breath_de", filename)
    }

    @Test
    fun `audioFilenameForCurrentLanguage returns null for breath in English`() {
        Introduction.languageOverride = "en"
        assertNull(Introduction.audioFilenameForCurrentLanguage("breath"))
    }

    @Test
    fun `audioFilenameForCurrentLanguage returns null for unknown ID`() {
        Introduction.languageOverride = "de"
        assertNull(Introduction.audioFilenameForCurrentLanguage("nonexistent"))
    }

    // MARK: - Localized Name Tests

    @Test
    fun `localizedName returns German name for German locale`() {
        Introduction.languageOverride = "de"
        val breath = Introduction.allIntroductions.first { it.id == "breath" }
        assertEquals(breath.nameGerman, breath.localizedName)
    }

    @Test
    fun `localizedName returns English name for English locale`() {
        Introduction.languageOverride = "en"
        val breath = Introduction.allIntroductions.first { it.id == "breath" }
        assertEquals(breath.nameEnglish, breath.localizedName)
    }

    // MARK: - Formatted Duration Tests

    @Test
    fun `formattedDuration formats correctly for various durations`() {
        val intro = Introduction(
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
        val intro = Introduction(
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
