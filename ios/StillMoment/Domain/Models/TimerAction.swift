//
//  TimerAction.swift
//  Still Moment
//
//  Domain Model - Timer Actions for Reducer Pattern
//

import Foundation

/// All possible actions that can be dispatched to the timer reducer
///
/// This enum defines the complete set of system events that can affect the timer.
/// The reducer processes these actions to produce effects to execute.
/// User actions (duration selection) are handled directly by the ViewModel.
enum TimerAction: Equatable {
    // MARK: - User Actions

    /// User pressed the start button
    case startPressed

    /// User pressed the reset button
    case resetPressed

    // MARK: - System Events

    /// Preparation phase finished, transitioning to start gong
    case preparationFinished

    /// Start gong finished playing, silent meditation phase can now begin
    case startGongFinished

    /// Timer reached zero, entering endGong phase
    case timerCompleted

    /// Completion gong finished playing (audio callback), transitioning to completed
    case endGongFinished

    /// Interval gong should be played (emitted by tick() via TimerEvent.intervalGongDue)
    case intervalGongTriggered
}
