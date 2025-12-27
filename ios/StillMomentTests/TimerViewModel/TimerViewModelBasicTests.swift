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

    func testPauseTimer_whenRunning_callsService() {
        // Given - simulate running state via tick
        self.sut.dispatch(.tick(
            remainingSeconds: 300,
            totalSeconds: 600,
            countdownSeconds: 0,
            progress: 0.5,
            state: .running
        ))

        // When
        self.sut.pauseTimer()

        // Then
        XCTAssertTrue(self.mockTimerService.pauseCalled)
    }

    func testResumeTimer_whenPaused_callsService() {
        // Given - simulate paused state via tick
        self.sut.dispatch(.tick(
            remainingSeconds: 300,
            totalSeconds: 600,
            countdownSeconds: 0,
            progress: 0.5,
            state: .paused
        ))

        // When
        self.sut.resumeTimer()

        // Then
        XCTAssertTrue(self.mockTimerService.resumeCalled)
    }

    func testResetTimer_whenRunning_callsService() {
        // Given - simulate running state
        self.sut.dispatch(.tick(
            remainingSeconds: 300,
            totalSeconds: 600,
            countdownSeconds: 0,
            progress: 0.5,
            state: .running
        ))

        // When
        self.sut.resetTimer()

        // Then
        XCTAssertTrue(self.mockTimerService.resetCalled)
    }

    // MARK: - Formatting (tested via dispatch)

    func testFormattedTime_duringCountdown_showsSeconds() {
        // Given - countdown state
        self.sut.dispatch(.tick(
            remainingSeconds: 600,
            totalSeconds: 600,
            countdownSeconds: 12,
            progress: 0.0,
            state: .countdown
        ))

        // Then
        XCTAssertEqual(self.sut.formattedTime, "12")
    }

    func testFormattedTime_duringRunning_showsMinutesSeconds() {
        // Given - running state with 2:05 remaining
        self.sut.dispatch(.tick(
            remainingSeconds: 125,
            totalSeconds: 600,
            countdownSeconds: 0,
            progress: 0.5,
            state: .running
        ))

        // Then
        XCTAssertEqual(self.sut.formattedTime, "02:05")
    }

    // MARK: - Control Conditions (via dispatch)

    func testCanStart_whenIdleWithMinutes_returnsTrue() {
        // Given - initial idle state with default 10 minutes
        XCTAssertTrue(self.sut.canStart)
    }

    func testCanStart_whenRunning_returnsFalse() {
        // Given - running state
        self.sut.dispatch(.tick(
            remainingSeconds: 300,
            totalSeconds: 600,
            countdownSeconds: 0,
            progress: 0.5,
            state: .running
        ))

        // Then
        XCTAssertFalse(self.sut.canStart)
    }

    func testCanPause_whenRunning_returnsTrue() {
        // Given - running state
        self.sut.dispatch(.tick(
            remainingSeconds: 300,
            totalSeconds: 600,
            countdownSeconds: 0,
            progress: 0.5,
            state: .running
        ))

        // Then
        XCTAssertTrue(self.sut.canPause)
    }

    func testCanPause_whenIdle_returnsFalse() {
        // Given - initial idle state
        XCTAssertFalse(self.sut.canPause)
    }

    func testCanResume_whenPaused_returnsTrue() {
        // Given - paused state
        self.sut.dispatch(.tick(
            remainingSeconds: 300,
            totalSeconds: 600,
            countdownSeconds: 0,
            progress: 0.5,
            state: .paused
        ))

        // Then
        XCTAssertTrue(self.sut.canResume)
    }

    func testCanResume_whenRunning_returnsFalse() {
        // Given - running state
        self.sut.dispatch(.tick(
            remainingSeconds: 300,
            totalSeconds: 600,
            countdownSeconds: 0,
            progress: 0.5,
            state: .running
        ))

        // Then
        XCTAssertFalse(self.sut.canResume)
    }
}
