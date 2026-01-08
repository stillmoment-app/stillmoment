//
//  AudioPlayerService.swift
//  Still Moment
//
//  Infrastructure - Audio Player Service
//

import AVFoundation
import Combine
import MediaPlayer
import OSLog

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

    init(
        coordinator: AudioSessionCoordinatorProtocol,
        nowPlayingProvider: NowPlayingInfoProvider = SystemNowPlayingInfoProvider()
    ) {
        self.coordinator = coordinator
        self.nowPlayingProvider = nowPlayingProvider
        super.init()
        self.setupNotifications()
        self.registerConflictHandler()
    }

    override convenience init() {
        self.init(coordinator: AudioSessionCoordinator.shared)
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
        self.player = AVPlayer(playerItem: playerItem)

        // Store meditation for lock screen display
        self.currentMeditation = meditation

        // Wait for player to be ready
        guard self.player != nil else {
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

            // iOS REQUIREMENT: Now Playing info MUST be set AFTER audio session is activated.
            // Setting Now Playing info before session activation can cause:
            // - Lock screen controls to not appear
            // - Metadata to not display correctly
            // - Inconsistent behavior across iOS versions
            // Solution: Defer setup to play() method where session is guaranteed active.

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

        // Request exclusive audio session from coordinator
        // This activates the audio session before we configure lock screen controls
        _ = try self.coordinator.requestAudioSession(for: .guidedMeditation)

        // iOS REQUIREMENT: Setup remote commands AFTER audio session is active
        // One-time configuration: Use flag to prevent duplicate setup on subsequent play calls
        // Rationale: Remote Command Center must be configured while session is active,
        // but reconfiguring on every pause/resume is unnecessary and could cause issues
        if !self.remoteCommandsConfigured {
            self.setupRemoteCommandCenter()
            self.remoteCommandsConfigured = true
            Logger.audio.info("Remote command center configured (session active)")
        }

        // iOS REQUIREMENT: Setup Now Playing info AFTER audio session is active
        // Setting Now Playing before session activation causes:
        // - Lock screen controls may not appear
        // - Metadata may not display correctly
        // This is why we deferred setup from load() to play()
        if let meditation = currentMeditation {
            self.setupNowPlayingInfo(for: meditation, duration: self.duration.value)
            Logger.audio.info("Now Playing info configured (session active)")
        }

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
        self.clearNowPlayingInfo()
        self.disableRemoteCommandCenter()
        self.coordinator.releaseAudioSession(for: .guidedMeditation)
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
        // Request audio session through coordinator
        _ = try self.coordinator.requestAudioSession(for: .guidedMeditation)
    }

    func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        self.setupPlayPauseCommands(commandCenter)
        self.setupSeekCommands(commandCenter)
        self.setupSkipCommands(commandCenter)
    }

    private func setupPlayPauseCommands(_ commandCenter: MPRemoteCommandCenter) {
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            try? self?.play()
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        // Toggle command for wired headphones (EarPods) and some CarPlay configurations
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else {
                return .commandFailed
            }
            self.state.value == .playing ? self.pause() : (try? self.play())
            return .success
        }
    }

    private func setupSeekCommands(_ commandCenter: MPRemoteCommandCenter) {
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            try? self?.seek(to: event.positionTime)
            return .success
        }
    }

    private func setupSkipCommands(_ commandCenter: MPRemoteCommandCenter) {
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            guard let self, self.player != nil else {
                return .commandFailed
            }
            let newTime = min(self.currentTime.value + 15, self.duration.value)
            try? self.seek(to: newTime)
            return .success
        }

        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            guard let self, self.player != nil else {
                return .commandFailed
            }
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
        self.nowPlayingProvider.nowPlayingInfo = nil

        // Disable remote command center to prevent ghost lock screen UI
        self.disableRemoteCommandCenter()

        // Reset flag to allow remote commands to be configured on next playback session
        // This is necessary because cleanup fully disables commands, and the next
        // load() → play() cycle needs to reconfigure them from scratch
        self.remoteCommandsConfigured = false

        // Release audio session
        self.coordinator.releaseAudioSession(for: .guidedMeditation)
    }

    // MARK: Private

    private let coordinator: AudioSessionCoordinatorProtocol
    private let nowPlayingProvider: NowPlayingInfoProvider
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var currentMeditation: GuidedMeditation?
    private var cancellables = Set<AnyCancellable>()

    /// Tracks whether Remote Command Center has been configured for current playback session.
    /// Reset to false in cleanup() to allow reconfiguration after full cleanup.
    /// Prevents duplicate configuration on pause/resume cycles within same session.
    private var remoteCommandsConfigured = false

    /// Disables all remote command center controls
    private func disableRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.togglePlayPauseCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false

        // Remove all targets to clean up properly
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
    }

    // MARK: - Private Helpers

    private func setupTimeObserver() {
        guard let player else {
            return
        }

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

        self.nowPlayingProvider.nowPlayingInfo = nowPlayingInfo
    }

    private func updateNowPlayingPlaybackInfo() {
        guard var nowPlayingInfo = self.nowPlayingProvider.nowPlayingInfo else {
            return
        }

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime.value
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.state.value == .playing ? 1.0 : 0.0

        self.nowPlayingProvider.nowPlayingInfo = nowPlayingInfo
    }

    /// Clears Now Playing info from lock screen and control center
    private func clearNowPlayingInfo() {
        self.nowPlayingProvider.nowPlayingInfo = nil
    }

    private func handlePlaybackFinished() {
        self.state.send(.finished)
        self.currentTime.send(self.duration.value)

        // Clear lock screen widget when playback finishes naturally
        self.clearNowPlayingInfo()
        self.disableRemoteCommandCenter()

        // Release audio session when playback finishes
        self.coordinator.releaseAudioSession(for: .guidedMeditation)
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

    /// Handles audio session conflict by pausing playback and clearing lock screen info
    private func stopForAudioSessionConflict() {
        self.pause()
        self.clearNowPlayingInfo()
        self.disableRemoteCommandCenter()
        // Release audio session to prevent energy waste and ensure clean ownership transfer
        self.coordinator.releaseAudioSession(for: .guidedMeditation)
    }

    /// Registers conflict handler to stop playback when another source becomes active
    private func registerConflictHandler() {
        self.coordinator.registerConflictHandler(for: .guidedMeditation) { [weak self] in
            guard let self else {
                return
            }

            Logger.audio.info("Guided meditation stopping - another source became active")
            self.stopForAudioSessionConflict()
        }
    }
}
