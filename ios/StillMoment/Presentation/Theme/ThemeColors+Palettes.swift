//
//  ThemeColors+Palettes.swift
//  Still Moment
//
//  Presentation Layer - Concrete color values for each theme + color scheme combination.
//
//  All colors are inline RGB (sRGB color space). This replaces the Asset Catalog
//  colorsets with a single source of truth that's easier to maintain across palettes.
//
//  Three themes: Candlelight (warm), Forest (cool green), Moon (silver/indigo).
//

import SwiftUI

// MARK: - Candlelight ("Kerzenschein")

extension ThemeColors {
    /// Morning Glow - warmer Sonnenaufgang-Gradient
    static let candlelightLight = ThemeColors(
        textPrimary: Color(red: 0.290, green: 0.231, blue: 0.196),
        textSecondary: Color(red: 0.612, green: 0.400, blue: 0.373),
        textOnInteractive: .white,
        interactive: Color(red: 0.851, green: 0.467, blue: 0.408),
        progress: Color(red: 0.851, green: 0.467, blue: 0.408),
        backgroundPrimary: Color(red: 1.000, green: 0.984, blue: 0.961),
        backgroundSecondary: Color(red: 1.000, green: 0.894, blue: 0.839),
        ringTrack: Color(red: 0.784, green: 0.655, blue: 0.588),
        accentBackground: Color(red: 1.000, green: 0.796, blue: 0.643),
        error: Color(red: 0.729, green: 0.102, blue: 0.102)
    )

    /// Evening Cocoa - gedämpftes Terrakotta auf dunklem Kakao-Grund
    static let candlelightDark = ThemeColors(
        textPrimary: Color(red: 0.898, green: 0.863, blue: 0.804),
        textSecondary: Color(red: 0.651, green: 0.541, blue: 0.502),
        textOnInteractive: Color(red: 0.102, green: 0.063, blue: 0.047),
        interactive: Color(red: 0.780, green: 0.490, blue: 0.388),
        progress: Color(red: 0.780, green: 0.490, blue: 0.388),
        backgroundPrimary: Color(red: 0.102, green: 0.063, blue: 0.047),
        backgroundSecondary: Color(red: 0.196, green: 0.122, blue: 0.098),
        ringTrack: Color(red: 0.243, green: 0.145, blue: 0.118),
        accentBackground: Color(red: 0.365, green: 0.227, blue: 0.184),
        error: Color(red: 0.878, green: 0.380, blue: 0.318)
    )
}

// MARK: - Forest ("Wald")

extension ThemeColors {
    /// Misty Pine - kühler Wald-Gradient
    static let forestLight = ThemeColors(
        textPrimary: Color(red: 0.102, green: 0.149, blue: 0.110),
        textSecondary: Color(red: 0.361, green: 0.431, blue: 0.384),
        textOnInteractive: Color(red: 0.878, green: 0.902, blue: 0.882),
        interactive: Color(red: 0.180, green: 0.251, blue: 0.200),
        progress: Color(red: 0.180, green: 0.251, blue: 0.200),
        backgroundPrimary: Color(red: 0.949, green: 0.957, blue: 0.953),
        backgroundSecondary: Color(red: 0.878, green: 0.902, blue: 0.882),
        ringTrack: Color(red: 0.553, green: 0.639, blue: 0.573),
        accentBackground: Color(red: 0.796, green: 0.835, blue: 0.808),
        error: Color(red: 0.729, green: 0.102, blue: 0.102)
    )

    /// Ancient Woods - tiefer Wald-Gradient
    static let forestDark = ThemeColors(
        textPrimary: Color(red: 0.910, green: 0.922, blue: 0.914),
        textSecondary: Color(red: 0.541, green: 0.604, blue: 0.553),
        textOnInteractive: Color(red: 0.043, green: 0.071, blue: 0.051),
        interactive: Color(red: 0.345, green: 0.471, blue: 0.376),
        progress: Color(red: 0.345, green: 0.471, blue: 0.376),
        backgroundPrimary: Color(red: 0.043, green: 0.071, blue: 0.051),
        backgroundSecondary: Color(red: 0.094, green: 0.149, blue: 0.110),
        ringTrack: Color(red: 0.290, green: 0.365, blue: 0.322),
        accentBackground: Color(red: 0.184, green: 0.251, blue: 0.196),
        error: Color(red: 0.878, green: 0.380, blue: 0.318)
    )
}

// MARK: - Moon ("Mondlicht")

extension ThemeColors {
    /// Pure Silver - neutraler Silber-Gradient
    static let moonLight = ThemeColors(
        textPrimary: Color(red: 0.059, green: 0.090, blue: 0.165),
        textSecondary: Color(red: 0.392, green: 0.455, blue: 0.545),
        textOnInteractive: Color(red: 0.973, green: 0.980, blue: 0.988),
        interactive: Color(red: 0.278, green: 0.333, blue: 0.412),
        progress: Color(red: 0.278, green: 0.333, blue: 0.412),
        backgroundPrimary: .white,
        backgroundSecondary: Color(red: 0.973, green: 0.980, blue: 0.988),
        ringTrack: Color(red: 0.580, green: 0.639, blue: 0.722),
        accentBackground: Color(red: 0.796, green: 0.835, blue: 0.882),
        error: Color(red: 0.729, green: 0.102, blue: 0.102)
    )

    /// Midnight Shimmer - tiefstes Schwarz mit Indigo-Schimmer
    static let moonDark = ThemeColors(
        textPrimary: Color(red: 0.973, green: 0.980, blue: 0.988),
        textSecondary: Color(red: 0.580, green: 0.639, blue: 0.722),
        textOnInteractive: Color(red: 0.008, green: 0.008, blue: 0.020),
        interactive: Color(red: 0.506, green: 0.549, blue: 0.973),
        progress: Color(red: 0.506, green: 0.549, blue: 0.973),
        backgroundPrimary: Color(red: 0.008, green: 0.008, blue: 0.020),
        backgroundSecondary: Color(red: 0.059, green: 0.090, blue: 0.165),
        ringTrack: Color(red: 0.278, green: 0.333, blue: 0.412),
        accentBackground: Color(red: 0.192, green: 0.180, blue: 0.506),
        error: Color(red: 0.878, green: 0.380, blue: 0.318)
    )
}
