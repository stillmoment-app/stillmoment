//
//  GuidedMeditationsListViewModelTests+ScrubPreview.swift
//  Still Moment
//
//  Tests fuer shared-098: Library-Preview mit Scrub-Slider
//

import Combine
import XCTest
@testable import StillMoment

@MainActor
extension GuidedMeditationsListViewModelTests {
    // MARK: - Initialwerte sind 0

    func testInitialPreviewCurrentTimeAndDurationAreZero() {
        XCTAssertEqual(self.sut.previewCurrentTime, 0, accuracy: 0.001)
        XCTAssertEqual(self.sut.previewDuration, 0, accuracy: 0.001)
    }

    // MARK: - Position-Updates aus Service erreichen ViewModel

    func testPreviewCurrentTimeReflectsServicePosition() async {
        var cancellables = Set<AnyCancellable>()
        let expectation = self.expectation(description: "previewCurrentTime updates")
        self.sut.$previewCurrentTime
            .dropFirst()
            .sink { value in
                if value == 42.5 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        self.mockAudioService.meditationPreviewPositionSubject.send(42.5)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(self.sut.previewCurrentTime, 42.5, accuracy: 0.001)
        cancellables.removeAll()
    }

    func testPreviewDurationReflectsServiceDuration() async {
        var cancellables = Set<AnyCancellable>()
        let expectation = self.expectation(description: "previewDuration updates")
        self.sut.$previewDuration
            .dropFirst()
            .sink { value in
                if value == 691 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        self.mockAudioService.meditationPreviewDurationSubject.send(691)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(self.sut.previewDuration, 691, accuracy: 0.001)
        cancellables.removeAll()
    }

    // MARK: - seekPreview ruft Service

    func testSeekPreviewForwardsToAudioService() {
        // When
        self.sut.seekPreview(to: 123.4)

        // Then
        XCTAssertTrue(self.mockAudioService.seekMeditationPreviewCalled)
        XCTAssertEqual(self.mockAudioService.lastSeekMeditationPreviewTime ?? -1, 123.4, accuracy: 0.001)
    }

    // MARK: - Position wird auf 0 zurueckgesetzt nach Stop

    func testPositionResetsToZeroOnPreviewStop() async {
        var cancellables = Set<AnyCancellable>()
        let runningExpectation = self.expectation(description: "Position reaches 30")
        let resetExpectation = self.expectation(description: "Position resets to 0")
        var seenThirty = false
        self.sut.$previewCurrentTime
            .dropFirst()
            .sink { value in
                if value == 30, !seenThirty {
                    seenThirty = true
                    runningExpectation.fulfill()
                } else if value == 0, seenThirty {
                    resetExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        self.mockAudioService.meditationPreviewPositionSubject.send(30)
        await fulfillment(of: [runningExpectation], timeout: 1.0)

        // When — service signals stop (publishes 0)
        self.mockAudioService.meditationPreviewPositionSubject.send(0)

        // Then
        await fulfillment(of: [resetExpectation], timeout: 1.0)
        XCTAssertEqual(self.sut.previewCurrentTime, 0, accuracy: 0.001)
        cancellables.removeAll()
    }
}
