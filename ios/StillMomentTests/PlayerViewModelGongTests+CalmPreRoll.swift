//
//  PlayerViewModelGongTests+CalmPreRoll.swift
//  Still Moment
//
//  ViewModel tests - calm pre-roll view until the meditation audio begins (shared-143)
//

import Combine
import XCTest
@testable import StillMoment

extension PlayerViewModelGongTests {
    // MARK: - Calm view during start gong and breath pause

    func testPhase_duringStartGong_staysCalm() async {
        // Given
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()

        // When: the start gong rings
        self.sut.startPlayback()

        // Then: calm view, no play button or waveform yet
        XCTAssertEqual(self.sut.phase, .preRoll)
    }

    func testPhase_duringBreathPause_staysCalm() async {
        // Given
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()

        // When: the gong has faded, the breath pause runs
        self.mockGongPlayer.finishPlaying()

        // Then
        XCTAssertEqual(self.sut.phase, .preRoll)
    }

    func testPhase_whenMeditationAudioBegins_showsPlayingView() async {
        // Given
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        self.mockGongPlayer.finishPlaying()

        // When: the breath pause elapses
        self.mockClock.tick()

        // Then
        XCTAssertEqual(self.sut.phase, .playing)
    }

    func testPhase_afterPreparationWithStartGong_staysCalmUntilAudioBegins() async {
        // Given: preparation time and start gong
        self.sut = self.createViewModel(startGongEnabled: true, preparationTimeSeconds: 3)
        await self.sut.loadAudio()
        self.sut.startPlayback()

        // When: the countdown ends and the gong starts
        self.mockClock.advance(ticks: 3)

        // Then: no return to the playing view between preparation and gong
        XCTAssertEqual(self.sut.phase, .preRoll)
        XCTAssertFalse(self.sut.isPreparing)
    }

    func testZenMode_duringStartGong_isActive() async {
        // Given
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()

        // When
        self.sut.startPlayback()

        // Then: the tab bar stays hidden like during preparation
        XCTAssertTrue(self.sut.isZenMode)
    }

    // MARK: - Taps before the meditation audio begins

    func testTogglePlayPause_duringStartGong_doesNotStartMeditation() async {
        // Given
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()

        // When: a tap where the play button usually sits
        self.sut.togglePlayPause()

        // Then: the meditation does not start parallel to the gong
        XCTAssertFalse(self.mockPlayerService.playCalled)
    }

    func testTogglePlayPause_duringBreathPause_doesNotStartOrPauseMeditation() async {
        // Given
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        self.mockGongPlayer.finishPlaying()

        // When
        self.sut.togglePlayPause()

        // Then
        XCTAssertFalse(self.mockPlayerService.playCalled)
        XCTAssertFalse(self.mockPlayerService.pauseCalled)
    }

    func testMeditationStartsOnceAfterGongAndBreathPause_despiteTaps() async {
        // Given: taps during gong and breath pause
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        self.sut.togglePlayPause()
        self.mockGongPlayer.finishPlaying()
        self.sut.togglePlayPause()

        // When: the breath pause elapses
        self.mockClock.tick()

        // Then: the meditation starts exactly once, via the lock-screen-safe transition,
        // at the beginning of the playable range, with a single gong
        XCTAssertTrue(self.mockPlayerService.transitionFromSilentToPlaybackCalled)
        XCTAssertFalse(self.mockPlayerService.pauseCalled)
        XCTAssertNil(self.mockPlayerService.seekTime)
        XCTAssertEqual(self.mockGongPlayer.playCallCount, 1)
    }

    // MARK: - Seeking before the meditation audio begins

    func testSeek_duringStartGong_isIgnored() async {
        // Given
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()

        // When
        self.sut.seek(to: 120)
        self.sut.seek(toFraction: 0.5)
        self.sut.skipForward()

        // Then
        XCTAssertNil(self.mockPlayerService.seekTime)
    }

    func testScrub_duringBreathPause_isIgnored() async {
        // Given
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        self.mockGongPlayer.finishPlaying()

        // When: the user drags where the wave usually sits
        self.sut.beginScrub()
        self.sut.scrub(to: 120)
        self.sut.endScrub()

        // Then
        XCTAssertFalse(self.sut.isDragging)
        XCTAssertNil(self.mockPlayerService.seekTime)
        XCTAssertFalse(self.mockPlayerService.playCalled)
    }

    func testSeek_duringPreparation_isIgnored() async {
        // Given
        self.sut = self.createViewModel(preparationTimeSeconds: 10)
        await self.sut.loadAudio()
        self.sut.startPlayback()

        // When
        self.sut.seek(to: 120)

        // Then
        XCTAssertNil(self.mockPlayerService.seekTime)
    }

    // MARK: - Unchanged without start gong

    func testTogglePlayPause_afterExternalStop_startsDirectlyWithoutGong() async {
        // Given: the meditation ran with a start gong and was stopped from outside
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        self.mockGongPlayer.finishPlaying()
        self.mockClock.tick()
        self.sut.stop()
        await self.waitForPlaybackState(.idle)
        self.mockPlayerService.playCalled = false

        // When
        self.sut.startPlayback()

        // Then: play starts directly, no second gong
        XCTAssertTrue(self.mockPlayerService.playCalled)
        XCTAssertEqual(self.mockGongPlayer.playCallCount, 1)
    }

    // MARK: - Closing the player before the meditation audio begins

    func testClose_duringStartGong_nothingPlaysAfterwards() async {
        // Given: the start gong rings
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()

        // When: the player is closed (or stopped from outside), then time passes
        self.sut.stop()
        self.sut.cleanup()
        self.mockGongPlayer.finishPlaying()
        self.mockClock.tick()

        // Then: the meditation never starts
        XCTAssertFalse(self.mockPlayerService.transitionFromSilentToPlaybackCalled)
    }

    func testClose_duringBreathPause_nothingPlaysAfterwards() async {
        // Given: the gong has faded, the breath pause runs
        self.sut = self.createViewModel(startGongEnabled: true)
        await self.sut.loadAudio()
        self.sut.startPlayback()
        self.mockGongPlayer.finishPlaying()

        // When: the player is closed, then the breath pause would have elapsed
        self.sut.stop()
        self.sut.cleanup()
        self.mockClock.tick()

        // Then
        XCTAssertFalse(self.mockPlayerService.transitionFromSilentToPlaybackCalled)
    }

    // MARK: - Helpers

    /// The ViewModel receives playback states on the main queue — wait until it has seen `state`.
    private func waitForPlaybackState(_ state: PlaybackState) async {
        let reached = self.expectation(description: "playback state \(state)")
        let subscription = self.sut.$playbackState
            .first { $0 == state }
            .sink { _ in reached.fulfill() }
        await fulfillment(of: [reached], timeout: 1.0)
        subscription.cancel()
    }
}
