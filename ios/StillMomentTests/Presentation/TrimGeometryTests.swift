//
//  TrimGeometryTests.swift
//  Still Moment
//
//  Tests for the pure time↔x mapping of the waveform trim editor (shared-107).
//

import XCTest
@testable import StillMoment

final class TrimGeometryTests: XCTestCase {
    func testTimeMapsToProportionalX() {
        let positionX = TrimGeometry.x(for: 50, duration: 100, width: 200)

        XCTAssertEqual(positionX, 100, accuracy: 0.001)
    }

    func testXMapsBackToProportionalTime() {
        let time = TrimGeometry.time(forX: 100, duration: 100, width: 200)

        XCTAssertEqual(time, 50, accuracy: 0.001)
    }

    func testRoundTripIsStable() {
        let original: TimeInterval = 73
        let positionX = TrimGeometry.x(for: original, duration: 1145, width: 360)
        let back = TrimGeometry.time(forX: positionX, duration: 1145, width: 360)

        XCTAssertEqual(back, original, accuracy: 0.01)
    }

    func testTimeBeyondDurationClampsToWidth() {
        let positionX = TrimGeometry.x(for: 5000, duration: 100, width: 200)

        XCTAssertEqual(positionX, 200, accuracy: 0.001)
    }

    func testNegativeXClampsToZeroTime() {
        let time = TrimGeometry.time(forX: -40, duration: 100, width: 200)

        XCTAssertEqual(time, 0, accuracy: 0.001)
    }

    func testXBeyondWidthClampsToDuration() {
        let time = TrimGeometry.time(forX: 999, duration: 100, width: 200)

        XCTAssertEqual(time, 100, accuracy: 0.001)
    }

    func testZeroDurationReturnsZero() {
        XCTAssertEqual(TrimGeometry.x(for: 10, duration: 0, width: 200), 0)
        XCTAssertEqual(TrimGeometry.time(forX: 10, duration: 0, width: 200), 0)
    }

    // MARK: Drag anchor

    func testDraggedTimeOffsetsAnchorByTranslation() {
        let time = TrimGeometry.draggedTime(anchorX: 100, translation: 20, duration: 100, width: 200)

        XCTAssertEqual(time, 60, accuracy: 0.001)
    }

    func testRepeatedDragUpdatesDoNotCompound() {
        // A drag emits growing cumulative translations; each update maps against the
        // fixed anchor, so the result tracks the finger instead of accelerating away.
        let anchorX: CGFloat = 100
        var time: TimeInterval = 0
        for translation in [CGFloat(5), 10, 15, 20] {
            time = TrimGeometry.draggedTime(anchorX: anchorX, translation: translation, duration: 100, width: 200)
        }

        XCTAssertEqual(time, 60, accuracy: 0.001)
    }

    func testDraggedTimeClampsToTrackBounds() {
        let below = TrimGeometry.draggedTime(anchorX: 10, translation: -50, duration: 100, width: 200)
        let above = TrimGeometry.draggedTime(anchorX: 190, translation: 50, duration: 100, width: 200)

        XCTAssertEqual(below, 0, accuracy: 0.001)
        XCTAssertEqual(above, 100, accuracy: 0.001)
    }

    // MARK: Window mapping (zoom, shared-108)

    func testWindowedTimeMapsRelativeToWindowNotFile() {
        // Window [100, 306] of a 1145 s file: the track center is second 203,
        // not the file center 572.
        let positionX = TrimGeometry.x(for: 203, window: 100...306, width: 350)

        XCTAssertEqual(positionX, 175, accuracy: 0.001)
    }

    func testWindowedXClampsToWindowBounds() {
        XCTAssertEqual(TrimGeometry.x(for: 50, window: 100...306, width: 350), 0, accuracy: 0.001)
        XCTAssertEqual(TrimGeometry.x(for: 999, window: 100...306, width: 350), 350, accuracy: 0.001)
    }

    func testWindowedTimeForXClampsToWindowBounds() {
        XCTAssertEqual(TrimGeometry.time(forX: -50, window: 100...306, width: 350), 100, accuracy: 0.001)
        XCTAssertEqual(TrimGeometry.time(forX: 400, window: 100...306, width: 350), 306, accuracy: 0.001)
    }

    func testWindowedXForTimeRoundTripIsStable() {
        let positionX = TrimGeometry.x(for: 250, window: 100...306, width: 350)
        let back = TrimGeometry.time(forX: positionX, window: 100...306, width: 350)

        XCTAssertEqual(back, 250, accuracy: 0.01)
    }

    func testUnclampedXGoesNegativeForTimesBeforeWindow() {
        // 2 pt per second (span 206 s, width 412 pt): second 50 is 100 pt left of the track.
        let positionX = TrimGeometry.unclampedX(for: 50, window: 100...306, width: 412)

        XCTAssertEqual(positionX, -100, accuracy: 0.001)
    }

    func testUnclampedXExceedsWidthForTimesAfterWindow() {
        let positionX = TrimGeometry.unclampedX(for: 400, window: 100...306, width: 412)

        XCTAssertEqual(positionX, 600, accuracy: 0.001)
    }

    func testEmptyWindowReturnsSafeDefaults() {
        XCTAssertEqual(TrimGeometry.x(for: 10, window: 100...100, width: 350), 0)
        XCTAssertEqual(TrimGeometry.unclampedX(for: 10, window: 100...100, width: 350), 0)
        XCTAssertEqual(TrimGeometry.time(forX: 10, window: 100...100, width: 350), 100)
    }

    func testTimeCountsAsInWindowWithHalfSecondTolerance() {
        // Visibility rule for marks/playhead: a grip right at the window edge stays visible.
        XCTAssertTrue(TrimGeometry.isTime(150, inWindow: 100...306))
        XCTAssertTrue(TrimGeometry.isTime(99.6, inWindow: 100...306))
        XCTAssertTrue(TrimGeometry.isTime(306.4, inWindow: 100...306))
        XCTAssertFalse(TrimGeometry.isTime(99.4, inWindow: 100...306))
        XCTAssertFalse(TrimGeometry.isTime(306.6, inWindow: 100...306))
    }

    func testWholeFileWindowMatchesDurationMapping() {
        // In the overview the window is the whole file — both APIs must agree.
        let viaDuration = TrimGeometry.x(for: 300, duration: 1145, width: 350)
        let viaWindow = TrimGeometry.x(for: 300, window: 0...1145, width: 350)

        XCTAssertEqual(viaWindow, viaDuration, accuracy: 0.001)
    }
}
