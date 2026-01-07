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
    ///   - preparationTimeSeconds: Duration of preparation phase in seconds (default: 15). Use 0 to skip.
    /// - Throws: `MeditationTimerError.invalidDuration` if duration is not between 1 and 60 minutes
    init(durationMinutes: Int, preparationTimeSeconds: Int = 15) throws {
        guard (1...60).contains(durationMinutes) else {
            throw MeditationTimerError.invalidDuration(durationMinutes)
        }
        self.durationMinutes = durationMinutes
        self.remainingSeconds = durationMinutes * 60
        self.state = .idle
        self.remainingPreparationSeconds = 0
        self.preparationTimeSeconds = preparationTimeSeconds
        self.lastIntervalGongAt = nil
    }

    /// Private initializer for internal state updates
    private init(
        durationMinutes: Int,
        remainingSeconds: Int,
        state: TimerState,
        remainingPreparationSeconds: Int = 0,
        preparationTimeSeconds: Int,
        lastIntervalGongAt: Int? = nil
    ) {
        self.durationMinutes = durationMinutes
        self.remainingSeconds = remainingSeconds
        self.state = state
        self.remainingPreparationSeconds = remainingPreparationSeconds
        self.preparationTimeSeconds = preparationTimeSeconds
        self.lastIntervalGongAt = lastIntervalGongAt
    }

    // MARK: Internal

    /// Duration of the timer in minutes (1-60)
    let durationMinutes: Int

    /// Remaining time in seconds
    let remainingSeconds: Int

    /// Current state of the timer
    let state: TimerState

    /// Remaining preparation seconds (preparationTimeSeconds→0 before timer starts)
    let remainingPreparationSeconds: Int

    /// Duration of preparation phase in seconds (configured at initialization)
    let preparationTimeSeconds: Int

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
        // Handle preparation phase
        if self.state == .preparation {
            let newPreparation = max(0, remainingPreparationSeconds - 1)
            let newState: TimerState = newPreparation <= 0 ? .running : .preparation
            return MeditationTimer(
                durationMinutes: self.durationMinutes,
                remainingSeconds: self.remainingSeconds,
                state: newState,
                remainingPreparationSeconds: newPreparation,
                preparationTimeSeconds: self.preparationTimeSeconds,
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
            remainingPreparationSeconds: self.remainingPreparationSeconds,
            preparationTimeSeconds: self.preparationTimeSeconds,
            lastIntervalGongAt: self.lastIntervalGongAt
        )
    }

    /// Returns a copy with updated state
    func withState(_ newState: TimerState) -> MeditationTimer {
        MeditationTimer(
            durationMinutes: self.durationMinutes,
            remainingSeconds: self.remainingSeconds,
            state: newState,
            remainingPreparationSeconds: self.remainingPreparationSeconds,
            preparationTimeSeconds: self.preparationTimeSeconds,
            lastIntervalGongAt: self.lastIntervalGongAt
        )
    }

    /// Returns a copy ready for preparation phase (uses configured preparationTimeSeconds)
    func startPreparation() -> MeditationTimer {
        MeditationTimer(
            durationMinutes: self.durationMinutes,
            remainingSeconds: self.remainingSeconds,
            state: .preparation,
            remainingPreparationSeconds: self.preparationTimeSeconds,
            preparationTimeSeconds: self.preparationTimeSeconds,
            lastIntervalGongAt: nil
        )
    }

    /// Returns a copy with updated interval gong timestamp
    func markIntervalGongPlayed() -> MeditationTimer {
        MeditationTimer(
            durationMinutes: self.durationMinutes,
            remainingSeconds: self.remainingSeconds,
            state: self.state,
            remainingPreparationSeconds: self.remainingPreparationSeconds,
            preparationTimeSeconds: self.preparationTimeSeconds,
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
            remainingPreparationSeconds: 0,
            preparationTimeSeconds: self.preparationTimeSeconds,
            lastIntervalGongAt: nil
        )
    }
}
