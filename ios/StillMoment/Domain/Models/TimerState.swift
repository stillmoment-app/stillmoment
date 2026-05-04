//
//  TimerState.swift
//  Still Moment
//
//  Domain Model - Timer State
//

import Foundation

/// Represents the current state of the meditation timer
///
/// State machine: idle → preparation → startGong → running → endGong → completed
/// Preparation is optional.
/// Each state has exactly one meaning. Each transition has exactly one trigger.
enum TimerState: Equatable {
    /// Timer is idle and ready to start
    case idle

    /// Timer is in preparation phase (configurable seconds before meditation starts)
    case preparation

    /// Start gong is playing. The meditation countdown is already running.
    case startGong

    /// Timer is in silent meditation phase (countdown running)
    case running

    /// Completion gong is playing after timer reached zero.
    /// Timer shows 00:00, ring is full. Entered when timer reaches 0.
    /// Exited when the completion gong finishes (event-driven via audio callback).
    case endGong

    /// Timer has completed the meditation
    case completed
}
