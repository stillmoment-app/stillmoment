package com.stillmoment.data.local

import com.stillmoment.domain.models.AppTab
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.presentation.navigation.Screen
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Unit tests for SettingsDataStore preference keys and data mapping.
 * Note: Actual DataStore integration tests require instrumented tests.
 */
class SettingsDataStoreTest {
    // MARK: - MeditationSettings Default Values

    @Test
    fun `default settings have correct values`() {
        val settings = MeditationSettings.Default

        assertFalse(settings.intervalGongsEnabled)
        assertEquals(5, settings.intervalMinutes)
        assertEquals(0.75f, settings.intervalGongVolume)
        assertEquals("silent", settings.backgroundSoundId)
        assertEquals(10, settings.durationMinutes)
    }

    @Test
    fun `settings can be created with custom values`() {
        val settings =
            MeditationSettings.create(
                intervalGongsEnabled = true,
                intervalMinutes = 10,
                intervalGongVolume = 0.5f,
                backgroundSoundId = "forest",
                durationMinutes = 20
            )

        assertTrue(settings.intervalGongsEnabled)
        assertEquals(10, settings.intervalMinutes)
        assertEquals(0.5f, settings.intervalGongVolume)
        assertEquals("forest", settings.backgroundSoundId)
        assertEquals(20, settings.durationMinutes)
    }

    @Test
    fun `settings copy preserves unchanged values`() {
        val original =
            MeditationSettings(
                intervalGongsEnabled = true,
                intervalMinutes = 10,
                backgroundSoundId = "forest",
                durationMinutes = 30
            )

        val updated = original.copy(intervalMinutes = 5)

        assertTrue(updated.intervalGongsEnabled)
        assertEquals(5, updated.intervalMinutes)
        assertEquals("forest", updated.backgroundSoundId)
        assertEquals(30, updated.durationMinutes)
    }

    // MARK: - Settings Validation

    @Test
    fun `validateInterval maps to valid intervals (3, 5, 10)`() {
        // Values <= 3 map to 3
        assertEquals(3, MeditationSettings.validateInterval(0))
        assertEquals(3, MeditationSettings.validateInterval(-5))
        assertEquals(3, MeditationSettings.validateInterval(3))

        // Values 4-7 map to 5
        assertEquals(5, MeditationSettings.validateInterval(4))
        assertEquals(5, MeditationSettings.validateInterval(5))
        assertEquals(5, MeditationSettings.validateInterval(7))

        // Values > 7 map to 10
        assertEquals(10, MeditationSettings.validateInterval(8))
        assertEquals(10, MeditationSettings.validateInterval(10))
        assertEquals(10, MeditationSettings.validateInterval(30))
    }

    @Test
    fun `validateDuration clamps values to valid range`() {
        assertEquals(1, MeditationSettings.validateDuration(0))
        assertEquals(1, MeditationSettings.validateDuration(-10))
        assertEquals(10, MeditationSettings.validateDuration(10))
        assertEquals(60, MeditationSettings.validateDuration(60))
        assertEquals(60, MeditationSettings.validateDuration(120))
    }

    // MARK: - Settings Equality

    @Test
    fun `settings equality works correctly`() {
        val settings1 =
            MeditationSettings(
                intervalGongsEnabled = true,
                intervalMinutes = 5,
                backgroundSoundId = "silent",
                durationMinutes = 10
            )

        val settings2 =
            MeditationSettings(
                intervalGongsEnabled = true,
                intervalMinutes = 5,
                backgroundSoundId = "silent",
                durationMinutes = 10
            )

        val settings3 =
            MeditationSettings(
                intervalGongsEnabled = false,
                intervalMinutes = 5,
                backgroundSoundId = "silent",
                durationMinutes = 10
            )

        assertEquals(settings1, settings2)
        assertFalse(settings1 == settings3)
    }

    // MARK: - AppTab Enum Tests

    @Test
    fun `AppTab TIMER has correct route`() {
        assertEquals("timerGraph", AppTab.TIMER.route)
    }

    @Test
    fun `AppTab LIBRARY has correct route`() {
        assertEquals("library", AppTab.LIBRARY.route)
    }

    @Test
    fun `AppTab routes are stable for persistence`() {
        // These values are persisted in DataStore and must match NavHost startDestination routes
        assertEquals(
            "timerGraph",
            AppTab.TIMER.route,
            "AppTab.TIMER.route must be 'timerGraph' (top-level navigation route)"
        )
        assertEquals(
            "library",
            AppTab.LIBRARY.route,
            "AppTab.LIBRARY.route must remain 'library' for backwards compatibility"
        )
    }

    @Test
    fun `AppTab DEFAULT is TIMER`() {
        assertEquals(AppTab.TIMER, AppTab.DEFAULT)
    }

    @Test
    fun `AppTab fromRoute parses valid routes`() {
        assertEquals(AppTab.TIMER, AppTab.fromRoute("timerGraph"))
        assertEquals(AppTab.LIBRARY, AppTab.fromRoute("library"))
    }

    @Test
    fun `AppTab fromRoute returns DEFAULT for unknown routes`() {
        assertEquals(AppTab.DEFAULT, AppTab.fromRoute("unknown"))
        assertEquals(AppTab.DEFAULT, AppTab.fromRoute(null))
        assertEquals(AppTab.DEFAULT, AppTab.fromRoute(""))
    }

    // MARK: - Screen Routes Consistency with AppTab

    @Test
    fun `Screen routes match AppTab routes`() {
        // Ensures Screen and AppTab use the same values (single source of truth)
        assertEquals(
            AppTab.TIMER.route,
            Screen.TimerGraph.route,
            "Screen.TimerGraph must use AppTab.TIMER.route"
        )
        assertEquals(
            AppTab.LIBRARY.route,
            Screen.Library.route,
            "Screen.Library must use AppTab.LIBRARY.route"
        )
    }
}
