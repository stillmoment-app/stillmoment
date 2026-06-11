//
//  MockMeditationGongPlayer.swift
//  Still Moment
//
//  Mock MeditationGongPlayerProtocol for unit tests (shared-106)
//

import Foundation
@testable import StillMoment

final class MockMeditationGongPlayer: MeditationGongPlayerProtocol {
    private(set) var playCallCount = 0
    private(set) var playedSoundId: String?
    private(set) var playedVolume: Float?
    private(set) var stopCalled = false

    private var pendingCompletion: (() -> Void)?

    func play(soundId: String, volume: Float, completion: @escaping () -> Void) {
        self.playCallCount += 1
        self.playedSoundId = soundId
        self.playedVolume = volume
        self.pendingCompletion = completion
    }

    func stop() {
        self.stopCalled = true
        self.pendingCompletion = nil
    }

    /// Simulates the gong finishing — fires the captured completion once.
    func finishPlaying() {
        let completion = self.pendingCompletion
        self.pendingCompletion = nil
        completion?()
    }
}
