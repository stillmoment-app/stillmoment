//
//  ThemeManagerTests.swift
//  Still Moment
//
//  Unit tests for ThemeManager.
//

import SwiftUI
import XCTest
@testable import StillMoment

@MainActor
final class ThemeManagerTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var sut: ThemeManager!

    override func setUp() {
        super.setUp()
        self.sut = ThemeManager()
        // Reset to default to avoid test pollution from @AppStorage
        self.sut.selectedTheme = .default
    }

    func testDefaultThemeIsWarmDesert() {
        XCTAssertEqual(self.sut.selectedTheme, .warmDesert)
    }

    func testResolvedColorsReturnsCorrectPaletteForLightMode() {
        self.sut.selectedTheme = .darkWarm
        let colors = self.sut.resolvedColors(for: .light)
        XCTAssertEqual(colors, .darkWarmLight)
    }

    func testResolvedColorsReturnsCorrectPaletteForDarkMode() {
        self.sut.selectedTheme = .warmDesert
        let colors = self.sut.resolvedColors(for: .dark)
        XCTAssertEqual(colors, .warmDesertDark)
    }

    func testThemeSwitchChangesResolvedColors() {
        let before = self.sut.resolvedColors(for: .light)
        self.sut.selectedTheme = .darkWarm
        let after = self.sut.resolvedColors(for: .light)
        XCTAssertNotEqual(before, after)
    }
}
