//
//  TimerFocusViewTests.swift
//  Still Moment
//
//  Tests for Timer Focus Mode navigation logic
//

import XCTest
@testable import StillMoment

/// Tests for Focus Mode navigation behavior.
///
/// Focus Mode is a distraction-free view shown during active meditation.
/// These tests verify the ViewModel properties that control Focus Mode behavior:
/// - `canResume` determines if swipe-to-dismiss is enabled (only when paused)
/// - Timer state transitions control auto-dismiss behavior
@MainActor
final class TimerFocusViewTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: TimerViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockTimerService: MockTimerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockAudioService: MockAudioService!

    override func setUp() {
        super.setUp()
        self.mockTimerService = MockTimerService()
        self.mockAudioService = MockAudioService()

        self.sut = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )
    }

    override func tearDown() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: MeditationSettings.Keys.durationMinutes)
        defaults.removeObject(forKey: MeditationSettings.Keys.intervalGongsEnabled)
        defaults.removeObject(forKey: MeditationSettings.Keys.intervalMinutes)
        defaults.removeObject(forKey: MeditationSettings.Keys.backgroundSoundId)

        self.sut = nil
        self.mockTimerService = nil
        self.mockAudioService = nil
        super.tearDown()
    }

    // MARK: - Swipe-to-Dismiss Logic (interactiveDismissDisabled)

    func testSwipeToDismissDisabledWhenTimerRunning() {
        // Given
        let expectation = expectation(description: "Timer running")

        // When
        self.sut.startTimer()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Then - canResume is false when running, so swipe should be disabled
            XCTAssertFalse(self.sut.canResume, "canResume should be false when timer is running")
            XCTAssertEqual(self.sut.timerState, .running)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testSwipeToDismissEnabledWhenTimerPaused() {
        // Given
        let expectation = expectation(description: "Timer paused")

        // When - Simulate paused state directly
        self.mockTimerService.simulateTick(remainingSeconds: 300, state: .paused)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Then - canResume is true when paused, so swipe should be enabled
            XCTAssertTrue(self.sut.canResume, "canResume should be true when timer is paused")
            XCTAssertEqual(self.sut.timerState, .paused)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testSwipeToDismissDisabledDuringPreparation() {
        // Given
        let expectation = expectation(description: "Preparation running")

        // When - Simulate preparation state directly
        self.mockTimerService.simulateTick(remainingSeconds: 600, state: .preparation)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Then - canResume is false during preparation, so swipe should be disabled
            XCTAssertFalse(self.sut.canResume, "canResume should be false during preparation")
            XCTAssertEqual(self.sut.timerState, .preparation)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Auto-Dismiss Logic (Timer Returns to Idle)

    func testTimerReturnsToIdleAfterReset() {
        // Given
        let expectation = expectation(description: "Timer reset")

        // When
        self.sut.startTimer()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sut.resetTimer()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Then - Timer should be back to idle (triggers auto-dismiss in Focus View)
                XCTAssertEqual(self.sut.timerState, .idle)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testTimerReturnsToIdleAfterCompletion() {
        // Given
        let expectation = expectation(description: "Timer completed")

        // When - Simulate completion
        self.mockTimerService.simulateCompletion()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Completed state is transitional, reset is called automatically
            self.sut.resetTimer()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Then - Timer should be back to idle
                XCTAssertEqual(self.sut.timerState, .idle)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Close Button Behavior

    func testResetTimerSetsStateToIdle() {
        // Given
        let expectation = expectation(description: "Reset after start")

        // When
        self.sut.startTimer()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sut.resetTimer()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Then - Close button calls resetTimer(), which should set state to idle
                XCTAssertEqual(self.sut.timerState, .idle)
                XCTAssertTrue(self.sut.canStart, "Timer should be ready to start again")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
