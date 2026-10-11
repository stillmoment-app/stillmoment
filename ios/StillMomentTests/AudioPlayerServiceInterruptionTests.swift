//
//  AudioPlayerServiceInterruptionTests.swift
//  Still Moment
//
//  Infrastructure tests - phone calls and other interruptions during a guided meditation (ios-065)
//

import AVFoundation
import Combine
import MediaPlayer
import XCTest
@testable import StillMoment

@MainActor
final class AudioPlayerServiceInterruptionTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: AudioPlayerService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockNowPlayingProvider: MockNowPlayingInfoProvider!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var notificationCenter: NotificationCenter!

    override func setUp() {
        super.setUp()
        self.mockNowPlayingProvider = MockNowPlayingInfoProvider()
        self.notificationCenter = NotificationCenter()
        self.sut = AudioPlayerService(
            coordinator: MockAudioSessionCoordinator(),
            nowPlayingProvider: self.mockNowPlayingProvider,
            soundRepository: BackgroundSoundRepository(),
            gongPlayer: MockMeditationGongPlayer(),
            notificationCenter: self.notificationCenter
        )
    }

    override func tearDown() {
        self.sut.cleanup()
        self.sut = nil
        self.mockNowPlayingProvider = nil
        self.notificationCenter = nil
        super.tearDown()
    }

    // MARK: - While the interruption lasts

    func testInterruption_whilePlaying_pausesAlsoOnLockScreen() async throws {
        // Given
        try await self.loadMeditation()
        try self.sut.play()

        // When: a phone call comes in
        await self.postInterruptionBegan()

        // Then: paused in the app and on the lock screen
        XCTAssertEqual(self.sut.state.value, .paused)
        let rate = self.mockNowPlayingProvider.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] as? Double
        XCTAssertEqual(rate, 0.0)
    }

    func testInterruption_afterSecondMeditationWasLoaded_stillPauses() async throws {
        // Given: a second meditation was loaded into the same player
        try await self.loadMeditation()
        try await self.loadMeditation()
        try self.sut.play()

        // When
        await self.postInterruptionBegan()

        // Then
        XCTAssertEqual(self.sut.state.value, .paused)
    }

    func testInterruption_afterMeditationFinished_keepsItFinished() async throws {
        // Given: the meditation has ended (completion screen, end gong may still ring)
        try await self.loadMeditation()
        try self.sut.play()
        self.sut.state.send(.finished)

        // When
        await self.postInterruptionBegan()

        // Then
        XCTAssertEqual(self.sut.state.value, .finished)
    }

    func testInterruption_whilePlaying_isReportedToThePlayer() async throws {
        // Given
        try await self.loadMeditation()
        try self.sut.play()
        var reported = 0
        let subscription = self.sut.interruptionBegan.sink { reported += 1 }

        // When
        await self.postInterruptionBegan()

        // Then: the player learns about it, e.g. to abort the pre-roll
        XCTAssertEqual(reported, 1)
        subscription.cancel()
    }

    // MARK: - After the interruption

    func testInterruptionEnded_withResumeOffer_staysPaused() async throws {
        // Given: the call paused the meditation
        try await self.loadMeditation()
        try self.sut.play()
        await self.postInterruptionBegan()

        // When: the call ends and iOS offers to resume
        await self.postInterruptionEndedWithResumeOffer()

        // Then: the meditation does not continue on its own
        XCTAssertEqual(self.sut.state.value, .paused)
    }

    func testInterruptionEnded_whenPausedByUser_staysPaused() async throws {
        // Given: the user had paused before the call
        try await self.loadMeditation()
        try self.sut.play()
        self.sut.pause()

        // When
        await self.postInterruptionBegan()
        await self.postInterruptionEndedWithResumeOffer()

        // Then
        XCTAssertEqual(self.sut.state.value, .paused)
    }

    func testInterruptionEnded_beforeMeditationStarted_doesNotStartIt() async throws {
        // Given: loaded, the pre-roll keeps the session alive with silent audio
        try await self.loadMeditation()
        try self.sut.startSilentBackgroundAudio()

        // When
        await self.postInterruptionBegan()
        await self.postInterruptionEndedWithResumeOffer()

        // Then: nothing starts
        XCTAssertEqual(self.sut.state.value, .paused)
    }

    // MARK: Private

    private func loadMeditation() async throws {
        // silence.mp3 from BackgroundAudio — short and ideal for testing
        let url = try XCTUnwrap(
            Bundle.main.url(forResource: "silence", withExtension: "mp3", subdirectory: "BackgroundAudio")
        )
        let meditation = GuidedMeditation(
            fileBookmark: Data(),
            fileName: "test.mp3",
            duration: 600,
            teacher: "Test Teacher",
            name: "Test Meditation"
        )
        try await self.sut.load(url: url, meditation: meditation)
    }

    private func postInterruptionBegan() async {
        self.notificationCenter.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
        )
        await self.drainMainQueue()
    }

    private func postInterruptionEndedWithResumeOffer() async {
        self.notificationCenter.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
            ]
        )
        await self.drainMainQueue()
    }

    /// The service handles interruptions on the main queue — let it catch up.
    private func drainMainQueue() async {
        let drained = self.expectation(description: "main queue drained")
        DispatchQueue.main.async {
            drained.fulfill()
        }
        await fulfillment(of: [drained], timeout: 1.0)
    }
}
