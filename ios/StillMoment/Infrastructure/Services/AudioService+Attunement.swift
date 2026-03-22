//
//  AudioService+Attunement.swift
//  Still Moment
//
//  Infrastructure - Audio Service Attunement Extension
//

import AVFoundation
import Combine
import OSLog

// MARK: - Attunement Audio

extension AudioService {
    var attunementCompletionPublisher: AnyPublisher<Void, Never> {
        self.attunementCompletionSubject.eraseToAnyPublisher()
    }

    func playAttunement(filename: String) throws {
        Logger.audio.info("Playing attunement audio", metadata: ["filename": filename])

        // Audio session is already active via activateTimerSession().
        // Keep-alive runs in parallel — no coordination needed.

        // Resolve sound URL: absolute path (custom attunement) or bundle resource
        let soundURL: URL
        if filename.hasPrefix("/") {
            // Absolute path: custom attunement from app storage
            let url = URL(fileURLWithPath: filename)
            guard FileManager.default.fileExists(atPath: filename) else {
                Logger.audio.error(
                    "Custom attunement audio file not found",
                    metadata: ["path": filename]
                )
                throw AudioServiceError.soundFileNotFound
            }
            soundURL = url
        } else {
            // Bundle resource: built-in attunement
            // Note: Bundle subdirectory remains "IntroductionAudio" (historical name, not renamed)
            let (name, ext) = self.parseFilename(filename)
            guard let url = Bundle.main.url(
                forResource: name,
                withExtension: ext,
                subdirectory: "IntroductionAudio"
            ) else {
                Logger.audio.error(
                    "Attunement audio file not found",
                    metadata: ["filename": filename]
                )
                throw AudioServiceError.soundFileNotFound
            }
            soundURL = url
        }

        do {
            self.attunementPlayer = try AVAudioPlayer(contentsOf: soundURL)
            self.attunementPlayer?.volume = 0.9
            self.attunementPlayer?.delegate = self.attunementPlayerDelegate
            self.attunementPlayer?.prepareToPlay()
            self.attunementPlayer?.play()

            Logger.audio.info("Attunement audio playing", metadata: ["filename": filename])
        } catch {
            Logger.audio.error("Failed to play attunement audio", error: error)
            throw AudioServiceError.playbackFailed
        }
    }

    func stopAttunement() {
        guard self.attunementPlayer != nil else {
            return
        }
        Logger.audio.debug("Stopping attunement audio")
        self.attunementPlayer?.stop()
        self.attunementPlayer = nil
    }

    func playAttunementPreview(attunementId: String) throws {
        Logger.audio.info("Playing attunement preview", metadata: ["attunementId": attunementId])

        // Stop any previous previews (mutual exclusion)
        self.stopAttunementPreview()
        self.stopGongPreview()
        self.stopBackgroundPreview()
        self.stopMeditationPreview()

        _ = try self.coordinator.requestAudioSession(for: .preview)

        let soundURL = try self.resolveAttunementPreviewURL(attunementId: attunementId)

        do {
            self.attunementPreviewPlayer = try AVAudioPlayer(contentsOf: soundURL)
            self.attunementPreviewPlayer?.volume = 0.9
            self.attunementPreviewPlayer?.prepareToPlay()
            self.attunementPreviewPlayer?.play()
            Logger.audio.info(
                "Attunement preview started",
                metadata: ["file": soundURL.lastPathComponent]
            )
        } catch {
            Logger.audio.error("Failed to play attunement preview", error: error)
            throw AudioServiceError.playbackFailed
        }
    }

    func stopAttunementPreview() {
        guard self.attunementPreviewPlayer != nil else {
            return
        }
        Logger.audio.debug("Stopping attunement preview")
        self.attunementPreviewPlayer?.stop()
        self.attunementPreviewPlayer = nil
        self.coordinator.releaseAudioSession(for: .preview)
    }
}

// MARK: - Attunement Preview URL Resolution

private extension AudioService {
    func resolveAttunementPreviewURL(attunementId: String) throws -> URL {
        try self.attunementResolver.resolveAudioURL(id: attunementId)
    }
}

// MARK: - AttunementPlayerDelegate

/// AVAudioPlayerDelegate that notifies when attunement audio finishes playing.
/// Manual stop (via stopAttunement) does NOT trigger audioPlayerDidFinishPlaying.
/// Always fires onFinish — even on interruption (successfully: false) — to prevent
/// the state machine from getting stuck in `.attunement`.
class AttunementPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        self.onFinish()
    }
}
