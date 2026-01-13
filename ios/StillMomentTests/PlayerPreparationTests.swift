//
//  PlayerPreparationTests.swift
//  Still Moment
//
//  Tests for guided meditation player preparation countdown
//

import Combine
import XCTest
@testable import StillMoment

// MARK: - PlayerPreparationTests

@MainActor
final class PlayerPreparationTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: GuidedMeditationPlayerViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockPlayerService: MockAudioPlayerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockClock: MockClock!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var cancellables: Set<AnyCancellable>!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var tempFileURL: URL!

    override func setUp() {
        super.setUp()
        self.mockPlayerService = MockAudioPlayerService()
        self.mockClock = MockClock()
        self.cancellables = Set<AnyCancellable>()

        // Create temporary file for tests
        self.tempFileURL = GuidedMeditationTestHelpers.createTemporaryAudioFile()

        // Default: no preparation time
        self.sut = self.createViewModel(preparationTimeSeconds: nil)
    }

    override func tearDown() {
        self.sut.cleanup()
        self.cancellables.removeAll()
        self.cancellables = nil
        self.sut = nil
        self.mockPlayerService = nil
        self.mockClock = nil
        // Clean up temp file
        GuidedMeditationTestHelpers.cleanupTemporaryFile(self.tempFileURL)
        self.tempFileURL = nil
        super.tearDown()
    }

    // MARK: - Helper

    /// Creates a ViewModel with the specified preparation time
    func createViewModel(preparationTimeSeconds: Int?) -> GuidedMeditationPlayerViewModel {
        let meditation = GuidedMeditationTestHelpers.createTestMeditation(fileURL: self.tempFileURL)
        return GuidedMeditationPlayerViewModel(
            meditation: meditation,
            preparationTimeSeconds: preparationTimeSeconds,
            playerService: self.mockPlayerService,
            clock: self.mockClock
        )
    }

    // MARK: - Countdown State

    func testIsPreparing_initiallyFalse() {
        XCTAssertFalse(self.sut.isPreparing)
    }

    func testRemainingCountdownSeconds_initiallyZero() {
        XCTAssertEqual(self.sut.remainingCountdownSeconds, 0)
    }

    func testCountdownProgress_initiallyZero() {
        XCTAssertEqual(self.sut.countdownProgress, 0)
    }

    // MARK: - Start Playback

    func testStartPlayback_withoutPreparation_doesNotStartCountdown() async {
        // Given - sut already has nil preparation time from setUp
        await self.sut.loadAudio()

        // When
        self.sut.startPlayback()

        // Then
        XCTAssertFalse(self.sut.isPreparing)
        XCTAssertTrue(self.mockPlayerService.playCalled)
        XCTAssertFalse(self.mockClock.scheduleCalled, "Clock should not be used without preparation time")
    }

    func testStartPlayback_withPreparation_startsCountdown() async {
        // Given
        self.sut = self.createViewModel(preparationTimeSeconds: 15)
        await self.sut.loadAudio()
        self.mockPlayerService.playCalled = false

        // When
        self.sut.startPlayback()

        // Then
        XCTAssertTrue(self.sut.isPreparing)
        XCTAssertEqual(self.sut.remainingCountdownSeconds, 15)
        XCTAssertFalse(self.mockPlayerService.playCalled)
        XCTAssertTrue(self.mockClock.scheduleCalled, "Clock should be used for countdown")
        XCTAssertEqual(self.mockClock.requestedInterval, 1.0)
        XCTAssertTrue(self.mockPlayerService.silentBackgroundAudioStarted, "Silent audio should start during countdown")
    }

    func testStartPlayback_whileAlreadyPreparing_doesNothing() async {
        // Given
        self.sut = self.createViewModel(preparationTimeSeconds: 15)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        XCTAssertTrue(self.sut.isPreparing)

        // When - try to start again
        self.sut.startPlayback()

        // Then - should still be at original countdown
        XCTAssertTrue(self.sut.isPreparing)
        XCTAssertEqual(self.sut.remainingCountdownSeconds, 15)
    }

    // MARK: - Countdown Progress

    func testCountdownProgress_calculatesCorrectly() async {
        // Given
        self.sut = self.createViewModel(preparationTimeSeconds: 10)
        await self.sut.loadAudio()
        self.sut.startPlayback()

        // Initial progress should be 0
        XCTAssertEqual(self.sut.countdownProgress, 0, accuracy: 0.01)
    }

    // MARK: - Countdown State Transitions

    func testCountdownState_startsAtIdle() {
        XCTAssertEqual(self.sut.countdownState, .idle)
    }

    func testCountdownState_changesWhenStarted() async {
        // Given
        self.sut = self.createViewModel(preparationTimeSeconds: 10)
        await self.sut.loadAudio()

        // When
        self.sut.startPlayback()

        // Then - State should be active with PreparationCountdown value object
        let expectedCountdown = PreparationCountdown(totalSeconds: 10)
        XCTAssertEqual(self.sut.countdownState, .active(expectedCountdown))
    }

    // MARK: - No Countdown After Initial Start

    func testStartPlayback_whilePlaying_pausesWithoutCountdown() async {
        // Given - MP3 is already playing (countdown completed)
        self.sut = self.createViewModel(preparationTimeSeconds: 5)
        await self.sut.loadAudio()
        self.sut.startPlayback() // Starts countdown, marks session as started
        self.mockClock.advance(ticks: 5) // Complete countdown via MockClock

        // Wait for playing state
        let playingExpectation = expectation(description: "State updates to playing")
        self.sut.$playbackState
            .dropFirst()
            .sink { state in
                if state == .playing {
                    playingExpectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        await fulfillment(of: [playingExpectation], timeout: 1.0)
        self.mockPlayerService.pauseCalled = false

        // When - User taps play/pause button again
        self.sut.startPlayback()

        // Then - Should pause, NOT start countdown
        XCTAssertFalse(self.sut.isPreparing)
        XCTAssertTrue(self.mockPlayerService.pauseCalled)
    }

    func testStartPlayback_afterPause_resumesWithoutCountdown() async {
        // Given - MP3 was started (countdown completed) and then paused
        self.sut = self.createViewModel(preparationTimeSeconds: 5)
        await self.sut.loadAudio()
        self.sut.startPlayback() // Starts countdown
        self.mockClock.advance(ticks: 5) // Complete countdown via MockClock
        // Now MP3 is playing, user pauses
        self.mockPlayerService.pause()
        self.mockPlayerService.playCalled = false

        // When - User taps play/pause to resume
        self.sut.startPlayback()

        // Then - Should resume playback, NOT start countdown again
        XCTAssertFalse(self.sut.isPreparing)
        XCTAssertTrue(self.mockPlayerService.playCalled)
    }

    // MARK: - Countdown Tick Tests (using MockClock)

    func testCountdown_tickDecrementsRemainingSeconds() async {
        // Given
        self.sut = self.createViewModel(preparationTimeSeconds: 10)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        XCTAssertEqual(self.sut.remainingCountdownSeconds, 10)

        // When - Simulate one tick via MockClock
        self.mockClock.tick()

        // Then
        XCTAssertEqual(self.sut.remainingCountdownSeconds, 9)
        XCTAssertTrue(self.sut.isPreparing)
    }

    func testCountdown_completesAndStartsPlayback() async {
        // Given
        self.sut = self.createViewModel(preparationTimeSeconds: 5)
        await self.sut.loadAudio()
        self.mockPlayerService.playCalled = false
        self.sut.startPlayback()

        // Tick down to 1
        self.mockClock.advance(ticks: 4)
        XCTAssertEqual(self.sut.remainingCountdownSeconds, 1)
        XCTAssertFalse(self.mockPlayerService.playCalled)

        // When - Final tick
        self.mockClock.tick()

        // Then - Countdown finished and player started
        XCTAssertEqual(self.sut.countdownState, .finished)
        XCTAssertTrue(self.mockPlayerService.playCalled, "Player should start after countdown")
        XCTAssertTrue(self.mockPlayerService.silentBackgroundAudioStopped, "Silent audio should stop before MP3 starts")
    }

    func testCountdown_updatesProgress() async {
        // Given
        self.sut = self.createViewModel(preparationTimeSeconds: 10)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        XCTAssertEqual(self.sut.countdownProgress, 0, accuracy: 0.01)

        // When - Tick 5 times (halfway)
        self.mockClock.advance(ticks: 5)

        // Then - Progress should be 50%
        XCTAssertEqual(self.sut.countdownProgress, 0.5, accuracy: 0.01)
    }

    func testCountdown_tickWhenNotPreparing_doesNothing() {
        // Given - Not in preparation state
        XCTAssertEqual(self.sut.countdownState, .idle)

        // When - Clock ticks but no countdown active
        self.mockClock.tick()

        // Then - State unchanged (no crash, no effect)
        XCTAssertEqual(self.sut.countdownState, .idle)
    }
}
