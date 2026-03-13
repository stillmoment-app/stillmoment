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
        self.stopIntroductionPreview()

        _ = try self.coordinator.requestAudioSession(for: .preview)

        do {
            self.meditationPreviewPlayer = try AVAudioPlayer(contentsOf: fileURL)
            self.meditationPreviewPlayer?.volume = 0.9
            self.meditationPreviewPlayer?.prepareToPlay()
            self.meditationPreviewPlayer?.play()
            Logger.audio.info(
                "Meditation preview started",
                metadata: ["file": fileURL.lastPathComponent]
            )
        } catch {
            Logger.audio.error("Failed to play meditation preview", error: error)
            self.coordinator.releaseAudioSession(for: .preview)
            throw AudioServiceError.playbackFailed
        }
    }

    func stopMeditationPreview() {
        guard self.meditationPreviewPlayer != nil else {
            return
        }
        Logger.audio.debug("Stopping meditation preview with fade-out")

        // Fade out over 0.3s, then cleanup
        self.meditationPreviewPlayer?.setVolume(0, fadeDuration: self.fadeOutDuration)
        DispatchQueue.main.asyncAfter(deadline: .now() + self.fadeOutDuration) { [weak self] in
            self?.meditationPreviewPlayer?.stop()
            self?.meditationPreviewPlayer = nil
            self?.coordinator.releaseAudioSession(for: .preview)
            Logger.audio.debug("Meditation preview fade-out complete")
        }
    }
}
