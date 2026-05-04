//
//  TimerViewModelZenModeTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

/// Tests for TimerViewModel.isZenMode -- drives tab bar visibility during meditation
@MainActor
final class TimerViewModelZenModeTests: XCTestCase {
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

    // MARK: - isZenMode

    func testZenModeIsInactiveWhenIdle() {
        // Given / When: timer is idle (initial state, no timer object)
        // Then: tab bar should be visible
        XCTAssertFalse(self.sut.isZenMode, "Tab bar must be visible when timer is idle")
    }

    func testZenModeIsActiveWhenMeditationStarts() {
        // Given / When: timer transitions to preparation (first active state after start)
        self.sut.timer = .stub(state: .preparation, remainingPreparationSeconds: 15)

        // Then: tab bar should be hidden during active meditation
        XCTAssertTrue(self.sut.isZenMode, "Tab bar must be hidden once meditation starts")
    }

    func testZenModeIsActiveDuringPreparation() {
        // Given: timer is in preparation phase
        self.sut.timer = .stub(state: .preparation, remainingPreparationSeconds: 10)

        // Then
        XCTAssertTrue(self.sut.isZenMode, "Tab bar must be hidden during preparation")
    }

    func testZenModeIsActiveDuringStartGong() {
        // Given: timer is in startGong phase
        self.sut.timer = .stub(remainingSeconds: 600, state: .startGong)

        // Then
        XCTAssertTrue(self.sut.isZenMode, "Tab bar must be hidden during start gong")
    }

    func testZenModeIsActiveDuringRunning() {
        // Given: timer is running
        self.sut.timer = .stub(remainingSeconds: 300, state: .running)

        // Then
        XCTAssertTrue(self.sut.isZenMode, "Tab bar must be hidden while timer is running")
    }

    func testZenModeIsActiveDuringEndGong() {
        // Given: timer is in endGong phase
        self.sut.timer = .stub(remainingSeconds: 0, state: .endGong)

        // Then
        XCTAssertTrue(self.sut.isZenMode, "Tab bar must be hidden during end gong")
    }

    func testZenModeIsInactiveAfterReset() {
        // Given: timer is running
        self.sut.timer = .stub(remainingSeconds: 300, state: .running)
        XCTAssertTrue(self.sut.isZenMode)

        // When: user presses X (reset)
        self.sut.resetTimer()

        // Then: tab bar returns
        XCTAssertFalse(self.sut.isZenMode, "Tab bar must return when meditation is cancelled")
    }

    func testZenModeIsActiveWhenCompleted() {
        // Given: timer reaches completed state
        self.sut.timer = .stub(remainingSeconds: 0, state: .completed)

        // Then: tab bar must stay hidden during the completion screen
        XCTAssertTrue(self.sut.isZenMode, "Tab bar must remain hidden during completion screen")
    }
}
