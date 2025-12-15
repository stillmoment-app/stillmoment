package com.stillmoment.domain.models

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*

/**
 * Unit tests for MeditationSettings domain model.
 */
class MeditationSettingsTest {

    // MARK: - Default Values Tests

    @Test
    fun `default settings have expected values`() {
        val settings = MeditationSettings.Default

        assertFalse(settings.intervalGongsEnabled)
        assertEquals(5, settings.intervalMinutes)
        assertEquals("silent", settings.backgroundSoundId)
        assertEquals(10, settings.durationMinutes)
    }

    @Test
    fun `constructor uses default values`() {
        val settings = MeditationSettings()

        assertFalse(settings.intervalGongsEnabled)
        assertEquals(5, settings.intervalMinutes)
        assertEquals("silent", settings.backgroundSoundId)
        assertEquals(10, settings.durationMinutes)
    }

    // MARK: - Interval Validation Tests

    @Test
    fun `validateInterval returns 3 for values up to 3`() {
        assertEquals(3, MeditationSettings.validateInterval(1))
        assertEquals(3, MeditationSettings.validateInterval(2))
        assertEquals(3, MeditationSettings.validateInterval(3))
    }

    @Test
    fun `validateInterval returns 5 for values 4-7`() {
        assertEquals(5, MeditationSettings.validateInterval(4))
        assertEquals(5, MeditationSettings.validateInterval(5))
        assertEquals(5, MeditationSettings.validateInterval(6))
        assertEquals(5, MeditationSettings.validateInterval(7))
    }

    @Test
    fun `validateInterval returns 10 for values 8 and above`() {
        assertEquals(10, MeditationSettings.validateInterval(8))
        assertEquals(10, MeditationSettings.validateInterval(10))
        assertEquals(10, MeditationSettings.validateInterval(15))
        assertEquals(10, MeditationSettings.validateInterval(100))
    }

    @Test
    fun `validateInterval returns 3 for negative values`() {
        assertEquals(3, MeditationSettings.validateInterval(-5))
        assertEquals(3, MeditationSettings.validateInterval(0))
    }

    // MARK: - Duration Validation Tests

    @Test
    fun `validateDuration clamps to minimum 1`() {
        assertEquals(1, MeditationSettings.validateDuration(0))
        assertEquals(1, MeditationSettings.validateDuration(-5))
        assertEquals(1, MeditationSettings.validateDuration(1))
    }

    @Test
    fun `validateDuration clamps to maximum 60`() {
        assertEquals(60, MeditationSettings.validateDuration(60))
        assertEquals(60, MeditationSettings.validateDuration(61))
        assertEquals(60, MeditationSettings.validateDuration(100))
    }

    @Test
    fun `validateDuration passes through valid values`() {
        assertEquals(10, MeditationSettings.validateDuration(10))
        assertEquals(30, MeditationSettings.validateDuration(30))
        assertEquals(45, MeditationSettings.validateDuration(45))
    }

    // MARK: - Create with Validation Tests

    @Test
    fun `create validates interval minutes`() {
        val settings = MeditationSettings.create(intervalMinutes = 4)
        assertEquals(5, settings.intervalMinutes)
    }

    @Test
    fun `create validates duration minutes`() {
        val settings = MeditationSettings.create(durationMinutes = 100)
        assertEquals(60, settings.durationMinutes)
    }

    @Test
    fun `create with all parameters`() {
        val settings = MeditationSettings.create(
            intervalGongsEnabled = true,
            intervalMinutes = 10,
            backgroundSoundId = "forest",
            durationMinutes = 20
        )

        assertTrue(settings.intervalGongsEnabled)
        assertEquals(10, settings.intervalMinutes)
        assertEquals("forest", settings.backgroundSoundId)
        assertEquals(20, settings.durationMinutes)
    }

    // MARK: - Copy with Validation Tests

    @Test
    fun `withIntervalMinutes validates and updates`() {
        val original = MeditationSettings()
        val updated = original.withIntervalMinutes(4)

        assertEquals(5, updated.intervalMinutes)
        assertEquals(5, original.intervalMinutes) // Original unchanged
    }

    @Test
    fun `withDurationMinutes validates and updates`() {
        val original = MeditationSettings()
        val updated = original.withDurationMinutes(100)

        assertEquals(60, updated.durationMinutes)
        assertEquals(10, original.durationMinutes) // Original unchanged
    }

    // MARK: - Legacy Migration Tests

    @Test
    fun `migrateLegacyMode converts Silent to silent`() {
        assertEquals("silent", MeditationSettings.migrateLegacyMode("Silent"))
    }

    @Test
    fun `migrateLegacyMode converts White Noise to silent`() {
        assertEquals("silent", MeditationSettings.migrateLegacyMode("White Noise"))
    }

    @Test
    fun `migrateLegacyMode converts unknown to silent`() {
        assertEquals("silent", MeditationSettings.migrateLegacyMode("Unknown"))
        assertEquals("silent", MeditationSettings.migrateLegacyMode(""))
    }

    // MARK: - VALID_INTERVALS Tests

    @Test
    fun `VALID_INTERVALS contains expected values`() {
        assertEquals(listOf(3, 5, 10), MeditationSettings.VALID_INTERVALS)
    }

    // MARK: - Keys Tests

    @Test
    fun `settings keys have expected values`() {
        assertEquals("intervalGongsEnabled", MeditationSettingsKeys.INTERVAL_GONGS_ENABLED)
        assertEquals("intervalMinutes", MeditationSettingsKeys.INTERVAL_MINUTES)
        assertEquals("backgroundSoundId", MeditationSettingsKeys.BACKGROUND_SOUND_ID)
        assertEquals("durationMinutes", MeditationSettingsKeys.DURATION_MINUTES)
        assertEquals("backgroundAudioMode", MeditationSettingsKeys.LEGACY_BACKGROUND_AUDIO_MODE)
    }
}
