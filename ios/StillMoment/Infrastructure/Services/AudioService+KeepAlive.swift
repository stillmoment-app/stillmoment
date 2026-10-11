//
//  AudioService+KeepAlive.swift
//  Still Moment
//
//  Infrastructure - Keep-Alive Audio Management
//
//  Keep-alive plays silence.mp3 in a loop to prevent iOS from suspending the app
//  during silent phases (Preparation, transitions between audio). See ADR-004.
//

import AVFoundation
import OSLog

// MARK: - Keep-Alive Diagnostics

extension AudioService {
    /// Whether the keep-alive audio is currently playing. Used for diagnostics and testing.
    var isKeepAliveActive: Bool {
        self.keepAlivePlayer?.isPlaying ?? false
    }
}

// MARK: - Keep-Alive Audio

extension AudioService {
    func startKeepAliveAudio(retryCount: Int = 0) {
        guard self.keepAlivePlayer == nil else {
            return
        }

        guard let url = Bundle.main.url(
            forResource: "silence",
            withExtension: "mp3",
            subdirectory: "BackgroundAudio"
        ) else {
            Logger.audio.error("Keep-alive audio file not found in bundle")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.05
            player.prepareToPlay()

            if player.play() {
                // Assign only after confirmed playback — prevents false guard passes on retry
                self.keepAlivePlayer = player
                Logger.audio.info("Keep-alive audio started", metadata: ["attempt": "\(retryCount + 1)"])
            } else if retryCount < 2 {
                Logger.audio.warning(
                    "Keep-alive play() returned false, scheduling retry",
                    metadata: ["attempt": "\(retryCount + 1)"]
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self, self.timerSessionActive, self.keepAlivePlayer == nil else {
                        return
                    }
                    self.startKeepAliveAudio(retryCount: retryCount + 1)
                }
            } else {
                Logger.audio.error("Keep-alive audio failed to start after 3 attempts — app may be suspended")
            }
        } catch {
            Logger.audio.error("Failed to create keep-alive player", error: error)
        }
    }

    func restartKeepAliveAfterInterruption() {
        if let player = self.keepAlivePlayer, !player.isPlaying {
            if player.play() {
                Logger.audio.info("Keep-alive resumed after interruption")
            } else {
                // Player failed to resume — clear it so startKeepAliveAudio creates a fresh one
                self.keepAlivePlayer = nil
                self.startKeepAliveAudio()
            }
        } else if self.keepAlivePlayer == nil {
            self.startKeepAliveAudio()
            Logger.audio.info("Keep-alive restarted after interruption")
        }
    }

    func stopKeepAliveAudio() {
        guard self.keepAlivePlayer != nil else {
            return
        }
        self.keepAlivePlayer?.stop()
        self.keepAlivePlayer = nil
        Logger.audio.debug("Keep-alive audio stopped")
    }
}
