package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for Praxis domain model.
 */
class PraxisTest {
    // MARK: - Default Values Tests

    @Test
    fun `default praxis has expected values`() {
        val praxis = Praxis.Default

        assertEquals(10, praxis.durationMinutes)
        assertTrue(praxis.preparationTimeEnabled)
        assertEquals(15, praxis.preparationTimeSeconds)
        assertEquals(GongSound.DEFAULT_SOUND_ID, praxis.gongSoundId)
        assertEquals(1.0f, praxis.gongVolume)
        assertNull(praxis.attunementId)
        assertFalse(praxis.attunementEnabled)
        assertFalse(praxis.intervalGongsEnabled)
        assertEquals(5, praxis.intervalMinutes)
        assertEquals(IntervalMode.REPEATING, praxis.intervalMode)
        assertEquals(GongSound.SOFT_INTERVAL_SOUND_ID, praxis.intervalSoundId)
        assertEquals(0.75f, praxis.intervalGongVolume)
        assertEquals("silent", praxis.backgroundSoundId)
        assertEquals(0.15f, praxis.backgroundSoundVolume)
    }

    @Test
    fun `default praxis has non-empty id`() {
        val praxis = Praxis.Default

        assertTrue(praxis.id.isNotEmpty())
    }

    @Test
    fun `create with defaults matches Default instance values`() {
        val praxis = Praxis.create()

        assertEquals(Praxis.Default.durationMinutes, praxis.durationMinutes)
        assertEquals(Praxis.Default.preparationTimeEnabled, praxis.preparationTimeEnabled)
        assertEquals(Praxis.Default.preparationTimeSeconds, praxis.preparationTimeSeconds)
        assertEquals(Praxis.Default.gongSoundId, praxis.gongSoundId)
        assertEquals(Praxis.Default.gongVolume, praxis.gongVolume)
        assertEquals(Praxis.Default.attunementId, praxis.attunementId)
        assertEquals(Praxis.Default.attunementEnabled, praxis.attunementEnabled)
        assertEquals(Praxis.Default.intervalGongsEnabled, praxis.intervalGongsEnabled)
        assertEquals(Praxis.Default.intervalMinutes, praxis.intervalMinutes)
        assertEquals(Praxis.Default.intervalMode, praxis.intervalMode)
        assertEquals(Praxis.Default.intervalSoundId, praxis.intervalSoundId)
        assertEquals(Praxis.Default.intervalGongVolume, praxis.intervalGongVolume)
        assertEquals(Praxis.Default.backgroundSoundId, praxis.backgroundSoundId)
        assertEquals(Praxis.Default.backgroundSoundVolume, praxis.backgroundSoundVolume)
    }

    // MARK: - Duration Validation Tests

    @Nested
    inner class DurationValidation {
        @Test
        fun `create clamps duration below minimum to 1`() {
            val praxis = Praxis.create(durationMinutes = 0)
            assertEquals(1, praxis.durationMinutes)
        }

        @Test
        fun `create clamps negative duration to 1`() {
            val praxis = Praxis.create(durationMinutes = -5)
            assertEquals(1, praxis.durationMinutes)
        }

        @Test
        fun `create clamps duration above maximum to 60`() {
            val praxis = Praxis.create(durationMinutes = 61)
            assertEquals(60, praxis.durationMinutes)
        }

        @Test
        fun `create clamps large duration to 60`() {
            val praxis = Praxis.create(durationMinutes = 100)
            assertEquals(60, praxis.durationMinutes)
        }

        @Test
        fun `create passes through valid duration`() {
            val praxis = Praxis.create(durationMinutes = 30)
            assertEquals(30, praxis.durationMinutes)
        }

        @Test
        fun `validateDuration clamps to minimum 1`() {
            assertEquals(1, Praxis.validateDuration(0))
            assertEquals(1, Praxis.validateDuration(-5))
            assertEquals(1, Praxis.validateDuration(1))
        }

        @Test
        fun `validateDuration clamps to maximum 60`() {
            assertEquals(60, Praxis.validateDuration(60))
            assertEquals(60, Praxis.validateDuration(61))
            assertEquals(60, Praxis.validateDuration(100))
        }
    }

    // MARK: - Interval Validation Tests

    @Nested
    inner class IntervalValidation {
        @Test
        fun `create clamps interval below minimum to 1`() {
            val praxis = Praxis.create(intervalMinutes = 0)
            assertEquals(1, praxis.intervalMinutes)
        }

        @Test
        fun `create clamps negative interval to 1`() {
            val praxis = Praxis.create(intervalMinutes = -5)
            assertEquals(1, praxis.intervalMinutes)
        }

        @Test
        fun `create clamps interval above maximum to 60`() {
            val praxis = Praxis.create(intervalMinutes = 61)
            assertEquals(60, praxis.intervalMinutes)
        }

        @Test
        fun `create clamps large interval to 60`() {
            val praxis = Praxis.create(intervalMinutes = 100)
            assertEquals(60, praxis.intervalMinutes)
        }

        @Test
        fun `create passes through valid interval`() {
            val praxis = Praxis.create(intervalMinutes = 7)
            assertEquals(7, praxis.intervalMinutes)
        }

        @Test
        fun `validateInterval clamps to minimum 1`() {
            assertEquals(1, Praxis.validateInterval(0))
            assertEquals(1, Praxis.validateInterval(-5))
            assertEquals(1, Praxis.validateInterval(1))
        }

        @Test
        fun `validateInterval clamps to maximum 60`() {
            assertEquals(60, Praxis.validateInterval(60))
            assertEquals(60, Praxis.validateInterval(61))
            assertEquals(60, Praxis.validateInterval(100))
        }
    }

    // MARK: - Preparation Time Validation Tests

    @Nested
    inner class PreparationTimeValidation {
        @Test
        fun `create snaps 7 to 5`() {
            val praxis = Praxis.create(preparationTimeSeconds = 7)
            assertEquals(5, praxis.preparationTimeSeconds)
        }

        @Test
        fun `create snaps 12 to 10`() {
            val praxis = Praxis.create(preparationTimeSeconds = 12)
            assertEquals(10, praxis.preparationTimeSeconds)
        }

        @Test
        fun `create snaps 17 to 15`() {
            val praxis = Praxis.create(preparationTimeSeconds = 17)
            assertEquals(15, praxis.preparationTimeSeconds)
        }

        @Test
        fun `create snaps 22 to 20`() {
            val praxis = Praxis.create(preparationTimeSeconds = 22)
            assertEquals(20, praxis.preparationTimeSeconds)
        }

        @Test
        fun `create snaps 35 to 30`() {
            val praxis = Praxis.create(preparationTimeSeconds = 35)
            assertEquals(30, praxis.preparationTimeSeconds)
        }

        @Test
        fun `create snaps 40 to 45`() {
            val praxis = Praxis.create(preparationTimeSeconds = 40)
            assertEquals(45, praxis.preparationTimeSeconds)
        }

        @Test
        fun `create passes through exact valid values`() {
            assertEquals(5, Praxis.create(preparationTimeSeconds = 5).preparationTimeSeconds)
            assertEquals(10, Praxis.create(preparationTimeSeconds = 10).preparationTimeSeconds)
            assertEquals(15, Praxis.create(preparationTimeSeconds = 15).preparationTimeSeconds)
            assertEquals(20, Praxis.create(preparationTimeSeconds = 20).preparationTimeSeconds)
            assertEquals(30, Praxis.create(preparationTimeSeconds = 30).preparationTimeSeconds)
            assertEquals(45, Praxis.create(preparationTimeSeconds = 45).preparationTimeSeconds)
        }

        @Test
        fun `validatePreparationTime snaps to nearest value`() {
            assertEquals(5, Praxis.validatePreparationTime(7))
            assertEquals(10, Praxis.validatePreparationTime(12))
            assertEquals(15, Praxis.validatePreparationTime(17))
            assertEquals(20, Praxis.validatePreparationTime(22))
            assertEquals(30, Praxis.validatePreparationTime(35))
            assertEquals(45, Praxis.validatePreparationTime(40))
        }

        @Test
        fun `VALID_PREPARATION_TIMES contains expected values`() {
            assertEquals(listOf(5, 10, 15, 20, 30, 45), Praxis.VALID_PREPARATION_TIMES)
        }
    }

    // MARK: - Volume Validation Tests

    @Nested
    inner class VolumeValidation {
        @Test
        fun `create clamps gongVolume below minimum to 0`() {
            val praxis = Praxis.create(gongVolume = -0.1f)
            assertEquals(0.0f, praxis.gongVolume)
        }

        @Test
        fun `create clamps gongVolume above maximum to 1`() {
            val praxis = Praxis.create(gongVolume = 1.1f)
            assertEquals(1.0f, praxis.gongVolume)
        }

        @Test
        fun `create clamps intervalGongVolume below minimum to 0`() {
            val praxis = Praxis.create(intervalGongVolume = -0.1f)
            assertEquals(0.0f, praxis.intervalGongVolume)
        }

        @Test
        fun `create clamps intervalGongVolume above maximum to 1`() {
            val praxis = Praxis.create(intervalGongVolume = 1.1f)
            assertEquals(1.0f, praxis.intervalGongVolume)
        }

        @Test
        fun `create clamps backgroundSoundVolume below minimum to 0`() {
            val praxis = Praxis.create(backgroundSoundVolume = -0.1f)
            assertEquals(0.0f, praxis.backgroundSoundVolume)
        }

        @Test
        fun `create clamps backgroundSoundVolume above maximum to 1`() {
            val praxis = Praxis.create(backgroundSoundVolume = 1.1f)
            assertEquals(1.0f, praxis.backgroundSoundVolume)
        }

        @Test
        fun `validateVolume clamps to minimum 0`() {
            assertEquals(0f, Praxis.validateVolume(-0.5f))
            assertEquals(0f, Praxis.validateVolume(-1f))
            assertEquals(0f, Praxis.validateVolume(0f))
        }

        @Test
        fun `validateVolume clamps to maximum 1`() {
            assertEquals(1f, Praxis.validateVolume(1f))
            assertEquals(1f, Praxis.validateVolume(1.5f))
            assertEquals(1f, Praxis.validateVolume(2f))
        }

        @Test
        fun `validateVolume passes through valid values`() {
            assertEquals(0.15f, Praxis.validateVolume(0.15f))
            assertEquals(0.5f, Praxis.validateVolume(0.5f))
            assertEquals(0.75f, Praxis.validateVolume(0.75f))
        }
    }

    // MARK: - Migration from MeditationSettings Tests

    @Nested
    inner class MigrationFromMeditationSettings {
        @Test
        fun `fromMeditationSettings preserves all fields`() {
            val settings = MeditationSettings.create(
                intervalGongsEnabled = true,
                intervalMinutes = 10,
                intervalMode = IntervalMode.BEFORE_END,
                intervalSoundId = "soft-interval",
                intervalGongVolume = 0.6f,
                backgroundSoundId = "forest",
                backgroundSoundVolume = 0.5f,
                durationMinutes = 20,
                preparationTimeEnabled = false,
                preparationTimeSeconds = 30,
                gongSoundId = "clear-strike",
                gongVolume = 0.8f,
                attunementId = "breath",
                attunementEnabled = true
            )

            val praxis = Praxis.fromMeditationSettings(settings)

            assertTrue(praxis.intervalGongsEnabled)
            assertEquals(10, praxis.intervalMinutes)
            assertEquals(IntervalMode.BEFORE_END, praxis.intervalMode)
            assertEquals("soft-interval", praxis.intervalSoundId)
            assertEquals(0.6f, praxis.intervalGongVolume)
            assertEquals("forest", praxis.backgroundSoundId)
            assertEquals(0.5f, praxis.backgroundSoundVolume)
            assertEquals(20, praxis.durationMinutes)
            assertFalse(praxis.preparationTimeEnabled)
            assertEquals(30, praxis.preparationTimeSeconds)
            assertEquals("clear-strike", praxis.gongSoundId)
            assertEquals(0.8f, praxis.gongVolume)
            assertEquals("breath", praxis.attunementId)
            assertTrue(praxis.attunementEnabled)
        }

        @Test
        fun `fromMeditationSettings uses provided id`() {
            val settings = MeditationSettings.Default
            val customId = "custom-test-id"

            val praxis = Praxis.fromMeditationSettings(settings, id = customId)

            assertEquals(customId, praxis.id)
        }

        @Test
        fun `fromMeditationSettings generates id when not provided`() {
            val settings = MeditationSettings.Default

            val praxis = Praxis.fromMeditationSettings(settings)

            assertTrue(praxis.id.isNotEmpty())
        }
    }

    // MARK: - Conversion to MeditationSettings Tests

    @Nested
    inner class ConversionToMeditationSettings {
        @Test
        fun `toMeditationSettings round-trip preserves fields`() {
            val original = Praxis.create(
                durationMinutes = 25,
                preparationTimeEnabled = false,
                preparationTimeSeconds = 20,
                gongSoundId = "deep-resonance",
                gongVolume = 0.7f,
                attunementId = "breath",
                attunementEnabled = true,
                intervalGongsEnabled = true,
                intervalMinutes = 8,
                intervalMode = IntervalMode.AFTER_START,
                intervalSoundId = "temple-bell",
                intervalGongVolume = 0.5f,
                backgroundSoundId = "forest",
                backgroundSoundVolume = 0.4f
            )

            val settings = original.toMeditationSettings()

            assertEquals(original.durationMinutes, settings.durationMinutes)
            assertEquals(original.preparationTimeEnabled, settings.preparationTimeEnabled)
            assertEquals(original.preparationTimeSeconds, settings.preparationTimeSeconds)
            assertEquals(original.gongSoundId, settings.gongSoundId)
            assertEquals(original.gongVolume, settings.gongVolume)
            assertEquals(original.attunementId, settings.attunementId)
            assertEquals(original.attunementEnabled, settings.attunementEnabled)
            assertEquals(original.intervalGongsEnabled, settings.intervalGongsEnabled)
            assertEquals(original.intervalMinutes, settings.intervalMinutes)
            assertEquals(original.intervalMode, settings.intervalMode)
            assertEquals(original.intervalSoundId, settings.intervalSoundId)
            assertEquals(original.intervalGongVolume, settings.intervalGongVolume)
            assertEquals(original.backgroundSoundId, settings.backgroundSoundId)
            assertEquals(original.backgroundSoundVolume, settings.backgroundSoundVolume)
        }

        @Test
        fun `fromMeditationSettings then toMeditationSettings preserves all fields`() {
            val originalSettings = MeditationSettings.create(
                intervalGongsEnabled = true,
                intervalMinutes = 15,
                intervalMode = IntervalMode.BEFORE_END,
                intervalSoundId = "clear-strike",
                intervalGongVolume = 0.9f,
                backgroundSoundId = "forest",
                backgroundSoundVolume = 0.3f,
                durationMinutes = 45,
                preparationTimeEnabled = true,
                preparationTimeSeconds = 10,
                gongSoundId = "classic-bowl",
                gongVolume = 0.5f,
                attunementId = null,
                attunementEnabled = false
            )

            val praxis = Praxis.fromMeditationSettings(originalSettings)
            val roundTrippedSettings = praxis.toMeditationSettings()

            assertEquals(originalSettings.intervalGongsEnabled, roundTrippedSettings.intervalGongsEnabled)
            assertEquals(originalSettings.intervalMinutes, roundTrippedSettings.intervalMinutes)
            assertEquals(originalSettings.intervalMode, roundTrippedSettings.intervalMode)
            assertEquals(originalSettings.intervalSoundId, roundTrippedSettings.intervalSoundId)
            assertEquals(originalSettings.intervalGongVolume, roundTrippedSettings.intervalGongVolume)
            assertEquals(originalSettings.backgroundSoundId, roundTrippedSettings.backgroundSoundId)
            assertEquals(originalSettings.backgroundSoundVolume, roundTrippedSettings.backgroundSoundVolume)
            assertEquals(originalSettings.durationMinutes, roundTrippedSettings.durationMinutes)
            assertEquals(originalSettings.preparationTimeEnabled, roundTrippedSettings.preparationTimeEnabled)
            assertEquals(originalSettings.preparationTimeSeconds, roundTrippedSettings.preparationTimeSeconds)
            assertEquals(originalSettings.gongSoundId, roundTrippedSettings.gongSoundId)
            assertEquals(originalSettings.gongVolume, roundTrippedSettings.gongVolume)
            assertEquals(originalSettings.attunementId, roundTrippedSettings.attunementId)
            assertEquals(originalSettings.attunementEnabled, roundTrippedSettings.attunementEnabled)
        }
    }

    // MARK: - Builder Method Tests

    @Nested
    inner class BuilderMethods {
        @Test
        fun `withBackgroundSoundId preserves id and other fields`() {
            val original = Praxis.create(
                durationMinutes = 20,
                gongSoundId = "clear-strike",
                backgroundSoundId = "silent"
            )

            val updated = original.withBackgroundSoundId("forest")

            assertEquals(original.id, updated.id)
            assertEquals("forest", updated.backgroundSoundId)
            assertEquals(original.durationMinutes, updated.durationMinutes)
            assertEquals(original.gongSoundId, updated.gongSoundId)
            assertEquals(original.gongVolume, updated.gongVolume)
            assertEquals(original.preparationTimeEnabled, updated.preparationTimeEnabled)
        }

        @Test
        fun `withDurationMinutes preserves id and other fields`() {
            val original = Praxis.create(
                durationMinutes = 10,
                backgroundSoundId = "forest"
            )

            val updated = original.withDurationMinutes(30)

            assertEquals(original.id, updated.id)
            assertEquals(30, updated.durationMinutes)
            assertEquals(original.backgroundSoundId, updated.backgroundSoundId)
            assertEquals(original.gongSoundId, updated.gongSoundId)
        }

        @Test
        fun `withDurationMinutes validates input`() {
            val original = Praxis.create()

            assertEquals(1, original.withDurationMinutes(0).durationMinutes)
            assertEquals(60, original.withDurationMinutes(100).durationMinutes)
        }

        @Test
        fun `withAttunementId preserves id and other fields`() {
            val original = Praxis.create(
                durationMinutes = 15,
                attunementId = null
            )

            val updated = original.withAttunementId("breath")

            assertEquals(original.id, updated.id)
            assertEquals("breath", updated.attunementId)
            assertEquals(original.durationMinutes, updated.durationMinutes)
            assertEquals(original.gongSoundId, updated.gongSoundId)
        }

        @Test
        fun `withAttunementId accepts null`() {
            val original = Praxis.create(attunementId = "breath")

            val updated = original.withAttunementId(null)

            assertNull(updated.attunementId)
        }

        @Test
        fun `withAttunementEnabled preserves id and other fields`() {
            val original = Praxis.create(
                durationMinutes = 15,
                attunementEnabled = false,
                attunementId = "breath"
            )

            val updated = original.withAttunementEnabled(true)

            assertEquals(original.id, updated.id)
            assertTrue(updated.attunementEnabled)
            assertEquals(original.attunementId, updated.attunementId)
            assertEquals(original.durationMinutes, updated.durationMinutes)
        }

        @Test
        fun `withAttunementEnabled can disable`() {
            val original = Praxis.create(attunementEnabled = true)

            val updated = original.withAttunementEnabled(false)

            assertFalse(updated.attunementEnabled)
        }
    }

    // MARK: - Equality Tests

    @Nested
    inner class Equality {
        @Test
        fun `two praxes with same id and fields are equal`() {
            val id = "test-id"
            val praxis1 = Praxis.create(id = id, durationMinutes = 10)
            val praxis2 = Praxis.create(id = id, durationMinutes = 10)

            assertEquals(praxis1, praxis2)
        }

        @Test
        fun `two praxes with different ids are not equal`() {
            val praxis1 = Praxis.create(durationMinutes = 10)
            val praxis2 = Praxis.create(durationMinutes = 10)

            assertNotEquals(praxis1, praxis2)
        }

        @Test
        fun `two praxes with same id but different fields are not equal`() {
            val id = "test-id"
            val praxis1 = Praxis.create(id = id, durationMinutes = 10)
            val praxis2 = Praxis.create(id = id, durationMinutes = 20)

            assertNotEquals(praxis1, praxis2)
        }
    }
}
