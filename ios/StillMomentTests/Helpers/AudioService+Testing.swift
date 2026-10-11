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
    static func makeForTesting(
        coordinator: AudioSessionCoordinatorProtocol = AudioSessionCoordinator.shared,
        fadeOutDuration: TimeInterval = 0.5
    ) -> AudioService {
        let soundRepository = BackgroundSoundRepository()
        return AudioService(
            coordinator: coordinator,
            soundRepository: soundRepository,
            soundscapeResolver: SoundscapeResolver(
                soundRepository: soundRepository,
                customAudioRepository: MockCustomAudioRepository()
            ),
            fadeOutDuration: fadeOutDuration
        )
    }
}
