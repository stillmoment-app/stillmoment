//
//  AudioService.swift
//  MediTimer
//
//  Infrastructure - Audio Service Implementation
//

import Foundation
import AVFoundation
import OSLog

/// Concrete implementation of audio service using AVFoundation
final class AudioService: AudioServiceProtocol {
    // MARK: - Properties

    private var audioPlayer: AVAudioPlayer?

    // MARK: - Public Methods

    func configureAudioSession() throws {
        Logger.audio.info("Configuring audio session")
        let audioSession = AVAudioSession.sharedInstance()

        do {
            // Configure for playback in background
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try audioSession.setActive(true)
            Logger.audio.info("Audio session configured successfully")
        } catch {
            Logger.audio.error("Failed to configure audio session", error: error)
            throw AudioServiceError.sessionConfigurationFailed
        }
    }

    func playCompletionSound() throws {
        Logger.audio.info("Playing completion sound")

        // Use custom MP3 file from Resources
        guard let soundURL = Bundle.main.url(forResource: "completion", withExtension: "mp3") else {
            Logger.audio.error("Completion sound file not found")
            throw AudioServiceError.soundFileNotFound
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            Logger.audio.info("Completion sound playing")
        } catch {
            Logger.audio.error("Failed to play completion sound", error: error)
            throw AudioServiceError.playbackFailed
        }
    }

    func stop() {
        Logger.audio.debug("Stopping audio playback")
        audioPlayer?.stop()
        audioPlayer = nil
    }


    // MARK: - Deinit

    deinit {
        stop()
    }
}

// MARK: - Future Enhancement: Custom Sound Support

extension AudioService {
    /// Loads a custom sound file from the app bundle
    /// - Parameter filename: Name of the sound file (e.g., "completion.mp3")
    /// - Returns: URL to the sound file
    func loadCustomSound(filename: String) -> URL? {
        guard let url = Bundle.main.url(
            forResource: filename,
            withExtension: nil
        ) else {
            return nil
        }
        return url
    }
}
