//
//  MeditationTimer.swift
//  MediTimer
//
//  Domain Model - Meditation Timer
//

import Foundation

/// Errors that can occur when creating a meditation timer
enum MeditationTimerError: Error, LocalizedError {
    case invalidDuration(Int)

    var errorDescription: String? {
        switch self {
        case .invalidDuration(let minutes):
            return "Invalid duration: \(minutes) minutes. Duration must be between 1 and 60 minutes."
        }
    }
}

/// Domain model representing a meditation timer session
struct MeditationTimer: Equatable {
    /// Duration of the timer in minutes (1-60)
    let durationMinutes: Int

    /// Remaining time in seconds
    let remainingSeconds: Int

    /// Current state of the timer
    let state: TimerState

    /// Initializes a new meditation timer
    /// - Parameter durationMinutes: Duration in minutes (1-60)
    /// - Throws: `MeditationTimerError.invalidDuration` if duration is not between 1 and 60 minutes
    init(durationMinutes: Int) throws {
        guard (1...60).contains(durationMinutes) else {
            throw MeditationTimerError.invalidDuration(durationMinutes)
        }
        self.durationMinutes = durationMinutes
        self.remainingSeconds = durationMinutes * 60
        self.state = .idle
    }

    /// Private initializer for internal state updates
    private init(durationMinutes: Int, remainingSeconds: Int, state: TimerState) {
        self.durationMinutes = durationMinutes
        self.remainingSeconds = remainingSeconds
        self.state = state
    }

    /// Returns total duration in seconds
    var totalSeconds: Int {
        durationMinutes * 60
    }

    /// Returns progress as a value between 0.0 and 1.0
    var progress: Double {
        guard totalSeconds > 0 else { return 0.0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }

    /// Checks if timer has completed
    var isCompleted: Bool {
        remainingSeconds <= 0
    }

    /// Returns a copy with updated remaining seconds
    func tick() -> MeditationTimer {
        let newRemaining = max(0, remainingSeconds - 1)
        let newState: TimerState = newRemaining <= 0 ? .completed : state
        return MeditationTimer(
            durationMinutes: durationMinutes,
            remainingSeconds: newRemaining,
            state: newState
        )
    }

    /// Returns a copy with updated state
    func withState(_ newState: TimerState) -> MeditationTimer {
        MeditationTimer(
            durationMinutes: durationMinutes,
            remainingSeconds: remainingSeconds,
            state: newState
        )
    }

    /// Returns a reset timer with original duration
    func reset() -> MeditationTimer {
        // Safe to use try! here as durationMinutes is already validated
        // swiftlint:disable:next force_try
        try! MeditationTimer(durationMinutes: durationMinutes)
    }
}
