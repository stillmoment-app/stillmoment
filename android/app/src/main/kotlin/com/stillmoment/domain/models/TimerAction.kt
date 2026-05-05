package com.stillmoment.domain.models

/**
 * All possible actions that can be dispatched to the timer reducer.
 *
 * This sealed class defines the complete set of user interactions and system events
 * that can affect the timer state. The reducer processes these actions
 * to produce effects.
 */
sealed class TimerAction {
    // MARK: - User Actions

    /** User pressed the start button */
    data object StartPressed : TimerAction()

    /** User pressed the reset button */
    data object ResetPressed : TimerAction()

    // MARK: - System Events

    /** Preparation phase finished, transitioning to start gong */
    data object PreparationFinished : TimerAction()

    /** Start gong audio finished playing */
    data object StartGongFinished : TimerAction()

    /** Timer completed (reached zero), entering endGong phase */
    data object TimerCompleted : TimerAction()

    /** Completion gong finished playing (audio callback), transitioning to completed */
    data object EndGongFinished : TimerAction()

    /** Interval gong should be played (emitted by tick() via TimerEvent.IntervalGongDue) */
    data object IntervalGongTriggered : TimerAction()
}
