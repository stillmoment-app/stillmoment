package com.stillmoment.domain.services

import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.TimerAction
import com.stillmoment.domain.models.TimerDisplayState
import com.stillmoment.domain.models.TimerEffect
import com.stillmoment.domain.models.TimerState

/**
 * Pure reducer for timer state management.
 *
 * This object contains a single pure function that takes the current state
 * and an action, and returns the new state along with any effects to execute.
 * The reducer contains no side effects - all I/O is represented as effects.
 */
object TimerReducer {
    private const val AFFIRMATION_COUNT = 5

    /**
     * Reduces the current state with an action to produce new state and effects.
     *
     * @param state Current timer display state
     * @param action Action to process
     * @param settings Current meditation settings (for effect parameters)
     * @return Pair of (new state, effects to execute)
     */
    fun reduce(
        state: TimerDisplayState,
        action: TimerAction,
        settings: MeditationSettings
    ): Pair<TimerDisplayState, List<TimerEffect>> {
        return when (action) {
            is TimerAction.SelectDuration -> reduceSelectDuration(state, action.minutes)
            is TimerAction.StartPressed -> reduceStartPressed(state, settings)
            is TimerAction.PausePressed -> reducePausePressed(state)
            is TimerAction.ResumePressed -> reduceResumePressed(state)
            is TimerAction.ResetPressed -> reduceResetPressed(state)
            is TimerAction.Tick -> reduceTick(state, action)
            is TimerAction.PreparationFinished -> reducePreparationFinished(state)
            is TimerAction.TimerCompleted -> reduceTimerCompleted(state)
            is TimerAction.IntervalGongTriggered -> reduceIntervalGongTriggered(state, settings)
            is TimerAction.IntervalGongPlayed -> reduceIntervalGongPlayed(state)
        }
    }

    // MARK: - Duration Actions

    private fun reduceSelectDuration(
        state: TimerDisplayState,
        minutes: Int
    ): Pair<TimerDisplayState, List<TimerEffect>> {
        val newState =
            state.copy(
                selectedMinutes = MeditationSettings.validateDuration(minutes)
            )
        return newState to emptyList()
    }

    // MARK: - Control Actions

    private fun reduceStartPressed(
        state: TimerDisplayState,
        settings: MeditationSettings
    ): Pair<TimerDisplayState, List<TimerEffect>> {
        if (state.selectedMinutes <= 0) {
            return state to emptyList()
        }

        // Determine preparation time: skip if disabled (0), otherwise use configured value
        val preparationTime = if (settings.preparationTimeEnabled) {
            settings.preparationTimeSeconds
        } else {
            0
        }

        // If no preparation time, go directly to Running state
        val initialState = if (preparationTime > 0) {
            TimerState.Preparation
        } else {
            TimerState.Running
        }

        val newState =
            state.copy(
                timerState = initialState,
                remainingPreparationSeconds = preparationTime,
                currentAffirmationIndex = (state.currentAffirmationIndex + 1) % AFFIRMATION_COUNT,
                intervalGongPlayedForCurrentInterval = false
            )

        val updatedSettings =
            settings.copy(
                durationMinutes = state.selectedMinutes
            )

        // Build effects - add start gong immediately if no preparation time
        val effects = mutableListOf(
            TimerEffect.StartForegroundService(settings.backgroundSoundId),
            TimerEffect.StartTimer(state.selectedMinutes, preparationTime),
            TimerEffect.SaveSettings(updatedSettings)
        )

        // Play start gong immediately if skipping preparation
        if (preparationTime <= 0) {
            effects.add(TimerEffect.PlayStartGong)
        }

        return newState to effects
    }

    private fun reducePausePressed(state: TimerDisplayState): Pair<TimerDisplayState, List<TimerEffect>> {
        if (state.timerState != TimerState.Running) {
            return state to emptyList()
        }
        val newState = state.copy(timerState = TimerState.Paused)
        return newState to listOf(TimerEffect.PauseBackgroundAudio, TimerEffect.PauseTimer)
    }

    private fun reduceResumePressed(state: TimerDisplayState): Pair<TimerDisplayState, List<TimerEffect>> {
        if (state.timerState != TimerState.Paused) {
            return state to emptyList()
        }
        val newState = state.copy(timerState = TimerState.Running)
        return newState to listOf(TimerEffect.ResumeBackgroundAudio, TimerEffect.ResumeTimer)
    }

    private fun reduceResetPressed(state: TimerDisplayState): Pair<TimerDisplayState, List<TimerEffect>> {
        if (state.timerState == TimerState.Idle) {
            return state to emptyList()
        }

        val newState =
            state.copy(
                timerState = TimerState.Idle,
                remainingSeconds = 0,
                totalSeconds = 0,
                remainingPreparationSeconds = 0,
                progress = 0f,
                intervalGongPlayedForCurrentInterval = false
            )

        val effects =
            listOf(
                TimerEffect.StopForegroundService,
                TimerEffect.ResetTimer
            )

        return newState to effects
    }

    // MARK: - Timer Update Actions

    private fun reduceTick(
        state: TimerDisplayState,
        action: TimerAction.Tick
    ): Pair<TimerDisplayState, List<TimerEffect>> {
        val newState =
            state.copy(
                remainingSeconds = action.remainingSeconds,
                totalSeconds = action.totalSeconds,
                remainingPreparationSeconds = action.remainingPreparationSeconds,
                progress = action.progress,
                timerState = action.state
            )
        return newState to emptyList()
    }

    private fun reducePreparationFinished(state: TimerDisplayState): Pair<TimerDisplayState, List<TimerEffect>> {
        val newState = state.copy(timerState = TimerState.Running)
        return newState to listOf(TimerEffect.PlayStartGong)
    }

    private fun reduceTimerCompleted(state: TimerDisplayState): Pair<TimerDisplayState, List<TimerEffect>> {
        val newState =
            state.copy(
                timerState = TimerState.Completed,
                progress = 1.0f
            )
        val effects =
            listOf(
                TimerEffect.PlayCompletionSound,
                TimerEffect.StopForegroundService
            )
        return newState to effects
    }

    // MARK: - Interval Gong Actions

    private fun reduceIntervalGongTriggered(
        state: TimerDisplayState,
        settings: MeditationSettings
    ): Pair<TimerDisplayState, List<TimerEffect>> {
        if (!settings.intervalGongsEnabled || state.intervalGongPlayedForCurrentInterval) {
            return state to emptyList()
        }
        val newState = state.copy(intervalGongPlayedForCurrentInterval = true)
        return newState to listOf(TimerEffect.PlayIntervalGong)
    }

    private fun reduceIntervalGongPlayed(state: TimerDisplayState): Pair<TimerDisplayState, List<TimerEffect>> {
        val newState = state.copy(intervalGongPlayedForCurrentInterval = false)
        return newState to emptyList()
    }
}
