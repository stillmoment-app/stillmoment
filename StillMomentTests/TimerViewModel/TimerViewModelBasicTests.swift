//
//  TimerViewModelBasicTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

/// Tests for basic TimerViewModel functionality: initialization, state management, and control actions
@MainActor
final class TimerViewModelBasicTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: TimerViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockTimerService: MockTimerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockAudioService: MockAudioService!

    override func setUp() {
        super.setUp()
        // Use 0 countdown duration for fast tests
        self.mockTimerService = MockTimerService(countdownDuration: 0)
        self.mockAudioService = MockAudioService()

        self.sut = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )
    }

    override func tearDown() {
        // Clean up UserDefaults to prevent test pollution
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: MeditationSettings.Keys.durationMinutes)
        defaults.removeObject(forKey: MeditationSettings.Keys.intervalGongsEnabled)
        defaults.removeObject(forKey: MeditationSettings.Keys.intervalMinutes)
        defaults.removeObject(forKey: MeditationSettings.Keys.backgroundSoundId)
        defaults.removeObject(forKey: MeditationSettings.Keys.legacyBackgroundAudioMode)

        self.sut = nil
        self.mockTimerService = nil
        self.mockAudioService = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        // Then
        XCTAssertEqual(self.sut.selectedMinutes, 10)
        XCTAssertEqual(self.sut.timerState, .idle)
        XCTAssertEqual(self.sut.remainingSeconds, 0)
        XCTAssertEqual(self.sut.totalSeconds, 0)
        XCTAssertEqual(self.sut.progress, 0.0)
        XCTAssertNil(self.sut.errorMessage)
    }

    // MARK: - Timer Controls

    func testStartTimer() {
        // Given
        self.sut.selectedMinutes = 15

        // When
        self.sut.startTimer()

        // Then
        XCTAssertTrue(self.mockTimerService.startCalled)
        XCTAssertEqual(self.mockTimerService.lastStartDuration, 15)
    }

    func testPauseTimer() {
        // When
        self.sut.pauseTimer()

        // Then
        XCTAssertTrue(self.mockTimerService.pauseCalled)
    }

    func testResumeTimer() {
        // Given
        self.sut.remainingSeconds = 120

        // When
        self.sut.resumeTimer()

        // Then
        XCTAssertTrue(self.mockTimerService.resumeCalled)
    }

    func testResetTimer() {
        // When
        self.sut.resetTimer()

        // Then
        XCTAssertTrue(self.mockTimerService.resetCalled)
    }

    // MARK: - Formatting

    func testFormattedTime() {
        // Given
        self.sut.remainingSeconds = 0
        XCTAssertEqual(self.sut.formattedTime, "00:00")

        // When
        self.sut.remainingSeconds = 125 // 2:05
        XCTAssertEqual(self.sut.formattedTime, "02:05")

        // When
        self.sut.remainingSeconds = 3661 // 61:01
        XCTAssertEqual(self.sut.formattedTime, "61:01")
    }

    // MARK: - Control Conditions

    func testCanStartConditions() {
        // Given - idle state with valid minutes
        self.sut.timerState = .idle
        self.sut.selectedMinutes = 10
        XCTAssertTrue(self.sut.canStart)

        // When - running state
        self.sut.timerState = .running
        XCTAssertFalse(self.sut.canStart)

        // When - zero minutes
        self.sut.timerState = .idle
        self.sut.selectedMinutes = 0
        XCTAssertFalse(self.sut.canStart)
    }

    func testCanPauseConditions() {
        // Given - running state
        self.sut.timerState = .running
        XCTAssertTrue(self.sut.canPause)

        // When - idle state
        self.sut.timerState = .idle
        XCTAssertFalse(self.sut.canPause)

        // When - paused state
        self.sut.timerState = .paused
        XCTAssertFalse(self.sut.canPause)
    }

    func testCanResumeConditions() {
        // Given - paused state
        self.sut.timerState = .paused
        XCTAssertTrue(self.sut.canResume)

        // When - running state
        self.sut.timerState = .running
        XCTAssertFalse(self.sut.canResume)

        // When - idle state
        self.sut.timerState = .idle
        XCTAssertFalse(self.sut.canResume)
    }

    func testCanResetConditions() {
        // Given - idle state
        self.sut.timerState = .idle
        XCTAssertFalse(self.sut.canReset)

        // When - running state
        self.sut.timerState = .running
        XCTAssertTrue(self.sut.canReset)

        // When - paused state
        self.sut.timerState = .paused
        XCTAssertTrue(self.sut.canReset)

        // When - completed state
        self.sut.timerState = .completed
        XCTAssertTrue(self.sut.canReset)
    }
}
