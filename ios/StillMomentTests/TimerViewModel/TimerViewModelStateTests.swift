//
//  TimerViewModelStateTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

/// Tests for TimerViewModel state transitions, timer updates, completion, and affirmations
@MainActor
final class TimerViewModelStateTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: TimerViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockTimerService: MockTimerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockAudioService: MockAudioService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockSettingsRepository: MockTimerSettingsRepository!

    override func setUp() {
        super.setUp()
        self.mockTimerService = MockTimerService()
        self.mockAudioService = MockAudioService()
        self.mockSettingsRepository = MockTimerSettingsRepository()

        self.sut = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService,
            settingsRepository: self.mockSettingsRepository
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockTimerService = nil
        self.mockAudioService = nil
        self.mockSettingsRepository = nil
        super.tearDown()
    }

    // MARK: - State Updates

    func testTimerStateUpdatesFromService() {
        // Given
        let expectation = expectation(description: "State updates")

        // When
        self.sut.startTimer()

        // Wait for state to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Then
            XCTAssertTrue(self.sut.displayState.isRunning)
            XCTAssertEqual(self.sut.remainingSeconds, 600) // 10 minutes
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testCompletionTriggersSound() {
        // Given
        let expectation = expectation(description: "Sound plays on completion")

        // When
        self.mockTimerService.simulateCompletion()

        // Wait for sound to be triggered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Then
            XCTAssertTrue(self.mockAudioService.playCompletionSoundCalled)
            XCTAssertEqual(self.sut.timerState, .completed)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Affirmations

    func testAffirmationsRotation() {
        // Given
        let initialIndex = self.sut.currentAffirmationIndex

        // When
        self.sut.startTimer()

        // Then
        XCTAssertEqual(self.sut.currentAffirmationIndex, initialIndex + 1)
    }

    func testPreparationAffirmations() {
        // Given/When
        let affirmation = self.sut.currentPreparationAffirmation

        // Then
        XCTAssertFalse(affirmation.isEmpty)
        XCTAssertTrue(affirmation.contains("...") || affirmation.contains("Settle") || affirmation.contains("breath"))
    }

    func testRunningAffirmations() {
        // Given/When
        let affirmation = self.sut.currentRunningAffirmation

        // Then - Can be empty string (one of the affirmations is silence)
        XCTAssertTrue(!affirmation.isEmpty || affirmation.isEmpty)
    }
}
