//
//  MockAudioSessionCoordinator.swift
//  Still Moment
//
//  Test Mocks for Audio Player

import Combine
import Foundation
@testable import StillMoment

// MARK: - Mock Now Playing Info Provider

final class MockNowPlayingInfoProvider: NowPlayingInfoProvider {
    var nowPlayingInfo: [String: Any]?
}

// MARK: - Mock Audio Session Coordinator

final class MockAudioSessionCoordinator: AudioSessionCoordinatorProtocol {
    // MARK: Internal

    let activeSource = CurrentValueSubject<AudioSource?, Never>(nil)
    var requestedSources: [AudioSource] = []
    var releasedSources: [AudioSource] = []
    var activationCount = 0
    var deactivationCount = 0
    var shouldFailActivation = false

    func registerConflictHandler(for source: AudioSource, handler: @escaping () -> Void) {
        self.conflictHandlers[source] = handler
    }

    func requestAudioSession(for source: AudioSource) throws -> Bool {
        self.requestedSources.append(source)

        if self.shouldFailActivation {
            throw AudioSessionCoordinatorError.sessionActivationFailed
        }

        // If another source is active, call its conflict handler
        if let currentSource = activeSource.value, currentSource != source {
            self.conflictHandlers[currentSource]?()
        }

        self.activeSource.send(source)
        return true
    }

    func releaseAudioSession(for source: AudioSource) {
        self.releasedSources.append(source)
        if self.activeSource.value == source {
            self.activeSource.send(nil)
        }
    }

    func activateAudioSession() throws {
        self.activationCount += 1
        if self.shouldFailActivation {
            throw AudioSessionCoordinatorError.sessionActivationFailed
        }
    }

    func deactivateAudioSession() {
        self.deactivationCount += 1
    }

    // MARK: Private

    private var conflictHandlers: [AudioSource: () -> Void] = [:]
}
