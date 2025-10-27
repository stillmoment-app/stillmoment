//
//  AudioPlayerServiceProtocol.swift
//  MediTimer
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
        case (.failed(let lhsError), .failed(let rhsError)):
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
        case .playbackFailed(let reason):
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
    func setupRemoteCommandCenter()

    /// Cleans up resources (call when done with player)
    func cleanup()
}
