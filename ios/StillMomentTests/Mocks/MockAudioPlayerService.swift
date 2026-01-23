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

    var loadedMeditation: GuidedMeditation?
    var loadedURL: URL?
    var loadShouldThrow = false
    var playCalled = false
    var pauseCalled = false
    var stopCalled = false
    var seekTime: TimeInterval?
    var cleanupCalled = false
    var setupRemoteCommandCenterCalled = false
    var silentBackgroundAudioStarted = false
    var silentBackgroundAudioStopped = false
    var transitionFromSilentToPlaybackCalled = false

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
        self.state.send(.playing)
    }

    func pause() {
        self.pauseCalled = true
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
        self.silentBackgroundAudioStarted = true
    }

    func stopSilentBackgroundAudio() {
        self.silentBackgroundAudioStopped = true
    }

    func transitionFromSilentToPlayback() throws {
        self.transitionFromSilentToPlaybackCalled = true
        // Real implementation starts playback then stops silent audio
        self.playCalled = true
        self.state.send(.playing)
        self.silentBackgroundAudioStopped = true
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
