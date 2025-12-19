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

    /// Start background audio with the given sound ID
    case startBackgroundAudio(soundId: String)

    /// Stop background audio playback
    case stopBackgroundAudio

    // MARK: - Sound Effects

    /// Play the start gong (meditation begins)
    case playStartGong

    /// Play an interval gong
    case playIntervalGong

    /// Play the completion sound (meditation ends)
    case playCompletionSound

    // MARK: - Timer Service Effects

    /// Start the timer with given duration
    case startTimer(durationMinutes: Int)

    /// Pause the timer
    case pauseTimer

    /// Resume the timer
    case resumeTimer

    /// Reset the timer
    case resetTimer

    // MARK: - Persistence Effects

    /// Save settings to UserDefaults
    case saveSettings(MeditationSettings)
}
