//
//  TimerViewModelStateTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

/// Tests for TimerViewModel state transitions, timer updates, and completion
@MainActor
final class TimerViewModelStateTests: XCTestCase {
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

    // MARK: - State Updates

    func testTimerStateUpdatesFromService() {
        // Given
        let expectation = expectation(description: "State updates")

        // When
        self.sut.startTimer()

        // Wait for state to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Then
            XCTAssertTrue(self.sut.isRunning)
            XCTAssertEqual(self.sut.remainingSeconds, 600) // 10 minutes
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testCompletionTriggersEndGongPhase() {
        // Given
        let expectation = expectation(description: "Sound plays on completion")

        // When - Timer reaches zero
        self.mockTimerService.simulateCompletion()

        // Wait for endGong phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Then - Should be in endGong (gong is playing), not completed yet
            XCTAssertTrue(self.mockAudioService.playCompletionSoundCalled)
            XCTAssertEqual(self.sut.timerState, .endGong)

            // When - Gong finishes (audio callback)
            self.mockAudioService.gongCompletionSubject.send()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Then - Now should be completed
                XCTAssertEqual(self.sut.timerState, .completed)
                XCTAssertTrue(self.mockAudioService.deactivateTimerSessionCalled)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }
}
