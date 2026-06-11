//
//  AudioPlayerService+LockScreen.swift
//  Still Moment
//
//  Infrastructure - Lock screen integration (Remote Command Center + Now Playing)
//

import MediaPlayer
import UIKit

// MARK: - Remote Command Center

extension AudioPlayerService {
    func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        self.setupPlayPauseCommands(commandCenter)
        self.setupSeekCommands(commandCenter)
        self.setupSkipCommands(commandCenter)
    }

    /// Disables all remote command center controls
    func disableRemoteCommandCenter() {
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
            guard let self, let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            // Lock screen position is relative to the effective (trimmed) range
            let start = self.currentMeditation?.effectiveStart ?? 0
            try? self.seek(to: event.positionTime + start)
            return .success
        }
    }

    private func setupSkipCommands(_ commandCenter: MPRemoteCommandCenter) {
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            guard let self else {
                return .commandFailed
            }
            let newTime = min(self.currentTime.value + 15, self.duration.value)
            do {
                try self.seek(to: newTime)
            } catch {
                return .commandFailed
            }
            return .success
        }

        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            guard let self else {
                return .commandFailed
            }
            let newTime = max(self.currentTime.value - 15, 0)
            do {
                try self.seek(to: newTime)
            } catch {
                return .commandFailed
            }
            return .success
        }
    }
}

// MARK: - Now Playing Info

extension AudioPlayerService {
    func setupNowPlayingInfo(for meditation: GuidedMeditation, duration: TimeInterval) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = meditation.name
        nowPlayingInfo[MPMediaItemPropertyArtist] = meditation.teacher
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0

        if let artworkImage = UIImage(named: "LockScreenArtwork") {
            let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in artworkImage }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        self.nowPlayingProvider.nowPlayingInfo = nowPlayingInfo
    }

    func updateNowPlayingPlaybackInfo() {
        guard var nowPlayingInfo = self.nowPlayingProvider.nowPlayingInfo else {
            return
        }

        // Lock screen shows time relative to the effective (trimmed) range
        let start = self.currentMeditation?.effectiveStart ?? 0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = max(self.currentTime.value - start, 0)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.state.value == .playing ? 1.0 : 0.0

        self.nowPlayingProvider.nowPlayingInfo = nowPlayingInfo
    }

    /// Clears Now Playing info from lock screen and control center
    func clearNowPlayingInfo() {
        self.nowPlayingProvider.nowPlayingInfo = nil
    }
}
