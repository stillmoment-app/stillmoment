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
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockPraxisRepository: MockPraxisRepository!

    override func setUp() {
        super.setUp()
        self.mockTimerService = MockTimerService()
        self.mockAudioService = MockAudioService()
        self.mockPraxisRepository = MockPraxisRepository()

        self.sut = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            praxisRepository: self.mockPraxisRepository
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockTimerService = nil
        self.mockAudioService = nil
        self.mockPraxisRepository = nil
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

    func testResetTimer_whenRunning_callsService() {
        // Given - simulate running state
        self.sut.timer = .stub(remainingSeconds: 300, state: .running)

        // When
        self.sut.resetTimer()

        // Then
        XCTAssertTrue(self.mockTimerService.resetCalled)
    }

    // MARK: - Control Conditions

    func testCanStart_whenIdleWithMinutes_returnsTrue() {
        // Given - initial idle state with default 10 minutes
        XCTAssertTrue(self.sut.canStart)
    }

    func testCanStart_whenRunning_returnsFalse() {
        // Given - running state
        self.sut.timer = .stub(remainingSeconds: 300, state: .running)

        // Then
        XCTAssertFalse(self.sut.canStart)
    }

    func testIsRunning_whenRunning_returnsTrue() {
        // Given - running state
        self.sut.timer = .stub(remainingSeconds: 300, state: .running)

        // Then
        XCTAssertTrue(self.sut.isRunning)
    }

    func testIsRunning_whenIdle_returnsFalse() {
        // Given - initial idle state
        XCTAssertFalse(self.sut.isRunning)
    }
}
