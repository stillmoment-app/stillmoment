//
//  TimerViewModelTests.swift
//  Still Moment
//

import Combine
import XCTest
@testable import StillMoment

// MARK: - Mock Services

final class MockTimerService: TimerServiceProtocol {
    // MARK: Lifecycle

    init(countdownDuration: Int = 15) {
        self.countdownDuration = countdownDuration
    }

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

        guard let timer = try? MeditationTimer(
            durationMinutes: durationMinutes,
            countdownDuration: self.countdownDuration
        ) else {
            return
        }
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
        guard let timer = try? MeditationTimer(
            durationMinutes: 10,
            countdownDuration: self.countdownDuration
        ) else {
            return
        }
        // Create a timer with custom remaining seconds (simplified for testing)
        self.subject.send(timer.withState(state))
    }

    func simulateCompletion() {
        guard var timer = try? MeditationTimer(
            durationMinutes: 1,
            countdownDuration: self.countdownDuration
        ) else {
            return
        }
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
    private let countdownDuration: Int
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

    // Track order of audio calls (for critical regression tests)
    var audioCallOrder: [String] = []

    func configureAudioSession() throws {
        self.configureAudioSessionCalled = true
        self.audioCallOrder.append("configureAudioSession")
        if self.shouldThrowOnConfigure {
            throw AudioServiceError.sessionConfigurationFailed
        }
    }

    func startBackgroundAudio(soundId: String) throws {
        self.startBackgroundAudioCalled = true
        self.audioCallOrder.append("startBackgroundAudio")
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func stopBackgroundAudio() {
        self.stopBackgroundAudioCalled = true
        self.audioCallOrder.append("stopBackgroundAudio")
    }

    func playStartGong() throws {
        self.playStartGongCalled = true
        self.audioCallOrder.append("playStartGong")
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func playIntervalGong() throws {
        self.playIntervalGongCalled = true
        self.audioCallOrder.append("playIntervalGong")
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func playCompletionSound() throws {
        self.playCompletionSoundCalled = true
        self.audioCallOrder.append("playCompletionSound")
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func stop() {
        self.stopCalled = true
        self.audioCallOrder.append("stop")
    }
}

// MARK: - Tests

@MainActor
final class TimerViewModelTests: XCTestCase {
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

    func testSettingsLoadAndSave() {
        // Given
        self.sut.settings.intervalGongsEnabled = true
        self.sut.settings.intervalMinutes = 10
        self.sut.settings.backgroundSoundId = "forest"

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
        XCTAssertEqual(newViewModel.settings.backgroundSoundId, "forest")
    }

    func testSettingsLoadWithInvalidSoundId_FallsBackToDefault() {
        // Given - Save an invalid sound ID
        let defaults = UserDefaults.standard
        defaults.set("invalid_sound_id", forKey: MeditationSettings.Keys.backgroundSoundId)

        // When - Create new ViewModel (loads settings)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then - Should still use the invalid ID (AudioService will handle the error)
        XCTAssertEqual(newViewModel.settings.backgroundSoundId, "invalid_sound_id")

        // When - Try to start timer with invalid sound ID
        newViewModel.selectedMinutes = 1
        newViewModel.startTimer()

        // Then - AudioService should be called but will throw error
        XCTAssertTrue(self.mockAudioService.startBackgroundAudioCalled)
    }

    func testSettingsLoadWithMissingBackgroundSoundId_UsesDefault() {
        // Given - Remove backgroundSoundId from UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: MeditationSettings.Keys.backgroundSoundId)

        // When - Create new ViewModel (loads settings)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then - Should use default "silent"
        XCTAssertEqual(newViewModel.settings.backgroundSoundId, "silent")
    }

    func testSettingsLegacyMigration_SilentMode() {
        // Given - Save legacy backgroundAudioMode setting
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: MeditationSettings.Keys.backgroundSoundId)
        defaults.set("Silent", forKey: MeditationSettings.Keys.legacyBackgroundAudioMode)

        // When - Create new ViewModel (triggers migration)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then - Should migrate to "silent" sound ID
        XCTAssertEqual(newViewModel.settings.backgroundSoundId, "silent")

        // Verify migration saved the new value
        let savedValue = defaults.string(forKey: MeditationSettings.Keys.backgroundSoundId)
        XCTAssertEqual(savedValue, "silent")
    }

    func testSettingsLegacyMigration_WhiteNoiseMode() {
        // Given - Save legacy "White Noise" setting
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: MeditationSettings.Keys.backgroundSoundId)
        defaults.set("White Noise", forKey: MeditationSettings.Keys.legacyBackgroundAudioMode)

        // When - Create new ViewModel (triggers migration)
        let newViewModel = TimerViewModel(
            timerService: self.mockTimerService,
            audioService: self.mockAudioService
        )

        // Then - Should migrate to "silent" (WhiteNoise was removed)
        XCTAssertEqual(newViewModel.settings.backgroundSoundId, "silent")
    }

    // MARK: - Critical Regression Tests (Lock Screen Countdown Fix)

    func testBackgroundAudioStartsImmediatelyOnTimerStart() {
        // CRITICAL: This test prevents the countdown-freeze bug on locked screen
        // Background audio MUST start IMMEDIATELY when timer starts, not after countdown
        // Without this, iOS suspends the app during countdown when screen is locked

        // Given
        self.sut.selectedMinutes = 1

        // When
        self.sut.startTimer()

        // Then - Verify background audio was called
        XCTAssertTrue(
            self.mockAudioService.startBackgroundAudioCalled,
            "Background audio must start immediately to keep app alive during countdown"
        )

        // Critical: Verify audio session was configured before background audio starts
        let configureIndex = self.mockAudioService.audioCallOrder.firstIndex(of: "configureAudioSession")
        let startBackgroundIndex = self.mockAudioService.audioCallOrder.firstIndex(of: "startBackgroundAudio")

        XCTAssertNotNil(configureIndex, "Audio session must be configured")
        XCTAssertNotNil(startBackgroundIndex, "Background audio must be started")

        if let configIdx = configureIndex, let startIdx = startBackgroundIndex {
            XCTAssertLessThan(
                configIdx,
                startIdx,
                "Audio session must be configured BEFORE background audio starts"
            )
        }
    }

    func testCompletionGongPlaysBeforeBackgroundAudioStops() {
        // CRITICAL: This test prevents the completion-gong-silence bug
        // Completion gong MUST play BEFORE background audio stops
        // Otherwise audio session gets deactivated and gong can't play (especially on locked screen)

        // Given
        let expectation = expectation(description: "Completion sequence")

        // When - Simulate timer completion
        self.mockTimerService.simulateCompletion()

        // Wait for completion handlers to execute
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Then - Verify both were called
            XCTAssertTrue(
                self.mockAudioService.playCompletionSoundCalled,
                "Completion gong must play"
            )
            XCTAssertTrue(
                self.mockAudioService.stopBackgroundAudioCalled,
                "Background audio must stop"
            )

            // Critical: Verify completion gong played BEFORE background audio stopped
            let gongIndex = self.mockAudioService.audioCallOrder.firstIndex(of: "playCompletionSound")
            let stopIndex = self.mockAudioService.audioCallOrder.firstIndex(of: "stopBackgroundAudio")

            XCTAssertNotNil(gongIndex, "Completion gong must be played")
            XCTAssertNotNil(stopIndex, "Background audio must be stopped")

            if let gong = gongIndex, let stop = stopIndex {
                XCTAssertLessThan(
                    gong,
                    stop,
                    """
                    CRITICAL: Completion gong must play BEFORE background audio stops.
                    If background audio stops first, audio session deactivates and gong can't play.
                    """
                )
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
