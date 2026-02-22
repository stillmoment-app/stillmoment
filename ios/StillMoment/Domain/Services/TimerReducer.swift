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
            return self.reduceSelectDuration(state: state, minutes: minutes, settings: settings)
        case .startPressed:
            return self.reduceStartPressed(state: state, settings: settings)
        case .resetPressed:
            return self.reduceResetPressed(state: state, settings: settings)
        case let .tick(remainingSeconds, totalSeconds, remainingPreparationSeconds, progress, timerState):
            var newState = state
            newState.remainingSeconds = remainingSeconds
            newState.totalSeconds = totalSeconds
            newState.remainingPreparationSeconds = remainingPreparationSeconds
            newState.progress = progress
            newState.timerState = timerState
            return (newState, [])
        case .preparationFinished:
            return self.reducePreparationFinished(state: state, settings: settings)
        case .startGongFinished:
            return self.reduceStartGongFinished(state: state, settings: settings)
        case .introductionFinished:
            return self.reduceIntroductionFinished(state: state, settings: settings)
        case .timerCompleted:
            return self.reduceTimerCompleted(state: state, settings: settings)
        case .intervalGongTriggered:
            return self.reduceIntervalGongTriggered(state: state, settings: settings)
        case .intervalGongPlayed:
            return self.reduceIntervalGongPlayed(state: state)
        }
    }

    // MARK: - Duration Actions

    private static func reduceSelectDuration(
        state: TimerDisplayState,
        minutes: Int,
        settings: MeditationSettings
    ) -> (TimerDisplayState, [TimerEffect]) {
        var newState = state
        newState.selectedMinutes = MeditationSettings.validateDuration(
            minutes,
            introductionId: settings.introductionId
        )
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

        // Background audio never starts here. It starts when the start gong finishes:
        // - Without introduction: in reduceStartGongFinished
        // - With introduction: in reduceIntroductionFinished
        var effects: [TimerEffect] = [
            .activateTimerSession
        ]

        effects.append(.startTimer(durationMinutes: state.selectedMinutes))
        effects.append(.saveSettings(updatedSettings))

        return (newState, effects)
    }

    private static func reduceResetPressed(
        state: TimerDisplayState,
        settings: MeditationSettings
    ) -> (TimerDisplayState, [TimerEffect]) {
        guard state.timerState != .idle else {
            return (state, [])
        }

        var newState = state
        newState.timerState = .idle
        newState.remainingSeconds = 0
        newState.totalSeconds = 0
        newState.remainingPreparationSeconds = 0
        newState.progress = 0.0
        newState.intervalGongPlayedForCurrentInterval = false

        var effects: [TimerEffect] = []
        if state.timerState == .introduction {
            effects.append(.stopIntroduction)
        }
        effects.append(contentsOf: [.stopBackgroundAudio, .resetTimer, .deactivateTimerSession])

        return (newState, effects)
    }

    // MARK: - Timer Update Actions

    private static func reducePreparationFinished(
        state: TimerDisplayState,
        settings: MeditationSettings
    ) -> (TimerDisplayState, [TimerEffect]) {
        var newState = state
        newState.timerState = .startGong
        // Play start gong. Background audio decision is deferred to startGongFinished.
        return (newState, [.playStartGong])
    }

    private static func reduceStartGongFinished(
        state: TimerDisplayState,
        settings: MeditationSettings
    ) -> (TimerDisplayState, [TimerEffect]) {
        guard state.timerState == .startGong else {
            return (state, [])
        }

        var newState = state
        if self.hasActiveIntroduction(settings: settings),
           let introId = settings.introductionId {
            // Introduction configured → transition to .introduction and play audio
            newState.timerState = .introduction
            return (newState, [.playIntroduction(introductionId: introId)])
        } else {
            // No introduction → transition directly to .running with background audio
            newState.timerState = .running
            let effect = TimerEffect.startBackgroundAudio(
                soundId: settings.backgroundSoundId,
                volume: settings.backgroundSoundVolume
            )
            return (newState, [effect])
        }
    }

    private static func reduceIntroductionFinished(
        state: TimerDisplayState,
        settings: MeditationSettings
    ) -> (TimerDisplayState, [TimerEffect]) {
        guard state.timerState == .introduction else {
            return (state, [])
        }

        var newState = state
        newState.timerState = .running

        let effects: [TimerEffect] = [
            .stopIntroduction,
            .endIntroductionPhase,
            .startBackgroundAudio(
                soundId: settings.backgroundSoundId,
                volume: settings.backgroundSoundVolume
            )
        ]

        return (newState, effects)
    }

    private static func reduceTimerCompleted(
        state: TimerDisplayState,
        settings: MeditationSettings
    ) -> (TimerDisplayState, [TimerEffect]) {
        var newState = state
        newState.timerState = .completed
        newState.progress = 1.0

        var effects: [TimerEffect] = [.playCompletionSound]
        // Stop introduction if it was still playing (timer expired during introduction)
        if state.timerState == .introduction {
            effects.append(.stopIntroduction)
        }
        effects.append(contentsOf: [.stopBackgroundAudio, .deactivateTimerSession])

        return (newState, effects)
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
        let effect = TimerEffect.playIntervalGong(
            soundId: settings.intervalSoundId,
            volume: settings.intervalGongVolume
        )
        return (newState, [effect])
    }

    private static func reduceIntervalGongPlayed(
        state: TimerDisplayState
    ) -> (TimerDisplayState, [TimerEffect]) {
        var newState = state
        newState.intervalGongPlayedForCurrentInterval = false
        return (newState, [])
    }

    // MARK: - Helpers

    /// Checks if an introduction is configured and available for the current language
    private static func hasActiveIntroduction(settings: MeditationSettings) -> Bool {
        guard let introId = settings.introductionId else {
            return false
        }
        return Introduction.isAvailableForCurrentLanguage(introId)
    }
}
