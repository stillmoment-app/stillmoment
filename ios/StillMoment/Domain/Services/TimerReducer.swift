//
//  TimerReducer.swift
//  Still Moment
//
//  Domain Service - Pure Effect Mapper for Timer Actions
//

import Foundation

/// Pure effect mapper for timer actions
///
/// Maps actions to effects based on the current timer state and settings.
/// Contains no side effects and no state mutations — all I/O is represented as effects.
/// State is managed directly by the ViewModel via MeditationTimer.
enum TimerReducer {
    /// Maps an action to effects based on current timer state and settings
    ///
    /// - Parameters:
    ///   - action: Action to process
    ///   - timerState: Current timer state (.idle when no timer exists)
    ///   - selectedMinutes: Currently selected duration in minutes
    ///   - settings: Current meditation settings (for effect parameters)
    /// - Returns: Effects to execute
    static func reduce(
        action: TimerAction,
        timerState: TimerState,
        selectedMinutes: Int,
        settings: MeditationSettings,
        attunementResolver: AttunementResolverProtocol? = nil
    ) -> [TimerEffect] {
        switch action {
        case .startPressed:
            self.reduceStartPressed(
                timerState: timerState,
                selectedMinutes: selectedMinutes,
                settings: settings
            )
        case .resetPressed:
            self.reduceResetPressed(timerState: timerState)
        case .preparationFinished:
            self.reducePreparationFinished()
        case .startGongFinished:
            self.reduceStartGongFinished(
                timerState: timerState,
                settings: settings,
                attunementResolver: attunementResolver
            )
        case .introductionFinished:
            self.reduceIntroductionFinished(timerState: timerState, settings: settings)
        case .timerCompleted:
            self.reduceTimerCompleted(timerState: timerState)
        case .endGongFinished:
            self.reduceEndGongFinished(timerState: timerState)
        case .intervalGongTriggered:
            self.reduceIntervalGong(settings: settings)
        }
    }

    // MARK: - Control Actions

    private static func reduceStartPressed(
        timerState: TimerState,
        selectedMinutes: Int,
        settings: MeditationSettings
    ) -> [TimerEffect] {
        guard selectedMinutes > 0 else {
            return []
        }

        var updatedSettings = settings
        updatedSettings.durationMinutes = selectedMinutes

        // Background audio never starts here. It starts when the start gong finishes:
        // - Without introduction: in reduceStartGongFinished
        // - With introduction: in reduceIntroductionFinished
        return [
            .activateTimerSession,
            .startTimer(durationMinutes: selectedMinutes),
            .saveSettings(updatedSettings)
        ]
    }

    private static func reduceResetPressed(timerState: TimerState) -> [TimerEffect] {
        guard timerState != .idle else {
            return []
        }

        var effects: [TimerEffect] = []
        if timerState == .introduction {
            effects.append(.stopIntroduction)
        }
        effects.append(contentsOf: [.stopBackgroundAudio, .resetTimer, .clearTimer, .deactivateTimerSession])

        return effects
    }

    // MARK: - Timer Update Actions

    private static func reducePreparationFinished() -> [TimerEffect] {
        // Play start gong. Background audio decision is deferred to startGongFinished.
        [.playStartGong]
    }

    private static func reduceStartGongFinished(
        timerState: TimerState,
        settings: MeditationSettings,
        attunementResolver: AttunementResolverProtocol?
    ) -> [TimerEffect] {
        guard timerState == .startGong else {
            return []
        }

        if self.hasActiveIntroduction(settings: settings, attunementResolver: attunementResolver),
           let introId = settings.introductionId {
            // Introduction configured → play audio
            return [.beginIntroductionPhase, .playIntroduction(introductionId: introId)]
        } else {
            // No introduction → start background audio directly
            return [
                .startBackgroundAudio(
                    soundId: settings.backgroundSoundId,
                    volume: settings.backgroundSoundVolume
                )
            ]
        }
    }

    private static func reduceIntroductionFinished(
        timerState: TimerState,
        settings: MeditationSettings
    ) -> [TimerEffect] {
        guard timerState == .introduction else {
            return []
        }

        return [
            .stopIntroduction,
            .endIntroductionPhase,
            .startBackgroundAudio(
                soundId: settings.backgroundSoundId,
                volume: settings.backgroundSoundVolume
            )
        ]
    }

    private static func reduceTimerCompleted(timerState: TimerState) -> [TimerEffect] {
        var effects: [TimerEffect] = [.playCompletionSound]
        // Stop introduction if it was still playing (timer expired during introduction)
        if timerState == .introduction {
            effects.append(.stopIntroduction)
        }
        effects.append(.stopBackgroundAudio)
        // Keep-alive stays active during endGong — deactivation happens in reduceEndGongFinished

        return effects
    }

    private static func reduceEndGongFinished(timerState: TimerState) -> [TimerEffect] {
        guard timerState == .endGong else {
            return []
        }

        return [.transitionToCompleted, .deactivateTimerSession]
    }

    // MARK: - Interval Gong Actions

    /// Handles interval gong triggered by tick() domain event.
    /// Deduplication is handled by MeditationTimer.tick() via lastIntervalGongAt.
    private static func reduceIntervalGong(settings: MeditationSettings) -> [TimerEffect] {
        guard settings.intervalGongsEnabled else {
            return []
        }
        return [
            .playIntervalGong(
                soundId: settings.intervalSoundId,
                volume: settings.intervalGongVolume
            )
        ]
    }

    // MARK: - Helpers

    /// Checks if an introduction is configured, enabled, and available
    private static func hasActiveIntroduction(
        settings: MeditationSettings,
        attunementResolver: AttunementResolverProtocol?
    ) -> Bool {
        guard settings.introductionEnabled,
              let introId = settings.introductionId else {
            return false
        }
        if let resolver = attunementResolver {
            return resolver.resolve(id: introId) != nil
        }
        // Fallback for callers without resolver (backward compatibility)
        return Introduction.isAvailableForCurrentLanguage(introId)
    }
}
