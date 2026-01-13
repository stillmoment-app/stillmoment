package com.stillmoment.domain.models

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Unit tests for GuidedMeditationSettings domain model.
 */
class GuidedMeditationSettingsTest {

    // MARK: - Default Values

    @Test
    fun `default settings have preparation time disabled`() {
        val settings = GuidedMeditationSettings.Default

        assertFalse(settings.preparationTimeEnabled)
    }

    @Test
    fun `default settings have 15 seconds as initial preparation time`() {
        val settings = GuidedMeditationSettings.Default

        assertEquals(15, settings.preparationTimeSeconds)
    }

    // MARK: - Valid Preparation Time Values

    @Test
    fun `valid preparation time values are 5, 10, 15, 20, 30, 45`() {
        assertEquals(
            listOf(5, 10, 15, 20, 30, 45),
            GuidedMeditationSettings.VALID_PREPARATION_TIMES
        )
    }

    // MARK: - Validation

    @Test
    fun `validatePreparationTime returns 5 for values below 7`() {
        assertEquals(5, GuidedMeditationSettings.validatePreparationTime(1))
        assertEquals(5, GuidedMeditationSettings.validatePreparationTime(5))
        assertEquals(5, GuidedMeditationSettings.validatePreparationTime(6))
    }

    @Test
    fun `validatePreparationTime returns 10 for values between 8 and 12`() {
        assertEquals(10, GuidedMeditationSettings.validatePreparationTime(8))
        assertEquals(10, GuidedMeditationSettings.validatePreparationTime(10))
        assertEquals(10, GuidedMeditationSettings.validatePreparationTime(12))
    }

    @Test
    fun `validatePreparationTime returns 15 for values between 13 and 17`() {
        assertEquals(15, GuidedMeditationSettings.validatePreparationTime(13))
        assertEquals(15, GuidedMeditationSettings.validatePreparationTime(15))
        assertEquals(15, GuidedMeditationSettings.validatePreparationTime(17))
    }

    @Test
    fun `validatePreparationTime returns 20 for values between 18 and 25`() {
        assertEquals(20, GuidedMeditationSettings.validatePreparationTime(18))
        assertEquals(20, GuidedMeditationSettings.validatePreparationTime(20))
        assertEquals(20, GuidedMeditationSettings.validatePreparationTime(24))
    }

    @Test
    fun `validatePreparationTime returns 30 for values between 26 and 37`() {
        assertEquals(30, GuidedMeditationSettings.validatePreparationTime(26))
        assertEquals(30, GuidedMeditationSettings.validatePreparationTime(30))
        assertEquals(30, GuidedMeditationSettings.validatePreparationTime(37))
    }

    @Test
    fun `validatePreparationTime returns 20 for 25 due to tie-breaker`() {
        // At 25: distance to 20 = 5, distance to 30 = 5
        // minByOrNull returns first match (20) on tie
        assertEquals(20, GuidedMeditationSettings.validatePreparationTime(25))
    }

    @Test
    fun `validatePreparationTime returns 45 for values 38 and above`() {
        assertEquals(45, GuidedMeditationSettings.validatePreparationTime(38))
        assertEquals(45, GuidedMeditationSettings.validatePreparationTime(45))
        assertEquals(45, GuidedMeditationSettings.validatePreparationTime(100))
    }

    // MARK: - Factory Methods

    @Test
    fun `withPreparationTimeEnabled returns copy with enabled flag`() {
        val settings = GuidedMeditationSettings.Default
        val updated = settings.withPreparationTimeEnabled(true)

        assertTrue(updated.preparationTimeEnabled)
        assertEquals(settings.preparationTimeSeconds, updated.preparationTimeSeconds)
    }

    @Test
    fun `withPreparationTimeSeconds returns copy with validated seconds`() {
        val settings = GuidedMeditationSettings.Default
        val updated = settings.withPreparationTimeSeconds(10)

        assertEquals(10, updated.preparationTimeSeconds)
    }

    @Test
    fun `withPreparationTimeSeconds validates invalid values`() {
        val settings = GuidedMeditationSettings.Default
        val updated = settings.withPreparationTimeSeconds(7)

        assertEquals(5, updated.preparationTimeSeconds)
    }

    // MARK: - Effective Preparation Time

    @Test
    fun `effectivePreparationTimeSeconds returns null when disabled`() {
        val settings = GuidedMeditationSettings(
            preparationTimeEnabled = false,
            preparationTimeSeconds = 15
        )

        assertNull(settings.effectivePreparationTimeSeconds)
    }

    @Test
    fun `effectivePreparationTimeSeconds returns seconds when enabled`() {
        val settings = GuidedMeditationSettings(
            preparationTimeEnabled = true,
            preparationTimeSeconds = 20
        )

        assertEquals(20, settings.effectivePreparationTimeSeconds)
    }
}
