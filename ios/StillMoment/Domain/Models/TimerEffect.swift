//
//  TimerEffect.swift
//  Still Moment
//
//  Domain Model - Timer Effects (Side Effects)
//

import Foundation

/// Side effects that the timer reducer can produce
///
/// These effects are returned by the reducer alongside the new state.
/// The ViewModel's effect handler executes them, keeping the reducer pure.
enum TimerEffect: Equatable {
    // MARK: - Audio Session Effects

    /// Configure the audio session for playback
    case configureAudioSession

    /// Activate the timer session (audio session + always-on keep-alive)
    case activateTimerSession

    /// Deactivate the timer session (stop keep-alive + release audio session)
    case deactivateTimerSession

    /// Start background audio with the given sound ID and volume
    case startBackgroundAudio(soundId: String, volume: Float)

    /// Stop background audio playback (with fade out)
    case stopBackgroundAudio

    // MARK: - Sound Effects

    /// Play the start gong (meditation begins)
    case playStartGong

    /// Play the introduction audio (e.g., guided breathing exercise)
    case playIntroduction(introductionId: String)

    /// Stop the introduction audio (on reset or timer completion during introduction)
    case stopIntroduction

    /// Play an interval gong with the specified sound and volume
    case playIntervalGong(soundId: String, volume: Float)

    /// Play the completion sound (meditation ends)
    case playCompletionSound

    // MARK: - Timer Service Effects

    /// Start the timer with given duration
    case startTimer(durationMinutes: Int)

    /// Reset the timer
    case resetTimer

    /// Begin the introduction phase (transition timer from .startGong to .introduction)
    case beginIntroductionPhase

    /// End the introduction phase (transition timer from .introduction to .running)
    case endIntroductionPhase

    // MARK: - Persistence Effects

    /// Save settings to UserDefaults
    case saveSettings(MeditationSettings)
}
