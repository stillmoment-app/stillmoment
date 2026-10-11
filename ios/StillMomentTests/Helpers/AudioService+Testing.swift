//
//  AudioService+Testing.swift
//  Still Moment
//
//  Test helper: builds a real AudioService wired like the app (ios-055).
//

import Foundation
@testable import StillMoment

extension AudioService {
    /// A real `AudioService` with bundled sounds, wired the same way `AppDependencies.live()`
    /// wires it — but without imported soundscapes, so it never reads the app's own storage (ios-056).
    ///
    /// Without a `coordinator` it gets a fresh one of its own, never the app's (ios-058). Tests where
    /// several audio sources meet must pass the same coordinator to each of them.
    static func makeForTesting(
        coordinator: AudioSessionCoordinatorProtocol = AudioSessionCoordinator(),
        fadeOutDuration: TimeInterval = 0.5,
        notificationCenter: NotificationCenter = .default
    ) -> AudioService {
        let soundRepository = BackgroundSoundRepository()
        return AudioService(
            coordinator: coordinator,
            soundRepository: soundRepository,
            soundscapeResolver: SoundscapeResolver(
                soundRepository: soundRepository,
                customAudioRepository: MockCustomAudioRepository()
            ),
            fadeOutDuration: fadeOutDuration,
            notificationCenter: notificationCenter
        )
    }

    /// Whether the timer's background sound is currently playing
    var isBackgroundAudioPlaying: Bool {
        self.backgroundAudioPlayer?.isPlaying ?? false
    }

    /// Whether a start, interval or end gong of the timer is currently playing
    var isTimerGongPlaying: Bool {
        self.audioPlayer?.isPlaying ?? false
    }
}
