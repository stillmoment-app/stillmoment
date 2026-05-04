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
    func testResolveCandlelightLight() {
        let colors = ThemeColors.resolve(theme: .candlelight, colorScheme: .light)
        XCTAssertEqual(colors, .candlelightLight)
    }

    func testResolveCandlelightDark() {
        let colors = ThemeColors.resolve(theme: .candlelight, colorScheme: .dark)
        XCTAssertEqual(colors, .candlelightDark)
    }

    func testResolveForestLight() {
        let colors = ThemeColors.resolve(theme: .forest, colorScheme: .light)
        XCTAssertEqual(colors, .forestLight)
    }

    func testResolveForestDark() {
        let colors = ThemeColors.resolve(theme: .forest, colorScheme: .dark)
        XCTAssertEqual(colors, .forestDark)
    }

    func testResolveMoonLight() {
        let colors = ThemeColors.resolve(theme: .moon, colorScheme: .light)
        XCTAssertEqual(colors, .moonLight)
    }

    func testResolveMoonDark() {
        let colors = ThemeColors.resolve(theme: .moon, colorScheme: .dark)
        XCTAssertEqual(colors, .moonDark)
    }

    func testMoonLightAndDarkAreDifferent() {
        XCTAssertNotEqual(ThemeColors.moonLight, ThemeColors.moonDark)
    }

    func testAllLightPalettesAreDifferent() {
        let palettes: [ThemeColors] = [
            .candlelightLight, .forestLight, .moonLight
        ]
        // Each light palette should be unique
        for outer in 0..<palettes.count {
            for inner in (outer + 1)..<palettes.count {
                XCTAssertNotEqual(
                    palettes[outer],
                    palettes[inner],
                    "Light palette \(outer) should differ from light palette \(inner)"
                )
            }
        }
    }

    // MARK: - Banner Tokens (shared-039b)

    func testAccentBannerBackgroundDerivesFromInteractive() {
        let theme = ThemeColors.candlelightLight
        XCTAssertEqual(theme.accentBannerBackground, theme.interactive.opacity(0.10))
    }

    func testAccentBannerBorderDerivesFromInteractive() {
        let theme = ThemeColors.candlelightLight
        XCTAssertEqual(theme.accentBannerBorder, theme.interactive.opacity(0.28))
    }

    func testAccentBubbleBackgroundDerivesFromInteractive() {
        let theme = ThemeColors.candlelightLight
        XCTAssertEqual(theme.accentBubbleBackground, theme.interactive.opacity(0.18))
    }

    func testBannerTokensFollowThemeAcrossPalettes() {
        let palettes: [ThemeColors] = [
            .candlelightLight, .candlelightDark,
            .forestLight, .forestDark,
            .moonLight, .moonDark
        ]
        for theme in palettes {
            XCTAssertEqual(theme.accentBannerBackground, theme.interactive.opacity(0.10))
            XCTAssertEqual(theme.accentBannerBorder, theme.interactive.opacity(0.28))
            XCTAssertEqual(theme.accentBubbleBackground, theme.interactive.opacity(0.18))
        }
    }

    // MARK: - Breath Dial Tokens (shared-086)

    func testDialActiveArcUsesInteractive() {
        let theme = ThemeColors.candlelightLight
        XCTAssertEqual(theme.dialActiveArc, theme.interactive)
    }

    func testDialDropletCoreUsesInteractive() {
        let theme = ThemeColors.candlelightLight
        XCTAssertEqual(theme.dialDropletCore, theme.interactive)
    }

    func testDialDropletHaloDerivesFromInteractive() {
        let theme = ThemeColors.candlelightLight
        XCTAssertEqual(theme.dialDropletHalo, theme.interactive.opacity(0.18))
    }

    func testDialTokensFollowThemeAcrossPalettes() {
        let palettes: [ThemeColors] = [
            .candlelightLight, .candlelightDark,
            .forestLight, .forestDark,
            .moonLight, .moonDark
        ]
        for theme in palettes {
            XCTAssertEqual(theme.dialActiveArc, theme.interactive)
            XCTAssertEqual(theme.dialDropletCore, theme.interactive)
            XCTAssertEqual(theme.dialDropletHalo, theme.interactive.opacity(0.18))
        }
    }

    // MARK: - Settings List Tokens (shared-089)

    func testSettingsDividerDerivesFromControlTrack() {
        let theme = ThemeColors.candlelightLight
        XCTAssertEqual(theme.settingsDivider, theme.controlTrack.opacity(0.30))
    }

    func testSettingsValueAccentMatchesInteractive() {
        let theme = ThemeColors.candlelightLight
        XCTAssertEqual(theme.settingsValueAccent, theme.interactive)
    }

    func testSettingsTokensFollowThemeAcrossPalettes() {
        let palettes: [ThemeColors] = [
            .candlelightLight, .candlelightDark,
            .forestLight, .forestDark,
            .moonLight, .moonDark
        ]
        for theme in palettes {
            XCTAssertEqual(theme.settingsDivider, theme.controlTrack.opacity(0.30))
            XCTAssertEqual(theme.settingsValueAccent, theme.interactive)
        }
    }
}
