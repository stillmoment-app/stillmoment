//
//  GuidedMeditationPlayerViewModelTests+ZenMode.swift
//  Still Moment
//

import Combine
import XCTest
@testable import StillMoment

extension GuidedMeditationPlayerViewModelTests {
    // MARK: - Zen Mode

    func testZenModeIsInactiveInitially() {
        // Given / When: player just initialized
        // Then: tab bar should be visible
        XCTAssertFalse(self.sut.isZenMode, "Tab bar must be visible before playback starts")
    }

    func testZenModeIsActiveWhenPlaying() async {
        // Given: simulate playing state
        let expectation = self.expectation(description: "State updates to playing")
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

        // Then: tab bar should be hidden during playback
        XCTAssertTrue(self.sut.isZenMode, "Tab bar must be hidden during playback")
    }

    func testZenModeRemainsActiveWhenPaused() async {
        // Given: simulate paused state
        let expectation = self.expectation(description: "State updates to paused")
        self.sut.$playbackState
            .dropFirst()
            .sink { state in
                if state == .paused {
                    expectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        self.mockPlayerService.state.send(.paused)
        await fulfillment(of: [expectation], timeout: 1.0)

        // Then: tab bar must stay hidden while paused — the player is still the active surface,
        // not a navigation context to switch tabs from
        XCTAssertTrue(self.sut.isZenMode, "Tab bar must stay hidden while playback is paused")
    }

    // MARK: - Remaining-Time Label State

    /// Garantiert, dass das „Pausiert"-Prefix nur im echten Pause-Zustand erscheint —
    /// nicht in transienten Zustaenden wie `.loading` oder `.finished`, die im Player
    /// kurz auftreten koennen.
    func testIsPausedIsTrueOnlyWhenPlaybackStateIsPaused() async {
        // Given: just initialized → idle
        XCTAssertFalse(self.sut.isPaused, "Idle must not read as paused")

        // When: state transitions to loading
        await self.send(.loading)
        XCTAssertFalse(self.sut.isPaused, "Loading must not read as paused")

        // When: state transitions to playing
        await self.send(.playing)
        XCTAssertFalse(self.sut.isPaused, "Playing must not read as paused")

        // When: state transitions to paused
        await self.send(.paused)
        XCTAssertTrue(self.sut.isPaused, "Paused must read as paused")

        // When: state transitions to finished
        await self.send(.finished)
        XCTAssertFalse(self.sut.isPaused, "Finished must not read as paused")
    }

    // MARK: - Test helpers

    /// Sends a `PlaybackState` through the mock and waits until the ViewModel
    /// has observed it. Used to keep the multi-state tests above readable.
    private func send(_ state: PlaybackState) async {
        let expectation = self.expectation(description: "State updates to \(state)")
        self.sut.$playbackState
            .dropFirst()
            .sink { newState in
                if newState == state {
                    expectation.fulfill()
                }
            }
            .store(in: &self.cancellables)
        self.mockPlayerService.state.send(state)
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testZenModeIsActiveWhenCompleted() async {
        // Given: simulate finished state
        let expectation = self.expectation(description: "State updates to finished")
        self.sut.$playbackState
            .dropFirst()
            .sink { state in
                if state == .finished {
                    expectation.fulfill()
                }
            }
            .store(in: &self.cancellables)

        self.mockPlayerService.state.send(.finished)
        await fulfillment(of: [expectation], timeout: 1.0)

        // Then: tab bar must stay hidden on the completion/thank-you screen
        XCTAssertTrue(self.sut.isZenMode, "Tab bar must stay hidden during completion screen")
    }
}
