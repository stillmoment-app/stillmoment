package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Tests for MeditationSettings introduction and custom attunement behavior.
 *
 * Split from MeditationSettingsTest to keep test classes manageable.
 * Covers: minimumDuration with introductions, hasActiveIntroduction,
 * effectiveIntroDurationSeconds, and custom attunement data flow.
 */
class MeditationSettingsAttunementTest {
    // MARK: - Introduction Tests

    @Test
    fun `default introductionId is null`() {
        assertEquals(null, MeditationSettings.Default.introductionId)
        assertEquals(null, MeditationSettings().introductionId)
    }

    @Test
    fun `minimumDuration without introduction returns 1`() {
        assertEquals(1, MeditationSettings.minimumDuration(null))
    }

    @Test
    fun `minimumDuration with breath introduction returns 2`() {
        // breath: 95s -> ceil(95/60) = ceil(1.583) = 2
        assertEquals(2, MeditationSettings.minimumDuration("breath", introductionEnabled = true))
    }

    @Test
    fun `minimumDuration with unknown introduction returns 1`() {
        assertEquals(1, MeditationSettings.minimumDuration("nonexistent"))
    }

    @Test
    fun `validateDuration with introduction enforces minimum`() {
        // breath min = 2 -> requesting 1 should clamp to 2
        assertEquals(2, MeditationSettings.validateDuration(1, "breath", introductionEnabled = true))
        assertEquals(2, MeditationSettings.validateDuration(2, "breath", introductionEnabled = true))
        assertEquals(3, MeditationSettings.validateDuration(3, "breath", introductionEnabled = true))
        assertEquals(10, MeditationSettings.validateDuration(10, "breath", introductionEnabled = true))
    }

    @Test
    fun `validateDuration without introduction allows 1`() {
        assertEquals(1, MeditationSettings.validateDuration(1, null))
    }

    @Test
    fun `create with introductionId`() {
        val settings = MeditationSettings.create(introductionId = "breath")
        assertEquals("breath", settings.introductionId)
    }

    @Test
    fun `create with introductionId enforces minimum duration`() {
        // breath min = 2 -> duration 1 should be clamped to 2
        val settings = MeditationSettings.create(
            durationMinutes = 1,
            introductionId = "breath",
            introductionEnabled = true,
        )
        assertEquals(2, settings.durationMinutes)
    }

    @Test
    fun `withDurationMinutes respects introduction minimum`() {
        val settings = MeditationSettings(introductionId = "breath", introductionEnabled = true)
        val updated = settings.withDurationMinutes(1)
        assertEquals(2, updated.durationMinutes)
    }

    @Test
    fun `minimumDurationMinutes computed property`() {
        val settingsNoIntro = MeditationSettings()
        assertEquals(1, settingsNoIntro.minimumDurationMinutes)

        val settingsWithIntro = MeditationSettings(introductionId = "breath", introductionEnabled = true)
        assertEquals(2, settingsWithIntro.minimumDurationMinutes)
    }

    // MARK: - Custom Attunement Duration

    @Test
    fun `minimumDuration with custom intro duration 331 seconds returns 6`() {
        // Custom attunement of 5:31 (331s) -> ceil(331/60) = 6
        assertEquals(
            6,
            MeditationSettings.minimumDuration(
                activeIntroductionId = "custom-uuid",
                customIntroDurationSeconds = 331,
            ),
        )
    }

    @Test
    fun `minimumDuration with custom intro duration 61 seconds returns 2`() {
        // Just over 60s -> ceil(61/60) = 2
        assertEquals(
            2,
            MeditationSettings.minimumDuration(
                activeIntroductionId = "custom-uuid",
                customIntroDurationSeconds = 61,
            ),
        )
    }

    @Test
    fun `minimumDuration with custom intro duration but nil id returns 1`() {
        assertEquals(
            1,
            MeditationSettings.minimumDuration(
                activeIntroductionId = null,
                customIntroDurationSeconds = 331,
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
                introductionId = "custom-uuid",
                introductionEnabled = true,
                customIntroDurationSeconds = 331,
            ),
        )
    }

    @Test
    fun `minimumDuration built-in breath no extra minute`() {
        // Breath introduction is 95s -> ceil(95/60) = 2 (not 3)
        assertEquals(
            2,
            MeditationSettings.minimumDuration("breath", introductionEnabled = true),
        )
    }

    // MARK: - minimumDurationMinutes with customIntroDurationSeconds Property

    @Test
    fun `minimumDurationMinutes with custom intro duration property returns correct minimum`() {
        // Custom attunement of 5:31 (331s) -> ceil(331/60) = 6
        val settings = MeditationSettings(
            introductionId = "custom-uuid",
            introductionEnabled = true,
            customIntroDurationSeconds = 331,
        )
        assertEquals(6, settings.minimumDurationMinutes)
    }

    @Test
    fun `minimumDurationMinutes with nil custom intro duration uses built-in`() {
        val settings = MeditationSettings(
            introductionId = "breath",
            introductionEnabled = true,
            customIntroDurationSeconds = null,
        )
        assertEquals(2, settings.minimumDurationMinutes)
    }

    @Test
    fun `withDurationMinutes with custom intro duration clamps to minimum`() {
        val settings = MeditationSettings(
            introductionId = "custom-uuid",
            introductionEnabled = true,
            customIntroDurationSeconds = 331,
        )
        val updated = settings.withDurationMinutes(3)
        assertEquals(6, updated.durationMinutes)
    }

    // MARK: - hasActiveIntroduction Tests

    @Test
    fun `hasActiveIntroduction returns false when disabled`() {
        val settings = MeditationSettings(
            introductionEnabled = false,
            introductionId = "breath",
        )
        assertFalse(settings.hasActiveIntroduction)
    }

    @Test
    fun `hasActiveIntroduction returns false when no introductionId`() {
        val settings = MeditationSettings(
            introductionEnabled = true,
            introductionId = null,
        )
        assertFalse(settings.hasActiveIntroduction)
    }

    @Test
    fun `hasActiveIntroduction returns true for custom attunement`() {
        val settings = MeditationSettings(
            introductionEnabled = true,
            introductionId = "custom-uuid-123",
            customIntroDurationSeconds = 120,
        )
        assertTrue(settings.hasActiveIntroduction)
    }

    @Test
    fun `hasActiveIntroduction returns true for built-in when language available`() {
        Introduction.languageOverride = "de"
        try {
            val settings = MeditationSettings(
                introductionEnabled = true,
                introductionId = "breath",
            )
            assertTrue(settings.hasActiveIntroduction)
        } finally {
            Introduction.languageOverride = null
        }
    }

    @Test
    fun `hasActiveIntroduction returns false for built-in when language unavailable`() {
        Introduction.languageOverride = "fr"
        try {
            val settings = MeditationSettings(
                introductionEnabled = true,
                introductionId = "breath",
            )
            assertFalse(settings.hasActiveIntroduction)
        } finally {
            Introduction.languageOverride = null
        }
    }

    // MARK: - Custom Attunement minimumDuration Data Flow

    @Test
    fun `minimumDuration with custom attunement ID and no customIntroDurationSeconds falls back to 1`() {
        // Custom attunement IDs are not in the built-in Introduction catalog,
        // so Introduction.find() returns null. Without customIntroDurationSeconds
        // the minimum falls back to 1 minute. This is expected behavior --
        // the TimerViewModel resolves the custom duration via CustomAudioRepository
        // and populates customIntroDurationSeconds before passing settings to the Reducer.
        assertEquals(
            1,
            MeditationSettings.minimumDuration(
                activeIntroductionId = "custom-attunement-uuid",
                customIntroDurationSeconds = null,
            ),
        )
    }

    @Test
    fun `validateDuration with custom attunement and customIntroDurationSeconds enforces minimum`() {
        // When TimerViewModel provides customIntroDurationSeconds (sync path),
        // validateDuration correctly enforces the minimum based on audio duration.
        // 180s intro -> ceil(180/60) = 3 min minimum
        assertEquals(
            3,
            MeditationSettings.validateDuration(
                1,
                introductionId = "custom-attunement-uuid",
                introductionEnabled = true,
                customIntroDurationSeconds = 180,
            ),
        )
    }

    @Test
    fun `minimumDurationMinutes uses customIntroDurationSeconds from settings property`() {
        // The minimumDurationMinutes property on MeditationSettings uses the stored
        // customIntroDurationSeconds field -- this is the sync resolution path.
        // TimerViewModel populates this field when converting Praxis to MeditationSettings.
        val settings = MeditationSettings(
            introductionId = "custom-attunement-uuid",
            introductionEnabled = true,
            customIntroDurationSeconds = 240,
        )
        // 240s -> ceil(240/60) = 4
        assertEquals(4, settings.minimumDurationMinutes)
    }

    // MARK: - effectiveIntroDurationSeconds Tests

    @Test
    fun `effectiveIntroDurationSeconds returns 0 when disabled`() {
        val settings = MeditationSettings(
            introductionEnabled = false,
            introductionId = "breath",
        )
        assertEquals(0, settings.effectiveIntroDurationSeconds)
    }

    @Test
    fun `effectiveIntroDurationSeconds returns custom duration for custom attunement`() {
        val settings = MeditationSettings(
            introductionEnabled = true,
            introductionId = "custom-uuid-123",
            customIntroDurationSeconds = 120,
        )
        assertEquals(120, settings.effectiveIntroDurationSeconds)
    }

    @Test
    fun `effectiveIntroDurationSeconds returns built-in duration for breath`() {
        Introduction.languageOverride = "de"
        try {
            val settings = MeditationSettings(
                introductionEnabled = true,
                introductionId = "breath",
            )
            assertEquals(95, settings.effectiveIntroDurationSeconds)
        } finally {
            Introduction.languageOverride = null
        }
    }

    @Test
    fun `effectiveIntroDurationSeconds returns 0 for unknown built-in`() {
        Introduction.languageOverride = "de"
        try {
            val settings = MeditationSettings(
                introductionEnabled = true,
                introductionId = "nonexistent",
            )
            assertEquals(0, settings.effectiveIntroDurationSeconds)
        } finally {
            Introduction.languageOverride = null
        }
    }
}
