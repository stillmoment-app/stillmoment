//
//  MeditationGongPlayer.swift
//  Still Moment
//
//  Infrastructure - Per-Meditation Gong Player (shared-106)
//

import AudioToolbox
import AVFoundation
import Foundation
import OSLog

/// Plays the start/end gong for guided meditations via AVAudioPlayer.
///
/// Expects an already active audio session (silent keep-alive or main playback) —
/// it never requests or releases the session itself. Session lifecycle stays with
/// AudioPlayerService so the gong is audible on the lock screen.
final class MeditationGongPlayer: MeditationGongPlayerProtocol {
    // MARK: Internal

    func play(soundId: String, volume: Float, completion: @escaping () -> Void) {
        if soundId == GongSound.vibrationId {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            DispatchQueue.main.async {
                completion()
            }
            return
        }

        guard let soundURL = Self.soundURL(forSoundId: soundId) else {
            Logger.audio.error("Meditation gong sound not found", metadata: ["soundId": soundId])
            DispatchQueue.main.async {
                completion()
            }
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            // AVAudioPlayer.delegate is weak — keep a strong reference alongside the player
            let delegate = GongPlayerDelegate {
                DispatchQueue.main.async {
                    completion()
                }
            }
            player.volume = volume
            player.delegate = delegate
            player.prepareToPlay()
            player.play()
            self.player = player
            self.delegate = delegate
            Logger.audio.info(
                "Meditation gong playing",
                metadata: ["soundId": soundId, "volume": "\(volume)"]
            )
        } catch {
            Logger.audio.error("Failed to play meditation gong", error: error, metadata: ["soundId": soundId])
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func stop() {
        // AVAudioPlayer.stop() does not fire audioPlayerDidFinishPlaying,
        // so the pending completion is silently dropped — as documented.
        self.player?.stop()
        self.player = nil
        self.delegate = nil
    }

    // MARK: Private

    private var player: AVAudioPlayer?
    private var delegate: GongPlayerDelegate?

    /// Resolves the bundle URL: soft-interval tone lives in root Resources, all
    /// other gongs in GongSounds/ (same layout as AudioService.playGongSound).
    private static func soundURL(forSoundId soundId: String) -> URL? {
        let gongSound = GongSound.findOrDefault(byId: soundId)
        let components = gongSound.filename.components(separatedBy: ".")
        let name = components.first ?? gongSound.filename
        let ext = components.count > 1 ? components.last : nil

        if gongSound.id == "soft-interval" {
            return Bundle.main.url(forResource: name, withExtension: ext)
        }
        return Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "GongSounds")
    }
}
