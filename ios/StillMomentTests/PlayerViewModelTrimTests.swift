//
//  PlayerViewModelTrimTests.swift
//  Still Moment
//
//  Application Tests - Player respects trim points (shared-105)
//

import XCTest
@testable import StillMoment

@MainActor
final class PlayerViewModelTrimTests: XCTestCase {
    // MARK: - Remaining Time & Progress

    func testRemainingTimeEndsAtTrimEnd() {
        // Given: 10:00 file trimmed to 0:30–9:00, playback at 4:00
        let (sut, _) = self.makeSUT(duration: 600, trimStart: 30, trimEnd: 540)
        sut.duration = 600
        sut.currentTime = 240

        // Then: 5:00 left until trim end (not 6:00 until file end)
        XCTAssertEqual(sut.formattedRemainingTime, "5:00")
    }

    func testProgressReflectsTrimmedRange() {
        // Given: middle of the trimmed range
        let (sut, _) = self.makeSUT(duration: 600, trimStart: 30, trimEnd: 540)
        sut.duration = 600
        sut.currentTime = 285

        // Then
        XCTAssertEqual(sut.progress, 0.5, accuracy: 0.001)
    }

    func testProgressWithoutTrimIsUnchanged() {
        // Given
        let (sut, _) = self.makeSUT(duration: 600)
        sut.duration = 600
        sut.currentTime = 300

        // Then
        XCTAssertEqual(sut.progress, 0.5, accuracy: 0.001)
    }

    func testProgressClampsBeforeTrimStart() {
        // Given: playback position before the trim range (e.g. right after load)
        let (sut, _) = self.makeSUT(duration: 600, trimStart: 30, trimEnd: 540)
        sut.duration = 600
        sut.currentTime = 10

        // Then
        XCTAssertEqual(sut.progress, 0, accuracy: 0.001)
    }

    // MARK: - Skip Clamping

    func testSkipForwardStopsAtTrimEnd() {
        // Given
        let (sut, mock) = self.makeSUT(duration: 600, trimStart: 30, trimEnd: 540)
        sut.duration = 600
        sut.currentTime = 535

        // When
        sut.skipForward(by: 10)

        // Then
        XCTAssertEqual(mock.seekTime, 540)
    }

    func testSkipBackwardStopsAtTrimStart() {
        // Given
        let (sut, mock) = self.makeSUT(duration: 600, trimStart: 30, trimEnd: 540)
        sut.duration = 600
        sut.currentTime = 35

        // When
        sut.skipBackward(by: 10)

        // Then
        XCTAssertEqual(mock.seekTime, 30)
    }

    // MARK: - Restart After Finish

    func testRestartAfterFinishStartsAtTrimStart() {
        // Given: meditation finished
        let (sut, mock) = self.makeSUT(duration: 600, trimStart: 30, trimEnd: 540)
        sut.duration = 600
        sut.playbackState = .finished

        // When
        sut.togglePlayPause()

        // Then: restart skips the intro
        XCTAssertEqual(mock.seekTime, 30)
        XCTAssertTrue(mock.playCalled)
    }

    // MARK: - Helpers

    private func makeSUT(
        duration: TimeInterval,
        trimStart: TimeInterval? = nil,
        trimEnd: TimeInterval? = nil
    ) -> (GuidedMeditationPlayerViewModel, MockAudioPlayerService) {
        let meditation = GuidedMeditation(
            localFilePath: "test.mp3",
            fileName: "test.mp3",
            duration: duration,
            teacher: "Test Teacher",
            name: "Test Meditation",
            trimStart: trimStart,
            trimEnd: trimEnd
        )
        let mock = MockAudioPlayerService()
        let sut = GuidedMeditationPlayerViewModel(
            meditation: meditation,
            playerService: mock,
            meditationService: MockGuidedMeditationService()
        )
        return (sut, mock)
    }
}
