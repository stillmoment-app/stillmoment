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
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockCoordinator: MockAudioSessionCoordinator!

    override func setUp() {
        super.setUp()
        self.mockNowPlayingProvider = MockNowPlayingInfoProvider()
        self.notificationCenter = NotificationCenter()
        self.mockCoordinator = MockAudioSessionCoordinator()
        self.sut = AudioPlayerService(
            coordinator: self.mockCoordinator,
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
        self.mockCoordinator = nil
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

    func testInterruptionEnded_withResumeOffer_continuesAlsoOnLockScreen() async throws {
        // Given: the call paused the meditation
        try await self.loadMeditation()
        try self.sut.play()
        await self.postInterruptionBegan()

        // When: the call ends and iOS gives the sound back
        await self.postInterruptionEndedWithResumeOffer()

        // Then: the meditation goes on by itself, the lock screen shows it playing
        XCTAssertEqual(self.sut.state.value, .playing)
        let rate = self.mockNowPlayingProvider.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] as? Double
        XCTAssertEqual(rate, 1.0)
    }

    func testInterruptionEnded_withResumeOffer_isReportedToThePlayer() async throws {
        // Given
        try await self.loadMeditation()
        try self.sut.startSilentBackgroundAudio()
        var reported = 0
        let subscription = self.sut.interruptionEnded.sink { reported += 1 }
        await self.postInterruptionBegan()

        // When
        await self.postInterruptionEndedWithResumeOffer()

        // Then: the player learns about it, e.g. to restart the pre-roll
        XCTAssertEqual(reported, 1)
        subscription.cancel()
    }

    func testInterruptionEnded_withoutResumeOffer_staysPausedAndIsNotReported() async throws {
        // Given: the call paused the meditation
        try await self.loadMeditation()
        try self.sut.play()
        var reported = 0
        let subscription = self.sut.interruptionEnded.sink { reported += 1 }
        await self.postInterruptionBegan()

        // When: the call ends, but another app keeps the sound
        await self.postInterruptionEnded(options: 0)

        // Then
        XCTAssertEqual(self.sut.state.value, .paused)
        XCTAssertEqual(reported, 0)
        subscription.cancel()
    }

    func testInterruptionEnded_withoutAnyOptions_staysPaused() async throws {
        // Given
        try await self.loadMeditation()
        try self.sut.play()
        await self.postInterruptionBegan()

        // When
        await self.postInterruptionEnded(options: nil)

        // Then
        XCTAssertEqual(self.sut.state.value, .paused)
    }

    func testInterruptionEnded_afterTwoInterruptionsBegan_continues() async throws {
        // Given: Siri during a phone call
        try await self.loadMeditation()
        try self.sut.play()
        await self.postInterruptionBegan()
        await self.postInterruptionBegan()

        // When
        await self.postInterruptionEndedWithResumeOffer()

        // Then
        XCTAssertEqual(self.sut.state.value, .playing)
    }

    func testInterruptionEnded_whenSoundCannotResume_staysPausedAndTapContinues() async throws {
        // Given
        try await self.loadMeditation()
        try self.sut.play()
        await self.postInterruptionBegan()

        // When: the sound is not available when the meditation wants to go on
        self.mockCoordinator.shouldFailActivation = true
        await self.postInterruptionEndedWithResumeOffer()

        // Then: it stays paused; a tap on Play continues later
        XCTAssertEqual(self.sut.state.value, .paused)
        self.mockCoordinator.shouldFailActivation = false
        try self.sut.play()
        XCTAssertEqual(self.sut.state.value, .playing)
    }

    func testStaleResumeOffer_afterEndWithoutOffer_doesNotContinue() async throws {
        // Given: the interruption ended without giving the sound back
        try await self.loadMeditation()
        try self.sut.play()
        await self.postInterruptionBegan()
        await self.postInterruptionEnded(options: 0)

        // When: a late resume offer arrives without a new interruption
        await self.postInterruptionEndedWithResumeOffer()

        // Then
        XCTAssertEqual(self.sut.state.value, .paused)
    }

    func testInterruptionEnded_afterUserPlayedAndPausedMeanwhile_staysPaused() async throws {
        // Given: during the interruption the user played and paused again
        try await self.loadMeditation()
        try self.sut.play()
        await self.postInterruptionBegan()
        try self.sut.play()
        self.sut.pause()

        // When
        await self.postInterruptionEndedWithResumeOffer()

        // Then: the user's pause wins
        XCTAssertEqual(self.sut.state.value, .paused)
    }

    func testInterruptionEnded_afterMeditationFinished_keepsItFinished() async throws {
        // Given
        try await self.loadMeditation()
        try self.sut.play()
        self.sut.state.send(.finished)

        // When
        await self.postInterruptionBegan()
        await self.postInterruptionEndedWithResumeOffer()

        // Then
        XCTAssertEqual(self.sut.state.value, .finished)
    }

    func testInterruptionEnded_afterNextMeditationWasLoaded_doesNotStartIt() async throws {
        // Given: interrupted, then the player loaded another meditation
        try await self.loadMeditation()
        try self.sut.play()
        await self.postInterruptionBegan()
        try await self.loadMeditation()

        // When
        await self.postInterruptionEndedWithResumeOffer()

        // Then
        XCTAssertEqual(self.sut.state.value, .paused)
    }

    func testInterruptionEnded_afterPlayerWasClosed_doesNotPlay() async throws {
        // Given: interrupted, then the user closed the player
        try await self.loadMeditation()
        try self.sut.play()
        await self.postInterruptionBegan()
        self.sut.cleanup()
        let requestsBefore = self.mockCoordinator.requestedSources.count

        // When
        await self.postInterruptionEndedWithResumeOffer()

        // Then: the sound is not requested again
        XCTAssertEqual(self.mockCoordinator.requestedSources.count, requestsBefore)
        XCTAssertNotEqual(self.sut.state.value, .playing)
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
        await self.postInterruptionEnded(options: AVAudioSession.InterruptionOptions.shouldResume.rawValue)
    }

    /// `options: nil` leaves out the options key entirely
    private func postInterruptionEnded(options: UInt?) async {
        var userInfo: [AnyHashable: Any] = [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue
        ]
        if let options {
            userInfo[AVAudioSessionInterruptionOptionKey] = options
        }
        self.notificationCenter.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: userInfo
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
