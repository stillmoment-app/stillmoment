package com.stillmoment.presentation.viewmodel

import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.TimerState
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Unit tests for TimerUiState pure data class logic.
 * Tests default values, computed properties, copy behavior, and timer state properties.
 */
class TimerViewModelUiStateTest {

    // MARK: - Initial State Tests

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
        val state = TimerUiState(timer = null, selectedMinutes = 10)
        assertTrue(state.canStart)
    }

    @Test
    fun `canStart returns false when not idle`() {
        val state = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 600,
                state = TimerState.Running
            )
        )
        assertFalse(state.canStart)
    }

    @Test
    fun `canStart returns false when minutes is zero`() {
        val state = TimerUiState(timer = null, selectedMinutes = 0)
        assertFalse(state.canStart)
    }

    // MARK: - canReset Tests

    @Test
    fun `canReset returns true when not idle`() {
        val runningState = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 600,
                state = TimerState.Running
            )
        )
        assertTrue(runningState.canReset)

        val completedState = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 0,
                state = TimerState.Completed
            )
        )
        assertTrue(completedState.canReset)
    }

    @Test
    fun `canReset returns false when idle`() {
        val idleState = TimerUiState(timer = null)
        assertFalse(idleState.canReset)
    }

    // MARK: - isPreparation Tests

    @Test
    fun `isPreparation returns correct value based on state`() {
        val idleState = TimerUiState(timer = null)
        assertFalse(idleState.isPreparation)

        val countdownState = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 600,
                state = TimerState.Preparation,
                remainingPreparationSeconds = 15
            )
        )
        assertTrue(countdownState.isPreparation)

        val runningState = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 600,
                state = TimerState.Running
            )
        )
        assertFalse(runningState.isPreparation)

        val completedState = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 0,
                state = TimerState.Completed
            )
        )
        assertFalse(completedState.isPreparation)
    }

    // MARK: - isActive Tests (via timer property)

    @Test
    fun `isActive is true during preparation`() {
        val timer = MeditationTimer(
            durationMinutes = 10,
            remainingSeconds = 600,
            state = TimerState.Preparation,
            remainingPreparationSeconds = 15
        )
        assertTrue(timer.isActive)
    }

    @Test
    fun `isActive is true during running`() {
        val timer = MeditationTimer(
            durationMinutes = 10,
            remainingSeconds = 600,
            state = TimerState.Running
        )
        assertTrue(timer.isActive)
    }

    @Test
    fun `isActive is true during endGong`() {
        val timer = MeditationTimer(
            durationMinutes = 10,
            remainingSeconds = 0,
            state = TimerState.EndGong
        )
        assertTrue(timer.isActive)
    }

    @Test
    fun `isActive is false when idle`() {
        val timer = MeditationTimer(
            durationMinutes = 10,
            remainingSeconds = 600,
            state = TimerState.Idle
        )
        assertFalse(timer.isActive)
    }

    @Test
    fun `isActive is false when completed`() {
        val timer = MeditationTimer(
            durationMinutes = 10,
            remainingSeconds = 0,
            state = TimerState.Completed
        )
        assertFalse(timer.isActive)
    }

    // MARK: - formattedTime Tests

    @Test
    fun `formattedTime shows countdown seconds during countdown state`() {
        val state = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 600,
                state = TimerState.Preparation,
                remainingPreparationSeconds = 15
            )
        )
        assertEquals("15", state.formattedTime)
    }

    @Test
    fun `formattedTime shows MM SS format when running`() {
        val state = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 305, // 5:05
                state = TimerState.Running
            )
        )
        assertEquals("05:05", state.formattedTime)
    }

    @Test
    fun `formattedTime handles zero remaining seconds`() {
        val state = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 0,
                state = TimerState.Running
            )
        )
        assertEquals("00:00", state.formattedTime)
    }

    @Test
    fun `formattedTime formats full hour correctly`() {
        val state = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 60,
                remainingSeconds = 3600, // 60:00
                state = TimerState.Running
            )
        )
        assertEquals("60:00", state.formattedTime)
    }

    @Test
    fun `formattedTime handles single digit countdown`() {
        val state = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 600,
                state = TimerState.Preparation,
                remainingPreparationSeconds = 5
            )
        )
        assertEquals("5", state.formattedTime)
    }

    @Test
    fun `formattedTime shows default time when no timer`() {
        val state = TimerUiState(timer = null, selectedMinutes = 10)
        assertEquals("10:00", state.formattedTime)
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
        val timer = MeditationTimer(
            durationMinutes = 15,
            remainingSeconds = 500,
            state = TimerState.Running
        )
        val original = TimerUiState(timer = timer, selectedMinutes = 15)

        val updatedTimer = MeditationTimer(
            durationMinutes = 15,
            remainingSeconds = 499,
            state = TimerState.Running
        )
        val updated = original.copy(timer = updatedTimer)

        assertEquals(TimerState.Running, updated.timerState)
        assertEquals(15, updated.selectedMinutes)
        assertEquals(499, updated.remainingSeconds)
    }

    @Test
    fun `copy with new state updates derived properties`() {
        val idle = TimerUiState(timer = null, selectedMinutes = 10)
        assertTrue(idle.canStart)
        assertFalse(idle.canReset)

        val running = idle.copy(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 600,
                state = TimerState.Running
            )
        )
        assertFalse(running.canStart)
        assertTrue(running.canReset)
    }

    // MARK: - Settings Hint Pure Data Tests

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
