//
//  AudioService+Introduction.swift
//  Still Moment
//
//  Infrastructure - Audio Service Introduction Extension
//

import AVFoundation
import Combine
import OSLog

// MARK: - Introduction Audio

extension AudioService {
    var introductionCompletionPublisher: AnyPublisher<Void, Never> {
        self.introductionCompletionSubject.eraseToAnyPublisher()
    }

    func playIntroduction(filename: String) throws {
        Logger.audio.info("Playing introduction audio", metadata: ["filename": filename])

        // Audio session is already active via activateTimerSession().
        // Keep-alive runs in parallel — no coordination needed.

        // Resolve sound URL: absolute path (custom attunement) or bundle resource
        let soundURL: URL
        if filename.hasPrefix("/") {
            // Absolute path: custom attunement from app storage
            let url = URL(fileURLWithPath: filename)
            guard FileManager.default.fileExists(atPath: filename) else {
                Logger.audio.error(
                    "Custom introduction audio file not found",
                    metadata: ["path": filename]
                )
                throw AudioServiceError.soundFileNotFound
            }
            soundURL = url
        } else {
            // Bundle resource: built-in introduction
            let (name, ext) = self.parseFilename(filename)
            guard let url = Bundle.main.url(
                forResource: name,
                withExtension: ext,
                subdirectory: "IntroductionAudio"
            ) else {
                Logger.audio.error(
                    "Introduction audio file not found",
                    metadata: ["filename": filename]
                )
                throw AudioServiceError.soundFileNotFound
            }
            soundURL = url
        }

        do {
            self.introductionPlayer = try AVAudioPlayer(contentsOf: soundURL)
            self.introductionPlayer?.volume = 0.9
            self.introductionPlayer?.delegate = self.introductionPlayerDelegate
            self.introductionPlayer?.prepareToPlay()
            self.introductionPlayer?.play()

            Logger.audio.info("Introduction audio playing", metadata: ["filename": filename])
        } catch {
            Logger.audio.error("Failed to play introduction audio", error: error)
            throw AudioServiceError.playbackFailed
        }
    }

    func stopIntroduction() {
        guard self.introductionPlayer != nil else {
            return
        }
        Logger.audio.debug("Stopping introduction audio")
        self.introductionPlayer?.stop()
        self.introductionPlayer = nil
    }

    func playIntroductionPreview(introductionId: String) throws {
        Logger.audio.info("Playing introduction preview", metadata: ["introductionId": introductionId])

        // Stop any previous previews (mutual exclusion)
        self.stopIntroductionPreview()
        self.stopGongPreview()
        self.stopBackgroundPreview()

        _ = try self.coordinator.requestAudioSession(for: .preview)

        let soundURL = try self.resolveIntroductionPreviewURL(introductionId: introductionId)

        do {
            self.introductionPreviewPlayer = try AVAudioPlayer(contentsOf: soundURL)
            self.introductionPreviewPlayer?.volume = 0.9
            self.introductionPreviewPlayer?.prepareToPlay()
            self.introductionPreviewPlayer?.play()
            Logger.audio.info(
                "Introduction preview started",
                metadata: ["file": soundURL.lastPathComponent]
            )
        } catch {
            Logger.audio.error("Failed to play introduction preview", error: error)
            throw AudioServiceError.playbackFailed
        }
    }

    func stopIntroductionPreview() {
        guard self.introductionPreviewPlayer != nil else {
            return
        }
        Logger.audio.debug("Stopping introduction preview")
        self.introductionPreviewPlayer?.stop()
        self.introductionPreviewPlayer = nil
        self.coordinator.releaseAudioSession(for: .preview)
    }
}

// MARK: - Introduction Preview URL Resolution

private extension AudioService {
    func resolveIntroductionPreviewURL(introductionId: String) throws -> URL {
        try self.attunementResolver.resolveAudioURL(id: introductionId)
    }
}

// MARK: - IntroductionPlayerDelegate

/// AVAudioPlayerDelegate that notifies when introduction audio finishes playing.
/// Manual stop (via stopIntroduction) does NOT trigger audioPlayerDidFinishPlaying.
/// Always fires onFinish — even on interruption (successfully: false) — to prevent
/// the state machine from getting stuck in `.introduction`.
class IntroductionPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        self.onFinish()
    }
}
