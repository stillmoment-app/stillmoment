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

    /// Start background audio with the given sound ID and volume
    case startBackgroundAudio(soundId: String, volume: Float)

    /// Stop background audio playback (with fade out)
    case stopBackgroundAudio

    // MARK: - Sound Effects

    /// Play the start gong (meditation begins)
    case playStartGong

    /// Play an interval gong with the specified sound and volume
    case playIntervalGong(soundId: String, volume: Float)

    /// Play the completion sound (meditation ends)
    case playCompletionSound

    // MARK: - Timer Service Effects

    /// Start the timer with given duration
    case startTimer(durationMinutes: Int)

    /// Reset the timer
    case resetTimer

    // MARK: - Persistence Effects

    /// Save settings to UserDefaults
    case saveSettings(MeditationSettings)
}
