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

    func testDefaultThemeIsCandlelight() {
        XCTAssertEqual(self.sut.selectedTheme, .candlelight)
    }

    func testResolvedColorsReturnsCorrectPaletteForLightMode() {
        self.sut.selectedTheme = .forest
        let colors = self.sut.resolvedColors(for: .light)
        XCTAssertEqual(colors, .forestLight)
    }

    func testResolvedColorsReturnsCorrectPaletteForDarkMode() {
        self.sut.selectedTheme = .candlelight
        let colors = self.sut.resolvedColors(for: .dark)
        XCTAssertEqual(colors, .candlelightDark)
    }

    func testThemeSwitchChangesResolvedColors() {
        let before = self.sut.resolvedColors(for: .light)
        self.sut.selectedTheme = .forest
        let after = self.sut.resolvedColors(for: .light)
        XCTAssertNotEqual(before, after)
    }
}
