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
@MainActor
struct MockedAppDependencies {
    let audioService = MockAudioService()
    let waveformProvider = MockWaveformProvider()
    let meditationService = MockGuidedMeditationService()
    let playerService = MockAudioPlayerService()

    var dependencies: AppDependencies {
        let playerService = self.playerService
        return AppDependencies(
            audioService: self.audioService,
            timerService: MockTimerService(),
            clock: MockClock(),
            praxisRepository: MockPraxisRepository(),
            backgroundSoundRepository: MockBackgroundSoundRepository(),
            customAudioRepository: MockCustomAudioRepository(),
            soundscapeResolver: MockSoundscapeResolver(),
            meditationService: self.meditationService,
            metadataService: MockAudioMetadataService(),
            meditationSourceRepository: MockMeditationSourceRepository(),
            searchHistoryStore: MockSearchHistoryStore(),
            guidedSettingsRepository: MockGuidedMeditationSettingsRepository(),
            waveformProvider: self.waveformProvider,
            downloadService: MockAudioDownloadService(),
            makeGongPlayer: { MockMeditationGongPlayer() },
            makeAudioPlayerService: { playerService }
        )
    }
}
