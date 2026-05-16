//
//  WCAGContrastTests.swift
//  Still Moment
//
//  WCAG 2.1 AA contrast validation for all theme palettes.
//  Ensures text-on-background combinations meet minimum contrast ratios.
//
//  Reference: https://www.w3.org/TR/WCAG21/#contrast-minimum
//  - Normal text: 4.5:1
//  - Large text (>=18pt regular or >=14pt bold): 3:1
//

import SwiftUI
import UIKit
import XCTest
@testable import StillMoment

final class WCAGContrastTests: XCTestCase {
    // MARK: - WCAG Thresholds

    private let normalTextMinContrast: CGFloat = 4.5
    private let largeTextMinContrast: CGFloat = 3.0

    // MARK: - WCAG Contrast Calculation

    /// Relative luminance per WCAG 2.1.
    /// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
    private func relativeLuminance(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGFloat {
        func linearize(_ channel: CGFloat) -> CGFloat {
            channel <= 0.04045
                ? channel / 12.92
                : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearize(red) + 0.7152 * linearize(green) + 0.0722 * linearize(blue)
    }

    /// Contrast ratio per WCAG 2.1.
    /// https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
    private func contrastRatio(foreground: Color, background: Color) -> CGFloat {
        let fgColor = self.extractRGB(from: foreground)
        let bgColor = self.extractRGB(from: background)
        let lumFg = self.relativeLuminance(red: fgColor.red, green: fgColor.green, blue: fgColor.blue)
        let lumBg = self.relativeLuminance(red: bgColor.red, green: bgColor.green, blue: bgColor.blue)
        let lighter = max(lumFg, lumBg)
        let darker = min(lumFg, lumBg)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private struct RGB {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
    }

    private func extractRGB(from color: Color) -> RGB {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return RGB(red: red, green: green, blue: blue)
    }

    // MARK: - Assertion Helpers

    private struct ContrastCheck {
        let foreground: Color
        let background: Color
        let foregroundName: String
        let backgroundName: String
    }

    private func assertContrast(
        _ check: ContrastCheck,
        minimumRatio: CGFloat,
        palette: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let ratio = self.contrastRatio(foreground: check.foreground, background: check.background)
        XCTAssertGreaterThanOrEqual(
            ratio,
            minimumRatio,
            "\(palette): \(check.foregroundName) on \(check.backgroundName) — "
                + "contrast \(String(format: "%.2f", ratio)):1, "
                + "minimum \(String(format: "%.1f", minimumRatio)):1",
            file: file,
            line: line
        )
    }

    private func textChecks(_ palette: ThemeColors) -> [ContrastCheck] {
        [
            ContrastCheck(
                foreground: palette.textPrimary,
                background: palette.backgroundPrimary,
                foregroundName: "textPrimary",
                backgroundName: "backgroundPrimary"
            ),
            ContrastCheck(
                foreground: palette.textPrimary,
                background: palette.backgroundSecondary,
                foregroundName: "textPrimary",
                backgroundName: "backgroundSecondary"
            ),
            ContrastCheck(
                foreground: palette.textSecondary,
                background: palette.backgroundPrimary,
                foregroundName: "textSecondary",
                backgroundName: "backgroundPrimary"
            ),
            ContrastCheck(
                foreground: palette.textSecondary,
                background: palette.backgroundSecondary,
                foregroundName: "textSecondary",
                backgroundName: "backgroundSecondary"
            ),
            ContrastCheck(
                foreground: palette.textPrimary,
                background: palette.cardBackground,
                foregroundName: "textPrimary",
                backgroundName: "cardBackground"
            ),
            ContrastCheck(
                foreground: palette.textSecondary,
                background: palette.cardBackground,
                foregroundName: "textSecondary",
                backgroundName: "cardBackground"
            )
        ]
    }

    /// Body-Text-relevante interactive/error-Kombinationen mit 4.5:1.
    /// `interactive` als Settings-Wert rechts oder als Button-Label braucht
    /// volle Body-Text-Lesbarkeit.
    private func bodyTextInteractiveChecks(_ palette: ThemeColors) -> [ContrastCheck] {
        [
            ContrastCheck(
                foreground: palette.textOnInteractive,
                background: palette.interactive,
                foregroundName: "textOnInteractive",
                backgroundName: "interactive"
            ),
            ContrastCheck(
                foreground: palette.interactive,
                background: palette.cardBackground,
                foregroundName: "interactive",
                backgroundName: "cardBackground"
            ),
            ContrastCheck(
                foreground: palette.error,
                background: palette.backgroundPrimary,
                foregroundName: "error",
                backgroundName: "backgroundPrimary"
            )
        ]
    }

    /// UI-Akzent-Kombinationen mit 3:1 (Large-Text / Non-Text-Schwelle).
    /// `interactive` direkt auf den Gradient-Stops ist UI-Akzent (Glyphen,
    /// Icons, Settings-Wert ueber dem Gradient ohne Karte) — keine
    /// Body-Text-Lesbarkeit erforderlich, aber Visibility-Schwelle 3:1.
    private func uiAccentChecks(_ palette: ThemeColors) -> [ContrastCheck] {
        [
            ContrastCheck(
                foreground: palette.interactive,
                background: palette.backgroundPrimary,
                foregroundName: "interactive",
                backgroundName: "backgroundPrimary"
            ),
            ContrastCheck(
                foreground: palette.interactive,
                background: palette.backgroundSecondary,
                foregroundName: "interactive",
                backgroundName: "backgroundSecondary"
            )
        ]
    }

    /// Validate all required text-on-background combinations for a palette.
    private func assertAllCombinations(
        _ palette: ThemeColors,
        name: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let bodyChecks = self.textChecks(palette) + self.bodyTextInteractiveChecks(palette)
        for check in bodyChecks {
            self.assertContrast(
                check,
                minimumRatio: self.normalTextMinContrast,
                palette: name,
                file: file,
                line: line
            )
        }
        for check in self.uiAccentChecks(palette) {
            self.assertContrast(
                check,
                minimumRatio: self.largeTextMinContrast,
                palette: name,
                file: file,
                line: line
            )
        }
    }

    // MARK: - Tests per Palette

    func testLightContrast() {
        self.assertAllCombinations(.light, name: "Light")
    }

    func testDarkContrast() {
        self.assertAllCombinations(.dark, name: "Dark")
    }

    // MARK: - Control Track Contrast (WCAG SC 1.4.11)

    func testControlTrackContrastAgainstCardBackground() {
        let palettes: [(ThemeColors, String)] = [
            (.light, "Light"),
            (.dark, "Dark")
        ]
        for (palette, name) in palettes {
            self.assertContrast(
                ContrastCheck(
                    foreground: palette.controlTrack,
                    background: palette.cardBackground,
                    foregroundName: "controlTrack",
                    backgroundName: "cardBackground"
                ),
                minimumRatio: self.largeTextMinContrast,
                palette: name
            )
        }
    }

    // MARK: - Card Border Visibility (Dark Mode)

    func testDarkModeCardBorderIsLighterThanCardBackground() {
        let palette = ThemeColors.dark
        let borderLum = self.luminanceFromColor(palette.cardBorder)
        let cardLum = self.luminanceFromColor(palette.cardBackground)
        XCTAssertGreaterThan(
            borderLum,
            cardLum,
            "Dark: cardBorder should be lighter than cardBackground for visual separation"
        )
    }

    func testLightModeCardBorderIsWarmTinted() {
        // Nach shared-094 traegt der Light-Border einen warmen Hauch (Kupfer/Erde)
        // mit niedriger Opacity, damit Karten gegen alle drei Gradient-Stops lesbar
        // bleiben. Border ist nicht clear, sondern warm-getoent.
        let palette = ThemeColors.light
        let uiColor = UIColor(palette.cardBorder)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertGreaterThan(alpha, 0.05, "Light: cardBorder should have visible warm tint")
        XCTAssertLessThan(alpha, 0.25, "Light: cardBorder must remain subtle, not hard")
        XCTAssertGreaterThan(red, green, "Light: cardBorder hue must be warm (red > green)")
        XCTAssertGreaterThan(green, blue, "Light: cardBorder hue must be warm (green > blue)")
    }

    private func luminanceFromColor(_ color: Color) -> CGFloat {
        let rgb = self.extractRGB(from: color)
        return self.relativeLuminance(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }

    // MARK: - Luminance Formula Sanity Checks

    func testBlackHasZeroLuminance() {
        let luminance = self.relativeLuminance(red: 0, green: 0, blue: 0)
        XCTAssertEqual(luminance, 0, accuracy: 0.001)
    }

    func testWhiteHasFullLuminance() {
        let luminance = self.relativeLuminance(red: 1, green: 1, blue: 1)
        XCTAssertEqual(luminance, 1, accuracy: 0.001)
    }

    func testBlackOnWhiteHasMaxContrast() {
        let ratio = self.contrastRatio(foreground: .black, background: .white)
        XCTAssertEqual(ratio, 21.0, accuracy: 0.1)
    }
}
