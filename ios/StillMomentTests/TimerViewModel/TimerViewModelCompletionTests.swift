//
//  TimerViewModelCompletionTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

/// Tests that the TimerViewModel correctly handles the .completed state (shared-052)
@MainActor
final class TimerViewModelCompletionTests: XCTestCase {
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

    // MARK: - Completion State

    func testCompletedStateIsProduced() {
        // Given / When: timer transitions to completed state
        self.sut.timer = .stub(remainingSeconds: 0, state: .completed)

        // Then: ViewModel reports completed state
        XCTAssertEqual(self.sut.timerState, .completed, "Timer should report completed state")
    }

    func testResetFromCompletedStateReturnsToIdle() {
        // Given: timer is in completed state
        self.sut.timer = .stub(remainingSeconds: 0, state: .completed)

        // When: user taps "Back" (reset)
        self.sut.resetTimer()

        // Then: timer is cleared and returns to idle
        XCTAssertNil(self.sut.timer, "Timer should be cleared after reset from completed state")
        XCTAssertEqual(self.sut.timerState, .idle, "Timer state should be idle after reset")
    }

    // MARK: - Regression: Idle timer publish after reset must not restore timer

    func testIdleTimerPublishAfterClearIsIgnored() {
        // Regression for: after tapping "Back" on completion screen, Start button was missing.
        // Root cause: TimerService.reset() publishes an idle MeditationTimer asynchronously via
        // receive(on: DispatchQueue.main). If this delivery arrives after .clearTimer sets
        // self.timer = nil, handleTimerUpdate would re-assign a non-nil timer, hiding the Start button.

        // Given: timer has been cleared (post .clearTimer effect)
        self.sut.timer = nil

        // When: the deferred idle-timer publish from reset() arrives
        self.mockTimerService.simulateTick(remainingSeconds: 300, state: .idle)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        // Then: timer stays nil — start button remains visible
        XCTAssertNil(self.sut.timer, "Idle timer update from reset() must not restore a cleared timer")
        XCTAssertTrue(self.sut.canStart, "Start button must be visible after returning from completion screen")
    }
}
