//
//  IntervalSettings.swift
//  Still Moment
//
//  Domain Model - Interval Gong Settings for tick()
//

import Foundation

/// Configuration for interval gong detection during `MeditationTimer.tick()`.
///
/// Passed to `tick(intervalSettings:)` when interval gongs are enabled.
/// When `nil` is passed, no interval gong detection occurs.
struct IntervalSettings: Equatable {
    /// Interval in minutes between gongs (e.g., 5 for every 5 minutes)
    let intervalMinutes: Int

    /// The interval mode (repeating, afterStart, beforeEnd)
    let mode: IntervalMode
}
