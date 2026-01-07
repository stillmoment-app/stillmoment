package com.stillmoment.domain.models

/**
 * All possible actions that can be dispatched to the timer reducer.
 *
 * This sealed class defines the complete set of user interactions and system events
 * that can affect the timer state. The reducer processes these actions
 * to produce new state and effects.
 */
sealed class TimerAction {
    // MARK: - User Actions

    /** User selected a duration in minutes */
    data class SelectDuration(val minutes: Int) : TimerAction()

    /** User pressed the start button */
    data object StartPressed : TimerAction()

    /** User pressed the pause button */
    data object PausePressed : TimerAction()

    /** User pressed the resume button */
    data object ResumePressed : TimerAction()

    /** User pressed the reset button */
    data object ResetPressed : TimerAction()

    // MARK: - System Events

    /** Timer tick with updated values from TimerRepository */
    data class Tick(
        val remainingSeconds: Int,
        val totalSeconds: Int,
        val remainingPreparationSeconds: Int,
        val progress: Float,
        val state: TimerState
    ) : TimerAction()

    /** Preparation phase finished, transitioning to running */
    data object PreparationFinished : TimerAction()

    /** Timer completed (reached zero) */
    data object TimerCompleted : TimerAction()

    /** Interval gong should be played */
    data object IntervalGongTriggered : TimerAction()

    /** Mark that interval gong was played (prevents duplicate plays) */
    data object IntervalGongPlayed : TimerAction()
}
