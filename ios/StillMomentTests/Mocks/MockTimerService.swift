//
//  MockTimerService.swift
//  Still Moment
//

import Combine
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
    var pauseBackgroundAudioCalled = false
    var resumeBackgroundAudioCalled = false
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

    func pauseBackgroundAudio() {
        self.pauseBackgroundAudioCalled = true
        self.audioCallOrder.append("pauseBackgroundAudio")
    }

    func resumeBackgroundAudio() {
        self.resumeBackgroundAudioCalled = true
        self.audioCallOrder.append("resumeBackgroundAudio")
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
