//
//  ThemeColorsTests.swift
//  Still Moment
//
//  Unit tests for ThemeColors resolution and derived tokens.
//

import SwiftUI
import UIKit
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

    // MARK: - Settings List Tokens (shared-089 / shared-094)

    func testSettingsDividerIsAliasOfDivider() {
        let theme = ThemeColors.light
        XCTAssertEqual(theme.settingsDivider, theme.divider)
    }

    func testSettingsValueAccentMatchesInteractive() {
        let theme = ThemeColors.light
        XCTAssertEqual(theme.settingsValueAccent, theme.interactive)
    }

    func testSettingsTokensFollowThemeAcrossPalettes() {
        let palettes: [ThemeColors] = [.light, .dark]
        for theme in palettes {
            XCTAssertEqual(theme.settingsDivider, theme.divider)
            XCTAssertEqual(theme.settingsValueAccent, theme.interactive)
        }
    }

    // MARK: - Refinement Tokens (shared-094)

    func testPlayGradientDiffersBetweenLightAndDark() {
        XCTAssertNotEqual(ThemeColors.light.playGradientTop, ThemeColors.dark.playGradientTop)
        XCTAssertNotEqual(ThemeColors.light.playGradientBot, ThemeColors.dark.playGradientBot)
    }

    func testPlayGradientTopIsLighterThanBottom() {
        let palettes: [(ThemeColors, String)] = [(.light, "Light"), (.dark, "Dark")]
        for (palette, name) in palettes {
            let topLum = Self.luminance(of: palette.playGradientTop)
            let botLum = Self.luminance(of: palette.playGradientBot)
            XCTAssertGreaterThan(
                topLum,
                botLum,
                "\(name): playGradientTop should be lighter than playGradientBot for plastic effect"
            )
        }
    }

    func testDividerIsSetInBothPalettes() {
        for palette in [ThemeColors.light, ThemeColors.dark] {
            let uiColor = UIColor(palette.divider)
            var alpha: CGFloat = 0
            uiColor.getRed(nil, green: nil, blue: nil, alpha: &alpha)
            XCTAssertGreaterThan(alpha, 0, "Divider must not be clear")
        }
    }

    func testDividerDiffersBetweenLightAndDark() {
        XCTAssertNotEqual(ThemeColors.light.divider, ThemeColors.dark.divider)
    }

    func testTextOnInteractiveLightIsWarmCream() {
        // textOnInteractive im Light Mode ist warmes Cream (= cardBackground),
        // nicht reines Weiss — visueller Zusammenhalt mit dem Akzent-Gradient.
        let theme = ThemeColors.light
        XCTAssertEqual(theme.textOnInteractive, theme.cardBackground)
    }

    private static func luminance(of color: Color) -> CGFloat {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func linearize(_ channel: CGFloat) -> CGFloat {
            channel <= 0.04045
                ? channel / 12.92
                : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearize(red) + 0.7152 * linearize(green) + 0.0722 * linearize(blue)
    }
}
