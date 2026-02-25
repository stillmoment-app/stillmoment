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

    func testZenModeIsInactiveWhenPaused() async {
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

        // Then: tab bar should return when paused
        XCTAssertFalse(self.sut.isZenMode, "Tab bar must return when playback is paused")
    }

    func testZenModeIsInactiveWhenCompleted() async {
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

        // Then: tab bar must return after meditation ends
        XCTAssertFalse(self.sut.isZenMode, "Tab bar must return when meditation completes")
    }
}
