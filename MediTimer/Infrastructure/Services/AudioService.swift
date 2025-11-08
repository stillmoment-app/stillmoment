//
//  AudioService.swift
//  MediTimer
//
//  Infrastructure - Audio Service Implementation
//

import AVFoundation
import Combine
import Foundation
import OSLog

/// Concrete implementation of audio service using AVFoundation
final class AudioService: AudioServiceProtocol {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(coordinator: AudioSessionCoordinatorProtocol) {
        self.coordinator = coordinator
        self.setupAudioInterruptionHandling()
        self.registerConflictHandler()
    }

    convenience init() {
        self.init(coordinator: AudioSessionCoordinator.shared)
    }

    // MARK: - Deinit

    deinit {
        self.cancellables.removeAll()
        self.stopBackgroundAudio()
        stop()
    }

    // MARK: Internal

    // MARK: - Public Methods

    func configureAudioSession() throws {
        // Request audio session through coordinator
        _ = try self.coordinator.requestAudioSession(for: .timer)
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

        // Release audio session when stopping all audio
        self.coordinator.releaseAudioSession(for: .timer)
    }

    // MARK: Private

    private let coordinator: AudioSessionCoordinatorProtocol
    private var audioPlayer: AVAudioPlayer?
    private var backgroundAudioPlayer: AVAudioPlayer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Methods

    private func setupAudioInterruptionHandling() {
        // Handle audio session interruptions (e.g., phone call) using Combine
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                self?.handleAudioInterruption(notification)
            }
            .store(in: &self.cancellables)

        Logger.audio.debug("Audio interruption handling configured")
    }

    private func handleAudioInterruption(_ notification: Notification) {
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

        if !backgroundPlaying, !gongPlaying {
            self.coordinator.releaseAudioSession(for: .timer)
        }
    }

    /// Registers conflict handler to stop audio when another source becomes active
    private func registerConflictHandler() {
        self.coordinator.registerConflictHandler(for: .timer) { [weak self] in
            guard let self else {
                return
            }

            Logger.audio.info("Timer audio stopping - another source became active")
            self.audioPlayer?.stop()
            self.backgroundAudioPlayer?.stop()
            self.audioPlayer = nil
            self.backgroundAudioPlayer = nil
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
