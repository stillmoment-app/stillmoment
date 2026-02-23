package com.stillmoment.domain.services

import com.stillmoment.domain.models.Introduction
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
            is TimerAction.SelectDuration -> reduceSelectDuration(state, action.minutes, settings)
            is TimerAction.StartPressed -> reduceStartPressed(state, settings)
            is TimerAction.ResetPressed -> reduceResetPressed(state)
            is TimerAction.Tick -> reduceTick(state, action)
            is TimerAction.PreparationFinished -> reducePreparationFinished(state, settings)
            is TimerAction.StartGongFinished -> reduceStartGongFinished(state, settings)
            is TimerAction.IntroductionFinished -> reduceIntroductionFinished(state, settings)
            is TimerAction.TimerCompleted -> reduceTimerCompleted(state, settings)
            is TimerAction.EndGongFinished -> reduceEndGongFinished(state)
            is TimerAction.IntervalGongTriggered -> reduceIntervalGongTriggered(state, settings)
        }
    }

    // MARK: - Duration Actions

    private fun reduceSelectDuration(
        state: TimerDisplayState,
        minutes: Int,
        settings: MeditationSettings
    ): Pair<TimerDisplayState, List<TimerEffect>> {
        val newState =
            state.copy(
                selectedMinutes = MeditationSettings.validateDuration(minutes, settings.introductionId)
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

        // Determine introduction duration
        val introDuration = introductionDurationSeconds(settings)

        // If no preparation time, go directly to StartGong state (gong plays immediately)
        val initialState = if (preparationTime > 0) {
            TimerState.Preparation
        } else {
            TimerState.StartGong
        }

        // Initialize timer seconds immediately so UI shows correct time from the start
        val totalSeconds = state.selectedMinutes * 60

        val newState =
            state.copy(
                timerState = initialState,
                remainingSeconds = totalSeconds,
                totalSeconds = totalSeconds,
                remainingPreparationSeconds = preparationTime,
                currentAffirmationIndex = (state.currentAffirmationIndex + 1) % AFFIRMATION_COUNT
            )

        val updatedSettings =
            settings.copy(
                durationMinutes = state.selectedMinutes
            )

        // Background audio never starts here. It starts when the start gong finishes:
        // - Without introduction: in reduceStartGongFinished
        // - With introduction: in reduceIntroductionFinished
        // Always use "silent" for foreground service start — background audio is updated later
        val effects = mutableListOf(
            TimerEffect.StartForegroundService(
                "silent",
                settings.backgroundSoundVolume,
                settings.gongSoundId,
                settings.gongVolume
            ),
            TimerEffect.StartTimer(state.selectedMinutes, preparationTime, introDuration),
            TimerEffect.SaveSettings(updatedSettings)
        )

        // Note: start gong is played via PreparationCompleted event from start() when no preparation,
        // or via tick() → PreparationCompleted → PreparationFinished → reducePreparationFinished
        // when preparation is enabled. Never directly from startPressed.

        return newState to effects
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
                progress = 0f
            )

        val effects = mutableListOf<TimerEffect>()
        // Stop introduction if it was playing
        if (state.timerState == TimerState.Introduction) {
            effects.add(TimerEffect.StopIntroduction)
        }
        effects.add(TimerEffect.StopForegroundService)
        effects.add(TimerEffect.ResetTimer)

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

    private fun reducePreparationFinished(
        state: TimerDisplayState,
        settings: MeditationSettings
    ): Pair<TimerDisplayState, List<TimerEffect>> {
        val newState = state.copy(timerState = TimerState.StartGong)
        // Play start gong. Background audio decision is deferred to startGongFinished.
        return newState to listOf(TimerEffect.PlayStartGong(settings.gongSoundId, settings.gongVolume))
    }

    private fun reduceStartGongFinished(
        state: TimerDisplayState,
        settings: MeditationSettings
    ): Pair<TimerDisplayState, List<TimerEffect>> {
        if (state.timerState != TimerState.StartGong) {
            return state to emptyList()
        }

        val introId = settings.introductionId
        return if (introId != null && Introduction.isAvailableForCurrentLanguage(introId)) {
            // Introduction configured -> transition to Introduction, play audio
            // StartIntroductionPhase syncs the timer model state so ticks report Introduction
            val newState = state.copy(timerState = TimerState.Introduction)
            newState to listOf(TimerEffect.StartIntroductionPhase, TimerEffect.PlayIntroduction(introId))
        } else {
            // No introduction -> transition directly to Running with background audio
            val newState = state.copy(timerState = TimerState.Running)
            newState to listOf(
                TimerEffect.StartBackgroundAudio(settings.backgroundSoundId, settings.backgroundSoundVolume)
            )
        }
    }

    private fun reduceIntroductionFinished(
        state: TimerDisplayState,
        settings: MeditationSettings
    ): Pair<TimerDisplayState, List<TimerEffect>> {
        if (state.timerState != TimerState.Introduction) {
            return state to emptyList()
        }

        val newState = state.copy(timerState = TimerState.Running)
        val effects = listOf(
            TimerEffect.StopIntroduction,
            TimerEffect.EndIntroductionPhase,
            TimerEffect.StartBackgroundAudio(settings.backgroundSoundId, settings.backgroundSoundVolume)
        )

        return newState to effects
    }

    private fun reduceTimerCompleted(
        state: TimerDisplayState,
        settings: MeditationSettings
    ): Pair<TimerDisplayState, List<TimerEffect>> {
        val newState =
            state.copy(
                timerState = TimerState.EndGong,
                progress = 1.0f
            )

        val effects = mutableListOf<TimerEffect>(
            TimerEffect.PlayCompletionSound(settings.gongSoundId, settings.gongVolume)
        )
        // Stop introduction if it was still playing (timer expired during introduction)
        if (state.timerState == TimerState.Introduction) {
            effects.add(TimerEffect.StopIntroduction)
        }

        return newState to effects
    }

    private fun reduceEndGongFinished(state: TimerDisplayState): Pair<TimerDisplayState, List<TimerEffect>> {
        if (state.timerState != TimerState.EndGong) {
            return state to emptyList()
        }

        val newState = state.copy(timerState = TimerState.Completed)
        return newState to listOf(TimerEffect.StopForegroundService)
    }

    // MARK: - Interval Gong Actions

    private fun reduceIntervalGongTriggered(
        state: TimerDisplayState,
        settings: MeditationSettings
    ): Pair<TimerDisplayState, List<TimerEffect>> {
        if (!settings.intervalGongsEnabled) {
            return state to emptyList()
        }
        return state to listOf(
            TimerEffect.PlayIntervalGong(settings.intervalSoundId, settings.intervalGongVolume)
        )
    }

    // MARK: - Helpers

    /** Returns the introduction duration in seconds, or 0 if no introduction is configured. */
    private fun introductionDurationSeconds(settings: MeditationSettings): Int {
        val introId = settings.introductionId ?: return 0
        if (!Introduction.isAvailableForCurrentLanguage(introId)) return 0
        return Introduction.find(introId)?.durationSeconds ?: 0
    }
}
