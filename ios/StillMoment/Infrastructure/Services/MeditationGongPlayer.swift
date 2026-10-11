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
    // MARK: Lifecycle

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    // MARK: Internal

    func play(soundId: String, volume: Float, completion: @escaping () -> Void) {
        // A new gong replaces one still ringing (its completion is dropped, as with stop())
        self.stop()
        self.pendingCompletion = completion

        if soundId == GongSound.vibrationId {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            self.finish()
            return
        }

        guard let soundURL = Self.soundURL(forSoundId: soundId) else {
            Logger.audio.error("Meditation gong sound not found", metadata: ["soundId": soundId])
            self.finish()
            return
        }

        do {
            try self.startPlayer(url: soundURL, volume: volume)
            Logger.audio.info(
                "Meditation gong playing",
                metadata: ["soundId": soundId, "volume": "\(volume)"]
            )
        } catch {
            Logger.audio.error("Failed to play meditation gong", error: error, metadata: ["soundId": soundId])
            self.finish()
        }
    }

    func stop() {
        // The pending completion is dropped on purpose — as documented in the protocol.
        self.pendingCompletion = nil
        self.releasePlayer()
    }

    // MARK: Private

    private let notificationCenter: NotificationCenter
    private var player: AVAudioPlayer?
    private var delegate: GongPlayerDelegate?
    private var interruptionObserver: NSObjectProtocol?

    /// Completion of the gong currently ringing; nil once it fired or the gong was stopped.
    private var pendingCompletion: (() -> Void)?

    /// Plays the gong file; its end, an interruption or a failure finishes the gong.
    private func startPlayer(url: URL, volume: Float) throws {
        let player = try AVAudioPlayer(contentsOf: url)
        // AVAudioPlayer.delegate is weak — keep a strong reference alongside the player
        let delegate = GongPlayerDelegate { [weak self] in
            self?.finish()
        }
        player.volume = volume
        player.delegate = delegate
        player.prepareToPlay()
        self.player = player
        self.delegate = delegate
        self.observeInterruption()
        guard player.play() else {
            throw GongPlaybackError.didNotStart
        }
    }

    /// An interruption (phone call, Siri) pauses AVAudioPlayer without ever calling
    /// `audioPlayerDidFinishPlaying` — the gong counts as over then, so the flow does
    /// not get stuck before the meditation begins (shared-143).
    private func observeInterruption() {
        self.interruptionObserver = self.notificationCenter.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: rawType) == .began
            else {
                return
            }
            Logger.audio.info("Meditation gong interrupted")
            self?.finish()
        }
    }

    /// Ends the gong and fires its completion exactly once, on the main thread.
    private func finish() {
        guard let completion = self.pendingCompletion else {
            return
        }
        self.pendingCompletion = nil
        self.releasePlayer()
        DispatchQueue.main.async {
            completion()
        }
    }

    private func releasePlayer() {
        if let observer = self.interruptionObserver {
            self.notificationCenter.removeObserver(observer)
            self.interruptionObserver = nil
        }
        // AVAudioPlayer.stop() does not fire audioPlayerDidFinishPlaying
        self.player?.stop()
        self.player = nil
        self.delegate = nil
    }

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

/// Reasons a gong could not be played — logged, then the gong counts as finished.
private enum GongPlaybackError: Error {
    /// AVAudioPlayer refused to start (e.g. no usable audio session).
    case didNotStart
}
