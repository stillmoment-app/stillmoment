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
    /// Storage key behind `ThemeManager.appearanceMode`'s `@AppStorage`.
    private static let appearanceStorageKey = "appearanceMode"

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var sut: ThemeManager!

    override func setUp() {
        super.setUp()
        // Clear the stored value so each test starts like a fresh install
        // (and so no @AppStorage state leaks between tests)
        UserDefaults.standard.removeObject(forKey: Self.appearanceStorageKey)
        self.sut = ThemeManager()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: Self.appearanceStorageKey)
        self.sut = nil
        super.tearDown()
    }

    func testResolvedColorsReturnsLightPaletteForLightMode() {
        let colors = self.sut.resolvedColors(for: .light)
        XCTAssertEqual(colors, .light)
    }

    func testResolvedColorsReturnsDarkPaletteForDarkMode() {
        let colors = self.sut.resolvedColors(for: .dark)
        XCTAssertEqual(colors, .dark)
    }

    // MARK: - Appearance Mode

    func testFreshInstallShowsDarkAppearance() {
        // Given no stored selection (fresh install)
        // Then the app is dark, regardless of the device's light/dark setting
        XCTAssertEqual(self.sut.appearanceMode, .dark)
        XCTAssertEqual(self.sut.preferredColorScheme, .dark)
    }

    func testStoredSystemSelectionWinsOverDarkDefault() {
        // Given the user picked "System" in an earlier app run
        UserDefaults.standard.set(
            AppearanceMode.system.rawValue,
            forKey: Self.appearanceStorageKey
        )

        // When the app starts again
        let restored = ThemeManager()

        // Then the stored choice survives - the dark default must not overwrite it
        XCTAssertEqual(restored.appearanceMode, .system)
        XCTAssertNil(restored.preferredColorScheme)
    }

    func testStoredLightSelectionWinsOverDarkDefault() {
        // Given the user picked "Light" in an earlier app run
        UserDefaults.standard.set(
            AppearanceMode.light.rawValue,
            forKey: Self.appearanceStorageKey
        )

        // When the app starts again
        let restored = ThemeManager()

        // Then the stored choice survives
        XCTAssertEqual(restored.appearanceMode, .light)
        XCTAssertEqual(restored.preferredColorScheme, .light)
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
