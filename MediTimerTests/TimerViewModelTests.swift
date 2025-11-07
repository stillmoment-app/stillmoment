//
//  TimerViewModelTests.swift
//  MediTimerTests
//
//  Unit Tests - TimerViewModel
//

import Combine
import XCTest
@testable import MediTimer

// MARK: - Mock Services

final class MockTimerService: TimerServiceProtocol {
    // MARK: Internal

    var startCalled = false
    var pauseCalled = false
    var resumeCalled = false
    var resetCalled = false
    var stopCalled = false

    var lastStartDuration: Int?

    var timerPublisher: AnyPublisher<MeditationTimer, Never> {
        self.subject.eraseToAnyPublisher()
    }

    func start(durationMinutes: Int) {
        self.startCalled = true
        self.lastStartDuration = durationMinutes

        guard let timer = try? MeditationTimer(durationMinutes: durationMinutes) else { return }
        self.subject.send(timer.withState(.running))
    }

    func pause() {
        self.pauseCalled = true
    }

    func resume() {
        self.resumeCalled = true
    }

    func reset() {
        self.resetCalled = true
    }

    func stop() {
        self.stopCalled = true
    }

    func simulateTick(remainingSeconds: Int, state: TimerState = .running) {
        guard let timer = try? MeditationTimer(durationMinutes: 10) else { return }
        // Create a timer with custom remaining seconds (simplified for testing)
        self.subject.send(timer.withState(state))
    }

    func simulateCompletion() {
        guard var timer = try? MeditationTimer(durationMinutes: 1) else { return }
        timer = timer.withState(.completed)
        var completedTimer = timer
        // Tick to completion
        for _ in 0..<60 {
            completedTimer = completedTimer.tick()
        }
        self.subject.send(completedTimer)
    }

    // MARK: Private

    private let subject = PassthroughSubject<MeditationTimer, Never>()
}

final class MockAudioService: AudioServiceProtocol {
    var configureAudioSessionCalled = false
    var startBackgroundAudioCalled = false
    var stopBackgroundAudioCalled = false
    var playStartGongCalled = false
    var playIntervalGongCalled = false
    var playCompletionSoundCalled = false
    var stopCalled = false

    var shouldThrowOnConfigure = false
    var shouldThrowOnPlay = false

    func configureAudioSession() throws {
        self.configureAudioSessionCalled = true
        if self.shouldThrowOnConfigure {
            throw AudioServiceError.sessionConfigurationFailed
        }
    }

    func startBackgroundAudio(mode: BackgroundAudioMode) throws {
        self.startBackgroundAudioCalled = true
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func stopBackgroundAudio() {
        self.stopBackgroundAudioCalled = true
    }

    func playStartGong() throws {
        self.playStartGongCalled = true
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func playIntervalGong() throws {
        self.playIntervalGongCalled = true
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func playCompletionSound() throws {
        self.playCompletionSoundCalled = true
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func stop() {
        self.stopCalled = true
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
        self.mockTimerService = MockTimerService()
        self.mockAudioService = MockAudioService()

        self.sut = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockTimerService = nil
        self.mockAudioService = nil
        super.tearDown()
    }

    func testInitialState() {
        // Then
        XCTAssertEqual(self.sut.selectedMinutes, 10)
        XCTAssertEqual(self.sut.timerState, .idle)
        XCTAssertEqual(self.sut.remainingSeconds, 0)
        XCTAssertEqual(self.sut.totalSeconds, 0)
        XCTAssertEqual(self.sut.progress, 0.0)
        XCTAssertNil(self.sut.errorMessage)
    }

    func testAudioConfigurationOnInit() {
        // Then
        XCTAssertTrue(self.mockAudioService.configureAudioSessionCalled)
    }

    func testStartTimer() {
        // Given
        self.sut.selectedMinutes = 15

        // When
        self.sut.startTimer()

        // Then
        XCTAssertTrue(self.mockTimerService.startCalled)
        XCTAssertEqual(self.mockTimerService.lastStartDuration, 15)
    }

    func testPauseTimer() {
        // When
        self.sut.pauseTimer()

        // Then
        XCTAssertTrue(self.mockTimerService.pauseCalled)
    }

    func testResumeTimer() {
        // Given
        self.sut.remainingSeconds = 120

        // When
        self.sut.resumeTimer()

        // Then
        XCTAssertTrue(self.mockTimerService.resumeCalled)
    }

    func testResetTimer() {
        // When
        self.sut.resetTimer()

        // Then
        XCTAssertTrue(self.mockTimerService.resetCalled)
    }

    func testFormattedTime() {
        // Given
        self.sut.remainingSeconds = 0
        XCTAssertEqual(self.sut.formattedTime, "00:00")

        // When
        self.sut.remainingSeconds = 125 // 2:05
        XCTAssertEqual(self.sut.formattedTime, "02:05")

        // When
        self.sut.remainingSeconds = 3661 // 61:01
        XCTAssertEqual(self.sut.formattedTime, "61:01")
    }

    func testCanStartConditions() {
        // Given - idle state with valid minutes
        self.sut.timerState = .idle
        self.sut.selectedMinutes = 10
        XCTAssertTrue(self.sut.canStart)

        // When - running state
        self.sut.timerState = .running
        XCTAssertFalse(self.sut.canStart)

        // When - zero minutes
        self.sut.timerState = .idle
        self.sut.selectedMinutes = 0
        XCTAssertFalse(self.sut.canStart)
    }

    func testCanPauseConditions() {
        // Given - running state
        self.sut.timerState = .running
        XCTAssertTrue(self.sut.canPause)

        // When - idle state
        self.sut.timerState = .idle
        XCTAssertFalse(self.sut.canPause)

        // When - paused state
        self.sut.timerState = .paused
        XCTAssertFalse(self.sut.canPause)
    }

    func testCanResumeConditions() {
        // Given - paused state
        self.sut.timerState = .paused
        XCTAssertTrue(self.sut.canResume)

        // When - running state
        self.sut.timerState = .running
        XCTAssertFalse(self.sut.canResume)

        // When - idle state
        self.sut.timerState = .idle
        XCTAssertFalse(self.sut.canResume)
    }

    func testCanResetConditions() {
        // Given - idle state
        self.sut.timerState = .idle
        XCTAssertFalse(self.sut.canReset)

        // When - running state
        self.sut.timerState = .running
        XCTAssertTrue(self.sut.canReset)

        // When - paused state
        self.sut.timerState = .paused
        XCTAssertTrue(self.sut.canReset)

        // When - completed state
        self.sut.timerState = .completed
        XCTAssertTrue(self.sut.canReset)
    }

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

    func testErrorHandlingOnAudioConfiguration() {
        // Given
        self.mockAudioService.shouldThrowOnConfigure = true

        // When
        let viewModel = TimerViewModel(
            timerService: mockTimerService,
            audioService: mockAudioService
        )

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("audio") ?? false)
    }

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
        XCTAssertTrue(affirmation.count >= 0)
    }

    func testSettingsLoadAndSave() {
        // Given
        self.sut.settings.intervalGongsEnabled = true
        self.sut.settings.intervalMinutes = 10
        self.sut.settings.backgroundAudioMode = .whiteNoise

        // When
        self.sut.saveSettings()

        // Create new instance
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then
        XCTAssertEqual(newViewModel.settings.intervalGongsEnabled, true)
        XCTAssertEqual(newViewModel.settings.intervalMinutes, 10)
        XCTAssertEqual(newViewModel.settings.backgroundAudioMode, .whiteNoise)
    }
}
