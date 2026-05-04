//
//  MockTimerService.swift
//  Still Moment
//

import Combine
import Foundation
@testable import StillMoment

// MARK: - Mock Services

final class MockTimerService: TimerServiceProtocol {
    // MARK: Internal

    var startCalled = false
    var resetCalled = false
    var stopCalled = false

    var lastStartDuration: Int?
    var lastStartPreparationTime: Int?
    var lastStartIntervalSettings: IntervalSettings?

    var timerPublisher: AnyPublisher<(MeditationTimer, [TimerEvent]), Never> {
        self.subject.eraseToAnyPublisher()
    }

    func start(durationMinutes: Int, preparationTimeSeconds: Int, intervalSettings: IntervalSettings?) {
        self.startCalled = true
        self.lastStartDuration = durationMinutes
        self.lastStartPreparationTime = preparationTimeSeconds
        self.lastStartIntervalSettings = intervalSettings

        guard let timer = try? MeditationTimer(
            durationMinutes: durationMinutes,
            preparationTimeSeconds: preparationTimeSeconds
        ) else {
            return
        }
        let startGongTimer = timer.withState(.startGong)
        self.currentTimerForTest = startGongTimer
        self.subject.send((startGongTimer, []))
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
        self.subject.send((timer.withState(state), []))
    }

    func simulateCompletion() {
        guard var timer = try? MeditationTimer(
            durationMinutes: 1,
            preparationTimeSeconds: 0
        ) else {
            return
        }
        timer = timer.withState(.running)
        // Tick to endGong (timer reaches zero → .endGong state)
        for _ in 0..<60 {
            (timer, _) = timer.tick()
        }
        self.subject.send((timer, [.meditationCompleted]))
    }

    /// Simulates a running timer that has reached an interval gong point.
    /// The mock sends the timer with an `.intervalGongDue` event, mirroring
    /// how the real TimerService emits events from `tick()`.
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

        // Start running directly
        timer = timer.withState(.running)

        // Tick elapsed time in running state
        for _ in 0..<elapsedSeconds {
            (timer, _) = timer.tick()
        }

        self.currentTimerForTest = timer
        // Emit intervalGongDue event — in the real system, tick() detects and emits this
        self.subject.send((timer, [.intervalGongDue]))
    }

    /// Continues the current timer by ticking additional seconds.
    /// Emits `.intervalGongDue` if the timer's `shouldPlayIntervalGong` returns true
    /// for the configured interval settings.
    /// - Parameters:
    ///   - additionalSeconds: Number of additional seconds to tick
    ///   - intervalSettings: Interval configuration to check gong conditions
    func continueTimer(additionalSeconds: Int, intervalSettings: IntervalSettings? = nil) {
        guard var timer = currentTimerForTest else {
            return
        }

        var events: [TimerEvent] = []
        for _ in 0..<additionalSeconds {
            let (ticked, tickEvents) = timer.tick(intervalSettings: intervalSettings)
            timer = ticked
            events.append(contentsOf: tickEvents)
        }

        self.currentTimerForTest = timer
        self.subject.send((timer, events))
    }

    /// Returns the current test timer (for verification)
    var currentTimerForTest: MeditationTimer?

    var beginRunningPhaseCalled = false

    func beginRunningPhase() {
        self.beginRunningPhaseCalled = true
        guard let timer = currentTimerForTest else {
            return
        }
        let updatedTimer = timer.withState(.running)
        self.currentTimerForTest = updatedTimer
        self.subject.send((updatedTimer, []))
    }

    // MARK: Private

    private let subject = PassthroughSubject<(MeditationTimer, [TimerEvent]), Never>()
}

final class MockAudioService: AudioServiceProtocol {
    let gongCompletionSubject = PassthroughSubject<Void, Never>()
    var gongCompletionPublisher: AnyPublisher<Void, Never> {
        self.gongCompletionSubject.eraseToAnyPublisher()
    }

    var configureAudioSessionCalled = false
    var activateTimerSessionCalled = false
    var deactivateTimerSessionCalled = false
    var startBackgroundAudioCalled = false
    var stopBackgroundAudioCalled = false
    var playStartGongCalled = false
    var playIntervalGongCalled = false
    var playCompletionSoundCalled = false
    var playGongPreviewCalled = false
    var stopGongPreviewCalled = false
    var playBackgroundPreviewCalled = false
    var stopBackgroundPreviewCalled = false
    var playMeditationPreviewCalled = false
    var stopMeditationPreviewCalled = false
    var stopCalled = false

    var lastStartGongSoundId: String?
    var lastStartGongVolume: Float?
    var lastIntervalGongSoundId: String?
    var lastIntervalGongVolume: Float?
    var lastCompletionSoundId: String?
    var lastCompletionSoundVolume: Float?
    var lastPreviewSoundId: String?
    var lastPreviewVolume: Float?
    var lastBackgroundPreviewSoundId: String?
    var lastBackgroundPreviewVolume: Float?
    var lastMeditationPreviewFileURL: URL?
    var lastStartBackgroundAudioSoundId: String?
    var lastStartBackgroundAudioVolume: Float?

    var shouldThrowOnConfigure = false
    var shouldThrowOnPlay = false

    /// Track order of audio calls (for critical regression tests)
    var audioCallOrder: [String] = []

    func configureAudioSession() throws {
        self.configureAudioSessionCalled = true
        self.audioCallOrder.append("configureAudioSession")
        if self.shouldThrowOnConfigure {
            throw AudioServiceError.sessionConfigurationFailed
        }
    }

    func activateTimerSession() throws {
        self.activateTimerSessionCalled = true
        self.audioCallOrder.append("activateTimerSession")
        if self.shouldThrowOnConfigure {
            throw AudioServiceError.sessionConfigurationFailed
        }
    }

    func deactivateTimerSession() {
        self.deactivateTimerSessionCalled = true
        self.audioCallOrder.append("deactivateTimerSession")
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

    func playStartGong(soundId: String, volume: Float) throws {
        self.playStartGongCalled = true
        self.lastStartGongSoundId = soundId
        self.lastStartGongVolume = volume
        self.audioCallOrder.append("playStartGong")
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func playIntervalGong(soundId: String, volume: Float) throws {
        self.playIntervalGongCalled = true
        self.lastIntervalGongSoundId = soundId
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

    func playMeditationPreview(fileURL: URL) throws {
        self.playMeditationPreviewCalled = true
        self.lastMeditationPreviewFileURL = fileURL
        self.audioCallOrder.append("playMeditationPreview")
        if self.shouldThrowOnPlay {
            throw AudioServiceError.playbackFailed
        }
    }

    func stopMeditationPreview() {
        self.stopMeditationPreviewCalled = true
        self.audioCallOrder.append("stopMeditationPreview")
    }

    func stop() {
        self.stopCalled = true
        self.audioCallOrder.append("stop")
    }
}
