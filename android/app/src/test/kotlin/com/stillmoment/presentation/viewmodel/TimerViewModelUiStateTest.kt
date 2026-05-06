package com.stillmoment.presentation.viewmodel

import com.stillmoment.domain.models.MeditationPhase
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

    // MARK: - phase Tests

    @Test
    fun `phase returns PreRoll during Preparation`() {
        val state = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 600,
                state = TimerState.Preparation,
                remainingPreparationSeconds = 7
            )
        )
        assertEquals(MeditationPhase.PreRoll, state.phase)
    }

    @Test
    fun `phase returns Playing during StartGong`() {
        val state = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 600,
                state = TimerState.StartGong
            )
        )
        assertEquals(MeditationPhase.Playing, state.phase)
    }

    @Test
    fun `phase returns Playing during Running`() {
        val state = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 305,
                state = TimerState.Running
            )
        )
        assertEquals(MeditationPhase.Playing, state.phase)
    }

    @Test
    fun `phase returns Playing during EndGong`() {
        val state = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 0,
                state = TimerState.EndGong
            )
        )
        assertEquals(MeditationPhase.Playing, state.phase)
    }

    @Test
    fun `phase returns Playing when idle`() {
        val state = TimerUiState(timer = null)
        assertEquals(MeditationPhase.Playing, state.phase)
    }

    // MARK: - formattedRemainingMinutes Tests

    @Test
    fun `formattedRemainingMinutes formats mm-ss without leading zero on minutes`() {
        val state = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 512, // 8:32
                state = TimerState.Running
            )
        )
        assertEquals("8:32", state.formattedRemainingMinutes)
    }

    @Test
    fun `formattedRemainingMinutes formats less than one minute`() {
        val state = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 45,
                state = TimerState.Running
            )
        )
        assertEquals("0:45", state.formattedRemainingMinutes)
    }

    @Test
    fun `formattedRemainingMinutes handles zero seconds`() {
        val state = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 10,
                remainingSeconds = 0,
                state = TimerState.Running
            )
        )
        assertEquals("0:00", state.formattedRemainingMinutes)
    }

    @Test
    fun `formattedRemainingMinutes pads seconds with leading zero`() {
        val state = TimerUiState(
            timer = MeditationTimer(
                durationMinutes = 5,
                remainingSeconds = 65, // 1:05
                state = TimerState.Running
            )
        )
        assertEquals("1:05", state.formattedRemainingMinutes)
    }

    @Test
    fun `formattedRemainingMinutes uses selectedMinutes when no timer`() {
        val state = TimerUiState(timer = null, selectedMinutes = 10)
        assertEquals("10:00", state.formattedRemainingMinutes)
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
}
