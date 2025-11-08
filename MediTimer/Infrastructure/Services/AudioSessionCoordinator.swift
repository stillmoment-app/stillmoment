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
@MainActor
final class AudioSessionCoordinator: AudioSessionCoordinatorProtocol {
    // MARK: Lifecycle

    // swiftlint:disable:next modifier_order
    private nonisolated init() {
        Logger.audio.info("AudioSessionCoordinator initialized")
    }

    // MARK: Internal

    static let shared = AudioSessionCoordinator()

    let activeSource = CurrentValueSubject<AudioSource?, Never>(nil)

    func requestAudioSession(for source: AudioSource) throws -> Bool {
        let currentSource = self.activeSource.value

        // If same source, just ensure session is active
        if currentSource == source {
            Logger.audio.debug("Audio session already owned by \(source.rawValue)")
            try self.activateAudioSession()
            return true
        }

        // If different source is active, log the conflict
        if let currentSource {
            Logger.audio.info(
                "Audio session requested by \(source.rawValue), releasing \(currentSource.rawValue)"
            )
            // Note: The old source should listen to activeSource changes and stop itself
        }

        // Activate session and grant to new source
        try self.activateAudioSession()
        self.activeSource.send(source)

        Logger.audio.info("Audio session granted to \(source.rawValue)")
        return true
    }

    func releaseAudioSession(for source: AudioSource) {
        // Only release if this source currently owns the session
        guard self.activeSource.value == source else {
            Logger.audio.debug(
                "Ignoring release request from \(source.rawValue) - not current owner"
            )
            return
        }

        Logger.audio.info("Audio session released by \(source.rawValue)")
        self.activeSource.send(nil)
        self.deactivateAudioSession()
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
}
