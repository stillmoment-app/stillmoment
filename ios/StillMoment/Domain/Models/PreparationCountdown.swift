//
//  PreparationCountdown.swift
//  Still Moment
//
//  Domain Model - Preparation Countdown for Guided Meditations
//

import Foundation

/// Immutable Value Object representing a preparation countdown
///
/// Used before guided meditation playback to give the user time
/// to put down the phone and settle into position.
///
/// Pattern: Same as `MeditationTimer` - immutable with `tick()` returning new instance.
struct PreparationCountdown: Equatable {
    // MARK: - Properties

    /// Total countdown duration in seconds (configured value)
    let totalSeconds: Int

    /// Remaining seconds in the countdown
    let remainingSeconds: Int

    // MARK: - Initialization

    /// Creates a new countdown with the given duration
    ///
    /// - Parameter totalSeconds: Total countdown duration in seconds
    init(totalSeconds: Int) {
        self.totalSeconds = totalSeconds
        self.remainingSeconds = totalSeconds
    }

    /// Creates a countdown with explicit remaining seconds (for tick operations)
    ///
    /// - Parameters:
    ///   - totalSeconds: Total countdown duration in seconds
    ///   - remainingSeconds: Current remaining seconds
    init(totalSeconds: Int, remainingSeconds: Int) {
        self.totalSeconds = totalSeconds
        self.remainingSeconds = remainingSeconds
    }

    // MARK: - Computed Properties

    /// Whether the countdown has finished (remaining <= 0)
    var isFinished: Bool {
        self.remainingSeconds <= 0
    }

    /// Progress as a value between 0.0 (start) and 1.0 (finished)
    var progress: Double {
        guard self.totalSeconds > 0 else {
            return 0
        }
        return Double(self.totalSeconds - self.remainingSeconds) / Double(self.totalSeconds)
    }

    // MARK: - Methods

    /// Returns a new countdown with remaining seconds decremented by 1
    ///
    /// - Returns: New `PreparationCountdown` instance with updated state
    func tick() -> PreparationCountdown {
        PreparationCountdown(
            totalSeconds: self.totalSeconds,
            remainingSeconds: max(0, self.remainingSeconds - 1)
        )
    }
}
