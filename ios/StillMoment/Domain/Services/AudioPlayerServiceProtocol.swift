//
//  AudioPlayerServiceProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Audio Player
//

import Combine
import Foundation

/// Playback state of the audio player
enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case finished
    case failed(Error)

    // MARK: Internal

    static func == (lhs: PlaybackState, rhs: PlaybackState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.playing, .playing),
             (.paused, .paused),
             (.finished, .finished):
            true
        case let (.failed(lhsError), .failed(rhsError)):
            lhsError.localizedDescription == rhsError.localizedDescription
        default:
            false
        }
    }
}

/// Errors that can occur during audio playback
enum AudioPlayerError: Error, LocalizedError {
    case fileNotAccessible
    case playbackFailed(reason: String)
    case invalidAudioFormat
    case audioSessionFailed

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .fileNotAccessible:
            "Could not access audio file"
        case let .playbackFailed(reason):
            "Playback failed: \(reason)"
        case .invalidAudioFormat:
            "Audio format not supported"
        case .audioSessionFailed:
            "Failed to configure audio session"
        }
    }
}

/// Service for playing audio files with background support and lock screen controls
///
/// This service handles:
/// - Playing guided meditation audio files
/// - Background audio playback
/// - Lock screen controls (play/pause/seek)
/// - Progress tracking and seeking
protocol AudioPlayerServiceProtocol {
    /// Current playback state
    var state: CurrentValueSubject<PlaybackState, Never> { get }

    /// Current playback time in seconds
    var currentTime: CurrentValueSubject<TimeInterval, Never> { get }

    /// Total duration of current audio in seconds (0 if no audio loaded)
    var duration: CurrentValueSubject<TimeInterval, Never> { get }

    /// Loads an audio file for playback
    ///
    /// - Parameters:
    ///   - url: URL to the audio file
    ///   - meditation: Meditation metadata for lock screen display
    /// - Throws: AudioPlayerError if loading fails
    func load(url: URL, meditation: GuidedMeditation) async throws

    /// Starts or resumes playback
    ///
    /// - Throws: AudioPlayerError if playback fails
    func play() throws

    /// Pauses playback
    func pause()

    /// Stops playback and unloads audio
    func stop()

    /// Seeks to a specific time
    ///
    /// - Parameter time: Time in seconds to seek to
    /// - Throws: AudioPlayerError if seeking fails
    func seek(to time: TimeInterval) throws

    /// Configures audio session for background playback
    ///
    /// - Throws: AudioPlayerError if configuration fails
    func configureAudioSession() throws

    /// Sets up remote command center for lock screen controls
    ///
    /// - Important: This method must be called AFTER the audio session is activated.
    ///   iOS requires the audio session to be active before Remote Command Center
    ///   configuration for lock screen controls to work correctly.
    ///
    /// - Note: In typical usage, this is called automatically by `play()` after
    ///   requesting the audio session from the coordinator.
    func setupRemoteCommandCenter()

    /// Starts silent background audio to keep audio session active
    ///
    /// Use this during preparation countdown to ensure the timer runs reliably
    /// in the background. The silent audio prevents iOS from suspending the app.
    ///
    /// - Throws: AudioPlayerError if audio session fails
    func startSilentBackgroundAudio() throws

    /// Stops silent background audio
    ///
    /// Call this when preparation countdown ends (before starting actual playback).
    func stopSilentBackgroundAudio()

    /// Atomically transitions from silent background audio to actual playback
    ///
    /// This method ensures there is no gap between stopping silent audio and starting
    /// playback, which prevents iOS from suspending the app when the screen is locked.
    ///
    /// The transition sequence:
    /// 1. Starts the main audio player
    /// 2. Waits for playback to actually begin
    /// 3. Only then stops the silent background audio
    ///
    /// - Throws: AudioPlayerError if playback fails
    func transitionFromSilentToPlayback() throws

    /// Cleans up resources (call when done with player)
    func cleanup()
}
