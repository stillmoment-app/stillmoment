//
//  ThemeColorsTests.swift
//  Still Moment
//
//  Unit tests for ThemeColors resolution and derived tokens.
//

import SwiftUI
import XCTest
@testable import StillMoment

final class ThemeColorsTests: XCTestCase {
    func testResolveLight() {
        let colors = ThemeColors.resolve(colorScheme: .light)
        XCTAssertEqual(colors, .light)
    }

    func testResolveDark() {
        let colors = ThemeColors.resolve(colorScheme: .dark)
        XCTAssertEqual(colors, .dark)
    }

    func testLightAndDarkAreDifferent() {
        XCTAssertNotEqual(ThemeColors.light, ThemeColors.dark)
    }

    // MARK: - Banner Tokens (shared-039b)

    func testAccentBannerBackgroundDerivesFromInteractive() {
        let theme = ThemeColors.light
        XCTAssertEqual(theme.accentBannerBackground, theme.interactive.opacity(0.10))
    }

    func testAccentBannerBorderDerivesFromInteractive() {
        let theme = ThemeColors.light
        XCTAssertEqual(theme.accentBannerBorder, theme.interactive.opacity(0.28))
    }

    func testAccentBubbleBackgroundDerivesFromInteractive() {
        let theme = ThemeColors.light
        XCTAssertEqual(theme.accentBubbleBackground, theme.interactive.opacity(0.18))
    }

    func testBannerTokensFollowThemeAcrossPalettes() {
        let palettes: [ThemeColors] = [.light, .dark]
        for theme in palettes {
            XCTAssertEqual(theme.accentBannerBackground, theme.interactive.opacity(0.10))
            XCTAssertEqual(theme.accentBannerBorder, theme.interactive.opacity(0.28))
            XCTAssertEqual(theme.accentBubbleBackground, theme.interactive.opacity(0.18))
        }
    }

    // MARK: - Breath Dial Tokens (shared-086)

    func testDialActiveArcUsesInteractive() {
        let theme = ThemeColors.light
        XCTAssertEqual(theme.dialActiveArc, theme.interactive)
    }

    func testDialActiveArcFollowsThemeAcrossPalettes() {
        let palettes: [ThemeColors] = [.light, .dark]
        for theme in palettes {
            XCTAssertEqual(theme.dialActiveArc, theme.interactive)
        }
    }

    // MARK: - Settings List Tokens (shared-089)

    func testSettingsDividerDerivesFromControlTrack() {
        let theme = ThemeColors.light
        XCTAssertEqual(theme.settingsDivider, theme.controlTrack.opacity(0.30))
    }

    func testSettingsValueAccentMatchesInteractive() {
        let theme = ThemeColors.light
        XCTAssertEqual(theme.settingsValueAccent, theme.interactive)
    }

    func testSettingsTokensFollowThemeAcrossPalettes() {
        let palettes: [ThemeColors] = [.light, .dark]
        for theme in palettes {
            XCTAssertEqual(theme.settingsDivider, theme.controlTrack.opacity(0.30))
            XCTAssertEqual(theme.settingsValueAccent, theme.interactive)
        }
    }
}
