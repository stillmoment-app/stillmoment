//
//  AudioService+MeditationPreview.swift
//  Still Moment
//
//  Infrastructure - Audio Service Meditation Preview Extension
//

import AVFoundation
import OSLog

// MARK: - Meditation Preview

extension AudioService {
    func playMeditationPreview(fileURL: URL) throws {
        Logger.audio.info("Playing meditation preview", metadata: ["file": fileURL.lastPathComponent])

        // Stop any previous previews (mutual exclusion)
        self.stopMeditationPreview()
        self.stopGongPreview()
        self.stopBackgroundPreview()

        _ = try self.coordinator.requestAudioSession(for: .preview)

        do {
            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.volume = 0.9
            // Delegate fires when audio reaches end naturally — explicit stop() does not trigger it.
            let delegate = GongPlayerDelegate { [weak self] in
                self?.handleMeditationPreviewDidFinish()
            }
            player.delegate = delegate
            player.prepareToPlay()
            player.play()
            self.meditationPreviewPlayer = player
            self.meditationPreviewDelegate = delegate

            self.meditationPreviewDurationSubject.send(player.duration)
            self.meditationPreviewPositionSubject.send(player.currentTime)
            self.startMeditationPreviewPositionTimer()

            Logger.audio.info(
                "Meditation preview started",
                metadata: ["file": fileURL.lastPathComponent, "duration": "\(player.duration)"]
            )
        } catch {
            Logger.audio.error("Failed to play meditation preview", error: error)
            self.coordinator.releaseAudioSession(for: .preview)
            throw AudioServiceError.playbackFailed
        }
    }

    func stopMeditationPreview() {
        guard let player = self.meditationPreviewPlayer else {
            return
        }
        // Nil out immediately so a new preview can start during fade-out
        self.meditationPreviewPlayer = nil
        self.meditationPreviewDelegate = nil
        self.stopMeditationPreviewPositionTimer()
        self.meditationPreviewPositionSubject.send(0)
        self.meditationPreviewDurationSubject.send(0)
        Logger.audio.debug("Stopping meditation preview with fade-out")

        // Fade out over 0.3s, then cleanup the captured player instance
        player.setVolume(0, fadeDuration: self.fadeOutDuration)
        DispatchQueue.main.asyncAfter(deadline: .now() + self.fadeOutDuration) { [weak self] in
            player.stop()
            self?.coordinator.releaseAudioSession(for: .preview)
            Logger.audio.debug("Meditation preview fade-out complete")
        }
    }

    func seekMeditationPreview(to time: TimeInterval) {
        guard let player = self.meditationPreviewPlayer else {
            return
        }
        let clamped = max(0, min(time, player.duration))
        player.currentTime = clamped
        self.meditationPreviewPositionSubject.send(clamped)
    }
}

// MARK: - Private Helpers

private extension AudioService {
    /// Polls AVAudioPlayer.currentTime every 100 ms and pushes it to the position subject.
    /// Idle when no preview is active.
    func startMeditationPreviewPositionTimer() {
        self.stopMeditationPreviewPositionTimer()
        self.meditationPreviewTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { [weak self] _ in
            guard let self, let player = self.meditationPreviewPlayer else {
                return
            }
            self.meditationPreviewPositionSubject.send(player.currentTime)
        }
    }

    func stopMeditationPreviewPositionTimer() {
        self.meditationPreviewTimer?.invalidate()
        self.meditationPreviewTimer = nil
    }

    /// Called by the AVAudioPlayerDelegate when audio reaches the natural end.
    /// Treats it like a Stop tap — fade-out is unnecessary here, but using the same
    /// path keeps the lifecycle consistent (session release, subjects reset).
    func handleMeditationPreviewDidFinish() {
        Logger.audio.info("Meditation preview finished playing")
        self.stopMeditationPreview()
    }
}
