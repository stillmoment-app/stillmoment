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
    var mockSettingsRepository: MockTimerSettingsRepository!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockPraxisRepository: MockPraxisRepository!

    override func setUp() {
        super.setUp()
        self.mockTimerService = MockTimerService()
        self.mockAudioService = MockAudioService()
        self.mockSettingsRepository = MockTimerSettingsRepository()
        self.mockPraxisRepository = MockPraxisRepository()
        self.sut = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository,
            praxisRepository: self.mockPraxisRepository
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockTimerService = nil
        self.mockAudioService = nil
        self.mockSettingsRepository = nil
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

    func testIsZenModeActiveWhenCompleted() {
        // Given: meditation has completed and the completion screen is shown
        self.sut.timer = .stub(remainingSeconds: 0, state: .completed)

        // Then: zen mode must stay active so the tab bar remains hidden during the completion screen
        XCTAssertTrue(self.sut.isZenMode, "Zen mode must be active during completion screen to keep tab bar hidden")
    }
}
