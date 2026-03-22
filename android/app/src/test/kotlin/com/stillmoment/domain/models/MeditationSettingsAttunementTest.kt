package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Tests for MeditationSettings attunement and custom attunement behavior.
 *
 * Split from MeditationSettingsTest to keep test classes manageable.
 * Covers: minimumDuration with attunements, hasActiveAttunement,
 * effectiveAttunementDurationSeconds, and custom attunement data flow.
 */
class MeditationSettingsAttunementTest {
    // MARK: - Attunement Tests

    @Test
    fun `default attunementId is null`() {
        assertEquals(null, MeditationSettings.Default.attunementId)
        assertEquals(null, MeditationSettings().attunementId)
    }

    @Test
    fun `minimumDuration without attunement returns 1`() {
        assertEquals(1, MeditationSettings.minimumDuration(null))
    }

    @Test
    fun `minimumDuration with breath attunement returns 2`() {
        // breath: 95s -> ceil(95/60) = ceil(1.583) = 2
        assertEquals(2, MeditationSettings.minimumDuration("breath", attunementEnabled = true))
    }

    @Test
    fun `minimumDuration with unknown attunement returns 1`() {
        assertEquals(1, MeditationSettings.minimumDuration("nonexistent"))
    }

    @Test
    fun `validateDuration with attunement enforces minimum`() {
        // breath min = 2 -> requesting 1 should clamp to 2
        assertEquals(2, MeditationSettings.validateDuration(1, "breath", attunementEnabled = true))
        assertEquals(2, MeditationSettings.validateDuration(2, "breath", attunementEnabled = true))
        assertEquals(3, MeditationSettings.validateDuration(3, "breath", attunementEnabled = true))
        assertEquals(10, MeditationSettings.validateDuration(10, "breath", attunementEnabled = true))
    }

    @Test
    fun `validateDuration without attunement allows 1`() {
        assertEquals(1, MeditationSettings.validateDuration(1, null))
    }

    @Test
    fun `create with attunementId`() {
        val settings = MeditationSettings.create(attunementId = "breath")
        assertEquals("breath", settings.attunementId)
    }

    @Test
    fun `create with attunementId enforces minimum duration`() {
        // breath min = 2 -> duration 1 should be clamped to 2
        val settings = MeditationSettings.create(
            durationMinutes = 1,
            attunementId = "breath",
            attunementEnabled = true,
        )
        assertEquals(2, settings.durationMinutes)
    }

    @Test
    fun `withDurationMinutes respects attunement minimum`() {
        val settings = MeditationSettings(attunementId = "breath", attunementEnabled = true)
        val updated = settings.withDurationMinutes(1)
        assertEquals(2, updated.durationMinutes)
    }

    @Test
    fun `minimumDurationMinutes computed property`() {
        val settingsNoIntro = MeditationSettings()
        assertEquals(1, settingsNoIntro.minimumDurationMinutes)

        val settingsWithIntro = MeditationSettings(attunementId = "breath", attunementEnabled = true)
        assertEquals(2, settingsWithIntro.minimumDurationMinutes)
    }

    // MARK: - Custom Attunement Duration

    @Test
    fun `minimumDuration with custom intro duration 331 seconds returns 6`() {
        // Custom attunement of 5:31 (331s) -> ceil(331/60) = 6
        assertEquals(
            6,
            MeditationSettings.minimumDuration(
                activeAttunementId = "custom-uuid",
                customAttunementDurationSeconds = 331,
            ),
        )
    }

    @Test
    fun `minimumDuration with custom intro duration 61 seconds returns 2`() {
        // Just over 60s -> ceil(61/60) = 2
        assertEquals(
            2,
            MeditationSettings.minimumDuration(
                activeAttunementId = "custom-uuid",
                customAttunementDurationSeconds = 61,
            ),
        )
    }

    @Test
    fun `minimumDuration with custom intro duration but nil id returns 1`() {
        assertEquals(
            1,
            MeditationSettings.minimumDuration(
                activeAttunementId = null,
                customAttunementDurationSeconds = 331,
            ),
        )
    }

    @Test
    fun `validateDuration with custom intro duration clamps to minimum`() {
        // 331s intro -> minimum 6, selecting 3 should clamp to 6
        assertEquals(
            6,
            MeditationSettings.validateDuration(
                3,
                attunementId = "custom-uuid",
                attunementEnabled = true,
                customAttunementDurationSeconds = 331,
            ),
        )
    }

    @Test
    fun `minimumDuration built-in breath no extra minute`() {
        // Breath attunement is 95s -> ceil(95/60) = 2 (not 3)
        assertEquals(
            2,
            MeditationSettings.minimumDuration("breath", attunementEnabled = true),
        )
    }

    // MARK: - minimumDurationMinutes with customAttunementDurationSeconds Property

    @Test
    fun `minimumDurationMinutes with custom intro duration property returns correct minimum`() {
        // Custom attunement of 5:31 (331s) -> ceil(331/60) = 6
        val settings = MeditationSettings(
            attunementId = "custom-uuid",
            attunementEnabled = true,
            customAttunementDurationSeconds = 331,
        )
        assertEquals(6, settings.minimumDurationMinutes)
    }

    @Test
    fun `minimumDurationMinutes with nil custom intro duration uses built-in`() {
        val settings = MeditationSettings(
            attunementId = "breath",
            attunementEnabled = true,
            customAttunementDurationSeconds = null,
        )
        assertEquals(2, settings.minimumDurationMinutes)
    }

    @Test
    fun `withDurationMinutes with custom intro duration clamps to minimum`() {
        val settings = MeditationSettings(
            attunementId = "custom-uuid",
            attunementEnabled = true,
            customAttunementDurationSeconds = 331,
        )
        val updated = settings.withDurationMinutes(3)
        assertEquals(6, updated.durationMinutes)
    }

    // MARK: - hasActiveAttunement Tests

    @Test
    fun `hasActiveAttunement returns false when disabled`() {
        val settings = MeditationSettings(
            attunementEnabled = false,
            attunementId = "breath",
        )
        assertFalse(settings.hasActiveAttunement)
    }

    @Test
    fun `hasActiveAttunement returns false when no attunementId`() {
        val settings = MeditationSettings(
            attunementEnabled = true,
            attunementId = null,
        )
        assertFalse(settings.hasActiveAttunement)
    }

    @Test
    fun `hasActiveAttunement returns true for custom attunement`() {
        val settings = MeditationSettings(
            attunementEnabled = true,
            attunementId = "custom-uuid-123",
            customAttunementDurationSeconds = 120,
        )
        assertTrue(settings.hasActiveAttunement)
    }

    @Test
    fun `hasActiveAttunement returns true for built-in when language available`() {
        Attunement.languageOverride = "de"
        try {
            val settings = MeditationSettings(
                attunementEnabled = true,
                attunementId = "breath",
            )
            assertTrue(settings.hasActiveAttunement)
        } finally {
            Attunement.languageOverride = null
        }
    }

    @Test
    fun `hasActiveAttunement returns false for built-in when language unavailable`() {
        Attunement.languageOverride = "fr"
        try {
            val settings = MeditationSettings(
                attunementEnabled = true,
                attunementId = "breath",
            )
            assertFalse(settings.hasActiveAttunement)
        } finally {
            Attunement.languageOverride = null
        }
    }

    // MARK: - Custom Attunement minimumDuration Data Flow

    @Test
    fun `minimumDuration with custom attunement ID and no customAttunementDurationSeconds falls back to 1`() {
        // Custom attunement IDs are not in the built-in Attunement catalog,
        // so Attunement.find() returns null. Without customAttunementDurationSeconds
        // the minimum falls back to 1 minute. This is expected behavior --
        // the TimerViewModel resolves the custom duration via CustomAudioRepository
        // and populates customAttunementDurationSeconds before passing settings to the Reducer.
        assertEquals(
            1,
            MeditationSettings.minimumDuration(
                activeAttunementId = "custom-attunement-uuid",
                customAttunementDurationSeconds = null,
            ),
        )
    }

    @Test
    fun `validateDuration with custom attunement and customAttunementDurationSeconds enforces minimum`() {
        // When TimerViewModel provides customAttunementDurationSeconds (sync path),
        // validateDuration correctly enforces the minimum based on audio duration.
        // 180s intro -> ceil(180/60) = 3 min minimum
        assertEquals(
            3,
            MeditationSettings.validateDuration(
                1,
                attunementId = "custom-attunement-uuid",
                attunementEnabled = true,
                customAttunementDurationSeconds = 180,
            ),
        )
    }

    @Test
    fun `minimumDurationMinutes uses customAttunementDurationSeconds from settings property`() {
        // The minimumDurationMinutes property on MeditationSettings uses the stored
        // customAttunementDurationSeconds field -- this is the sync resolution path.
        // TimerViewModel populates this field when converting Praxis to MeditationSettings.
        val settings = MeditationSettings(
            attunementId = "custom-attunement-uuid",
            attunementEnabled = true,
            customAttunementDurationSeconds = 240,
        )
        // 240s -> ceil(240/60) = 4
        assertEquals(4, settings.minimumDurationMinutes)
    }

    // MARK: - effectiveAttunementDurationSeconds Tests

    @Test
    fun `effectiveAttunementDurationSeconds returns 0 when disabled`() {
        val settings = MeditationSettings(
            attunementEnabled = false,
            attunementId = "breath",
        )
        assertEquals(0, settings.effectiveAttunementDurationSeconds)
    }

    @Test
    fun `effectiveAttunementDurationSeconds returns custom duration for custom attunement`() {
        val settings = MeditationSettings(
            attunementEnabled = true,
            attunementId = "custom-uuid-123",
            customAttunementDurationSeconds = 120,
        )
        assertEquals(120, settings.effectiveAttunementDurationSeconds)
    }

    @Test
    fun `effectiveAttunementDurationSeconds returns built-in duration for breath`() {
        Attunement.languageOverride = "de"
        try {
            val settings = MeditationSettings(
                attunementEnabled = true,
                attunementId = "breath",
            )
            assertEquals(95, settings.effectiveAttunementDurationSeconds)
        } finally {
            Attunement.languageOverride = null
        }
    }

    @Test
    fun `effectiveAttunementDurationSeconds returns 0 for unknown built-in`() {
        Attunement.languageOverride = "de"
        try {
            val settings = MeditationSettings(
                attunementEnabled = true,
                attunementId = "nonexistent",
            )
            assertEquals(0, settings.effectiveAttunementDurationSeconds)
        } finally {
            Attunement.languageOverride = null
        }
    }
}
