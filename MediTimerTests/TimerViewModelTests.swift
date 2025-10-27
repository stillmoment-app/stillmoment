//
//  TimerViewModelTests.swift
//  MediTimerTests
//
//  Unit Tests - TimerViewModel
//

import XCTest
import Combine
@testable import MediTimer

// MARK: - Mock Services

final class MockTimerService: TimerServiceProtocol {
    private let subject = PassthroughSubject<MeditationTimer, Never>()
    var timerPublisher: AnyPublisher<MeditationTimer, Never> {
        subject.eraseToAnyPublisher()
    }

    var startCalled = false
    var pauseCalled = false
    var resumeCalled = false
    var resetCalled = false
    var stopCalled = false

    var lastStartDuration: Int?

    func start(durationMinutes: Int) {
        startCalled = true
        lastStartDuration = durationMinutes

        guard let timer = try? MeditationTimer(durationMinutes: durationMinutes) else { return }
        subject.send(timer.withState(.running))
    }

    func pause() {
        pauseCalled = true
    }

    func resume() {
        resumeCalled = true
    }

    func reset() {
        resetCalled = true
    }

    func stop() {
        stopCalled = true
    }

    func simulateTick(remainingSeconds: Int, state: TimerState = .running) {
        guard let timer = try? MeditationTimer(durationMinutes: 10) else { return }
        // Create a timer with custom remaining seconds (simplified for testing)
        subject.send(timer.withState(state))
    }

    func simulateCompletion() {
        guard var timer = try? MeditationTimer(durationMinutes: 1) else { return }
        timer = timer.withState(.completed)
        var completedTimer = timer
        // Tick to completion
        for _ in 0..<60 {
            completedTimer = completedTimer.tick()
        }
        subject.send(completedTimer)
    }
}

final class MockAudioService: AudioServiceProtocol {
    var configureAudioSessionCalled = false
    var playCompletionSoundCalled = false
    var stopCalled = false

    var shouldThrowOnConfigure = false
    var shouldThrowOnPlay = false

    func configureAudioSession() throws {
        configureAudioSessionCalled = true
        if shouldThrowOnConfigure {
            throw AudioServiceError.sessionConfigurationFailed
        }
    }

    func playCompletionSound() throws {
        playCompletionSoundCalled = true
        if shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func stop() {
        stopCalled = true
    }
}


// MARK: - Tests

@MainActor
final class TimerViewModelTests: XCTestCase {
    var sut: TimerViewModel!
    var mockTimerService: MockTimerService!
    var mockAudioService: MockAudioService!

    override func setUp() {
        super.setUp()
        mockTimerService = MockTimerService()
        mockAudioService = MockAudioService()

        sut = TimerViewModel(
            timerService: mockTimerService,
            audioService: mockAudioService
        )
    }

    override func tearDown() {
        sut = nil
        mockTimerService = nil
        mockAudioService = nil
        super.tearDown()
    }

    func testInitialState() {
        // Then
        XCTAssertEqual(sut.selectedMinutes, 10)
        XCTAssertEqual(sut.timerState, .idle)
        XCTAssertEqual(sut.remainingSeconds, 0)
        XCTAssertEqual(sut.totalSeconds, 0)
        XCTAssertEqual(sut.progress, 0.0)
        XCTAssertNil(sut.errorMessage)
    }

    func testAudioConfigurationOnInit() {
        // Then
        XCTAssertTrue(mockAudioService.configureAudioSessionCalled)
    }

    func testStartTimer() {
        // Given
        sut.selectedMinutes = 15

        // When
        sut.startTimer()

        // Then
        XCTAssertTrue(mockTimerService.startCalled)
        XCTAssertEqual(mockTimerService.lastStartDuration, 15)
    }

    func testPauseTimer() {
        // When
        sut.pauseTimer()

        // Then
        XCTAssertTrue(mockTimerService.pauseCalled)
    }

    func testResumeTimer() {
        // Given
        sut.remainingSeconds = 120

        // When
        sut.resumeTimer()

        // Then
        XCTAssertTrue(mockTimerService.resumeCalled)
    }

    func testResetTimer() {
        // When
        sut.resetTimer()

        // Then
        XCTAssertTrue(mockTimerService.resetCalled)
    }

    func testFormattedTime() {
        // Given
        sut.remainingSeconds = 0
        XCTAssertEqual(sut.formattedTime, "00:00")

        // When
        sut.remainingSeconds = 125 // 2:05
        XCTAssertEqual(sut.formattedTime, "02:05")

        // When
        sut.remainingSeconds = 3661 // 61:01
        XCTAssertEqual(sut.formattedTime, "61:01")
    }

    func testCanStartConditions() {
        // Given - idle state with valid minutes
        sut.timerState = .idle
        sut.selectedMinutes = 10
        XCTAssertTrue(sut.canStart)

        // When - running state
        sut.timerState = .running
        XCTAssertFalse(sut.canStart)

        // When - zero minutes
        sut.timerState = .idle
        sut.selectedMinutes = 0
        XCTAssertFalse(sut.canStart)
    }

    func testCanPauseConditions() {
        // Given - running state
        sut.timerState = .running
        XCTAssertTrue(sut.canPause)

        // When - idle state
        sut.timerState = .idle
        XCTAssertFalse(sut.canPause)

        // When - paused state
        sut.timerState = .paused
        XCTAssertFalse(sut.canPause)
    }

    func testCanResumeConditions() {
        // Given - paused state
        sut.timerState = .paused
        XCTAssertTrue(sut.canResume)

        // When - running state
        sut.timerState = .running
        XCTAssertFalse(sut.canResume)

        // When - idle state
        sut.timerState = .idle
        XCTAssertFalse(sut.canResume)
    }

    func testCanResetConditions() {
        // Given - idle state
        sut.timerState = .idle
        XCTAssertFalse(sut.canReset)

        // When - running state
        sut.timerState = .running
        XCTAssertTrue(sut.canReset)

        // When - paused state
        sut.timerState = .paused
        XCTAssertTrue(sut.canReset)

        // When - completed state
        sut.timerState = .completed
        XCTAssertTrue(sut.canReset)
    }

    func testTimerStateUpdatesFromService() {
        // Given
        let expectation = expectation(description: "State updates")

        // When
        sut.startTimer()

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
        mockTimerService.simulateCompletion()

        // Wait for sound to be triggered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Then
            XCTAssertTrue(self.mockAudioService.playCompletionSoundCalled)
            XCTAssertEqual(self.sut.timerState, .completed)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testErrorHandlingOnAudioConfiguration() {
        // Given
        mockAudioService.shouldThrowOnConfigure = true

        // When
        let viewModel = TimerViewModel(
            timerService: mockTimerService,
            audioService: mockAudioService
        )

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("audio") ?? false)
    }
}
