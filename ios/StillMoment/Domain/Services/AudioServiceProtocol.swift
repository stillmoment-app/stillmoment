//
//  AudioServiceProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Audio Playback
//

import Foundation

/// Protocol defining audio playback behavior
protocol AudioServiceProtocol {
    /// Configures the audio session for background-capable playback
    func configureAudioSession() throws

    /// Starts background audio to keep app active
    /// - Parameter soundId: ID of the background sound to play (references BackgroundSound.id)
    func startBackgroundAudio(soundId: String) throws

    /// Stops background audio (with fade out)
    func stopBackgroundAudio()

    /// Pauses background audio with fade out (for "Brief Pause")
    func pauseBackgroundAudio()

    /// Resumes background audio with fade in (after "Brief Pause")
    func resumeBackgroundAudio()

    /// Plays the start gong when countdown completes
    func playStartGong() throws

    /// Plays an interval gong during meditation
    func playIntervalGong() throws

    /// Plays the completion sound when timer finishes
    func playCompletionSound() throws

    /// Stops any currently playing sound
    func stop()
}

/// Errors that can occur during audio operations
enum AudioServiceError: Error, LocalizedError {
    case sessionConfigurationFailed
    case soundFileNotFound
    case playbackFailed

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .sessionConfigurationFailed:
            "Failed to configure audio session"
        case .soundFileNotFound:
            "Sound file not found"
        case .playbackFailed:
            "Failed to play sound"
        }
    }
}
