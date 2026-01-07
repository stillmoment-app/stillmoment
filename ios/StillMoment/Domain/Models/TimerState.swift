//
//  TimerState.swift
//  Still Moment
//
//  Domain Model - Timer State
//

import Foundation

/// Represents the current state of the meditation timer
enum TimerState: Equatable {
    /// Timer is idle and ready to start
    case idle

    /// Timer is in preparation phase (configurable seconds before meditation starts)
    case preparation

    /// Timer is actively counting down
    case running

    /// Timer is paused and can be resumed
    case paused

    /// Timer has completed the meditation
    case completed
}
