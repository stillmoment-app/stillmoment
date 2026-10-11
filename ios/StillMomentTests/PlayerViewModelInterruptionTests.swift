//
//  PlayerViewModelInterruptionTests.swift
//  Still Moment
//
//  ViewModel tests - phone calls and other interruptions during a guided meditation (ios-065)
//

import Combine
import XCTest
@testable import StillMoment

@MainActor
final class PlayerViewModelInterruptionTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: GuidedMeditationPlayerViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockPlayerService: MockAudioPlayerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockClock: MockClock!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockGongPlayer: MockMeditationGongPlayer!

    override func setUp() {
        super.setUp()
        self.mockPlayerService = MockAudioPlayerService()
        self.mockClock = MockClock()
        self.mockGongPlayer = MockMeditationGongPlayer()
    }

    override func tearDown() {
        self.sut?.cleanup()
        self.sut = nil
        self.mockPlayerService = nil
        self.mockClock = nil
        self.mockGongPlayer = nil
        super.tearDown()
    }

    // MARK: - During playback

    func testInterruption_whilePlaying_showsMeditationPaused() async {
        // Given
        await self.startMeditation()

        // When: a phone call comes in
        await self.interrupt()

        // Then: play button and remaining-time line show the pause
        XCTAssertFalse(self.sut.isPlaying)
        XCTAssertEqual(self.sut.remainingLineState, .paused)
    }

    func testTapOnPlay_afterInterruption_continuesAtSamePositionWithoutPreRoll() async {
        // Given: the call paused the meditation at 5:00
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        self.mockGongPlayer.finishPlaying()
        self.mockClock.tick()
        self.mockPlayerService.currentTime.send(300)
        await self.interrupt()

        // When: the user taps Play after the call
        self.sut.togglePlayPause()

        // Then: it goes on at 5:00 — no jump, no second start gong
        XCTAssertEqual(self.mockPlayerService.playCallCount, 1)
        XCTAssertNil(self.mockPlayerService.seekTime)
        XCTAssertEqual(self.mockGongPlayer.playCallCount, 1)
        XCTAssertEqual(self.mockPlayerService.state.value, .playing)
    }

    func testInterruption_whenPausedByUser_staysPaused() async {
        // Given: the user had paused before the call
        await self.startMeditation()
        self.sut.togglePlayPause()
        let playsBefore = self.mockPlayerService.playCallCount

        // When
        await self.interrupt()

        // Then
        XCTAssertEqual(self.mockPlayerService.state.value, .paused)
        XCTAssertEqual(self.mockPlayerService.playCallCount, playsBefore)
    }

    func testInterruption_whileScrubbing_releaseDoesNotResume() async {
        // Given: the user holds the waveform of a playing meditation
        await self.startMeditation()
        self.sut.beginScrub()
        let playsBefore = self.mockPlayerService.playCallCount

        // When: a call comes in, then the finger lets go
        await self.interrupt()
        self.sut.endScrub()

        // Then: the meditation stays paused
        XCTAssertEqual(self.mockPlayerService.playCallCount, playsBefore)
        XCTAssertEqual(self.mockPlayerService.state.value, .paused)
    }

    // MARK: - During the pre-roll

    func testInterruption_duringPreparation_meditationDoesNotStart() async {
        // Given: the preparation countdown runs
        self.sut = self.createViewModel(startGongEnabled: true, preparationTimeSeconds: 3)
        await self.sut.loadAudio()
        self.sut.startPlayback()

        // When: a call comes in, and the countdown would have ended meanwhile
        await self.interrupt()
        self.mockClock.advance(ticks: 3)

        // Then: no start gong, no meditation; the player waits paused at the beginning
        XCTAssertEqual(self.mockGongPlayer.playCallCount, 0)
        self.assertMeditationNotStarted()
        XCTAssertEqual(self.sut.phase, .playing)
        XCTAssertTrue(self.sut.isPaused)
        XCTAssertTrue(self.mockPlayerService.silentBackgroundAudioStopped)
    }

    func testInterruption_duringStartGong_meditationDoesNotStart() async {
        // Given: the start gong rings
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()

        // When: the call ends the gong (its completion fires), then reaches the player
        self.mockGongPlayer.finishPlaying()
        await self.interrupt()
        self.mockClock.tick()

        // Then: no breath pause runs out into the meditation
        self.assertMeditationNotStarted()
        XCTAssertEqual(self.sut.phase, .playing)
    }

    func testInterruption_duringStartGong_lateGongCompletionDoesNotStartMeditation() async {
        // Given: the start gong rings
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()

        // When: the call reaches the player before the gong's completion arrives
        await self.interrupt()
        self.mockGongPlayer.deliverLateCompletion()
        self.mockClock.tick()

        // Then
        self.assertMeditationNotStarted()
    }

    func testInterruption_duringBreathPause_meditationDoesNotStart() async {
        // Given: the gong has faded, the breath pause runs
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        self.mockGongPlayer.finishPlaying()

        // When: a call comes in, and the breath pause would have elapsed
        await self.interrupt()
        self.mockClock.tick()

        // Then
        self.assertMeditationNotStarted()
        XCTAssertEqual(self.sut.phase, .playing)
    }

    func testTapOnPlay_afterInterruptedStartGong_restartsPreRollAndStartsOnce() async {
        // Given: the call aborted the pre-roll during the start gong
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        self.mockGongPlayer.finishPlaying()
        await self.interrupt()

        // When: the user taps Play, then gong and breath pause run out
        self.sut.togglePlayPause()
        XCTAssertEqual(self.sut.phase, .preRoll)
        self.mockGongPlayer.finishPlaying()
        self.mockClock.tick()

        // Then: the start gong rang again and the meditation began exactly once
        XCTAssertEqual(self.mockGongPlayer.playCallCount, 2)
        XCTAssertEqual(self.mockPlayerService.transitionFromSilentToPlaybackCallCount, 1)
        XCTAssertEqual(self.mockPlayerService.playCallCount, 0)
    }

    func testTapOnPlay_afterInterruptedPreparation_restartsCountdownAndStartsOnce() async {
        // Given: the call aborted the preparation countdown
        self.sut = self.createViewModel(preparationTimeSeconds: 3)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        self.mockClock.tick()
        await self.interrupt()

        // When: the user taps Play, then the full countdown runs out
        self.sut.togglePlayPause()
        XCTAssertEqual(self.sut.remainingCountdownSeconds, 3)
        self.mockClock.advance(ticks: 3)

        // Then: the meditation began exactly once
        XCTAssertEqual(self.mockPlayerService.transitionFromSilentToPlaybackCallCount, 1)
        XCTAssertEqual(self.mockPlayerService.playCallCount, 0)
    }

    // MARK: Private

    private func createViewModel(
        startGongEnabled: Bool = false,
        preparationTimeSeconds: Int? = nil
    ) -> GuidedMeditationPlayerViewModel {
        GuidedMeditationPlayerViewModel(
            meditation: GuidedMeditationTestHelpers.createTestMeditation(startGongEnabled: startGongEnabled),
            preparationTimeSeconds: preparationTimeSeconds,
            playerService: self.mockPlayerService,
            meditationService: MockGuidedMeditationService(),
            waveformProvider: MockWaveformProvider(),
            clock: self.mockClock,
            gongPlayer: self.mockGongPlayer,
            praxisRepository: MockPraxisRepository()
        )
    }

    /// Opens a meditation without pre-roll; it plays right away.
    private func startMeditation() async {
        self.sut = self.createViewModel()
        await self.sut.loadAudio()
        self.sut.startPlayback()
        await self.drainMainQueue()
    }

    /// A phone call begins; the ViewModel learns about it on the main queue.
    private func interrupt() async {
        self.mockPlayerService.simulateInterruption()
        await self.drainMainQueue()
    }

    private func assertMeditationNotStarted(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(self.mockPlayerService.transitionFromSilentToPlaybackCallCount, 0, file: file, line: line)
        XCTAssertEqual(self.mockPlayerService.playCallCount, 0, file: file, line: line)
    }

    private func drainMainQueue() async {
        let drained = self.expectation(description: "main queue drained")
        DispatchQueue.main.async {
            drained.fulfill()
        }
        await fulfillment(of: [drained], timeout: 1.0)
    }
}
