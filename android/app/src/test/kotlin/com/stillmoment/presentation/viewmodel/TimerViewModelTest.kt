package com.stillmoment.presentation.viewmodel

import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.TimerDisplayState
import com.stillmoment.domain.models.TimerState
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Unit tests for TimerUiState.
 * Tests the pure data class logic without ViewModel dependencies.
 */
class TimerViewModelTest {
    // MARK: - TimerUiState Tests

    @Test
    fun `initial state has correct default values`() {
        val state = TimerUiState()

        assertEquals(TimerState.Idle, state.timerState)
        assertEquals(10, state.selectedMinutes)
        assertEquals(0, state.remainingSeconds)
        assertEquals(0f, state.progress)
        assertNull(state.errorMessage)
        assertFalse(state.showSettings)
        assertFalse(state.showSettingsHint)
    }

    @Test
    fun `default settings have correct values`() {
        val state = TimerUiState()
        val settings = state.settings

        assertFalse(settings.intervalGongsEnabled)
        assertEquals(5, settings.intervalMinutes)
        assertEquals("silent", settings.backgroundSoundId)
    }

    // MARK: - canStart Tests

    @Test
    fun `canStart returns true when idle with valid minutes`() {
        val state =
            TimerUiState(
                displayState = TimerDisplayState(
                    timerState = TimerState.Idle,
                    selectedMinutes = 10
                )
            )
        assertTrue(state.canStart)
    }

    @Test
    fun `canStart returns false when not idle`() {
        val runningState =
            TimerUiState(
                displayState = TimerDisplayState(
                    timerState = TimerState.Running,
                    selectedMinutes = 10
                )
            )
        assertFalse(runningState.canStart)

        val pausedState =
            TimerUiState(
                displayState = TimerDisplayState(
                    timerState = TimerState.Paused,
                    selectedMinutes = 10
                )
            )
        assertFalse(pausedState.canStart)
    }

    @Test
    fun `canStart returns false when minutes is zero`() {
        val state =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Idle, selectedMinutes = 0)
            )
        assertFalse(state.canStart)
    }

    // MARK: - canPause Tests

    @Test
    fun `canPause returns true only when running`() {
        val runningState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Running)
            )
        assertTrue(runningState.canPause)

        val idleState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Idle)
            )
        assertFalse(idleState.canPause)

        val pausedState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Paused)
            )
        assertFalse(pausedState.canPause)
    }

    // MARK: - canResume Tests

    @Test
    fun `canResume returns true only when paused`() {
        val pausedState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Paused)
            )
        assertTrue(pausedState.canResume)

        val runningState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Running)
            )
        assertFalse(runningState.canResume)

        val idleState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Idle)
            )
        assertFalse(idleState.canResume)
    }

    // MARK: - canReset Tests

    @Test
    fun `canReset returns true when not idle`() {
        val runningState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Running)
            )
        assertTrue(runningState.canReset)

        val pausedState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Paused)
            )
        assertTrue(pausedState.canReset)

        val completedState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Completed)
            )
        assertTrue(completedState.canReset)
    }

    @Test
    fun `canReset returns false when idle`() {
        val idleState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Idle)
            )
        assertFalse(idleState.canReset)
    }

    // MARK: - isPreparation Tests

    @Test
    fun `isPreparation returns correct value based on state`() {
        val idleState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Idle)
            )
        assertFalse(idleState.isPreparation)

        val countdownState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Preparation)
            )
        assertTrue(countdownState.isPreparation)

        val runningState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Running)
            )
        assertFalse(runningState.isPreparation)

        val pausedState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Paused)
            )
        assertFalse(pausedState.isPreparation)

        val completedState =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Completed)
            )
        assertFalse(completedState.isPreparation)
    }

    // MARK: - formattedTime Tests

    @Test
    fun `formattedTime shows countdown seconds during countdown state`() {
        val state =
            TimerUiState(
                displayState =
                TimerDisplayState(
                    timerState = TimerState.Preparation,
                    remainingPreparationSeconds = 15
                )
            )
        assertEquals("15", state.formattedTime)
    }

    @Test
    fun `formattedTime shows MM SS format when running`() {
        val state =
            TimerUiState(
                displayState =
                TimerDisplayState(
                    timerState = TimerState.Running,
                    remainingSeconds = 305 // 5:05
                )
            )
        assertEquals("05:05", state.formattedTime)
    }

    @Test
    fun `formattedTime handles zero remaining seconds`() {
        val state =
            TimerUiState(
                displayState =
                TimerDisplayState(
                    timerState = TimerState.Running,
                    remainingSeconds = 0
                )
            )
        assertEquals("00:00", state.formattedTime)
    }

    @Test
    fun `formattedTime formats full hour correctly`() {
        val state =
            TimerUiState(
                displayState =
                TimerDisplayState(
                    timerState = TimerState.Running,
                    remainingSeconds = 3600 // 60:00
                )
            )
        assertEquals("60:00", state.formattedTime)
    }

    @Test
    fun `formattedTime handles single digit countdown`() {
        val state =
            TimerUiState(
                displayState =
                TimerDisplayState(
                    timerState = TimerState.Preparation,
                    remainingPreparationSeconds = 5
                )
            )
        assertEquals("5", state.formattedTime)
    }

    // MARK: - Settings Integration Tests

    @Test
    fun `state with custom settings preserves values`() {
        val customSettings =
            MeditationSettings(
                intervalGongsEnabled = true,
                intervalMinutes = 10,
                backgroundSoundId = "forest",
                durationMinutes = 20
            )

        val state = TimerUiState(settings = customSettings)

        assertTrue(state.settings.intervalGongsEnabled)
        assertEquals(10, state.settings.intervalMinutes)
        assertEquals("forest", state.settings.backgroundSoundId)
        assertEquals(20, state.settings.durationMinutes)
    }

    // MARK: - State Copy Tests

    @Test
    fun `copy preserves unchanged values`() {
        val original =
            TimerUiState(
                displayState =
                TimerDisplayState(
                    timerState = TimerState.Running,
                    selectedMinutes = 15,
                    remainingSeconds = 500,
                    progress = 0.5f
                )
            )

        val updated =
            original.copy(
                displayState = original.displayState.copy(progress = 0.6f)
            )

        assertEquals(TimerState.Running, updated.timerState)
        assertEquals(15, updated.selectedMinutes)
        assertEquals(500, updated.remainingSeconds)
        assertEquals(0.6f, updated.progress)
    }

    @Test
    fun `copy with new state updates derived properties`() {
        val idle =
            TimerUiState(
                displayState = TimerDisplayState(timerState = TimerState.Idle)
            )
        assertTrue(idle.canStart)
        assertFalse(idle.canPause)

        val running =
            idle.copy(
                displayState = idle.displayState.copy(timerState = TimerState.Running)
            )
        assertFalse(running.canStart)
        assertTrue(running.canPause)
    }

    // MARK: - Settings Hint Tests

    @Test
    fun `showSettingsHint default is false`() {
        val state = TimerUiState()
        assertFalse(state.showSettingsHint)
    }

    @Test
    fun `showSettingsHint can be set to true`() {
        val state = TimerUiState(showSettingsHint = true)
        assertTrue(state.showSettingsHint)
    }

    @Test
    fun `showSettingsHint can be toggled via copy`() {
        val initial = TimerUiState(showSettingsHint = true)
        assertTrue(initial.showSettingsHint)

        val dismissed = initial.copy(showSettingsHint = false)
        assertFalse(dismissed.showSettingsHint)
    }

    @Test
    fun `showSettingsHint is independent of showSettings`() {
        // Hint visible, settings closed
        val hintVisible = TimerUiState(showSettingsHint = true, showSettings = false)
        assertTrue(hintVisible.showSettingsHint)
        assertFalse(hintVisible.showSettings)

        // Both can be false
        val bothHidden = TimerUiState(showSettingsHint = false, showSettings = false)
        assertFalse(bothHidden.showSettingsHint)
        assertFalse(bothHidden.showSettings)

        // Settings open, hint hidden (typical after user taps settings)
        val settingsOpen = TimerUiState(showSettingsHint = false, showSettings = true)
        assertFalse(settingsOpen.showSettingsHint)
        assertTrue(settingsOpen.showSettings)
    }
}
