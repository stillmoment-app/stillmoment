//
//  TimerDisplayState.swift
//  Still Moment
//
//  Domain Model - Timer Display State for Reducer Pattern
//

import Foundation

/// Complete UI state for the timer display
///
/// This struct contains all data needed to render the timer UI.
/// All computed properties are pure functions of the stored properties,
/// making this state fully testable without mocks.
struct TimerDisplayState: Equatable {
    // MARK: - Stored Properties

    /// Current timer state
    var timerState: TimerState

    /// Selected duration in minutes (1-60)
    var selectedMinutes: Int

    /// Remaining time in seconds
    var remainingSeconds: Int

    /// Total duration in seconds
    var totalSeconds: Int

    /// Countdown seconds (15, 14, 13... 0)
    var countdownSeconds: Int

    /// Progress value (0.0 - 1.0)
    var progress: Double

    /// Current affirmation index (rotates between sessions)
    var currentAffirmationIndex: Int

    /// Whether an interval gong was already played for current interval
    var intervalGongPlayedForCurrentInterval: Bool

    // MARK: - Computed Properties (Pure, Testable)

    /// Whether currently in countdown phase
    var isCountdown: Bool {
        self.timerState == .countdown
    }

    /// Returns true if timer can be started
    var canStart: Bool {
        self.timerState == .idle && self.selectedMinutes > 0
    }

    /// Returns true if timer can be paused
    var canPause: Bool {
        self.timerState == .running
    }

    /// Returns true if timer can be resumed
    var canResume: Bool {
        self.timerState == .paused
    }

    /// Formatted time string (MM:SS or countdown seconds)
    var formattedTime: String {
        if self.isCountdown {
            return "\(self.countdownSeconds)"
        }
        let minutes = self.remainingSeconds / 60
        let seconds = self.remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Static Factory

    /// Initial state for a fresh timer
    static let initial = TimerDisplayState(
        timerState: .idle,
        selectedMinutes: 10,
        remainingSeconds: 0,
        totalSeconds: 0,
        countdownSeconds: 0,
        progress: 0.0,
        currentAffirmationIndex: 0,
        intervalGongPlayedForCurrentInterval: false
    )

    /// Creates a state with custom selected minutes (for loading from settings)
    static func withDuration(minutes: Int) -> TimerDisplayState {
        var state = self.initial
        state.selectedMinutes = MeditationSettings.validateDuration(minutes)
        return state
    }
}
