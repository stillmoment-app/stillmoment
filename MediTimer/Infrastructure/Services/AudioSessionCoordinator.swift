//
//  AudioSessionCoordinator.swift
//  MediTimer
//
//  Infrastructure - Audio Session Coordinator Implementation
//

import AVFoundation
import Combine
import Foundation
import OSLog

/// Errors that can occur during audio session coordination
enum AudioSessionCoordinatorError: Error, LocalizedError {
    case sessionActivationFailed
    case sessionDeactivationFailed
    case categoryConfigurationFailed

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .sessionActivationFailed:
            "Failed to activate audio session"
        case .sessionDeactivationFailed:
            "Failed to deactivate audio session"
        case .categoryConfigurationFailed:
            "Failed to configure audio session category"
        }
    }
}

/// Centralized coordinator for managing audio session across multiple audio sources
///
/// This singleton ensures that timer background audio and guided meditation playback
/// don't conflict with each other. Only one audio source can be active at a time.
///
/// Thread-Safety: All methods are thread-safe and can be called from any queue.
/// Uses a serial DispatchQueue to synchronize access to shared state.
final class AudioSessionCoordinator: AudioSessionCoordinatorProtocol {
    // MARK: Lifecycle

    private init() {
        Logger.audio.info("AudioSessionCoordinator initialized")
    }

    // MARK: Internal

    static let shared = AudioSessionCoordinator()

    var activeSource: CurrentValueSubject<AudioSource?, Never> {
        self._activeSource
    }

    func registerConflictHandler(for source: AudioSource, handler: @escaping () -> Void) {
        self.queue.sync {
            self.conflictHandlers[source] = handler
            Logger.audio.debug("Registered conflict handler for \(source.rawValue)")
        }
    }

    func requestAudioSession(for source: AudioSource) throws -> Bool {
        try self.queue.sync {
            let currentSource = self._activeSource.value

            // If same source, just ensure session is active
            if currentSource == source {
                Logger.audio.debug("Audio session already owned by \(source.rawValue)")
                try? self.activateAudioSession() // Best-effort activation
                return true
            }

            // If different source is active, call its conflict handler synchronously
            if let currentSource, currentSource != source {
                Logger.audio.info(
                    "Audio session requested by \(source.rawValue), releasing \(currentSource.rawValue)"
                )

                // Call the conflict handler for the current source
                if let handler = conflictHandlers[currentSource] {
                    Logger.audio.debug("Calling conflict handler for \(currentSource.rawValue)")
                    handler() // Synchronous callback
                }
            }

            // Grant ownership to new source
            self._activeSource.send(source)

            // Activate session (best-effort, don't fail if activation fails)
            do {
                try self.activateAudioSession()
                Logger.audio.info("Audio session granted and activated for \(source.rawValue)")
            } catch {
                Logger.audio.warning(
                    """
                    Audio session granted to \(source.rawValue) but activation failed \
                    (non-critical in test env): \(error.localizedDescription)
                    """
                )
            }

            return true
        }
    }

    func releaseAudioSession(for source: AudioSource) {
        self.queue.sync {
            // Only release if this source currently owns the session
            guard self._activeSource.value == source else {
                Logger.audio.debug(
                    "Ignoring release request from \(source.rawValue) - not current owner"
                )
                return
            }

            Logger.audio.info("Audio session released by \(source.rawValue)")
            self._activeSource.send(nil)
            self.deactivateAudioSession()
        }
    }

    func activateAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()

        // Set category if not already configured
        if audioSession.category != .playback {
            Logger.audio.info("Configuring audio session category to .playback")
            do {
                try audioSession.setCategory(
                    .playback,
                    mode: .default,
                    options: []
                )
            } catch {
                Logger.audio.error(
                    "Failed to set audio session category",
                    error: error
                )
                throw AudioSessionCoordinatorError.categoryConfigurationFailed
            }
        }

        // Activate the session
        do {
            try audioSession.setActive(true)
            Logger.audio.debug("Audio session activated")
        } catch {
            Logger.audio.error("Failed to activate audio session", error: error)
            throw AudioSessionCoordinatorError.sessionActivationFailed
        }
    }

    func deactivateAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
            Logger.audio.debug("Audio session deactivated")
        } catch {
            Logger.audio.error(
                "Failed to deactivate audio session",
                error: error
            )
            // Don't throw - deactivation failure is not critical
        }
    }

    // MARK: Private

    /// Serial queue for thread-safe access to shared state
    private let queue = DispatchQueue(label: "com.meditimer.audio.coordinator", qos: .userInitiated)

    /// Thread-safe publisher for active audio source
    private let _activeSource = CurrentValueSubject<AudioSource?, Never>(nil)

    /// Registered conflict handlers for each audio source
    private var conflictHandlers: [AudioSource: () -> Void] = [:]
}
