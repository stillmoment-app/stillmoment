//
//  AudioServiceProtocol.swift
//  MediTimer
//
//  Domain Service Protocol - Audio Playback
//

import Foundation

/// Protocol defining audio playback behavior
protocol AudioServiceProtocol {
    /// Configures the audio session for background playback
    func configureAudioSession() throws

    /// Plays the completion sound
    func playCompletionSound() throws

    /// Stops any currently playing sound
    func stop()
}

/// Errors that can occur during audio operations
enum AudioServiceError: Error, LocalizedError {
    case sessionConfigurationFailed
    case soundFileNotFound
    case playbackFailed

    var errorDescription: String? {
        switch self {
        case .sessionConfigurationFailed:
            return "Failed to configure audio session"
        case .soundFileNotFound:
            return "Sound file not found"
        case .playbackFailed:
            return "Failed to play sound"
        }
    }
}
