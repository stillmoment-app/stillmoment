//
//  AudioService+Testing.swift
//  Still Moment
//
//  Test helper: builds a real AudioService wired like the app (ios-055).
//

import Foundation
@testable import StillMoment

extension AudioService {
    /// A real `AudioService` with bundled sounds and real custom-audio storage,
    /// wired the same way `AppDependencies.live()` wires it.
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
                customAudioRepository: CustomAudioRepository()
            ),
            fadeOutDuration: fadeOutDuration
        )
    }
}
