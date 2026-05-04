//
//  BreathDialGeometryTests.swift
//  Still Moment
//
//  Pure-function tests fuer den Atemkreis-Picker (shared-086).
//  Geprueft wird die Geste-Mathematik: Punkt -> Winkel -> Wert,
//  Wraparound an 12-Uhr und Clamping gegen [1, 60].
//

import CoreGraphics
import XCTest
@testable import StillMoment

final class BreathDialGeometryTests: XCTestCase {
    // MARK: - Konfiguration

    /// Standard-Dial-Mittelpunkt fuer die Tests. Konkrete Werte irrelevant —
    /// der Helper rechnet rein mit Differenzen.
    private let center = CGPoint(x: 100, y: 100)

    /// Ring-Mittelradius fuer Drag-/Tropfen-Berechnungen.
    private let ringRadius: CGFloat = 92

    // MARK: - AK-1: Drag setzt Wert kontinuierlich

    func testThreeOClockMapsTo15Minutes() {
        // Given: Punkt rechts von der Mitte (3-Uhr-Position)
        let point = CGPoint(x: self.center.x + self.ringRadius, y: self.center.y)

        // When
        let value = BreathDialGeometry.valueFromPoint(point, center: self.center)

        // Then: 3 Uhr = 90°, 90/360 * 60 = 15 Min
        XCTAssertEqual(value, 15)
    }

    func testSixOClockMapsTo30Minutes() {
        let point = CGPoint(x: self.center.x, y: self.center.y + self.ringRadius)

        let value = BreathDialGeometry.valueFromPoint(point, center: self.center)

        XCTAssertEqual(value, 30)
    }

    func testNineOClockMapsTo45Minutes() {
        let point = CGPoint(x: self.center.x - self.ringRadius, y: self.center.y)

        let value = BreathDialGeometry.valueFromPoint(point, center: self.center)

        XCTAssertEqual(value, 45)
    }

    func testElevenOClockMapsTo55Minutes() {
        // 11 Uhr = -150° im Math-System (links oben), -150 + 90 = -60 mod 360 = 300? Nein
        // Watch-Schritt: jede Stunde = 30°. 11 Uhr = 30° vor 12 (entgegen Uhrzeigersinn).
        // In unserer Skala: 12 = 0, 1 = 5, ..., 11 = 55.
        let angleFromTop: CGFloat = -30 * .pi / 180 // 11 o'clock = 30° counter-clockwise from 12
        let point = CGPoint(
            x: self.center.x + sin(angleFromTop) * self.ringRadius,
            y: self.center.y - cos(angleFromTop) * self.ringRadius
        )

        let value = BreathDialGeometry.valueFromPoint(point, center: self.center)

        XCTAssertEqual(value, 55)
    }

    func testOneOClockMapsTo5Minutes() {
        // 1 Uhr = 30° im Uhrzeigersinn ab 12. Skala: 12 = 0, 1 = 5.
        let angleFromTop: CGFloat = 30 * .pi / 180
        let point = CGPoint(
            x: self.center.x + sin(angleFromTop) * self.ringRadius,
            y: self.center.y - cos(angleFromTop) * self.ringRadius
        )

        let value = BreathDialGeometry.valueFromPoint(point, center: self.center)

        XCTAssertEqual(value, 5)
    }

    // MARK: - AK-2: 12-Uhr-Wraparound + Clamping

    func testTwelveOClockSnapsToOne() {
        // Genau auf 12 Uhr berechnet sich der Rohwert zu 0 — der Dial hat keinen
        // Null-Zustand, also snappt es auf 1 (Minimum).
        let point = CGPoint(x: self.center.x, y: self.center.y - self.ringRadius)

        let value = BreathDialGeometry.valueFromPoint(point, center: self.center)

        XCTAssertEqual(value, 1)
    }

    func testValueRightBeforeTwelveReachesSixty() {
        // 359° (knapp vor 12 Uhr im Uhrzeigersinn) muss exakt 60 ergeben.
        let angleFromTop: CGFloat = -1 * .pi / 180
        let point = CGPoint(
            x: self.center.x + sin(angleFromTop) * self.ringRadius,
            y: self.center.y - cos(angleFromTop) * self.ringRadius
        )

        let value = BreathDialGeometry.valueFromPoint(point, center: self.center)

        XCTAssertEqual(value, 60)
    }

    func testClampValueClampsHigh() {
        XCTAssertEqual(BreathDialGeometry.clampValue(75), 60)
    }

    func testClampValueClampsLow() {
        XCTAssertEqual(BreathDialGeometry.clampValue(-3), 1)
    }

    func testClampValueLetsValidValueThrough() {
        XCTAssertEqual(BreathDialGeometry.clampValue(18), 18)
    }

    // MARK: - Bogen-Skala 1..60

    func testArcProgressUsesFullScale() {
        // value=30 muss den Bogen halb fuellen (30/60 = 0.5).
        XCTAssertEqual(BreathDialGeometry.arcProgress(30), 0.5, accuracy: 0.0001)
    }

    func testArcProgressAtMinimumStillProportional() {
        XCTAssertEqual(BreathDialGeometry.arcProgress(1), 1.0 / 60.0, accuracy: 0.0001)
    }

    func testArcProgressAtMaximum() {
        XCTAssertEqual(BreathDialGeometry.arcProgress(60), 1.0, accuracy: 0.0001)
    }

    // MARK: - Tropfen-Position

    func testDropletPositionAtZeroIsTwelveOClock() {
        // Wert = 0: Tropfen sitzt direkt ueber dem Mittelpunkt (12 Uhr).
        let point = BreathDialGeometry.dropletPosition(value: 0, center: self.center, radius: self.ringRadius)

        XCTAssertEqual(point.x, self.center.x, accuracy: 0.001)
        XCTAssertEqual(point.y, self.center.y - self.ringRadius, accuracy: 0.001)
    }

    func testDropletPositionAt15IsThreeOClock() {
        let point = BreathDialGeometry.dropletPosition(value: 15, center: self.center, radius: self.ringRadius)

        XCTAssertEqual(point.x, self.center.x + self.ringRadius, accuracy: 0.001)
        XCTAssertEqual(point.y, self.center.y, accuracy: 0.001)
    }

    func testDropletPositionAt30IsSixOClock() {
        let point = BreathDialGeometry.dropletPosition(value: 30, center: self.center, radius: self.ringRadius)

        XCTAssertEqual(point.x, self.center.x, accuracy: 0.001)
        XCTAssertEqual(point.y, self.center.y + self.ringRadius, accuracy: 0.001)
    }

    // MARK: - Button-Offsets

    func testPlusButtonSitsBelowRight() {
        let offset = BreathDialGeometry.buttonOffset(direction: .plus, distance: 168)

        // 5-Uhr = 45° rechts von unten -> beide Komponenten positiv.
        XCTAssertGreaterThan(offset.width, 0)
        XCTAssertGreaterThan(offset.height, 0)
        // 45°-Symmetrie: |dx| == |dy|
        XCTAssertEqual(offset.width, offset.height, accuracy: 0.001)
    }

    func testMinusButtonSitsBelowLeft() {
        let offset = BreathDialGeometry.buttonOffset(direction: .minus, distance: 168)

        // 7-Uhr = 45° links von unten -> dx negativ, dy positiv.
        XCTAssertLessThan(offset.width, 0)
        XCTAssertGreaterThan(offset.height, 0)
        XCTAssertEqual(abs(offset.width), offset.height, accuracy: 0.001)
    }

    func testButtonOffsetMagnitudeMatchesDistance() {
        let distance: CGFloat = 168
        let offset = BreathDialGeometry.buttonOffset(direction: .plus, distance: distance)

        let magnitude = sqrt(offset.width * offset.width + offset.height * offset.height)
        XCTAssertEqual(magnitude, distance, accuracy: 0.001)
    }
}
