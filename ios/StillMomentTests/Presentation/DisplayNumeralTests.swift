//
//  DisplayNumeralTests.swift
//  Still Moment
//
//  Unit tests fuer Typografie 2.1 — Display-Numerik container-relativ.
//

import SwiftUI
import XCTest
@testable import StillMoment

final class DisplayNumeralTests: XCTestCase {
    // MARK: - Container * 0.32 als Default-Skalierung

    func testCappedSizeMatchesContainerTimesPointThreeTwo() {
        // Bei normalen Containern (zwischen Floor 56 und Ceiling 120):
        // size = containerDiameter * 0.32 * scale.
        let size = DisplayNumeral.cappedSize(
            containerDiameter: 280,
            dynamicTypeScale: 1.0,
            dynamicTypeSize: .large
        )
        XCTAssertEqual(size, 280 * 0.32, accuracy: 0.001)
    }

    // MARK: - Floor 56 pt

    func testCappedSizeFloorsAt56() {
        // Plan-Regel: Floor 56pt. Bei sehr kleinem Container (z.B. 100pt)
        // muss die Numerik mindestens 56pt sein, sonst wird sie unleserlich.
        let size = DisplayNumeral.cappedSize(
            containerDiameter: 100,
            dynamicTypeScale: 1.0,
            dynamicTypeSize: .large
        )
        XCTAssertEqual(size, 56, accuracy: 0.001)
    }

    // MARK: - Ceiling 120 pt

    func testCappedSizeCeilsAt120() {
        // Plan-Regel: Ceiling 120pt. Bei sehr grossem Container (z.B. 500pt)
        // bleibt die Numerik bei 120pt — sonst sprengt sie den Ring.
        let size = DisplayNumeral.cappedSize(
            containerDiameter: 500,
            dynamicTypeScale: 1.0,
            dynamicTypeSize: .large
        )
        XCTAssertEqual(size, 120, accuracy: 0.001)
    }

    // MARK: - Dynamic Type < AX2 skaliert mit

    func testCappedSizeScalesWithDynamicTypeBelowAccessibility2() {
        // Bei xLarge (~scale 1.12) und AX1 (~scale 1.35) skaliert die Numerik mit.
        let baseSize = DisplayNumeral.cappedSize(
            containerDiameter: 280,
            dynamicTypeScale: 1.0,
            dynamicTypeSize: .large
        )
        let ax1Size = DisplayNumeral.cappedSize(
            containerDiameter: 280,
            dynamicTypeScale: 1.35,
            dynamicTypeSize: .accessibility1
        )
        XCTAssertGreaterThan(ax1Size, baseSize)
    }

    // MARK: - Dynamic Type >= AX2 cappt (Plan: cap @ AX1)

    func testCappedSizeIgnoresScaleAtAccessibility2OrAbove() {
        // Plan-Regel: ".display capped @ AX1." Ab AX2 keine weitere Skalierung —
        // der Caller verschiebt die Numerik unter den Container.
        let normalSize = DisplayNumeral.cappedSize(
            containerDiameter: 280,
            dynamicTypeScale: 1.0,
            dynamicTypeSize: .large
        )
        let ax2Size = DisplayNumeral.cappedSize(
            containerDiameter: 280,
            dynamicTypeScale: 1.8,
            dynamicTypeSize: .accessibility2
        )
        let ax5Size = DisplayNumeral.cappedSize(
            containerDiameter: 280,
            dynamicTypeScale: 2.35,
            dynamicTypeSize: .accessibility5
        )
        // Bei AX2+ ignoriert die Berechnung den scale-Faktor.
        XCTAssertEqual(ax2Size, normalSize, accuracy: 0.001)
        XCTAssertEqual(ax5Size, normalSize, accuracy: 0.001)
    }
}
