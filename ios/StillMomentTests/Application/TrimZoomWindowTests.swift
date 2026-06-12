//
//  TrimZoomWindowTests.swift
//  Still Moment
//
//  Tests for the pure zoom-window math of the trim editor (shared-108).
//

import XCTest
@testable import StillMoment

final class TrimZoomWindowTests: XCTestCase {
    /// Reference file from the design handoff: 19:05 = 1145 s → span 206 s.
    private let duration: TimeInterval = 1145

    // MARK: - zoomSpan

    func testZoomSpanScalesWithLongFiles() {
        // 18 % of 1145 s, rounded.
        XCTAssertEqual(TrimZoomWindow.zoomSpan(duration: self.duration), 206, accuracy: 0.001)
    }

    func testZoomSpanHasMinimumOf120Seconds() {
        // 18 % of 500 s would be 90 s — the floor wins.
        XCTAssertEqual(TrimZoomWindow.zoomSpan(duration: 500), 120, accuracy: 0.001)
    }

    func testZoomSpanNeverExceedsFileDuration() {
        XCTAssertEqual(TrimZoomWindow.zoomSpan(duration: 90), 90, accuracy: 0.001)
    }

    // MARK: - frame (auto-zoom around a mark)

    func testFrameAroundStartPlacesMarkNearLeftEdge() {
        // Mark at 500 s: 25 % of the 206 s span from the left edge.
        let window = TrimZoomWindow.frame(around: 500, point: .start, duration: self.duration)

        XCTAssertEqual(window.lowerBound, 448.5, accuracy: 0.001)
        XCTAssertEqual(window.upperBound, 654.5, accuracy: 0.001)
    }

    func testFrameAroundEndPlacesMarkNearRightEdge() {
        // Mark at 600 s: 25 % of the 206 s span from the right edge.
        let window = TrimZoomWindow.frame(around: 600, point: .end, duration: self.duration)

        XCTAssertEqual(window.lowerBound, 445.5, accuracy: 0.001)
        XCTAssertEqual(window.upperBound, 651.5, accuracy: 0.001)
    }

    func testFrameClampsAtFileStart() {
        let window = TrimZoomWindow.frame(around: 30, point: .start, duration: self.duration)

        XCTAssertEqual(window.lowerBound, 0, accuracy: 0.001)
        XCTAssertEqual(window.upperBound, 206, accuracy: 0.001)
    }

    func testFrameClampsAtFileEnd() {
        let window = TrimZoomWindow.frame(around: self.duration, point: .end, duration: self.duration)

        XCTAssertEqual(window.lowerBound, 939, accuracy: 0.001)
        XCTAssertEqual(window.upperBound, 1145, accuracy: 0.001)
    }

    func testFrameOnShortFileReturnsWholeFile() {
        // 90 s file is below the 120 s minimum span — there is no zoom.
        let window = TrimZoomWindow.frame(around: 10, point: .start, duration: 90)

        XCTAssertEqual(window, 0...90)
    }

    func testFrameOnFileMatchingSpanReturnsWholeFile() {
        let window = TrimZoomWindow.frame(around: 60, point: .end, duration: 120)

        XCTAssertEqual(window, 0...120)
    }

    // MARK: - pan (minimap)

    func testPanCentersWindowOnTarget() {
        let window = TrimZoomWindow.pan(toCenter: 572, duration: self.duration)

        XCTAssertEqual(window.lowerBound, 469, accuracy: 0.001)
        XCTAssertEqual(window.upperBound, 675, accuracy: 0.001)
    }

    func testPanClampsAtFileStart() {
        let window = TrimZoomWindow.pan(toCenter: 0, duration: self.duration)

        XCTAssertEqual(window.lowerBound, 0, accuracy: 0.001)
        XCTAssertEqual(window.upperBound, 206, accuracy: 0.001)
    }

    func testPanClampsAtFileEnd() {
        let window = TrimZoomWindow.pan(toCenter: self.duration, duration: self.duration)

        XCTAssertEqual(window.lowerBound, 939, accuracy: 0.001)
        XCTAssertEqual(window.upperBound, 1145, accuracy: 0.001)
    }

    func testPanOnShortFileReturnsWholeFile() {
        XCTAssertEqual(TrimZoomWindow.pan(toCenter: 45, duration: 90), 0...90)
    }
}
