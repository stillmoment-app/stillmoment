//
//  PlayheadWindowGeometryTests.swift
//  Still Moment
//
//  Pure geometry of the scrolling "Tonkopf" window (shared-109).
//

import CoreGraphics
import XCTest
@testable import StillMoment

@MainActor
final class PlayheadWindowGeometryTests: XCTestCase {
    // MARK: - pxPerSec

    func testPxPerSecDividesWidthByWindow() {
        // Given a 393pt window showing 60s
        // When asking for the px-per-second density
        let density = PlayheadWindowGeometry.pxPerSec(windowSec: 60, width: 393)

        // Then it is width / windowSec
        XCTAssertEqual(density, 393.0 / 60.0, accuracy: 0.001)
    }

    func testPxPerSecZeroForInvalidInput() {
        XCTAssertEqual(PlayheadWindowGeometry.pxPerSec(windowSec: 0, width: 393), 0)
        XCTAssertEqual(PlayheadWindowGeometry.pxPerSec(windowSec: 60, width: 0), 0)
    }

    // MARK: - x(forSec:)

    func testNowMapsToCenter() {
        // Given now = 100s
        // When mapping the current position
        let positionX = PlayheadWindowGeometry.x(forSec: 100, now: 100, windowSec: 60, width: 393)

        // Then it sits at the center (the fixed "now"-line)
        XCTAssertEqual(positionX, 196.5, accuracy: 0.001)
    }

    func testFutureMapsRightOfCenter() {
        // Given a time 30s ahead of now → window edge
        let positionX = PlayheadWindowGeometry.x(forSec: 130, now: 100, windowSec: 60, width: 393)

        // Then it lands at the right edge
        XCTAssertEqual(positionX, 393.0, accuracy: 0.001)
    }

    func testPastMapsLeftOfCenter() {
        // Given a time 30s before now → left window edge
        let positionX = PlayheadWindowGeometry.x(forSec: 70, now: 100, windowSec: 60, width: 393)

        // Then it lands at the left edge
        XCTAssertEqual(positionX, 0.0, accuracy: 0.001)
    }

    // MARK: - sec(forX:)

    func testCenterMapsToNow() {
        let sec = PlayheadWindowGeometry.sec(forX: 196.5, now: 100, windowSec: 60, width: 393)
        XCTAssertEqual(sec, 100, accuracy: 0.001)
    }

    func testRightEdgeMapsToFuture() {
        let sec = PlayheadWindowGeometry.sec(forX: 393, now: 100, windowSec: 60, width: 393)
        XCTAssertEqual(sec, 130, accuracy: 0.001)
    }

    func testXAndSecAreInverse() {
        let original: TimeInterval = 117
        let positionX = PlayheadWindowGeometry.x(forSec: original, now: 100, windowSec: 60, width: 393)
        let roundTrip = PlayheadWindowGeometry.sec(forX: positionX, now: 100, windowSec: 60, width: 393)
        XCTAssertEqual(roundTrip, original, accuracy: 0.001)
    }

    // MARK: - draggedNow (scrub direction + clamping)

    func testDragLeftMovesForward() {
        // Given dragging the wave to the LEFT (negative translation)
        let newNow = PlayheadWindowGeometry.draggedNow(
            startNow: 100,
            translation: -65.5, // 65.5pt ≈ 10s at 6.55 px/s
            windowSec: 60,
            width: 393,
            bounds: 0...600
        )

        // Then the position moves FORWARD (later)
        XCTAssertEqual(newNow, 110, accuracy: 0.05)
    }

    func testDragRightMovesBackward() {
        // Given dragging the wave to the RIGHT (positive translation)
        let newNow = PlayheadWindowGeometry.draggedNow(
            startNow: 100,
            translation: 65.5,
            windowSec: 60,
            width: 393,
            bounds: 0...600
        )

        // Then the position moves BACKWARD (earlier)
        XCTAssertEqual(newNow, 90, accuracy: 0.05)
    }

    func testDragClampsToLowerBound() {
        // Given a drag that would go before the start
        let newNow = PlayheadWindowGeometry.draggedNow(
            startNow: 5,
            translation: 655, // way back
            windowSec: 60,
            width: 393,
            bounds: 0...600
        )

        // Then it clamps at the lower bound
        XCTAssertEqual(newNow, 0, accuracy: 0.001)
    }

    func testDragClampsToTrimBounds() {
        // Given a trimmed range [120, 1200]
        let newNow = PlayheadWindowGeometry.draggedNow(
            startNow: 130,
            translation: 655, // way back past the trim start
            windowSec: 60,
            width: 393,
            bounds: 120...1200
        )

        // Then it clamps at the trim start, never the file start
        XCTAssertEqual(newNow, 120, accuracy: 0.001)
    }
}
