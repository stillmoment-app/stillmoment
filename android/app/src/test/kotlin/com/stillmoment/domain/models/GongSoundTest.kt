package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

/**
 * Unit tests for GongSound domain model.
 */
class GongSoundTest {
    // MARK: - All Sounds Tests

    @Test
    fun `allSounds contains 5 sounds`() {
        assertEquals(5, GongSound.allSounds.size)
    }

    @Test
    fun `allSounds contains expected IDs`() {
        val ids = GongSound.allSounds.map { it.id }

        assertTrue(ids.contains("classic-bowl"))
        assertTrue(ids.contains("deep-resonance"))
        assertTrue(ids.contains("clear-strike"))
        assertTrue(ids.contains("deep-zen"))
        assertTrue(ids.contains("warm-zen"))
    }

    @Test
    fun `allSounds have unique IDs`() {
        val ids = GongSound.allSounds.map { it.id }
        assertEquals(ids.size, ids.distinct().size)
    }

    @Test
    fun `allSounds have both English and German names`() {
        for (sound in GongSound.allSounds) {
            assertTrue(sound.nameEnglish.isNotBlank(), "Sound ${sound.id} has blank English name")
            assertTrue(sound.nameGerman.isNotBlank(), "Sound ${sound.id} has blank German name")
        }
    }

    // MARK: - Default Sound Tests

    @Test
    fun `DEFAULT_SOUND_ID is classic-bowl`() {
        assertEquals("classic-bowl", GongSound.DEFAULT_SOUND_ID)
    }

    @Test
    fun `defaultSound is classic-bowl`() {
        assertEquals("classic-bowl", GongSound.defaultSound.id)
        assertEquals("Classic Bowl", GongSound.defaultSound.nameEnglish)
        assertEquals("Klassisch", GongSound.defaultSound.nameGerman)
    }

    // MARK: - Find Tests

    @Test
    fun `find returns correct sound for valid ID`() {
        val sound = GongSound.find("deep-zen")

        assertNotNull(sound)
        assertEquals("deep-zen", sound?.id)
        assertEquals("Deep Zen", sound?.nameEnglish)
        assertEquals("Tiefer Zen", sound?.nameGerman)
    }

    @Test
    fun `find returns null for unknown ID`() {
        val sound = GongSound.find("nonexistent")
        assertNull(sound)
    }

    @Test
    fun `find returns null for empty ID`() {
        val sound = GongSound.find("")
        assertNull(sound)
    }

    // MARK: - FindOrDefault Tests

    @Test
    fun `findOrDefault returns correct sound for valid ID`() {
        val sound = GongSound.findOrDefault("warm-zen")

        assertEquals("warm-zen", sound.id)
        assertEquals("Warm Zen", sound.nameEnglish)
    }

    @Test
    fun `findOrDefault returns default for unknown ID`() {
        val sound = GongSound.findOrDefault("nonexistent")

        assertEquals(GongSound.defaultSound, sound)
        assertEquals("classic-bowl", sound.id)
    }

    @Test
    fun `findOrDefault returns default for empty ID`() {
        val sound = GongSound.findOrDefault("")

        assertEquals(GongSound.defaultSound, sound)
    }

    // MARK: - Localized Name Tests

    @Test
    fun `all sounds have valid rawResId`() {
        for (sound in GongSound.allSounds) {
            assertTrue(sound.rawResId != 0, "Sound ${sound.id} has invalid rawResId")
        }
    }

    // MARK: - Individual Sound Tests

    @Test
    fun `classic-bowl has correct properties`() {
        val sound = GongSound.find("classic-bowl")!!

        assertEquals("Classic Bowl", sound.nameEnglish)
        assertEquals("Klassisch", sound.nameGerman)
    }

    @Test
    fun `deep-resonance has correct properties`() {
        val sound = GongSound.find("deep-resonance")!!

        assertEquals("Deep Resonance", sound.nameEnglish)
        assertEquals("Tiefe Resonanz", sound.nameGerman)
    }

    @Test
    fun `clear-strike has correct properties`() {
        val sound = GongSound.find("clear-strike")!!

        assertEquals("Clear Strike", sound.nameEnglish)
        assertEquals("Klarer Anschlag", sound.nameGerman)
    }

    @Test
    fun `deep-zen has correct properties`() {
        val sound = GongSound.find("deep-zen")!!

        assertEquals("Deep Zen", sound.nameEnglish)
        assertEquals("Tiefer Zen", sound.nameGerman)
    }

    @Test
    fun `warm-zen has correct properties`() {
        val sound = GongSound.find("warm-zen")!!

        assertEquals("Warm Zen", sound.nameEnglish)
        assertEquals("Warmer Zen", sound.nameGerman)
    }
}
