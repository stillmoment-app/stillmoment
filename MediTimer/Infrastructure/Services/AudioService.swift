//
//  AudioService.swift
//  MediTimer
//
//  Infrastructure - Audio Service Implementation
//

import AVFoundation
import Foundation
import OSLog

/// Concrete implementation of audio service using AVFoundation
final class AudioService: AudioServiceProtocol {
    // MARK: Lifecycle

    // MARK: - Initialization

    init() {
        self.setupAudioInterruptionHandling()
    }

    // MARK: - Deinit

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.stopBackgroundAudio()
        stop()
    }

    // MARK: Internal

    // MARK: - Public Methods

    func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()

        // Only configure if not already active to avoid conflicts
        // Check if our category is already set
        if audioSession.category == .playback {
            Logger.audio.debug("Audio session already configured, skipping")
            return
        }

        Logger.audio.info("Configuring audio session for background-capable playback")

        do {
            // Configure for background playback
            // No .mixWithOthers - this is primary audio for meditation
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: []
            )
            try audioSession.setActive(true)
            Logger.audio.info("Audio session configured successfully for background mode")
        } catch {
            Logger.audio.error("Failed to configure audio session", error: error)
            throw AudioServiceError.sessionConfigurationFailed
        }
    }

    func playStartGong() throws {
        Logger.audio.info("Playing start gong")
        try self.configureAudioSession() // Ensure session is active
        try self.playGong(soundName: "completion")
    }

    func playIntervalGong() throws {
        Logger.audio.info("Playing interval gong")
        try self.configureAudioSession() // Ensure session is active
        try self.playGong(soundName: "completion")
    }

    func startBackgroundAudio(mode: BackgroundAudioMode) throws {
        Logger.audio.info("Starting background audio", metadata: ["mode": mode.rawValue])

        try self.configureAudioSession() // Ensure session is active

        guard let soundURL = Bundle.main.url(forResource: "silence", withExtension: "m4a") else {
            Logger.audio.error("Background audio file not found")
            throw AudioServiceError.soundFileNotFound
        }

        do {
            self.backgroundAudioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            self.backgroundAudioPlayer?.numberOfLoops = -1 // Loop indefinitely

            // Set volume based on mode
            switch mode {
            case .silent:
                self.backgroundAudioPlayer?.volume = 0.01 // Almost silent, but audible to iOS
            case .whiteNoise:
                self.backgroundAudioPlayer?.volume = 0.15 // Audible white noise
            }

            self.backgroundAudioPlayer?.prepareToPlay()
            self.backgroundAudioPlayer?.play()
            Logger.audio.info("Background audio started successfully")
        } catch {
            Logger.audio.error("Failed to start background audio", error: error)
            throw AudioServiceError.playbackFailed
        }
    }

    func stopBackgroundAudio() {
        Logger.audio.debug("Stopping background audio")
        self.backgroundAudioPlayer?.stop()
        self.backgroundAudioPlayer = nil

        // Deactivate audio session to save energy when no audio is playing
        self.deactivateAudioSessionIfIdle()
    }

    func playCompletionSound() throws {
        Logger.audio.info("Playing completion sound")
        try self.configureAudioSession() // Ensure session is active
        try self.playGong(soundName: "completion")
    }

    func stop() {
        Logger.audio.debug("Stopping all audio playback")
        self.audioPlayer?.stop()
        self.audioPlayer = nil
        self.stopBackgroundAudio()

        // Deactivate audio session when stopping all audio
        self.deactivateAudioSession()
    }

    // MARK: Private

    private var audioPlayer: AVAudioPlayer?
    private var backgroundAudioPlayer: AVAudioPlayer?

    // MARK: - Private Methods

    private func setupAudioInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        Logger.audio.debug("Audio interruption handling configured")
    }

    @objc
    private func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }

        switch type {
        case .began:
            Logger.audio.info("Audio interruption began")
            // iOS automatically pauses audio, we just log it

        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

            if options.contains(.shouldResume) {
                Logger.audio.info("Audio interruption ended, can resume if needed")
            } else {
                Logger.audio.info("Audio interruption ended without resume option")
            }

        @unknown default:
            Logger.audio.warning("Unknown audio interruption type")
        }
    }

    /// Shared method to play a gong sound
    private func playGong(soundName: String) throws {
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            Logger.audio.error("Sound file not found", metadata: ["sound": soundName])
            throw AudioServiceError.soundFileNotFound
        }

        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.play()
            Logger.audio.info("Gong playing", metadata: ["sound": soundName])
        } catch {
            Logger.audio.error("Failed to play gong", error: error, metadata: ["sound": soundName])
            throw AudioServiceError.playbackFailed
        }
    }

    /// Deactivates audio session if no audio is currently playing
    private func deactivateAudioSessionIfIdle() {
        // Only deactivate if both players are nil or not playing
        let backgroundPlaying = self.backgroundAudioPlayer?.isPlaying ?? false
        let gongPlaying = self.audioPlayer?.isPlaying ?? false

        if !backgroundPlaying && !gongPlaying {
            self.deactivateAudioSession()
        }
    }

    /// Deactivates the audio session to save energy
    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            Logger.audio.info("Audio session deactivated to save energy")
        } catch {
            Logger.audio.warning("Failed to deactivate audio session: \(error.localizedDescription)")
        }
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
