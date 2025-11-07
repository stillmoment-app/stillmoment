//
//  AudioPlayerService.swift
//  MediTimer
//
//  Infrastructure - Audio Player Service
//

import AVFoundation
import Combine
import MediaPlayer

/// Concrete implementation of AudioPlayerServiceProtocol
///
/// Provides audio playback with:
/// - Background audio support
/// - Lock screen controls via Remote Command Center
/// - Progress tracking
/// - Now Playing metadata display
final class AudioPlayerService: NSObject, AudioPlayerServiceProtocol {
    // MARK: Lifecycle

    // MARK: - Initialization

    override init() {
        super.init()
        self.setupNotifications()
    }

    // MARK: Internal

    let state = CurrentValueSubject<PlaybackState, Never>(.idle)
    let currentTime = CurrentValueSubject<TimeInterval, Never>(0)
    let duration = CurrentValueSubject<TimeInterval, Never>(0)

    // MARK: - AudioPlayerServiceProtocol

    func load(url: URL, meditation: GuidedMeditation) async throws {
        self.state.send(.loading)

        // Clean up previous player
        self.cleanup()

        // Create new player
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        // Store meditation for lock screen display
        self.currentMeditation = meditation

        // Wait for player to be ready
        guard let player else {
            throw AudioPlayerError.playbackFailed(reason: "Failed to create player")
        }

        // Observe player status
        do {
            let status = try await playerItem.asset.load(.duration)
            let durationSeconds = status.seconds
            guard durationSeconds.isFinite, durationSeconds > 0 else {
                throw AudioPlayerError.invalidAudioFormat
            }

            self.duration.send(durationSeconds)

            // Setup time observer for progress tracking
            self.setupTimeObserver()

            // Setup now playing info
            self.setupNowPlayingInfo(for: meditation, duration: durationSeconds)

            self.state.send(.paused)
        } catch {
            self.state.send(.failed(AudioPlayerError.playbackFailed(reason: error.localizedDescription)))
            throw AudioPlayerError.playbackFailed(reason: error.localizedDescription)
        }

        // Observe playback end
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .sink { [weak self] _ in
                self?.handlePlaybackFinished()
            }
            .store(in: &self.cancellables)
    }

    func play() throws {
        guard let player else {
            throw AudioPlayerError.playbackFailed(reason: "No audio loaded")
        }

        try self.configureAudioSession() // Ensure session is active
        player.play()
        self.state.send(.playing)
        self.updateNowPlayingPlaybackInfo()
    }

    func pause() {
        self.player?.pause()
        self.state.send(.paused)
        self.updateNowPlayingPlaybackInfo()
    }

    func stop() {
        self.player?.pause()
        self.player?.seek(to: .zero)
        self.currentTime.send(0)
        self.state.send(.idle)
        self.updateNowPlayingPlaybackInfo()

        // Deactivate audio session to save energy when player is stopped
        self.deactivateAudioSession()
    }

    func seek(to time: TimeInterval) throws {
        guard let player else {
            throw AudioPlayerError.playbackFailed(reason: "No audio loaded")
        }

        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime) { [weak self] finished in
            if finished {
                self?.currentTime.send(time)
                self?.updateNowPlayingPlaybackInfo()
            }
        }
    }

    func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()

        // Only configure if not already active to avoid conflicts
        if audioSession.category == .playback {
            return
        }

        do {
            // Configure for playback with background audio support
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            throw AudioPlayerError.audioSessionFailed
        }
    }

    func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            try? self?.play()
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        // Change playback position command
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            try? self?.seek(to: event.positionTime)
            return .success
        }

        // Skip forward/backward (optional, 15 seconds)
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            guard let self, let player = self.player else { return .commandFailed }
            let newTime = min(self.currentTime.value + 15, self.duration.value)
            try? self.seek(to: newTime)
            return .success
        }

        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            guard let self, let player = self.player else { return .commandFailed }
            let newTime = max(self.currentTime.value - 15, 0)
            try? self.seek(to: newTime)
            return .success
        }
    }

    func cleanup() {
        // Remove time observer
        if let token = timeObserverToken {
            self.player?.removeTimeObserver(token)
            self.timeObserverToken = nil
        }

        // Stop player
        self.player?.pause()
        self.player = nil

        // Clear state
        self.currentMeditation = nil
        self.cancellables.removeAll()
        self.currentTime.send(0)
        self.duration.send(0)

        // Clear now playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: Private

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var currentMeditation: GuidedMeditation?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Helpers

    private func setupTimeObserver() {
        guard let player else { return }

        // Update current time every 0.5 seconds
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        self.timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            let seconds = time.seconds
            if seconds.isFinite {
                self?.currentTime.send(seconds)
                self?.updateNowPlayingPlaybackInfo()
            }
        }
    }

    private func setupNowPlayingInfo(for meditation: GuidedMeditation, duration: TimeInterval) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = meditation.effectiveName
        nowPlayingInfo[MPMediaItemPropertyArtist] = meditation.effectiveTeacher
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func updateNowPlayingPlaybackInfo() {
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            return
        }

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime.value
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.state.value == .playing ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func handlePlaybackFinished() {
        self.state.send(.finished)
        self.currentTime.send(self.duration.value)
        self.updateNowPlayingPlaybackInfo()
    }

    private func setupNotifications() {
        // Handle audio session interruptions (e.g., phone call)
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                self?.handleAudioInterruption(notification)
            }
            .store(in: &self.cancellables)
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
            // Interruption began, pause playback
            self.pause()
        case .ended:
            // Interruption ended, optionally resume playback
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                try? self.play()
            }
        @unknown default:
            break
        }
    }

    /// Deactivates the audio session to save energy
    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Silently ignore - not critical
        }
    }
}
