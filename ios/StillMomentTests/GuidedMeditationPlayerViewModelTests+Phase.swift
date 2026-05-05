//
//  GuidedMeditationPlayerViewModelTests+Phase.swift
//  Still Moment
//

import Combine
import XCTest
@testable import StillMoment

extension GuidedMeditationPlayerViewModelTests {
    // MARK: - MeditationPhase

    func testPhase_isPlayingInitiallyWithoutPreRoll() {
        // Given a freshly initialized player without preparation time
        // Then phase should be .playing (no pre-roll → main phase visual)
        XCTAssertEqual(self.sut.phase, .playing)
    }

    func testPhase_isPreRollWhilePreparing() async {
        // Given a player with preparation time
        let viewModel = GuidedMeditationPlayerViewModel(
            meditation: GuidedMeditationTestHelpers.createTestMeditation(fileURL: self.tempFileURL),
            preparationTimeSeconds: 10,
            playerService: self.mockPlayerService,
            meditationService: self.mockMeditationService
        )
        await viewModel.loadAudio()

        // When countdown is running
        viewModel.startPlayback()

        // Then phase should reflect pre-roll
        XCTAssertEqual(viewModel.phase, .preRoll)
    }

    func testPhase_isPlayingDuringPlayback() async {
        // Given audio is loaded and playback starts
        await self.sut.loadAudio()

        let expectation = self.expectation(description: "playing")
        self.sut.$playbackState
            .dropFirst()
            .sink { state in
                if state == .playing {
                    expectation.fulfill()
                }
            }
            .store(in: &self.cancellables)
        self.mockPlayerService.state.send(.playing)
        await fulfillment(of: [expectation], timeout: 1.0)

        // Then
        XCTAssertEqual(self.sut.phase, .playing)
    }

    func testPhase_remainsPlayingAfterUserPause() async {
        // Given audio was playing
        await self.sut.loadAudio()
        let playingExp = self.expectation(description: "playing")
        let pausedExp = self.expectation(description: "paused")
        self.sut.$playbackState
            .dropFirst()
            .sink { state in
                if state == .playing {
                    playingExp.fulfill()
                } else if state == .paused {
                    pausedExp.fulfill()
                }
            }
            .store(in: &self.cancellables)
        self.mockPlayerService.state.send(.playing)
        await fulfillment(of: [playingExp], timeout: 1.0)

        // When user pauses
        self.mockPlayerService.state.send(.paused)
        await fulfillment(of: [pausedExp], timeout: 1.0)

        // Then visuelle Phase bleibt .playing — der Atemkreis sieht
        // pausiert und spielend identisch aus (Bogen friert ein, Atem laeuft).
        XCTAssertEqual(self.sut.phase, .playing)
    }

    // MARK: - formattedRemainingMinutes

    func testFormattedRemainingMinutes_formatsAsMmSs() async {
        // Given audio is loaded (duration 600s)
        await self.sut.loadAudio()
        let exp = self.expectation(description: "currentTime updates")
        self.sut.$currentTime
            .dropFirst()
            .sink { time in
                if time == 88.0 {
                    exp.fulfill()
                }
            }
            .store(in: &self.cancellables)
        self.mockPlayerService.currentTime.send(88.0)
        await fulfillment(of: [exp], timeout: 1.0)

        // When remaining is 600 - 88 = 512s = 8:32
        let formatted = self.sut.formattedRemainingMinutes

        // Then label-friendly mm:ss without prefix/suffix
        XCTAssertEqual(formatted, "8:32")
    }

    func testFormattedRemainingMinutes_padsSecondsBelowTen() async {
        // Given remaining 0:45 → 600 - 555 = 45
        await self.sut.loadAudio()
        let exp = self.expectation(description: "currentTime updates")
        self.sut.$currentTime
            .dropFirst()
            .sink { time in
                if time == 555.0 {
                    exp.fulfill()
                }
            }
            .store(in: &self.cancellables)
        self.mockPlayerService.currentTime.send(555.0)
        await fulfillment(of: [exp], timeout: 1.0)

        // Then
        XCTAssertEqual(self.sut.formattedRemainingMinutes, "0:45")
    }

    func testFormattedRemainingMinutes_zeroWhenAtEnd() async {
        // Given remaining is 0
        await self.sut.loadAudio()
        let exp = self.expectation(description: "currentTime updates")
        self.sut.$currentTime
            .dropFirst()
            .sink { time in
                if time == 600.0 {
                    exp.fulfill()
                }
            }
            .store(in: &self.cancellables)
        self.mockPlayerService.currentTime.send(600.0)
        await fulfillment(of: [exp], timeout: 1.0)

        // Then
        XCTAssertEqual(self.sut.formattedRemainingMinutes, "0:00")
    }
}
