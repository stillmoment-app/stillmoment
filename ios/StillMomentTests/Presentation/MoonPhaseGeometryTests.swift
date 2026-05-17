//
//  MoonPhaseGeometryTests.swift
//  Still Moment
//
//  Pure-function tests fuer die Mondphasen-Animation (shared-095).
//  AK: Bei Halbzeit muss die Schattenkante senkrecht in der Mondmitte
//  stehen — also exakt der Halbmond. Vorher fuhr der Schatten ~11 %
//  zu schnell ("200/180"-Skalierung), sodass bei progress=0.5 bereits
//  ~56 % des Mondes sichtbar waren.
//

import CoreGraphics
import XCTest
@testable import StillMoment

final class MoonPhaseGeometryTests: XCTestCase {
    private let outerSize: CGFloat = 220

    func testNeumondAtProgressZero() {
        // Given: Sitzung gerade gestartet
        // When
        let offset = MoonPhaseView.shadowOffset(progress: 0.0, outerSize: self.outerSize)

        // Then: Schatten deckt Mond exakt — Schatten-Mitte bei x = 0
        XCTAssertEqual(offset, 0, accuracy: 0.0001)
    }

    func testHalbmondAtHalftime() {
        // Given: Halbzeit einer Sitzung
        // When
        let offset = MoonPhaseView.shadowOffset(progress: 0.5, outerSize: self.outerSize)

        // Then: Schatten-Mitte 1 Mondradius links → Schattenkante senkrecht in
        // Mondmitte (AK aus shared-095: "Halbzeit: Halbmond, Schattenkante
        // senkrecht in der Mondmitte")
        XCTAssertEqual(offset, -self.outerSize / 2, accuracy: 0.0001)
    }

    func testVollmondAtProgressOne() {
        // Given: Sitzung beendet
        // When
        let offset = MoonPhaseView.shadowOffset(progress: 1.0, outerSize: self.outerSize)

        // Then: Schatten links tangential zum Mond → Mond ist voll sichtbar,
        // kein Restschatten im Clip
        XCTAssertEqual(offset, -self.outerSize, accuracy: 0.0001)
    }

    func testProgressIsClampedBelowZero() {
        // Given: ungueltiger negativer Progress (Defensiv-Check)
        // When
        let offset = MoonPhaseView.shadowOffset(progress: -0.5, outerSize: self.outerSize)

        // Then: wie Neumond behandelt
        XCTAssertEqual(offset, 0, accuracy: 0.0001)
    }

    func testProgressIsClampedAboveOne() {
        // Given: ungueltiger Progress > 1 (z.B. nach Drift)
        // When
        let offset = MoonPhaseView.shadowOffset(progress: 1.5, outerSize: self.outerSize)

        // Then: wie Vollmond behandelt — Schatten bleibt tangential, faehrt
        // nicht weiter raus
        XCTAssertEqual(offset, -self.outerSize, accuracy: 0.0001)
    }
}
