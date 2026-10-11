//
//  MeditationGongPlayerTests.swift
//  Still Moment
//
//  Infrastructure tests - start/end gong completion contract (shared-106, shared-143)
//

import AVFoundation
import XCTest
@testable import StillMoment

final class MeditationGongPlayerTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: MeditationGongPlayer!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var notificationCenter: NotificationCenter!

    override func setUp() {
        super.setUp()
        self.notificationCenter = NotificationCenter()
        self.sut = MeditationGongPlayer(notificationCenter: self.notificationCenter)
    }

    override func tearDown() {
        self.sut.stop()
        self.sut = nil
        self.notificationCenter = nil
        super.tearDown()
    }

    func testInterruption_whileGongRings_completesOnce() async {
        // Given: the gong rings
        let completed = self.expectation(description: "gong completion")
        completed.assertForOverFulfill = true
        self.sut.play(soundId: GongSound.defaultSoundId, volume: 0.5) {
            completed.fulfill()
        }

        // When: a phone call interrupts the gong (twice, to prove "exactly once")
        self.postInterruptionBegan()
        self.postInterruptionBegan()

        // Then: the flow is told the gong is over, so it never gets stuck
        await fulfillment(of: [completed], timeout: 1.0)
        await self.drainMainQueue()
    }

    func testStop_thenInterruption_doesNotComplete() async {
        // Given: the gong rings and the player is closed
        let completed = self.expectation(description: "gong completion")
        completed.isInverted = true
        self.sut.play(soundId: GongSound.defaultSoundId, volume: 0.5) {
            completed.fulfill()
        }
        self.sut.stop()

        // When
        self.postInterruptionBegan()

        // Then: a stopped gong stays silent — nothing continues the flow
        await fulfillment(of: [completed], timeout: 0.3)
    }

    // MARK: Private

    private func postInterruptionBegan() {
        self.notificationCenter.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
        )
    }

    /// Lets any further (unwanted) completion dispatched to main run before the test ends.
    private func drainMainQueue() async {
        let drained = self.expectation(description: "main queue drained")
        DispatchQueue.main.async {
            drained.fulfill()
        }
        await fulfillment(of: [drained], timeout: 1.0)
    }
}
