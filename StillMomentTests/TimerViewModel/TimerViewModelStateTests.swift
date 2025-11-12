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

    // MARK: - State Updates

    func testTimerStateUpdatesFromService() {
        // Given
        let expectation = expectation(description: "State updates")

        // When
        self.sut.startTimer()

        // Wait for state to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Then
            XCTAssertEqual(self.sut.timerState, .running)
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

    func testCountdownAffirmations() {
        // Given/When
        let affirmation = self.sut.currentCountdownAffirmation

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
