package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

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
        assertEquals(0.15f, settings.backgroundSoundVolume)
        assertEquals(10, settings.durationMinutes)
        assertTrue(settings.preparationTimeEnabled)
        assertEquals(15, settings.preparationTimeSeconds)
        assertEquals("temple-bell", settings.gongSoundId)
        assertEquals(1.0f, settings.gongVolume)
    }

    @Test
    fun `constructor uses default values`() {
        val settings = MeditationSettings()

        assertFalse(settings.intervalGongsEnabled)
        assertEquals(5, settings.intervalMinutes)
        assertEquals("silent", settings.backgroundSoundId)
        assertEquals(0.15f, settings.backgroundSoundVolume)
        assertEquals(10, settings.durationMinutes)
        assertTrue(settings.preparationTimeEnabled)
        assertEquals(15, settings.preparationTimeSeconds)
        assertEquals("temple-bell", settings.gongSoundId)
        assertEquals(1.0f, settings.gongVolume)
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

    // MARK: - Preparation Time Validation Tests

    @Test
    fun `validatePreparationTime returns exact matches for valid values`() {
        assertEquals(5, MeditationSettings.validatePreparationTime(5))
        assertEquals(10, MeditationSettings.validatePreparationTime(10))
        assertEquals(15, MeditationSettings.validatePreparationTime(15))
        assertEquals(20, MeditationSettings.validatePreparationTime(20))
        assertEquals(30, MeditationSettings.validatePreparationTime(30))
        assertEquals(45, MeditationSettings.validatePreparationTime(45))
    }

    @Test
    fun `validatePreparationTime rounds to nearest valid value`() {
        // Rounds to 5
        assertEquals(5, MeditationSettings.validatePreparationTime(3))
        assertEquals(5, MeditationSettings.validatePreparationTime(7))

        // Rounds to 10
        assertEquals(10, MeditationSettings.validatePreparationTime(8))
        assertEquals(10, MeditationSettings.validatePreparationTime(12))

        // Rounds to 15
        assertEquals(15, MeditationSettings.validatePreparationTime(13))
        assertEquals(15, MeditationSettings.validatePreparationTime(17))

        // Rounds to 20
        assertEquals(20, MeditationSettings.validatePreparationTime(18))
        assertEquals(20, MeditationSettings.validatePreparationTime(24))

        // Rounds to 30
        assertEquals(30, MeditationSettings.validatePreparationTime(26))
        assertEquals(30, MeditationSettings.validatePreparationTime(37))

        // Rounds to 45
        assertEquals(45, MeditationSettings.validatePreparationTime(38))
        assertEquals(45, MeditationSettings.validatePreparationTime(100))
    }

    @Test
    fun `validatePreparationTime handles edge cases`() {
        assertEquals(5, MeditationSettings.validatePreparationTime(0))
        assertEquals(5, MeditationSettings.validatePreparationTime(-5))
        assertEquals(5, MeditationSettings.validatePreparationTime(1))
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
        val settings =
            MeditationSettings.create(
                intervalGongsEnabled = true,
                intervalMinutes = 10,
                backgroundSoundId = "forest",
                backgroundSoundVolume = 0.5f,
                durationMinutes = 20,
                preparationTimeEnabled = false,
                preparationTimeSeconds = 30,
                gongSoundId = "clear-strike",
                gongVolume = 0.8f
            )

        assertTrue(settings.intervalGongsEnabled)
        assertEquals(10, settings.intervalMinutes)
        assertEquals("forest", settings.backgroundSoundId)
        assertEquals(0.5f, settings.backgroundSoundVolume)
        assertEquals(20, settings.durationMinutes)
        assertFalse(settings.preparationTimeEnabled)
        assertEquals(30, settings.preparationTimeSeconds)
        assertEquals("clear-strike", settings.gongSoundId)
        assertEquals(0.8f, settings.gongVolume)
    }

    @Test
    fun `create uses default gongSoundId when not specified`() {
        val settings = MeditationSettings.create()
        assertEquals("temple-bell", settings.gongSoundId)
    }

    @Test
    fun `create validates preparation time seconds`() {
        val settings = MeditationSettings.create(preparationTimeSeconds = 12)
        assertEquals(10, settings.preparationTimeSeconds) // Rounds to nearest valid value
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

    @Test
    fun `withPreparationTimeSeconds validates and updates`() {
        val original = MeditationSettings()
        val updated = original.withPreparationTimeSeconds(12)

        assertEquals(10, updated.preparationTimeSeconds) // Rounds to nearest valid
        assertEquals(15, original.preparationTimeSeconds) // Original unchanged
    }

    @Test
    fun `withPreparationTimeSeconds accepts valid values`() {
        val original = MeditationSettings()
        val updated = original.withPreparationTimeSeconds(30)

        assertEquals(30, updated.preparationTimeSeconds)
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

    // MARK: - VALID_PREPARATION_TIMES Tests

    @Test
    fun `VALID_PREPARATION_TIMES contains expected values`() {
        assertEquals(listOf(5, 10, 15, 20, 30, 45), MeditationSettings.VALID_PREPARATION_TIMES)
    }

    // MARK: - Volume Validation Tests

    @Test
    fun `validateVolume clamps to minimum 0`() {
        assertEquals(0f, MeditationSettings.validateVolume(-0.5f))
        assertEquals(0f, MeditationSettings.validateVolume(-1f))
        assertEquals(0f, MeditationSettings.validateVolume(0f))
    }

    @Test
    fun `validateVolume clamps to maximum 1`() {
        assertEquals(1f, MeditationSettings.validateVolume(1f))
        assertEquals(1f, MeditationSettings.validateVolume(1.5f))
        assertEquals(1f, MeditationSettings.validateVolume(2f))
    }

    @Test
    fun `validateVolume passes through valid values`() {
        assertEquals(0.15f, MeditationSettings.validateVolume(0.15f))
        assertEquals(0.5f, MeditationSettings.validateVolume(0.5f))
        assertEquals(0.75f, MeditationSettings.validateVolume(0.75f))
    }

    @Test
    fun `default backgroundSoundVolume is 0_15`() {
        assertEquals(0.15f, MeditationSettings.DEFAULT_BACKGROUND_SOUND_VOLUME)
        assertEquals(0.15f, MeditationSettings.Default.backgroundSoundVolume)
    }

    @Test
    fun `default gongVolume is 1_0`() {
        assertEquals(1.0f, MeditationSettings.DEFAULT_GONG_VOLUME)
        assertEquals(1.0f, MeditationSettings.Default.gongVolume)
    }

    @Test
    fun `create validates backgroundSoundVolume`() {
        val settingsAboveMax = MeditationSettings.create(backgroundSoundVolume = 1.5f)
        assertEquals(1f, settingsAboveMax.backgroundSoundVolume)

        val settingsBelowMin = MeditationSettings.create(backgroundSoundVolume = -0.5f)
        assertEquals(0f, settingsBelowMin.backgroundSoundVolume)

        val settingsValid = MeditationSettings.create(backgroundSoundVolume = 0.5f)
        assertEquals(0.5f, settingsValid.backgroundSoundVolume)
    }

    @Test
    fun `create validates gongVolume`() {
        val settingsAboveMax = MeditationSettings.create(gongVolume = 1.5f)
        assertEquals(1f, settingsAboveMax.gongVolume)

        val settingsBelowMin = MeditationSettings.create(gongVolume = -0.5f)
        assertEquals(0f, settingsBelowMin.gongVolume)

        val settingsValid = MeditationSettings.create(gongVolume = 0.7f)
        assertEquals(0.7f, settingsValid.gongVolume)
    }

    @Test
    fun `copy preserves backgroundSoundVolume`() {
        val original = MeditationSettings.create(backgroundSoundVolume = 0.75f)
        val copied = original.copy(durationMinutes = 20)

        assertEquals(0.75f, copied.backgroundSoundVolume)
        assertEquals(20, copied.durationMinutes)
    }

    @Test
    fun `copy preserves gongVolume`() {
        val original = MeditationSettings.create(gongVolume = 0.6f)
        val copied = original.copy(durationMinutes = 20)

        assertEquals(0.6f, copied.gongVolume)
        assertEquals(20, copied.durationMinutes)
    }

    // MARK: - Keys Tests

    @Test
    fun `settings keys have expected values`() {
        assertEquals("intervalGongsEnabled", MeditationSettingsKeys.INTERVAL_GONGS_ENABLED)
        assertEquals("intervalMinutes", MeditationSettingsKeys.INTERVAL_MINUTES)
        assertEquals("backgroundSoundId", MeditationSettingsKeys.BACKGROUND_SOUND_ID)
        assertEquals("backgroundSoundVolume", MeditationSettingsKeys.BACKGROUND_SOUND_VOLUME)
        assertEquals("durationMinutes", MeditationSettingsKeys.DURATION_MINUTES)
        assertEquals("backgroundAudioMode", MeditationSettingsKeys.LEGACY_BACKGROUND_AUDIO_MODE)
        assertEquals("preparationTimeEnabled", MeditationSettingsKeys.PREPARATION_TIME_ENABLED)
        assertEquals("preparationTimeSeconds", MeditationSettingsKeys.PREPARATION_TIME_SECONDS)
        assertEquals("gongSoundId", MeditationSettingsKeys.GONG_SOUND_ID)
        assertEquals("gongVolume", MeditationSettingsKeys.GONG_VOLUME)
        assertEquals("intervalGongVolume", MeditationSettingsKeys.INTERVAL_GONG_VOLUME)
    }

    // MARK: - Interval Gong Volume Tests

    @Test
    fun `default intervalGongVolume is 0_75`() {
        assertEquals(0.75f, MeditationSettings.DEFAULT_INTERVAL_GONG_VOLUME)
        assertEquals(0.75f, MeditationSettings.Default.intervalGongVolume)
    }

    @Test
    fun `default settings have correct intervalGongVolume`() {
        val settings = MeditationSettings.Default

        assertEquals(0.75f, settings.intervalGongVolume)
    }

    @Test
    fun `constructor uses default intervalGongVolume`() {
        val settings = MeditationSettings()

        assertEquals(0.75f, settings.intervalGongVolume)
    }

    @Test
    fun `create with custom intervalGongVolume`() {
        val settings = MeditationSettings.create(intervalGongVolume = 0.5f)

        assertEquals(0.5f, settings.intervalGongVolume)
    }

    @Test
    fun `create validates intervalGongVolume`() {
        val settingsAboveMax = MeditationSettings.create(intervalGongVolume = 1.5f)
        assertEquals(1f, settingsAboveMax.intervalGongVolume)

        val settingsBelowMin = MeditationSettings.create(intervalGongVolume = -0.5f)
        assertEquals(0f, settingsBelowMin.intervalGongVolume)

        val settingsValid = MeditationSettings.create(intervalGongVolume = 0.6f)
        assertEquals(0.6f, settingsValid.intervalGongVolume)
    }

    @Test
    fun `copy preserves intervalGongVolume`() {
        val original = MeditationSettings.create(intervalGongVolume = 0.4f)
        val copied = original.copy(durationMinutes = 20)

        assertEquals(0.4f, copied.intervalGongVolume)
        assertEquals(20, copied.durationMinutes)
    }
}
