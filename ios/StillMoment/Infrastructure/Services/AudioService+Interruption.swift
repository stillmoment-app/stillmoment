//
//  AudioService+Interruption.swift
//  Still Moment
//
//  Infrastructure - Timer audio during interruptions (phone call, Siri, alarm)
//

import AVFoundation
import OSLog

// MARK: - Audio Interruption Handling

extension AudioService {
    func setupAudioInterruptionHandling() {
        self.notificationCenter.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                self?.handleAudioInterruption(notification)
            }
            .store(in: &self.cancellables)

        Logger.audio.debug("Audio interruption handling configured")
    }

    func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }

        switch type {
        case .began:
            // Only a late report that the app was suspended, not a real interruption
            guard userInfo[AVAudioSessionInterruptionWasSuspendedKey] as? Bool != true else {
                return
            }
            self.handleInterruptionBegan()

        case .ended:
            // A missing AVAudioSessionInterruptionOptionKey means the sound was not given back.
            let optionsValue = (userInfo[AVAudioSessionInterruptionOptionKey] as? UInt) ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            self.handleInterruptionEnded(soundGivenBack: options.contains(.shouldResume))

        @unknown default:
            Logger.audio.warning("Unknown audio interruption type")
        }
    }

    /// The system silences the timer's audio. A ringing gong counts as over, so the timer
    /// never waits for it; the gong is not played again afterwards (shared-147).
    private func handleInterruptionBegan() {
        Logger.audio.info("Audio interruption began")
        self.backgroundAudioPlayer?.pause()
        self.finishTimerGong()
    }

    /// Keep-alive comes back whenever a timer session is active — timerSessionActive is false
    /// after a reset, the end of the timer or a takeover by another source, so nothing restarts
    /// then. The background sound only comes back when the system gives the sound back.
    private func handleInterruptionEnded(soundGivenBack: Bool) {
        Logger.audio.info("Audio interruption ended", metadata: ["shouldResume": "\(soundGivenBack)"])
        guard self.timerSessionActive else {
            return
        }
        self.restartKeepAliveAfterInterruption()
        if soundGivenBack {
            self.resumeBackgroundAudioAfterInterruption()
        }
    }

    /// Fades the background sound back in. Also covers a sound that was meant to start
    /// during the interruption but could not.
    private func resumeBackgroundAudioAfterInterruption() {
        guard let player = self.backgroundAudioPlayer, !player.isPlaying else {
            return
        }
        player.volume = 0
        guard player.play() else {
            Logger.audio.warning("Background audio could not resume after interruption")
            return
        }
        player.setVolume(self.targetVolume, fadeDuration: Self.fadeInDuration)
        Logger.audio.info("Background audio resumed after interruption")
    }
}

// MARK: - Gong End

extension AudioService {
    /// Ends the timer gong and reports it exactly once — whether it rang out, was interrupted
    /// or could not start (same rule as `MeditationGongPlayer`, shared-143/shared-147).
    func finishTimerGong() {
        guard self.timerGongRinging else {
            return
        }
        self.timerGongRinging = false
        // AVAudioPlayer.stop() does not fire audioPlayerDidFinishPlaying
        self.audioPlayer?.stop()
        self.audioPlayer = nil
        self.gongCompletionSubject.send()
    }
}
