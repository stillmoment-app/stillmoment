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

        try self.configureAudioSession() // Ensure session is active

        // Parse filename and find in IntroductionAudio directory
        let (name, ext) = self.parseFilename(filename)
        guard let soundURL = Bundle.main.url(
            forResource: name,
            withExtension: ext,
            subdirectory: "IntroductionAudio"
        ) else {
            Logger.audio.error("Introduction audio file not found", metadata: ["filename": filename])
            throw AudioServiceError.soundFileNotFound
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
