//
//  PlayerViewModelGongTests.swift
//  Still Moment
//
//  ViewModel tests - Start/end gong orchestration (shared-106)
//

import Combine
import XCTest
@testable import StillMoment

@MainActor
final class PlayerViewModelGongTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: GuidedMeditationPlayerViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockPlayerService: MockAudioPlayerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockMeditationService: MockGuidedMeditationService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockClock: MockClock!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockGongPlayer: MockMeditationGongPlayer!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockPraxisRepository: MockPraxisRepository!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var tempFileURL: URL!

    override func setUp() {
        super.setUp()
        self.mockPlayerService = MockAudioPlayerService()
        self.mockMeditationService = MockGuidedMeditationService()
        self.mockClock = MockClock()
        self.mockGongPlayer = MockMeditationGongPlayer()
        self.mockPraxisRepository = MockPraxisRepository()
        self.mockPraxisRepository.currentPraxis = Praxis(
            startGongSoundId: "classic-bowl",
            gongVolume: 0.5
        )
        self.tempFileURL = GuidedMeditationTestHelpers.createTemporaryAudioFile()
    }

    override func tearDown() {
        self.sut?.cleanup()
        self.sut = nil
        self.mockPlayerService = nil
        self.mockMeditationService = nil
        self.mockClock = nil
        self.mockGongPlayer = nil
        self.mockPraxisRepository = nil
        GuidedMeditationTestHelpers.cleanupTemporaryFile(self.tempFileURL)
        self.tempFileURL = nil
        super.tearDown()
    }

    // MARK: - Start Gong (without preparation time)

    func testStartPlayback_withGong_playsGongBeforeAudio() async {
        // Given
        self.sut = self.createViewModel(gongEnabled: true)
        await self.sut.loadAudio()

        // When
        self.sut.startPlayback()

        // Then: silent keep-alive runs, gong plays with the timer settings' sound,
        // but the meditation audio has not started yet
        XCTAssertTrue(self.mockPlayerService.silentBackgroundAudioStarted)
        XCTAssertEqual(self.mockGongPlayer.playCallCount, 1)
        XCTAssertEqual(self.mockGongPlayer.playedSoundId, "classic-bowl")
        XCTAssertEqual(self.mockGongPlayer.playedVolume, 0.5)
        XCTAssertFalse(self.mockPlayerService.playCalled)
        XCTAssertFalse(self.mockPlayerService.transitionFromSilentToPlaybackCalled)
    }

    func testGongCompletion_schedulesBreathPause() async {
        // Given
        self.sut = self.createViewModel(gongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()

        // When: gong finished ringing
        self.mockGongPlayer.finishPlaying()

        // Then: breath pause is scheduled, audio still not started
        XCTAssertTrue(self.mockClock.scheduleCalled)
        XCTAssertEqual(self.mockClock.requestedInterval, 2.0)
        XCTAssertFalse(self.mockPlayerService.transitionFromSilentToPlaybackCalled)
    }

    func testBreathPauseEnd_startsAudioViaAtomicTransition() async {
        // Given
        self.sut = self.createViewModel(gongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        self.mockGongPlayer.finishPlaying()

        // When: breath pause elapses
        self.mockClock.tick()

        // Then: lock-screen-safe atomic transition starts the meditation audio
        XCTAssertTrue(self.mockPlayerService.transitionFromSilentToPlaybackCalled)
    }

    func testStartPlayback_withoutGong_playsImmediately() async {
        // Given
        self.sut = self.createViewModel(gongEnabled: false)
        await self.sut.loadAudio()

        // When
        self.sut.startPlayback()

        // Then
        XCTAssertTrue(self.mockPlayerService.playCalled)
        XCTAssertEqual(self.mockGongPlayer.playCallCount, 0)
    }

    func testStartPlayback_duringGongSequence_isIgnored() async {
        // Given: gong is ringing
        self.sut = self.createViewModel(gongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()

        // When: user taps play again during the gong
        self.sut.startPlayback()

        // Then: no second gong, no premature audio start
        XCTAssertEqual(self.mockGongPlayer.playCallCount, 1)
        XCTAssertFalse(self.mockPlayerService.playCalled)
    }

    // MARK: - Start Gong (with preparation countdown)

    func testCountdownEnd_withGong_playsGongBeforeTransition() async {
        // Given
        self.sut = self.createViewModel(gongEnabled: true, preparationTimeSeconds: 3)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        XCTAssertEqual(self.mockGongPlayer.playCallCount, 0)

        // When: countdown completes
        self.mockClock.advance(ticks: 3)

        // Then: gong plays, audio waits for gong + breath pause
        XCTAssertEqual(self.mockGongPlayer.playCallCount, 1)
        XCTAssertFalse(self.mockPlayerService.transitionFromSilentToPlaybackCalled)

        // When: gong finished and breath pause elapses
        self.mockGongPlayer.finishPlaying()
        self.mockClock.tick()

        // Then
        XCTAssertTrue(self.mockPlayerService.transitionFromSilentToPlaybackCalled)
    }

    func testCountdownEnd_withoutGong_transitionsDirectly() async {
        // Given
        self.sut = self.createViewModel(gongEnabled: false, preparationTimeSeconds: 3)
        await self.sut.loadAudio()
        self.sut.startPlayback()

        // When
        self.mockClock.advance(ticks: 3)

        // Then
        XCTAssertTrue(self.mockPlayerService.transitionFromSilentToPlaybackCalled)
        XCTAssertEqual(self.mockGongPlayer.playCallCount, 0)
    }

    // MARK: - Resume

    func testResume_afterPause_doesNotPlayGongAgain() async {
        // Given: meditation started with gong and is playing
        self.sut = self.createViewModel(gongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        self.mockGongPlayer.finishPlaying()
        self.mockClock.tick()
        XCTAssertTrue(self.mockPlayerService.transitionFromSilentToPlaybackCalled)

        // When: user pauses and resumes
        self.sut.startPlayback() // pause
        self.sut.startPlayback() // resume

        // Then: the gong only played at the session start
        XCTAssertEqual(self.mockGongPlayer.playCallCount, 1)
    }

    // MARK: - End Gong Configuration

    func testLoadAudio_withGong_configuresEndGong() async {
        // Given
        self.sut = self.createViewModel(gongEnabled: true)

        // When
        await self.sut.loadAudio()

        // Then: end gong follows the timer settings
        XCTAssertTrue(self.mockPlayerService.configureEndGongCalled)
        XCTAssertEqual(self.mockPlayerService.endGongSoundId, "classic-bowl")
        XCTAssertEqual(self.mockPlayerService.endGongVolume, 0.5)
    }

    func testLoadAudio_withoutGong_doesNotConfigureEndGong() async {
        // Given
        self.sut = self.createViewModel(gongEnabled: false)

        // When
        await self.sut.loadAudio()

        // Then
        XCTAssertFalse(self.mockPlayerService.configureEndGongCalled)
    }

    // MARK: - Helpers

    private func createViewModel(
        gongEnabled: Bool,
        preparationTimeSeconds: Int? = nil
    ) -> GuidedMeditationPlayerViewModel {
        let meditation = GuidedMeditationTestHelpers.createTestMeditation(
            fileURL: self.tempFileURL,
            gongEnabled: gongEnabled
        )
        return GuidedMeditationPlayerViewModel(
            meditation: meditation,
            preparationTimeSeconds: preparationTimeSeconds,
            playerService: self.mockPlayerService,
            meditationService: self.mockMeditationService,
            clock: self.mockClock,
            gongPlayer: self.mockGongPlayer,
            praxisRepository: self.mockPraxisRepository
        )
    }
}
