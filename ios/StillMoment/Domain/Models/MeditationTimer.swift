//
//  MeditationTimer.swift
//  Still Moment
//
//  Domain Model - Meditation Timer
//

import Foundation

/// Errors that can occur when creating a meditation timer
enum MeditationTimerError: Error, LocalizedError {
    case invalidDuration(Int)

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case let .invalidDuration(minutes):
            "Invalid duration: \(minutes) minutes. Duration must be between 1 and 60 minutes."
        }
    }
}

/// Domain model representing a meditation timer session
struct MeditationTimer: Equatable {
    // MARK: Lifecycle

    /// Initializes a new meditation timer
    /// - Parameters:
    ///   - durationMinutes: Duration in minutes (1-60)
    ///   - countdownDuration: Duration of countdown in seconds (default: 15). Use 0 to skip countdown.
    /// - Throws: `MeditationTimerError.invalidDuration` if duration is not between 1 and 60 minutes
    init(durationMinutes: Int, countdownDuration: Int = 15) throws {
        guard (1...60).contains(durationMinutes) else {
            throw MeditationTimerError.invalidDuration(durationMinutes)
        }
        self.durationMinutes = durationMinutes
        self.remainingSeconds = durationMinutes * 60
        self.state = .idle
        self.countdownSeconds = 0
        self.countdownDuration = countdownDuration
        self.lastIntervalGongAt = nil
    }

    /// Private initializer for internal state updates
    private init(
        durationMinutes: Int,
        remainingSeconds: Int,
        state: TimerState,
        countdownSeconds: Int = 0,
        countdownDuration: Int,
        lastIntervalGongAt: Int? = nil
    ) {
        self.durationMinutes = durationMinutes
        self.remainingSeconds = remainingSeconds
        self.state = state
        self.countdownSeconds = countdownSeconds
        self.countdownDuration = countdownDuration
        self.lastIntervalGongAt = lastIntervalGongAt
    }

    // MARK: Internal

    /// Duration of the timer in minutes (1-60)
    let durationMinutes: Int

    /// Remaining time in seconds
    let remainingSeconds: Int

    /// Current state of the timer
    let state: TimerState

    /// Countdown seconds (countdownDuration→0 before timer starts)
    let countdownSeconds: Int

    /// Duration of countdown in seconds (configured at initialization)
    let countdownDuration: Int

    /// Remaining seconds when last interval gong was played
    let lastIntervalGongAt: Int?

    /// Returns total duration in seconds
    var totalSeconds: Int {
        self.durationMinutes * 60
    }

    /// Returns progress as a value between 0.0 and 1.0
    var progress: Double {
        guard self.totalSeconds > 0 else {
            return 0.0
        }
        return 1.0 - (Double(self.remainingSeconds) / Double(self.totalSeconds))
    }

    /// Checks if timer has completed
    var isCompleted: Bool {
        self.remainingSeconds <= 0
    }

    /// Returns a copy with updated remaining seconds
    func tick() -> MeditationTimer {
        // Handle countdown phase
        if self.state == .countdown {
            let newCountdown = max(0, countdownSeconds - 1)
            let newState: TimerState = newCountdown <= 0 ? .running : .countdown
            return MeditationTimer(
                durationMinutes: self.durationMinutes,
                remainingSeconds: self.remainingSeconds,
                state: newState,
                countdownSeconds: newCountdown,
                countdownDuration: self.countdownDuration,
                lastIntervalGongAt: self.lastIntervalGongAt
            )
        }

        // Handle regular timer
        let newRemaining = max(0, remainingSeconds - 1)
        let newState: TimerState = newRemaining <= 0 ? .completed : self.state
        return MeditationTimer(
            durationMinutes: self.durationMinutes,
            remainingSeconds: newRemaining,
            state: newState,
            countdownSeconds: self.countdownSeconds,
            countdownDuration: self.countdownDuration,
            lastIntervalGongAt: self.lastIntervalGongAt
        )
    }

    /// Returns a copy with updated state
    func withState(_ newState: TimerState) -> MeditationTimer {
        MeditationTimer(
            durationMinutes: self.durationMinutes,
            remainingSeconds: self.remainingSeconds,
            state: newState,
            countdownSeconds: self.countdownSeconds,
            countdownDuration: self.countdownDuration,
            lastIntervalGongAt: self.lastIntervalGongAt
        )
    }

    /// Returns a copy ready for countdown (uses configured countdownDuration)
    func startCountdown() -> MeditationTimer {
        MeditationTimer(
            durationMinutes: self.durationMinutes,
            remainingSeconds: self.remainingSeconds,
            state: .countdown,
            countdownSeconds: self.countdownDuration,
            countdownDuration: self.countdownDuration,
            lastIntervalGongAt: nil
        )
    }

    /// Returns a copy with updated interval gong timestamp
    func markIntervalGongPlayed() -> MeditationTimer {
        MeditationTimer(
            durationMinutes: self.durationMinutes,
            remainingSeconds: self.remainingSeconds,
            state: self.state,
            countdownSeconds: self.countdownSeconds,
            countdownDuration: self.countdownDuration,
            lastIntervalGongAt: self.remainingSeconds
        )
    }

    /// Checks if an interval gong should be played
    /// - Parameter intervalMinutes: Interval in minutes (e.g., 5 for every 5 minutes)
    /// - Returns: True if enough time has passed since last interval gong
    func shouldPlayIntervalGong(intervalMinutes: Int) -> Bool {
        guard self.state == .running else {
            return false
        }
        guard intervalMinutes > 0 else {
            return false
        }

        let intervalSeconds = intervalMinutes * 60

        // Never played before - play if we've passed first interval
        guard let lastGongAt = lastIntervalGongAt else {
            let elapsed = self.totalSeconds - self.remainingSeconds
            return elapsed >= intervalSeconds && self.remainingSeconds > 0
        }

        // Check if enough time passed since last gong
        let timeSinceLastGong = lastGongAt - self.remainingSeconds
        return timeSinceLastGong >= intervalSeconds && self.remainingSeconds > 0
    }

    /// Returns a reset timer with original duration
    ///
    /// Uses the private initializer since durationMinutes is already validated
    func reset() -> MeditationTimer {
        MeditationTimer(
            durationMinutes: self.durationMinutes,
            remainingSeconds: self.durationMinutes * 60,
            state: .idle,
            countdownSeconds: 0,
            countdownDuration: self.countdownDuration,
            lastIntervalGongAt: nil
        )
    }
}
