//
//  ThemeColorsTests.swift
//  Still Moment
//
//  Unit tests for ThemeColors resolution.
//

import SwiftUI
import XCTest
@testable import StillMoment

final class ThemeColorsTests: XCTestCase {
    func testResolveWarmDesertLight() {
        let colors = ThemeColors.resolve(theme: .warmDesert, colorScheme: .light)
        XCTAssertEqual(colors, .warmDesertLight)
    }

    func testResolveWarmDesertDark() {
        let colors = ThemeColors.resolve(theme: .warmDesert, colorScheme: .dark)
        XCTAssertEqual(colors, .warmDesertDark)
    }

    func testResolveDarkWarmLight() {
        let colors = ThemeColors.resolve(theme: .darkWarm, colorScheme: .light)
        XCTAssertEqual(colors, .darkWarmLight)
    }

    func testResolveDarkWarmDark() {
        let colors = ThemeColors.resolve(theme: .darkWarm, colorScheme: .dark)
        XCTAssertEqual(colors, .darkWarmDark)
    }

    func testAllPalettesAreDifferent() {
        let palettes: [ThemeColors] = [
            .warmDesertLight, .warmDesertDark,
            .darkWarmLight, .darkWarmDark
        ]
        // Each palette should be unique
        for outer in 0..<palettes.count {
            for inner in (outer + 1)..<palettes.count {
                XCTAssertNotEqual(
                    palettes[outer],
                    palettes[inner],
                    "Palette \(outer) should differ from palette \(inner)"
                )
            }
        }
    }
}
