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
        self.sut.appearanceMode = .default
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

    // MARK: - Appearance Mode

    func testDefaultAppearanceModeIsSystem() {
        XCTAssertEqual(self.sut.appearanceMode, .system)
    }

    func testSystemModeReturnsNilColorScheme() {
        // Given
        self.sut.appearanceMode = .system

        // Then - nil means follow system setting
        XCTAssertNil(self.sut.preferredColorScheme)
    }

    func testLightModeReturnsLightColorScheme() {
        // Given
        self.sut.appearanceMode = .light

        // Then
        XCTAssertEqual(self.sut.preferredColorScheme, .light)
    }

    func testDarkModeReturnsDarkColorScheme() {
        // Given
        self.sut.appearanceMode = .dark

        // Then
        XCTAssertEqual(self.sut.preferredColorScheme, .dark)
    }

    func testAppearanceModeChangeUpdatesPreferredColorScheme() {
        // Given
        self.sut.appearanceMode = .system
        XCTAssertNil(self.sut.preferredColorScheme)

        // When
        self.sut.appearanceMode = .dark

        // Then
        XCTAssertEqual(self.sut.preferredColorScheme, .dark)

        // When
        self.sut.appearanceMode = .light

        // Then
        XCTAssertEqual(self.sut.preferredColorScheme, .light)
    }
}
