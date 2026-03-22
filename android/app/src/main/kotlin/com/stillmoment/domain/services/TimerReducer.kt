package com.stillmoment.domain.services

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
     * @param attunementResolver Resolves attunement IDs (built-in and custom)
     * @return Effects to execute
     */
    fun reduce(
        action: TimerAction,
        timerState: TimerState,
        selectedMinutes: Int,
        settings: MeditationSettings,
        attunementResolver: AttunementResolverProtocol
    ): List<TimerEffect> {
        return when (action) {
            is TimerAction.StartPressed -> reduceStartPressed(selectedMinutes, settings, attunementResolver)
            is TimerAction.ResetPressed -> reduceResetPressed(timerState)
            is TimerAction.PreparationFinished -> reducePreparationFinished(settings)
            is TimerAction.StartGongFinished -> reduceStartGongFinished(timerState, settings, attunementResolver)
            is TimerAction.AttunementFinished -> reduceAttunementFinished(timerState, settings)
            is TimerAction.TimerCompleted -> reduceTimerCompleted(timerState, settings)
            is TimerAction.EndGongFinished -> reduceEndGongFinished(timerState)
            is TimerAction.IntervalGongTriggered -> reduceIntervalGongTriggered(settings)
        }
    }

    // MARK: - Control Actions

    private fun reduceStartPressed(
        selectedMinutes: Int,
        settings: MeditationSettings,
        attunementResolver: AttunementResolverProtocol
    ): List<TimerEffect> {
        if (selectedMinutes <= 0) {
            return emptyList()
        }

        // Determine attunement duration
        val attunementDuration = attunementDurationSeconds(settings, attunementResolver)

        // Determine preparation time: skip if disabled (0), otherwise use configured value
        val preparationTime = if (settings.preparationTimeEnabled) {
            settings.preparationTimeSeconds
        } else {
            0
        }

        val updatedSettings = settings.copy(durationMinutes = selectedMinutes)

        // Background audio never starts here. It starts when the start gong finishes:
        // - Without attunement: in reduceStartGongFinished
        // - With attunement: in reduceAttunementFinished
        // Always use "silent" for foreground service start - background audio is updated later
        return listOf(
            TimerEffect.StartForegroundService(
                "silent",
                settings.backgroundSoundVolume,
                settings.gongSoundId,
                settings.gongVolume
            ),
            TimerEffect.StartTimer(selectedMinutes, preparationTime, attunementDuration),
            TimerEffect.SaveSettings(updatedSettings)
        )
    }

    private fun reduceResetPressed(timerState: TimerState): List<TimerEffect> {
        if (timerState == TimerState.Idle) {
            return emptyList()
        }

        val effects = mutableListOf<TimerEffect>()
        // Stop attunement if it was playing
        if (timerState == TimerState.Attunement) {
            effects.add(TimerEffect.StopAttunement)
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

    private fun reduceStartGongFinished(
        timerState: TimerState,
        settings: MeditationSettings,
        attunementResolver: AttunementResolverProtocol
    ): List<TimerEffect> {
        if (timerState != TimerState.StartGong) {
            return emptyList()
        }

        val attunementId = settings.attunementId
        return if (settings.attunementEnabled && attunementId != null &&
            attunementResolver.resolve(attunementId) != null
        ) {
            // Attunement configured -> play audio
            listOf(TimerEffect.StartAttunementPhase, TimerEffect.PlayAttunement(attunementId))
        } else {
            // No attunement -> start background audio directly
            listOf(
                TimerEffect.TransitionToRunning,
                TimerEffect.StartBackgroundAudio(settings.backgroundSoundId, settings.backgroundSoundVolume)
            )
        }
    }

    private fun reduceAttunementFinished(timerState: TimerState, settings: MeditationSettings): List<TimerEffect> {
        if (timerState != TimerState.Attunement) {
            return emptyList()
        }

        return listOf(
            TimerEffect.StopAttunement,
            TimerEffect.EndAttunementPhase,
            TimerEffect.StartBackgroundAudio(settings.backgroundSoundId, settings.backgroundSoundVolume)
        )
    }

    private fun reduceTimerCompleted(timerState: TimerState, settings: MeditationSettings): List<TimerEffect> {
        val effects = mutableListOf<TimerEffect>(
            TimerEffect.PlayCompletionSound(settings.gongSoundId, settings.gongVolume)
        )
        // Stop attunement if it was still playing (timer expired during attunement)
        if (timerState == TimerState.Attunement) {
            effects.add(TimerEffect.StopAttunement)
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

    /** Returns the attunement duration in seconds, or 0 if no attunement is configured or disabled. */
    private fun attunementDurationSeconds(
        settings: MeditationSettings,
        attunementResolver: AttunementResolverProtocol
    ): Int {
        if (!settings.attunementEnabled) return 0
        val attunementId = settings.attunementId ?: return 0
        return attunementResolver.resolve(attunementId)?.durationSeconds ?: 0
    }
}
