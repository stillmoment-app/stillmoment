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
        attunementResolver: AttunementResolverProtocol
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
        case .attunementFinished:
            self.reduceAttunementFinished(timerState: timerState, settings: settings)
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

        // Background audio never starts here. It starts when the start gong finishes:
        // - Without attunement: in reduceStartGongFinished
        // - With attunement: in reduceAttunementFinished
        return [
            .activateTimerSession,
            .startTimer(durationMinutes: selectedMinutes)
        ]
    }

    private static func reduceResetPressed(timerState: TimerState) -> [TimerEffect] {
        guard timerState != .idle else {
            return []
        }

        var effects: [TimerEffect] = []
        if timerState == .attunement {
            effects.append(.stopAttunement)
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
        attunementResolver: AttunementResolverProtocol
    ) -> [TimerEffect] {
        guard timerState == .startGong else {
            return []
        }

        if self.hasActiveAttunement(settings: settings, attunementResolver: attunementResolver),
           let attunementId = settings.attunementId {
            // Attunement configured → play audio
            return [.beginAttunementPhase, .playAttunement(attunementId: attunementId)]
        } else {
            // No attunement → transition to running and start background audio
            return [
                .beginRunningPhase,
                .startBackgroundAudio(
                    soundId: settings.backgroundSoundId,
                    volume: settings.backgroundSoundVolume
                )
            ]
        }
    }

    private static func reduceAttunementFinished(
        timerState: TimerState,
        settings: MeditationSettings
    ) -> [TimerEffect] {
        guard timerState == .attunement else {
            return []
        }

        return [
            .stopAttunement,
            .endAttunementPhase,
            .startBackgroundAudio(
                soundId: settings.backgroundSoundId,
                volume: settings.backgroundSoundVolume
            )
        ]
    }

    private static func reduceTimerCompleted(timerState: TimerState) -> [TimerEffect] {
        var effects: [TimerEffect] = [.playCompletionSound]
        // Stop attunement if it was still playing (timer expired during attunement)
        if timerState == .attunement {
            effects.append(.stopAttunement)
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

    /// Checks if an attunement is configured, enabled, and available
    private static func hasActiveAttunement(
        settings: MeditationSettings,
        attunementResolver: AttunementResolverProtocol
    ) -> Bool {
        guard settings.attunementEnabled,
              let attunementId = settings.attunementId else {
            return false
        }
        return attunementResolver.resolve(id: attunementId) != nil
    }
}
