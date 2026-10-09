//
//  MockedAppDependencies.swift
//  Still Moment
//
//  Test helper: an AppDependencies graph made of test doubles (ios-055).
//

import Foundation
@testable import StillMoment

/// An `AppDependencies` graph built from test doubles. The shared services are exposed
/// so tests can observe which screen talks to which shared service.
///
/// Like `AppDependencies.live()` in the app, the graph is built once: every read of
/// `dependencies` returns the same set of doubles.
@MainActor
struct MockedAppDependencies {
    // MARK: Lifecycle

    init() {
        let audioService = MockAudioService()
        let waveformProvider = MockWaveformProvider()
        let meditationService = MockGuidedMeditationService()
        let playerService = MockAudioPlayerService()

        self.audioService = audioService
        self.waveformProvider = waveformProvider
        self.meditationService = meditationService
        self.playerService = playerService
        self.dependencies = AppDependencies(
            audioService: audioService,
            timerService: MockTimerService(),
            clock: MockClock(),
            praxisRepository: MockPraxisRepository(),
            backgroundSoundRepository: MockBackgroundSoundRepository(),
            customAudioRepository: MockCustomAudioRepository(),
            soundscapeResolver: MockSoundscapeResolver(),
            meditationService: meditationService,
            metadataService: MockAudioMetadataService(),
            meditationSourceRepository: MockMeditationSourceRepository(),
            searchHistoryStore: MockSearchHistoryStore(),
            guidedSettingsRepository: MockGuidedMeditationSettingsRepository(),
            waveformProvider: waveformProvider,
            downloadService: MockAudioDownloadService(),
            makeGongPlayer: { MockMeditationGongPlayer() },
            // Deliberately the one shared mock, so tests can observe the player's playback.
            // Production creates a fresh service per player — tested on `live()` in AppDependenciesTests.
            makeAudioPlayerService: { playerService }
        )
    }

    // MARK: Internal

    let audioService: MockAudioService
    let waveformProvider: MockWaveformProvider
    let meditationService: MockGuidedMeditationService
    let playerService: MockAudioPlayerService
    let dependencies: AppDependencies
}
