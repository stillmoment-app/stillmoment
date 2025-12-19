//
//  TimerAction.swift
//  Still Moment
//
//  Domain Model - Timer Actions for Reducer Pattern
//

import Foundation

/// All possible actions that can be dispatched to the timer reducer
///
/// This enum defines the complete set of user interactions and system events
/// that can affect the timer state. The reducer processes these actions
/// to produce new state and effects.
enum TimerAction: Equatable {
    // MARK: - User Actions

    /// User selected a duration in minutes
    case selectDuration(minutes: Int)

    /// User pressed the start button
    case startPressed

    /// User pressed the pause button
    case pausePressed

    /// User pressed the resume button
    case resumePressed

    /// User pressed the reset button
    case resetPressed

    // MARK: - System Events

    /// Timer tick with updated values from TimerService
    case tick(remainingSeconds: Int, totalSeconds: Int, countdownSeconds: Int, progress: Double, state: TimerState)

    /// Countdown phase finished, transitioning to running
    case countdownFinished

    /// Timer completed (reached zero)
    case timerCompleted

    /// Interval gong should be played
    case intervalGongTriggered

    /// Mark that interval gong was played (prevents duplicate plays)
    case intervalGongPlayed
}
