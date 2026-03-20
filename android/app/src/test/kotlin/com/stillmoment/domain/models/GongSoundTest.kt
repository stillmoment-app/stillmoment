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
        assertTrue(ids.contains("temple-bell"))
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
    fun `DEFAULT_SOUND_ID is temple-bell`() {
        assertEquals("temple-bell", GongSound.DEFAULT_SOUND_ID)
    }

    @Test
    fun `defaultSound is temple-bell`() {
        assertEquals("temple-bell", GongSound.defaultSound.id)
        assertEquals("Temple Bell", GongSound.defaultSound.nameEnglish)
        assertEquals("Tempelglocke", GongSound.defaultSound.nameGerman)
    }

    // MARK: - Find Tests

    @Test
    fun `find returns correct sound for valid ID`() {
        val sound = GongSound.find("clear-strike")

        assertNotNull(sound)
        assertEquals("clear-strike", sound?.id)
        assertEquals("Clear Strike", sound?.nameEnglish)
        assertEquals("Klarer Anschlag", sound?.nameGerman)
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
        val sound = GongSound.findOrDefault("deep-resonance")

        assertEquals("deep-resonance", sound.id)
        assertEquals("Deep Resonance", sound.nameEnglish)
    }

    @Test
    fun `findOrDefault returns default for unknown ID`() {
        val sound = GongSound.findOrDefault("nonexistent")

        assertEquals(GongSound.defaultSound, sound)
        assertEquals("temple-bell", sound.id)
    }

    @Test
    fun `findOrDefault returns default for empty ID`() {
        val sound = GongSound.findOrDefault("")

        assertEquals(GongSound.defaultSound, sound)
    }

    // MARK: - Localized Name Tests

    @Test
    fun `all non-vibration sounds have valid rawResourceName`() {
        for (sound in GongSound.allSounds.filter { it.id != GongSound.VIBRATION_ID }) {
            assertTrue(sound.rawResourceName.isNotBlank(), "Sound ${sound.id} has blank rawResourceName")
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
    fun `temple-bell has correct properties`() {
        val sound = GongSound.find("temple-bell")!!

        assertEquals("Temple Bell", sound.nameEnglish)
        assertEquals("Tempelglocke", sound.nameGerman)
    }

    // MARK: - Interval Sounds Tests

    @Test
    fun `allIntervalSounds contains 6 sounds`() {
        assertEquals(6, GongSound.allIntervalSounds.size)
    }

    @Test
    fun `allIntervalSounds includes all base sounds plus soft-interval`() {
        val ids = GongSound.allIntervalSounds.map { it.id }

        assertTrue(ids.contains("classic-bowl"))
        assertTrue(ids.contains("deep-resonance"))
        assertTrue(ids.contains("clear-strike"))
        assertTrue(ids.contains("temple-bell"))
        assertTrue(ids.contains("soft-interval"))
    }

    @Test
    fun `allIntervalSounds have unique IDs`() {
        val ids = GongSound.allIntervalSounds.map { it.id }
        assertEquals(ids.size, ids.distinct().size)
    }

    @Test
    fun `SOFT_INTERVAL_SOUND_ID is soft-interval`() {
        assertEquals("soft-interval", GongSound.SOFT_INTERVAL_SOUND_ID)
    }

    @Test
    fun `soft-interval has correct properties`() {
        val sound = GongSound.find("soft-interval")

        assertNotNull(sound)
        assertEquals("Soft Interval Tone", sound?.nameEnglish)
        assertEquals("Sanfter Intervallton", sound?.nameGerman)
    }

    @Test
    fun `find searches allIntervalSounds including soft-interval`() {
        val sound = GongSound.find("soft-interval")
        assertNotNull(sound)
        assertEquals("soft-interval", sound?.id)
    }

    @Test
    fun `findOrDefault returns soft-interval for soft-interval ID`() {
        val sound = GongSound.findOrDefault("soft-interval")
        assertEquals("soft-interval", sound.id)
    }

    // MARK: - Vibration Tests

    @Test
    fun `allSounds last entry is vibration`() {
        assertEquals(GongSound.VIBRATION_ID, GongSound.allSounds.last().id)
    }

    @Test
    fun `allIntervalSounds last entry is vibration`() {
        assertEquals(GongSound.VIBRATION_ID, GongSound.allIntervalSounds.last().id)
    }

    @Test
    fun `VIBRATION_ID is vibration`() {
        assertEquals("vibration", GongSound.VIBRATION_ID)
    }

    @Test
    fun `vibration sound has correct localized names`() {
        val vibration = GongSound.find(GongSound.VIBRATION_ID)
        assertNotNull(vibration)
        assertEquals("Vibration", vibration?.nameEnglish)
        assertEquals("Vibration", vibration?.nameGerman)
    }

    @Test
    fun `find returns vibration sound`() {
        val sound = GongSound.find("vibration")
        assertNotNull(sound)
        assertEquals("vibration", sound?.id)
    }

    @Test
    fun `findOrDefault returns vibration for vibration id`() {
        val sound = GongSound.findOrDefault("vibration")
        assertEquals("vibration", sound.id)
    }

    @Test
    fun `vibration rawResourceName is empty string`() {
        val vibration = GongSound.find("vibration")!!
        assertEquals("", vibration.rawResourceName)
    }
}
