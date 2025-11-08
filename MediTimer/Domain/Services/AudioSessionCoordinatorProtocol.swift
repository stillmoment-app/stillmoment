//
//  AudioSessionCoordinatorProtocol.swift
//  MediTimer
//
//  Domain Service Protocol - Audio Session Coordinator
//

import Combine
import Foundation

/// Audio source identifier for coordination
enum AudioSource: String, Equatable {
    case timer
    case guidedMeditation
}

/// Centralized coordinator for audio session management
///
/// This coordinator ensures that only one audio source is active at a time,
/// preventing conflicts between timer background audio and guided meditation playback.
///
/// Usage:
/// ```swift
/// // Register callback for when another source takes over
/// coordinator.registerConflictHandler(for: .timer) {
///     // Stop audio playback
/// }
///
/// // Request audio session before playing
/// try coordinator.requestAudioSession(for: .timer)
///
/// // Release when done
/// coordinator.releaseAudioSession(for: .timer)
/// ```
protocol AudioSessionCoordinatorProtocol: AnyObject {
    /// Currently active audio source (nil if none)
    var activeSource: CurrentValueSubject<AudioSource?, Never> { get }

    /// Registers a conflict handler for the given audio source
    ///
    /// The handler will be called synchronously when another source requests the audio session.
    /// This allows the current source to cleanly stop its audio playback.
    ///
    /// - Parameters:
    ///   - source: The audio source registering the handler
    ///   - handler: Closure called when another source becomes active
    func registerConflictHandler(for source: AudioSource, handler: @escaping () -> Void)

    /// Requests exclusive use of the audio session
    ///
    /// If another source is currently active, its conflict handler will be called synchronously.
    ///
    /// - Parameter source: The audio source requesting the session
    /// - Returns: True if session was granted, false if request was denied
    /// - Throws: Audio session configuration errors
    func requestAudioSession(for source: AudioSource) throws -> Bool

    /// Releases the audio session for the given source
    ///
    /// If this source is currently active, the audio session will be deactivated
    /// to save energy.
    ///
    /// - Parameter source: The audio source releasing the session
    func releaseAudioSession(for source: AudioSource)

    /// Configures and activates the shared audio session
    ///
    /// - Throws: Audio session configuration errors
    func activateAudioSession() throws

    /// Deactivates the shared audio session
    ///
    /// Should only be called when no audio sources are active.
    func deactivateAudioSession()
}
