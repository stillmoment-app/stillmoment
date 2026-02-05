//
//  ThemeColors+Palettes.swift
//  Still Moment
//
//  Presentation Layer - Concrete color values for each theme + color scheme combination.
//
//  All colors are inline RGB (sRGB color space). This replaces the Asset Catalog
//  colorsets with a single source of truth that's easier to maintain across 4 palettes.
//
//  warmDesertLight values are identical to the original Asset Catalog colors
//  to ensure zero visual regression.
//

import SwiftUI

// MARK: - Warm Desert

extension ThemeColors {
    /// Current theme - identical RGB values from Asset Catalog (zero visual regression)
    static let warmDesertLight = ThemeColors(
        textPrimary: Color(red: 0.239, green: 0.196, blue: 0.157),
        textSecondary: Color(red: 0.545, green: 0.490, blue: 0.420),
        textOnInteractive: .white,
        interactive: Color(red: 0.831, green: 0.529, blue: 0.435),
        progress: Color(red: 0.831, green: 0.529, blue: 0.435),
        backgroundPrimary: Color(red: 1.000, green: 0.973, blue: 0.941),
        backgroundSecondary: Color(red: 0.961, green: 0.902, blue: 0.827),
        ringTrack: Color(red: 0.910, green: 0.867, blue: 0.816),
        accentBackground: Color(red: 1.000, green: 0.831, blue: 0.722),
        error: Color(red: 0.780, green: 0.294, blue: 0.231)
    )

    /// Placeholder - will be designed iteratively with MCP screenshots
    static let warmDesertDark = ThemeColors(
        textPrimary: Color(red: 0.961, green: 0.937, blue: 0.910),
        textSecondary: Color(red: 0.710, green: 0.667, blue: 0.616),
        textOnInteractive: .white,
        interactive: Color(red: 0.878, green: 0.592, blue: 0.498),
        progress: Color(red: 0.878, green: 0.592, blue: 0.498),
        backgroundPrimary: Color(red: 0.118, green: 0.098, blue: 0.078),
        backgroundSecondary: Color(red: 0.176, green: 0.149, blue: 0.122),
        ringTrack: Color(red: 0.235, green: 0.208, blue: 0.176),
        accentBackground: Color(red: 0.294, green: 0.243, blue: 0.192),
        error: Color(red: 0.878, green: 0.380, blue: 0.318)
    )
}

// MARK: - Dark Warm ("Kerzenschein")

extension ThemeColors {
    /// Placeholder - will be designed iteratively with MCP screenshots
    static let darkWarmLight = ThemeColors(
        textPrimary: Color(red: 0.200, green: 0.157, blue: 0.118),
        textSecondary: Color(red: 0.475, green: 0.427, blue: 0.369),
        textOnInteractive: .white,
        interactive: Color(red: 0.776, green: 0.486, blue: 0.247),
        progress: Color(red: 0.776, green: 0.486, blue: 0.247),
        backgroundPrimary: Color(red: 0.988, green: 0.965, blue: 0.933),
        backgroundSecondary: Color(red: 0.953, green: 0.918, blue: 0.867),
        ringTrack: Color(red: 0.910, green: 0.867, blue: 0.804),
        accentBackground: Color(red: 0.976, green: 0.851, blue: 0.710),
        error: Color(red: 0.780, green: 0.294, blue: 0.231)
    )

    /// Placeholder - will be designed iteratively with MCP screenshots
    static let darkWarmDark = ThemeColors(
        textPrimary: Color(red: 0.941, green: 0.914, blue: 0.878),
        textSecondary: Color(red: 0.667, green: 0.624, blue: 0.569),
        textOnInteractive: .white,
        interactive: Color(red: 0.839, green: 0.557, blue: 0.325),
        progress: Color(red: 0.839, green: 0.557, blue: 0.325),
        backgroundPrimary: Color(red: 0.098, green: 0.078, blue: 0.059),
        backgroundSecondary: Color(red: 0.157, green: 0.129, blue: 0.098),
        ringTrack: Color(red: 0.216, green: 0.184, blue: 0.149),
        accentBackground: Color(red: 0.275, green: 0.227, blue: 0.169),
        error: Color(red: 0.878, green: 0.380, blue: 0.318)
    )
}
