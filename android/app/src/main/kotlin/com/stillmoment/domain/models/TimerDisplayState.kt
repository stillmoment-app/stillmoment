package com.stillmoment.domain.models

import java.util.Locale

/**
 * Complete UI state for the timer display.
 *
 * This data class contains all data needed to render the timer UI.
 * All computed properties are pure functions of the stored properties,
 * making this state fully testable without mocks.
 */
data class TimerDisplayState(
    /** Current timer state */
    val timerState: TimerState = TimerState.Idle,
    /** Selected duration in minutes (1-60) */
    val selectedMinutes: Int = MeditationSettings.DEFAULT_DURATION_MINUTES,
    /** Remaining time in seconds */
    val remainingSeconds: Int = 0,
    /** Total duration in seconds */
    val totalSeconds: Int = 0,
    /** Remaining preparation seconds (15, 14, 13... 0) */
    val remainingPreparationSeconds: Int = 0,
    /** Progress value (0.0 - 1.0) */
    val progress: Float = 0f,
    /** Current affirmation index (rotates between sessions) */
    val currentAffirmationIndex: Int = 0,
    /** Whether an interval gong was already played for current interval */
    val intervalGongPlayedForCurrentInterval: Boolean = false
) {
    // MARK: - Computed Properties (Pure, Testable)

    /** Whether currently in preparation phase */
    val isPreparation: Boolean
        get() = timerState == TimerState.Preparation

    /** Returns true if timer can be started */
    val canStart: Boolean
        get() = timerState == TimerState.Idle && selectedMinutes > 0

    /** Returns true if timer can be paused */
    val canPause: Boolean
        get() = timerState == TimerState.Running

    /** Returns true if timer can be resumed */
    val canResume: Boolean
        get() = timerState == TimerState.Paused

    /** Returns true if timer can be reset */
    val canReset: Boolean
        get() = timerState != TimerState.Idle

    /** Formatted time string (MM:SS or preparation seconds) */
    val formattedTime: String
        get() =
            if (isPreparation) {
                "$remainingPreparationSeconds"
            } else {
                val minutes = remainingSeconds / 60
                val seconds = remainingSeconds % 60
                String.format(Locale.ROOT, "%02d:%02d", minutes, seconds)
            }

    companion object {
        /** Initial state for a fresh timer */
        val Initial = TimerDisplayState()

        /**
         * Creates a state with custom selected minutes (for loading from settings).
         */
        fun withDuration(minutes: Int): TimerDisplayState {
            return Initial.copy(
                selectedMinutes = MeditationSettings.validateDuration(minutes)
            )
        }
    }
}
