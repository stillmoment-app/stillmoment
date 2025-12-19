package com.stillmoment.data.local

import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.presentation.navigation.Screen
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
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
        assertEquals("silent", settings.backgroundSoundId)
        assertEquals(10, settings.durationMinutes)
    }

    @Test
    fun `settings can be created with custom values`() {
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

    @Test
    fun `settings copy preserves unchanged values`() {
        val original = MeditationSettings(
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
        val settings1 = MeditationSettings(
            intervalGongsEnabled = true,
            intervalMinutes = 5,
            backgroundSoundId = "silent",
            durationMinutes = 10
        )

        val settings2 = MeditationSettings(
            intervalGongsEnabled = true,
            intervalMinutes = 5,
            backgroundSoundId = "silent",
            durationMinutes = 10
        )

        val settings3 = MeditationSettings(
            intervalGongsEnabled = false,
            intervalMinutes = 5,
            backgroundSoundId = "silent",
            durationMinutes = 10
        )

        assertEquals(settings1, settings2)
        assertFalse(settings1 == settings3)
    }

    // MARK: - Tab Persistence Constants

    @Test
    fun `TAB_TIMER constant has correct value`() {
        assertEquals("timer", SettingsDataStore.TAB_TIMER)
    }

    @Test
    fun `TAB_LIBRARY constant has correct value`() {
        assertEquals("library", SettingsDataStore.TAB_LIBRARY)
    }

    @Test
    fun `tab constants are stable for persistence`() {
        // These values are persisted in DataStore
        // Changing them would break existing user preferences
        assertEquals(
            "timer",
            SettingsDataStore.TAB_TIMER,
            "TAB_TIMER must remain 'timer' for backwards compatibility"
        )
        assertEquals(
            "library",
            SettingsDataStore.TAB_LIBRARY,
            "TAB_LIBRARY must remain 'library' for backwards compatibility"
        )
    }

    // MARK: - Tab Constants Consistency with Navigation

    @Test
    fun `tab constants match Screen routes for consistency`() {
        // Ensures SettingsDataStore and NavGraph use the same values
        // This prevents silent bugs if either side changes
        assertEquals(
            SettingsDataStore.TAB_TIMER,
            Screen.Timer.route,
            "TAB_TIMER must match Screen.Timer.route"
        )
        assertEquals(
            SettingsDataStore.TAB_LIBRARY,
            Screen.Library.route,
            "TAB_LIBRARY must match Screen.Library.route"
        )
    }

    @Test
    fun `default tab is timer`() {
        // When no value is stored, timer should be the default
        // This matches the behavior in NavGraph.produceState initialValue
        assertEquals(SettingsDataStore.TAB_TIMER, Screen.Timer.route)
    }
}
