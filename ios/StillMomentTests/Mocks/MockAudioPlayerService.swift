//
//  MockAudioPlayerService.swift
//  Still Moment
//

import Combine
import Foundation
@testable import StillMoment

final class MockAudioPlayerService: AudioPlayerServiceProtocol {
    var state = CurrentValueSubject<PlaybackState, Never>(.idle)
    var currentTime = CurrentValueSubject<TimeInterval, Never>(0)
    var duration = CurrentValueSubject<TimeInterval, Never>(0)
    let interruptionBegan = PassthroughSubject<Void, Never>()
    let interruptionEnded = PassthroughSubject<Void, Never>()

    var loadedMeditation: GuidedMeditation?
    var loadedURL: URL?
    var loadShouldThrow = false
    var playCalled = false
    private(set) var playCallCount = 0
    var pauseCalled = false
    var stopCalled = false
    var seekTime: TimeInterval?
    var cleanupCalled = false
    var setupRemoteCommandCenterCalled = false
    var silentBackgroundAudioStarted = false
    var silentBackgroundAudioStopped = false
    /// Simulates a phone call still holding the sound: the audio session cannot be activated
    var startSilentBackgroundAudioShouldThrow = false
    var transitionFromSilentToPlaybackCalled = false
    private(set) var transitionFromSilentToPlaybackCallCount = 0
    var configureEndGongCalled = false
    var endGongSoundId: String?
    var endGongVolume: Float?
    private var resumesAfterInterruption = false

    func load(url: URL, meditation: GuidedMeditation) async throws {
        if self.loadShouldThrow {
            throw AudioPlayerError.playbackFailed(reason: "Mock error")
        }
        self.loadedURL = url
        self.loadedMeditation = meditation
        self.state.send(.paused)
        self.duration.send(600) // 10 minutes
    }

    func play() throws {
        self.playCalled = true
        self.playCallCount += 1
        self.resumesAfterInterruption = false
        self.state.send(.playing)
    }

    func pause() {
        self.pauseCalled = true
        self.resumesAfterInterruption = false
        self.state.send(.paused)
    }

    func stop() {
        self.stopCalled = true
        self.state.send(.idle)
        self.currentTime.send(0)
    }

    func seek(to time: TimeInterval) throws {
        self.seekTime = time
        self.currentTime.send(time)
    }

    func configureAudioSession() throws {
        // Mock implementation
    }

    func setupRemoteCommandCenter() {
        self.setupRemoteCommandCenterCalled = true
    }

    func startSilentBackgroundAudio() throws {
        if self.startSilentBackgroundAudioShouldThrow {
            throw AudioPlayerError.audioSessionFailed
        }
        self.silentBackgroundAudioStarted = true
    }

    func stopSilentBackgroundAudio() {
        self.silentBackgroundAudioStopped = true
    }

    func transitionFromSilentToPlayback() throws {
        self.transitionFromSilentToPlaybackCalled = true
        self.transitionFromSilentToPlaybackCallCount += 1
        // Real implementation starts playback then stops silent audio
        self.playCalled = true
        self.state.send(.playing)
        self.silentBackgroundAudioStopped = true
    }

    func configureEndGong(soundId: String, volume: Float) {
        self.configureEndGongCalled = true
        self.endGongSoundId = soundId
        self.endGongVolume = volume
    }

    /// Simulates a phone call like the real service: running playback pauses, then the
    /// interruption is reported (ios-065).
    func simulateInterruption() {
        if self.state.value == .playing {
            self.pause()
            self.resumesAfterInterruption = true
        }
        self.interruptionBegan.send()
    }

    /// Simulates the end of a phone call like the real service (shared-146): when the system
    /// gives the sound back, playback the call paused resumes, then the end is reported.
    func simulateInterruptionEnded(withResume: Bool) {
        if withResume {
            if self.resumesAfterInterruption {
                try? self.play()
            }
            self.interruptionEnded.send()
        }
        self.resumesAfterInterruption = false
    }

    func cleanup() {
        self.cleanupCalled = true
        self.state.send(.idle)
        self.currentTime.send(0)
        self.duration.send(0)
        self.silentBackgroundAudioStarted = false
        self.silentBackgroundAudioStopped = false
        self.transitionFromSilentToPlaybackCalled = false
    }
}
