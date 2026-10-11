//
//  GuidedMeditationPlayerViewModel+Phase.swift
//  Still Moment
//
//  Application Layer - Playback status and pre-roll phase of the player
//

import Foundation

extension GuidedMeditationPlayerViewModel {
    // MARK: - Playback Status

    /// Whether the player is currently playing
    var isPlaying: Bool {
        self.playbackState == .playing
    }

    /// Whether playback is paused (distinct from idle/loading/finished/failed).
    ///
    /// Used by the view to switch the remaining-time label format — only `.paused`
    /// should show the "PAUSIERT"-Prefix, not transient states like `.loading`.
    var isPaused: Bool {
        self.playbackState == .paused
    }

    /// Whether the guided meditation has completed naturally (audio reached end)
    var isCompleted: Bool {
        self.playbackState == .finished
    }

    /// Visuelle Phase des Players.
    ///
    /// - `.preRoll` bis der Ton der Meditation beginnt: Vorbereitung, Start-Gong und
    ///   Atempause (shared-143) — ruhige Ansicht ohne Play-Knopf und Wellenform.
    /// - `.playing` ansonsten (auch bei Pause, Loading, Idle, Finished —
    ///   der Atemkreis sieht in all diesen Zustaenden gleich aus).
    var phase: MeditationPhase {
        self.isBeforeAudio ? .preRoll : .playing
    }

    /// True while the meditation audio has not begun yet: preparation countdown, start gong
    /// or breath pause. Play, pause, seek and scrub do nothing then (shared-143).
    var isBeforeAudio: Bool {
        self.isPreparing || self.isStartGongSequenceActive
    }

    // MARK: - Pre-Roll

    /// Whether preparation countdown is currently active
    var isPreparing: Bool {
        if case .active = self.countdownState {
            return true
        }
        return false
    }

    /// Whether Zen Mode is active: tab bar should be hidden during active session
    ///
    /// Active before the meditation audio begins (preparation, start gong, breath pause),
    /// while the meditation is playing or paused, or the completion/thank-you screen is
    /// shown. Pause keeps the player as the active surface — switching tabs is not the
    /// intended action.
    var isZenMode: Bool {
        self.isBeforeAudio || self.isPlaying || self.playbackState == .paused || self.isCompleted
    }

    /// Remaining countdown seconds (for UI)
    var remainingCountdownSeconds: Int {
        if case let .active(countdown) = countdownState {
            return countdown.remainingSeconds
        }
        return 0
    }

    /// Progress for countdown ring (0.0 to 1.0)
    var countdownProgress: Double {
        if case let .active(countdown) = countdownState {
            return countdown.progress
        }
        return 0
    }
}
