//
//  TimerState.swift
//  Still Moment
//
//  Domain Model - Timer State
//

import Foundation

/// Represents the current state of the meditation timer
///
/// State machine: idle → preparation → startGong → [introduction →] running → completed
/// Preparation is optional. Introduction is optional, entered only when the introduction audio
/// actually starts (after the start gong finishes).
/// Each state has exactly one meaning. Each transition has exactly one trigger.
enum TimerState: Equatable {
    /// Timer is idle and ready to start
    case idle

    /// Timer is in preparation phase (configurable seconds before meditation starts)
    case preparation

    /// Start gong is playing. The meditation countdown is already running.
    case startGong

    /// Timer is playing the introduction audio (e.g., guided breathing exercise).
    /// The meditation countdown is running during this phase.
    /// Entered when the start gong finishes and an introduction is configured.
    /// Exited when the introduction audio finishes (event-driven, not countdown).
    case introduction

    /// Timer is in silent meditation phase (countdown running)
    case running

    /// Timer has completed the meditation
    case completed
}
