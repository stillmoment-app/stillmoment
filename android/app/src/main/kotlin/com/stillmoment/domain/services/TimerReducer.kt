package com.stillmoment.domain.services

import com.stillmoment.domain.models.Introduction
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.TimerAction
import com.stillmoment.domain.models.TimerEffect
import com.stillmoment.domain.models.TimerState

/**
 * Pure effect mapper for timer actions.
 *
 * Maps actions to effects based on the current timer state and settings.
 * Contains no side effects and no state mutations - all I/O is represented as effects.
 * State is managed directly by the ViewModel via MeditationTimer.
 */
object TimerReducer {
    /**
     * Maps an action to effects based on current timer state and settings.
     *
     * @param action Action to process
     * @param timerState Current timer state (.Idle when no timer exists)
     * @param selectedMinutes Currently selected duration in minutes
     * @param settings Current meditation settings (for effect parameters)
     * @return Effects to execute
     */
    fun reduce(
        action: TimerAction,
        timerState: TimerState,
        selectedMinutes: Int,
        settings: MeditationSettings
    ): List<TimerEffect> {
        return when (action) {
            is TimerAction.StartPressed -> reduceStartPressed(selectedMinutes, settings)
            is TimerAction.ResetPressed -> reduceResetPressed(timerState)
            is TimerAction.PreparationFinished -> reducePreparationFinished(settings)
            is TimerAction.StartGongFinished -> reduceStartGongFinished(timerState, settings)
            is TimerAction.IntroductionFinished -> reduceIntroductionFinished(timerState, settings)
            is TimerAction.TimerCompleted -> reduceTimerCompleted(timerState, settings)
            is TimerAction.EndGongFinished -> reduceEndGongFinished(timerState)
            is TimerAction.IntervalGongTriggered -> reduceIntervalGongTriggered(settings)
        }
    }

    // MARK: - Control Actions

    private fun reduceStartPressed(selectedMinutes: Int, settings: MeditationSettings): List<TimerEffect> {
        if (selectedMinutes <= 0) {
            return emptyList()
        }

        // Determine introduction duration
        val introDuration = introductionDurationSeconds(settings)

        // Determine preparation time: skip if disabled (0), otherwise use configured value
        val preparationTime = if (settings.preparationTimeEnabled) {
            settings.preparationTimeSeconds
        } else {
            0
        }

        val updatedSettings = settings.copy(durationMinutes = selectedMinutes)

        // Background audio never starts here. It starts when the start gong finishes:
        // - Without introduction: in reduceStartGongFinished
        // - With introduction: in reduceIntroductionFinished
        // Always use "silent" for foreground service start - background audio is updated later
        return listOf(
            TimerEffect.StartForegroundService(
                "silent",
                settings.backgroundSoundVolume,
                settings.gongSoundId,
                settings.gongVolume
            ),
            TimerEffect.StartTimer(selectedMinutes, preparationTime, introDuration),
            TimerEffect.SaveSettings(updatedSettings)
        )
    }

    private fun reduceResetPressed(timerState: TimerState): List<TimerEffect> {
        if (timerState == TimerState.Idle) {
            return emptyList()
        }

        val effects = mutableListOf<TimerEffect>()
        // Stop introduction if it was playing
        if (timerState == TimerState.Introduction) {
            effects.add(TimerEffect.StopIntroduction)
        }
        effects.add(TimerEffect.StopForegroundService)
        effects.add(TimerEffect.ResetTimer)

        return effects
    }

    // MARK: - Timer Update Actions

    private fun reducePreparationFinished(settings: MeditationSettings): List<TimerEffect> {
        // Play start gong. Background audio decision is deferred to startGongFinished.
        return listOf(TimerEffect.PlayStartGong(settings.gongSoundId, settings.gongVolume))
    }

    private fun reduceStartGongFinished(timerState: TimerState, settings: MeditationSettings): List<TimerEffect> {
        if (timerState != TimerState.StartGong) {
            return emptyList()
        }

        val introId = settings.introductionId
        return if (introId != null && Introduction.isAvailableForCurrentLanguage(introId)) {
            // Introduction configured -> play audio
            listOf(TimerEffect.StartIntroductionPhase, TimerEffect.PlayIntroduction(introId))
        } else {
            // No introduction -> start background audio directly
            listOf(
                TimerEffect.TransitionToRunning,
                TimerEffect.StartBackgroundAudio(settings.backgroundSoundId, settings.backgroundSoundVolume)
            )
        }
    }

    private fun reduceIntroductionFinished(timerState: TimerState, settings: MeditationSettings): List<TimerEffect> {
        if (timerState != TimerState.Introduction) {
            return emptyList()
        }

        return listOf(
            TimerEffect.StopIntroduction,
            TimerEffect.EndIntroductionPhase,
            TimerEffect.StartBackgroundAudio(settings.backgroundSoundId, settings.backgroundSoundVolume)
        )
    }

    private fun reduceTimerCompleted(timerState: TimerState, settings: MeditationSettings): List<TimerEffect> {
        val effects = mutableListOf<TimerEffect>(
            TimerEffect.PlayCompletionSound(settings.gongSoundId, settings.gongVolume)
        )
        // Stop introduction if it was still playing (timer expired during introduction)
        if (timerState == TimerState.Introduction) {
            effects.add(TimerEffect.StopIntroduction)
        }

        return effects
    }

    private fun reduceEndGongFinished(timerState: TimerState): List<TimerEffect> {
        if (timerState != TimerState.EndGong) {
            return emptyList()
        }

        return listOf(TimerEffect.TransitionToCompleted, TimerEffect.StopForegroundService)
    }

    // MARK: - Interval Gong Actions

    private fun reduceIntervalGongTriggered(settings: MeditationSettings): List<TimerEffect> {
        if (!settings.intervalGongsEnabled) {
            return emptyList()
        }
        return listOf(
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
