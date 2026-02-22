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

    /// User pressed the reset button
    case resetPressed

    // MARK: - System Events

    /// Timer tick with updated values from TimerService
    case tick(
        remainingSeconds: Int,
        totalSeconds: Int,
        remainingPreparationSeconds: Int,
        progress: Double,
        state: TimerState
    )

    /// Preparation phase finished, transitioning to introduction or running
    case preparationFinished

    /// Start gong finished playing, introduction audio can now begin
    case startGongFinished

    /// Introduction audio finished, transitioning to silent meditation
    case introductionFinished

    /// Timer reached zero, entering endGong phase
    case timerCompleted

    /// Completion gong finished playing (audio callback), transitioning to completed
    case endGongFinished

    /// Interval gong should be played (emitted by tick() via TimerEvent.intervalGongDue)
    case intervalGongTriggered
}
