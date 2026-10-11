//
//  AudioServiceInterruptionTests.swift
//  Still Moment
//
//  Infrastructure tests - phone calls and other interruptions during a silent meditation (shared-147)
//

import AVFoundation
import Combine
import XCTest
@testable import StillMoment

@MainActor
final class AudioServiceInterruptionTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: AudioService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var notificationCenter: NotificationCenter!
    var gongEnds = 0
    var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        self.notificationCenter = NotificationCenter()
        self.sut = AudioService.makeForTesting(notificationCenter: self.notificationCenter)
        self.gongEnds = 0
        self.sut.gongCompletionPublisher
            .sink { [weak self] in
                self?.gongEnds += 1
            }
            .store(in: &self.cancellables)
    }

    override func tearDown() {
        self.cancellables.removeAll()
        self.sut.stop()
        self.sut.deactivateTimerSession()
        self.sut = nil
        self.notificationCenter = nil
        super.tearDown()
    }

    // MARK: - Start gong

    func testInterruptionDuringStartGong_endsTheGongSoTheMeditationBegins() async throws {
        // Given
        try self.sut.activateTimerSession()
        try self.sut.playStartGong(soundId: GongSound.defaultSoundId, volume: 0.8)

        // When: a phone call comes in
        await self.postInterruptionBegan()

        // Then: the gong counts as over, exactly once
        XCTAssertEqual(self.gongEnds, 1)
    }

    func testSecondInterruptionDuringStartGong_endsTheGongOnlyOnce() async throws {
        // Given: the start gong was interrupted by a call
        try self.sut.activateTimerSession()
        try self.sut.playStartGong(soundId: GongSound.defaultSoundId, volume: 0.8)
        await self.postInterruptionBegan()

        // When: Siri interrupts during the call
        await self.postInterruptionBegan()

        // Then
        XCTAssertEqual(self.gongEnds, 1)
    }

    func testGongThatRangOut_reportsNoSecondEndOnInterruption() async throws {
        // Given: the start gong has rung out
        try self.sut.activateTimerSession()
        try self.sut.playStartGong(soundId: GongSound.defaultSoundId, volume: 0.8)
        self.sut.gongPlayerDelegate.onFinish()

        // When
        await self.postInterruptionBegan()

        // Then
        XCTAssertEqual(self.gongEnds, 1)
    }

    func testInterruptionDuringGongPreview_reportsNoTimerGongEnd() async throws {
        // Given: the user listens to a gong in the settings
        try self.sut.playGongPreview(soundId: GongSound.defaultSoundId, volume: 0.8)

        // When
        await self.postInterruptionBegan()

        // Then
        XCTAssertEqual(self.gongEnds, 0)
        self.sut.stopGongPreview()
    }

    // MARK: - End gong

    func testInterruptionDuringEndGong_endsTheGongSoTheCompletionScreenAppears() async throws {
        // Given
        try self.sut.activateTimerSession()
        try self.sut.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 0.8)

        // When
        await self.postInterruptionBegan()

        // Then
        XCTAssertEqual(self.gongEnds, 1)
    }

    func testInterruptionEndsAfterTheTimerFinished_noSoundStarts() async throws {
        // Given: end gong interrupted, the timer finished its session in response
        try self.sut.activateTimerSession()
        try self.sut.playCompletionSound(soundId: GongSound.defaultSoundId, volume: 0.8)
        await self.postInterruptionBegan()
        self.sut.deactivateTimerSession()

        // When: the system gives the sound back
        await self.postInterruptionEnded(shouldResume: true)

        // Then: nothing keeps the sound running in the background
        XCTAssertFalse(self.sut.isKeepAliveActive)
        XCTAssertFalse(self.sut.isBackgroundAudioPlaying)
    }

    // MARK: - Background sound

    func testInterruptionDuringMeditation_pausesTheBackgroundSound() async throws {
        // Given
        try self.sut.activateTimerSession()
        try self.sut.startBackgroundAudio(soundId: Self.audibleSoundId, volume: 0.15)

        // When
        await self.postInterruptionBegan()

        // Then
        XCTAssertFalse(self.sut.isBackgroundAudioPlaying)
    }

    func testSoundGivenBack_backgroundSoundPlaysAgain() async throws {
        // Given: the call paused the background sound (the system pauses every player)
        try self.sut.activateTimerSession()
        try self.sut.startBackgroundAudio(soundId: Self.audibleSoundId, volume: 0.15)
        self.sut.backgroundAudioPlayer?.pause()
        await self.postInterruptionBegan()

        // When
        await self.postInterruptionEnded(shouldResume: true)

        // Then
        XCTAssertTrue(self.sut.isBackgroundAudioPlaying)
        XCTAssertTrue(self.sut.isKeepAliveActive)
    }

    func testSoundNotGivenBack_backgroundSoundStaysOff() async throws {
        // Given
        try self.sut.activateTimerSession()
        try self.sut.startBackgroundAudio(soundId: Self.audibleSoundId, volume: 0.15)
        await self.postInterruptionBegan()

        // When
        await self.postInterruptionEnded(shouldResume: false)

        // Then: the background sound stays off, the timer keeps the app awake as before
        XCTAssertFalse(self.sut.isBackgroundAudioPlaying)
        XCTAssertTrue(self.sut.isKeepAliveActive)
    }

    func testSilentMeditation_soundGivenBack_onlyKeepAlivePlays() async throws {
        // Given: meditation without background sound
        try self.sut.activateTimerSession()
        await self.postInterruptionBegan()

        // When
        await self.postInterruptionEnded(shouldResume: true)

        // Then
        XCTAssertFalse(self.sut.isBackgroundAudioPlaying)
        XCTAssertTrue(self.sut.isKeepAliveActive)
    }

    func testTimerResetDuringInterruption_nothingPlaysAfterwards() async throws {
        // Given: interruption during a meditation with background sound
        try self.sut.activateTimerSession()
        try self.sut.startBackgroundAudio(soundId: Self.audibleSoundId, volume: 0.15)
        await self.postInterruptionBegan()

        // When: the user resets the timer, then the call ends
        self.sut.stop()
        self.sut.deactivateTimerSession()
        await self.postInterruptionEnded(shouldResume: true)

        // Then
        XCTAssertFalse(self.sut.isBackgroundAudioPlaying)
        XCTAssertFalse(self.sut.isKeepAliveActive)
    }

    // MARK: Helpers

    /// A bundled background sound that actually plays (not "silent")
    static let audibleSoundId = "forest"

    func postInterruptionBegan() async {
        await self.postInterruption(userInfo: [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
        ])
    }

    func postInterruptionEnded(shouldResume: Bool) async {
        let options: AVAudioSession.InterruptionOptions = shouldResume ? .shouldResume : []
        await self.postInterruption(userInfo: [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
            AVAudioSessionInterruptionOptionKey: options.rawValue
        ])
    }

    func postInterruption(userInfo: [AnyHashable: Any]) async {
        self.notificationCenter.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: userInfo
        )
        // Let anything the service dispatched to the main queue catch up
        let drained = self.expectation(description: "main queue drained")
        DispatchQueue.main.async {
            drained.fulfill()
        }
        await fulfillment(of: [drained], timeout: 1.0)
    }
}
