package com.stillmoment.domain.models

/**
 * Represents the current state of the meditation timer.
 *
 * This is a sealed class representing all possible timer states,
 * equivalent to the Swift enum TimerState.
 */
sealed class TimerState {
    /** Timer is idle and ready to start */
    data object Idle : TimerState()

    /** Timer is in countdown phase (15 seconds before start) */
    data object Countdown : TimerState()

    /** Timer is actively counting down */
    data object Running : TimerState()

    /** Timer is paused and can be resumed */
    data object Paused : TimerState()

    /** Timer has completed the countdown */
    data object Completed : TimerState()
}
