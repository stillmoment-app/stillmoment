//
//  AudioPlayerService+Gong.swift
//  Still Moment
//
//  Infrastructure - End gong for guided meditations (shared-106)
//

import Foundation
import OSLog

extension AudioPlayerService {
    /// Stores the end gong configuration; `handlePlaybackFinished()` picks it up.
    func configureEndGong(soundId: String, volume: Float) {
        self.endGongConfiguration = (soundId: soundId, volume: volume)
        Logger.audio.info(
            "End gong configured",
            metadata: ["soundId": soundId, "volume": "\(volume)"]
        )
    }

    /// Releases the audio session after playback finished — once the end gong rang out.
    ///
    /// Without a configured gong the session is released immediately (previous
    /// behavior). With a gong, the session stays active while the gong plays so it
    /// remains audible on the lock screen; only the completion callback releases it.
    func releaseSessionAfterEndGong() {
        guard let config = self.endGongConfiguration else {
            self.coordinator.releaseAudioSession(for: .guidedMeditation)
            return
        }

        self.gongPlayer.play(soundId: config.soundId, volume: config.volume) { [weak self] in
            guard let self else {
                return
            }
            // A restart during the gong ring re-requested the session — keep it then
            guard self.state.value == .finished else {
                return
            }
            self.coordinator.releaseAudioSession(for: .guidedMeditation)
            Logger.audio.info("Audio session released after end gong")
        }
    }
}
