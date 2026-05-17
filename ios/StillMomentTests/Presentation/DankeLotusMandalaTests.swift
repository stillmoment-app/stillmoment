//
//  DankeLotusMandalaTests.swift
//  Still Moment
//
//  Strukturelle Tests fuer das Doppel-Lotus-Mandala auf dem Danke-Screen
//  (shared-097). Geprueft wird die Geometrie — Petal-Anzahl, Inner-Ring-Offset,
//  Path-Schliessung — nicht das Rendering.
//

import SwiftUI
import XCTest
@testable import StillMoment

final class DankeLotusMandalaTests: XCTestCase {
    // MARK: - AK „Mandala-Geometrie": 16 Petals (8 outer + 8 inner)

    func testOuterRingHasEightPetals() {
        XCTAssertEqual(LotusMandalaGeometry.outerPetalAngles.count, 8)
    }

    func testInnerRingHasEightPetals() {
        XCTAssertEqual(LotusMandalaGeometry.innerPetalAngles.count, 8)
    }

    func testOuterPetalsStartAtZeroDegrees() {
        XCTAssertEqual(LotusMandalaGeometry.outerPetalAngles.first, 0.0)
    }

    func testOuterPetalsAreEquallySpacedBy45Degrees() {
        let angles = LotusMandalaGeometry.outerPetalAngles
        for index in 1..<angles.count {
            XCTAssertEqual(angles[index] - angles[index - 1], 45.0, accuracy: 0.001)
        }
    }

    func testInnerPetalsAreOffsetBy22Point5DegreesFromOuter() {
        // Inner-Ring sitzt in den Luecken zwischen den Outer-Petals
        XCTAssertEqual(LotusMandalaGeometry.innerPetalAngles.first, 22.5)
    }

    func testInnerPetalsAreEquallySpacedBy45Degrees() {
        let angles = LotusMandalaGeometry.innerPetalAngles
        for index in 1..<angles.count {
            XCTAssertEqual(angles[index] - angles[index - 1], 45.0, accuracy: 0.001)
        }
    }

    // MARK: - AK „Petals nur Stroke": Path ist geschlossen

    func testOuterPetalPathIsClosed() {
        let path = LotusPetalShape.outer.path(in: CGRect(x: 0, y: 0, width: 170, height: 170))
        XCTAssertFalse(path.isEmpty)
        XCTAssertTrue(self.isClosed(path), "Outer petal path must end with closeSubpath")
    }

    func testInnerPetalPathIsClosed() {
        let path = LotusPetalShape.inner.path(in: CGRect(x: 0, y: 0, width: 170, height: 170))
        XCTAssertFalse(path.isEmpty)
        XCTAssertTrue(self.isClosed(path), "Inner petal path must end with closeSubpath")
    }

    // MARK: - Helpers

    private func isClosed(_ path: Path) -> Bool {
        var closed = false
        path.cgPath.applyWithBlock { elementPtr in
            if elementPtr.pointee.type == .closeSubpath {
                closed = true
            }
        }
        return closed
    }

    // MARK: - AK „statisches Symbol": keine Animation

    func testInnerRingOpacityIsSixTenths() {
        // Spec: Inner-Petals haben opacity 0.6 (Handoff README)
        XCTAssertEqual(LotusMandalaGeometry.innerPetalOpacity, 0.6, accuracy: 0.001)
    }

    func testCenterRingOpacityIsHalf() {
        // Spec: Outline-Ring r=9 mit opacity 0.5 (Handoff README)
        XCTAssertEqual(LotusMandalaGeometry.centerRingOpacity, 0.5, accuracy: 0.001)
    }
}
