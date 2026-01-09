//
//  MockTimerService.swift
//  Still Moment
//

import Combine
@testable import StillMoment

// MARK: - Mock Services

final class MockTimerService: TimerServiceProtocol {
    // MARK: Internal

    var startCalled = false
    var pauseCalled = false
    var resumeCalled = false
    var resetCalled = false
    var stopCalled = false

    var lastStartDuration: Int?
    var lastStartPreparationTime: Int?

    var timerPublisher: AnyPublisher<MeditationTimer, Never> {
        self.subject.eraseToAnyPublisher()
    }

    func start(durationMinutes: Int, preparationTimeSeconds: Int) {
        self.startCalled = true
        self.lastStartDuration = durationMinutes
        self.lastStartPreparationTime = preparationTimeSeconds

        guard let timer = try? MeditationTimer(
            durationMinutes: durationMinutes,
            preparationTimeSeconds: preparationTimeSeconds
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
            preparationTimeSeconds: 0
        ) else {
            return
        }
        // Create a timer with custom remaining seconds (simplified for testing)
        self.subject.send(timer.withState(state))
    }

    func simulateCompletion() {
        guard var timer = try? MeditationTimer(
            durationMinutes: 1,
            preparationTimeSeconds: 0
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

    /// Simulates a running timer that has reached an interval gong point
    /// - Parameters:
    ///   - durationMinutes: Total timer duration in minutes
    ///   - elapsedSeconds: Number of seconds elapsed (to calculate remainingSeconds)
    func simulateTimerAtInterval(
        durationMinutes: Int,
        elapsedSeconds: Int
    ) {
        guard var timer = try? MeditationTimer(
            durationMinutes: durationMinutes,
            preparationTimeSeconds: 0
        ) else {
            return
        }

        // Start running
        timer = timer.withState(.running)

        // Tick to the elapsed time
        for _ in 0..<elapsedSeconds {
            timer = timer.tick()
        }

        self.currentTimerForTest = timer
        self.subject.send(timer)
    }

    /// Continues the current timer by ticking additional seconds
    /// This preserves the lastIntervalGongAt from previous markIntervalGongPlayed calls
    /// - Parameter additionalSeconds: Number of additional seconds to tick
    func continueTimer(additionalSeconds: Int) {
        guard var timer = currentTimerForTest else {
            return
        }

        for _ in 0..<additionalSeconds {
            timer = timer.tick()
        }

        self.currentTimerForTest = timer
        self.subject.send(timer)
    }

    /// Returns the current test timer (for verification)
    var currentTimerForTest: MeditationTimer?

    /// Marks interval gong as played on the current timer and emits update
    func markIntervalGongPlayed() {
        self.markIntervalGongPlayedCalled = true
        self.markIntervalGongPlayedCount += 1
        guard let timer = currentTimerForTest else {
            return
        }
        let updatedTimer = timer.markIntervalGongPlayed()
        self.currentTimerForTest = updatedTimer
        self.subject.send(updatedTimer)
    }

    var markIntervalGongPlayedCalled = false
    var markIntervalGongPlayedCount = 0

    // MARK: Private

    private let subject = PassthroughSubject<MeditationTimer, Never>()
}

final class MockAudioService: AudioServiceProtocol {
    var configureAudioSessionCalled = false
    var startBackgroundAudioCalled = false
    var stopBackgroundAudioCalled = false
    var pauseBackgroundAudioCalled = false
    var resumeBackgroundAudioCalled = false
    var playStartGongCalled = false
    var playIntervalGongCalled = false
    var playCompletionSoundCalled = false
    var playGongPreviewCalled = false
    var stopGongPreviewCalled = false
    var playBackgroundPreviewCalled = false
    var stopBackgroundPreviewCalled = false
    var stopCalled = false

    var lastStartGongSoundId: String?
    var lastStartGongVolume: Float?
    var lastIntervalGongVolume: Float?
    var lastCompletionSoundId: String?
    var lastCompletionSoundVolume: Float?
    var lastPreviewSoundId: String?
    var lastPreviewVolume: Float?
    var lastBackgroundPreviewSoundId: String?
    var lastBackgroundPreviewVolume: Float?
    var lastStartBackgroundAudioSoundId: String?
    var lastStartBackgroundAudioVolume: Float?

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

    func startBackgroundAudio(soundId: String, volume: Float) throws {
        self.startBackgroundAudioCalled = true
        self.lastStartBackgroundAudioSoundId = soundId
        self.lastStartBackgroundAudioVolume = volume
        self.audioCallOrder.append("startBackgroundAudio")
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func stopBackgroundAudio() {
        self.stopBackgroundAudioCalled = true
        self.audioCallOrder.append("stopBackgroundAudio")
    }

    func pauseBackgroundAudio() {
        self.pauseBackgroundAudioCalled = true
        self.audioCallOrder.append("pauseBackgroundAudio")
    }

    func resumeBackgroundAudio() {
        self.resumeBackgroundAudioCalled = true
        self.audioCallOrder.append("resumeBackgroundAudio")
    }

    func playStartGong(soundId: String, volume: Float) throws {
        self.playStartGongCalled = true
        self.lastStartGongSoundId = soundId
        self.lastStartGongVolume = volume
        self.audioCallOrder.append("playStartGong")
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func playIntervalGong(volume: Float) throws {
        self.playIntervalGongCalled = true
        self.lastIntervalGongVolume = volume
        self.audioCallOrder.append("playIntervalGong")
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func playCompletionSound(soundId: String, volume: Float) throws {
        self.playCompletionSoundCalled = true
        self.lastCompletionSoundId = soundId
        self.lastCompletionSoundVolume = volume
        self.audioCallOrder.append("playCompletionSound")
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func playGongPreview(soundId: String, volume: Float) throws {
        self.playGongPreviewCalled = true
        self.lastPreviewSoundId = soundId
        self.lastPreviewVolume = volume
        self.audioCallOrder.append("playGongPreview")
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func stopGongPreview() {
        self.stopGongPreviewCalled = true
        self.audioCallOrder.append("stopGongPreview")
    }

    func playBackgroundPreview(soundId: String, volume: Float) throws {
        self.playBackgroundPreviewCalled = true
        self.lastBackgroundPreviewSoundId = soundId
        self.lastBackgroundPreviewVolume = volume
        self.audioCallOrder.append("playBackgroundPreview")
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func stopBackgroundPreview() {
        self.stopBackgroundPreviewCalled = true
        self.audioCallOrder.append("stopBackgroundPreview")
    }

    func stop() {
        self.stopCalled = true
        self.audioCallOrder.append("stop")
    }
}
