//
//  TimerReducer.swift
//  Still Moment
//
//  Domain Service - Pure Reducer for Timer State
//

import Foundation

/// Pure reducer for timer state management
///
/// This struct contains a single pure function that takes the current state
/// and an action, and returns the new state along with any effects to execute.
/// The reducer contains no side effects - all I/O is represented as effects.
enum TimerReducer {
    /// Reduces the current state with an action to produce new state and effects
    ///
    /// - Parameters:
    ///   - state: Current timer display state
    ///   - action: Action to process
    ///   - settings: Current meditation settings (for effect parameters)
    /// - Returns: Tuple of (new state, effects to execute)
    static func reduce(
        state: TimerDisplayState,
        action: TimerAction,
        settings: MeditationSettings
    ) -> (TimerDisplayState, [TimerEffect]) {
        switch action {
        case let .selectDuration(minutes):
            return self.reduceSelectDuration(state: state, minutes: minutes)
        case .startPressed:
            return self.reduceStartPressed(state: state, settings: settings)
        case .pausePressed:
            return self.reducePausePressed(state: state)
        case .resumePressed:
            return self.reduceResumePressed(state: state)
        case .resetPressed:
            return self.reduceResetPressed(state: state)
        case let .tick(remainingSeconds, totalSeconds, countdownSeconds, progress, timerState):
            var newState = state
            newState.remainingSeconds = remainingSeconds
            newState.totalSeconds = totalSeconds
            newState.countdownSeconds = countdownSeconds
            newState.progress = progress
            newState.timerState = timerState
            return (newState, [])
        case .countdownFinished:
            return self.reduceCountdownFinished(state: state)
        case .timerCompleted:
            return self.reduceTimerCompleted(state: state)
        case .intervalGongTriggered:
            return self.reduceIntervalGongTriggered(state: state, settings: settings)
        case .intervalGongPlayed:
            return self.reduceIntervalGongPlayed(state: state)
        }
    }

    // MARK: - Duration Actions

    private static func reduceSelectDuration(
        state: TimerDisplayState,
        minutes: Int
    ) -> (TimerDisplayState, [TimerEffect]) {
        var newState = state
        newState.selectedMinutes = MeditationSettings.validateDuration(minutes)
        return (newState, [])
    }

    // MARK: - Control Actions

    private static func reduceStartPressed(
        state: TimerDisplayState,
        settings: MeditationSettings
    ) -> (TimerDisplayState, [TimerEffect]) {
        guard state.selectedMinutes > 0 else {
            return (state, [])
        }

        var newState = state
        newState.currentAffirmationIndex = (state.currentAffirmationIndex + 1) % 5
        newState.intervalGongPlayedForCurrentInterval = false

        var updatedSettings = settings
        updatedSettings.durationMinutes = state.selectedMinutes

        let effects: [TimerEffect] = [
            .configureAudioSession,
            .startBackgroundAudio(soundId: settings.backgroundSoundId),
            .startTimer(durationMinutes: state.selectedMinutes),
            .saveSettings(updatedSettings)
        ]

        return (newState, effects)
    }

    private static func reducePausePressed(
        state: TimerDisplayState
    ) -> (TimerDisplayState, [TimerEffect]) {
        guard state.timerState == .running else {
            return (state, [])
        }
        var newState = state
        newState.timerState = .paused
        return (newState, [.pauseBackgroundAudio, .pauseTimer])
    }

    private static func reduceResumePressed(
        state: TimerDisplayState
    ) -> (TimerDisplayState, [TimerEffect]) {
        guard state.timerState == .paused else {
            return (state, [])
        }
        var newState = state
        newState.timerState = .running
        return (newState, [.resumeBackgroundAudio, .resumeTimer])
    }

    private static func reduceResetPressed(
        state: TimerDisplayState
    ) -> (TimerDisplayState, [TimerEffect]) {
        guard state.timerState != .idle else {
            return (state, [])
        }

        var newState = state
        newState.timerState = .idle
        newState.remainingSeconds = 0
        newState.totalSeconds = 0
        newState.countdownSeconds = 0
        newState.progress = 0.0
        newState.intervalGongPlayedForCurrentInterval = false

        return (newState, [.stopBackgroundAudio, .resetTimer])
    }

    // MARK: - Timer Update Actions

    private static func reduceCountdownFinished(
        state: TimerDisplayState
    ) -> (TimerDisplayState, [TimerEffect]) {
        var newState = state
        newState.timerState = .running
        return (newState, [.playStartGong])
    }

    private static func reduceTimerCompleted(
        state: TimerDisplayState
    ) -> (TimerDisplayState, [TimerEffect]) {
        var newState = state
        newState.timerState = .completed
        newState.progress = 1.0
        return (newState, [.playCompletionSound, .stopBackgroundAudio])
    }

    // MARK: - Interval Gong Actions

    private static func reduceIntervalGongTriggered(
        state: TimerDisplayState,
        settings: MeditationSettings
    ) -> (TimerDisplayState, [TimerEffect]) {
        guard settings.intervalGongsEnabled,
              !state.intervalGongPlayedForCurrentInterval else {
            return (state, [])
        }
        var newState = state
        newState.intervalGongPlayedForCurrentInterval = true
        return (newState, [.playIntervalGong])
    }

    private static func reduceIntervalGongPlayed(
        state: TimerDisplayState
    ) -> (TimerDisplayState, [TimerEffect]) {
        var newState = state
        newState.intervalGongPlayedForCurrentInterval = false
        return (newState, [])
    }
}
