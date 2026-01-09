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
    /// - Parameters:
    ///   - soundId: ID of the background sound to play (references BackgroundSound.id)
    ///   - volume: Playback volume (0.0 to 1.0)
    func startBackgroundAudio(soundId: String, volume: Float) throws

    /// Stops background audio (with fade out)
    func stopBackgroundAudio()

    /// Pauses background audio with fade out (for "Brief Pause")
    func pauseBackgroundAudio()

    /// Resumes background audio with fade in (after "Brief Pause")
    func resumeBackgroundAudio()

    /// Plays the start gong when countdown completes
    /// - Parameters:
    ///   - soundId: ID of the gong sound to play (references GongSound.id)
    ///   - volume: Playback volume (0.0 to 1.0)
    func playStartGong(soundId: String, volume: Float) throws

    /// Plays an interval gong during meditation (uses fixed interval.mp3)
    /// - Parameter volume: Playback volume (0.0 to 1.0)
    func playIntervalGong(volume: Float) throws

    /// Plays the completion sound when timer finishes
    /// - Parameters:
    ///   - soundId: ID of the gong sound to play (references GongSound.id)
    ///   - volume: Playback volume (0.0 to 1.0)
    func playCompletionSound(soundId: String, volume: Float) throws

    /// Plays a preview of a gong sound (stops any previous preview)
    /// - Parameters:
    ///   - soundId: ID of the gong sound to preview (references GongSound.id)
    ///   - volume: Playback volume (0.0 to 1.0)
    func playGongPreview(soundId: String, volume: Float) throws

    /// Stops any currently playing gong preview
    func stopGongPreview()

    /// Plays a preview of a background sound (3 seconds with fade-out)
    /// - Parameters:
    ///   - soundId: ID of the background sound to preview (references BackgroundSound.id)
    ///   - volume: Playback volume (0.0 to 1.0)
    func playBackgroundPreview(soundId: String, volume: Float) throws

    /// Stops any currently playing background preview
    func stopBackgroundPreview()

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
