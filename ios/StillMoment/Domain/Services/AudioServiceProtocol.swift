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
    /// - Parameter soundId: ID of the gong sound to play (references GongSound.id)
    func playStartGong(soundId: String) throws

    /// Plays an interval gong during meditation (uses fixed interval.mp3)
    func playIntervalGong() throws

    /// Plays the completion sound when timer finishes
    /// - Parameter soundId: ID of the gong sound to play (references GongSound.id)
    func playCompletionSound(soundId: String) throws

    /// Plays a preview of a gong sound (stops any previous preview)
    /// - Parameter soundId: ID of the gong sound to preview (references GongSound.id)
    func playGongPreview(soundId: String) throws

    /// Stops any currently playing gong preview
    func stopGongPreview()

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
