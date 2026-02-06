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
        textSecondary: Color(red: 0.541, green: 0.353, blue: 0.325),
        textOnInteractive: .white,
        interactive: Color(red: 0.690, green: 0.361, blue: 0.298),
        progress: Color(red: 0.690, green: 0.361, blue: 0.298),
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
    /// Woodland Floor - warmer Waldboden-Gradient
    static let forestLight = ThemeColors(
        textPrimary: Color(red: 0.161, green: 0.161, blue: 0.133),
        textSecondary: Color(red: 0.361, green: 0.353, blue: 0.322),
        textOnInteractive: Color(red: 0.976, green: 0.969, blue: 0.949),
        interactive: Color(red: 0.322, green: 0.329, blue: 0.255),
        progress: Color(red: 0.322, green: 0.329, blue: 0.255),
        backgroundPrimary: Color(red: 0.922, green: 0.914, blue: 0.871),
        backgroundSecondary: Color(red: 0.839, green: 0.827, blue: 0.773),
        ringTrack: Color(red: 0.620, green: 0.616, blue: 0.561),
        accentBackground: Color(red: 0.690, green: 0.686, blue: 0.612),
        error: Color(red: 0.729, green: 0.102, blue: 0.102)
    )

    /// Deep Woods - tiefer dunkler Wald-Gradient
    static let forestDark = ThemeColors(
        textPrimary: Color(red: 0.918, green: 0.937, blue: 0.918),
        textSecondary: Color(red: 0.522, green: 0.588, blue: 0.533),
        textOnInteractive: Color(red: 0.059, green: 0.078, blue: 0.059),
        interactive: Color(red: 0.392, green: 0.541, blue: 0.420),
        progress: Color(red: 0.392, green: 0.541, blue: 0.420),
        backgroundPrimary: Color(red: 0.059, green: 0.078, blue: 0.059),
        backgroundSecondary: Color(red: 0.102, green: 0.141, blue: 0.106),
        ringTrack: Color(red: 0.200, green: 0.259, blue: 0.212),
        accentBackground: Color(red: 0.173, green: 0.231, blue: 0.188),
        error: Color(red: 0.878, green: 0.380, blue: 0.318)
    )
}

// MARK: - Moon ("Mondlicht")

extension ThemeColors {
    /// Sterling Silver - satteres Silber-Blau mit Tiefe
    static let moonLight = ThemeColors(
        textPrimary: Color(red: 0.063, green: 0.165, blue: 0.263),
        textSecondary: Color(red: 0.243, green: 0.349, blue: 0.447),
        textOnInteractive: Color(red: 0.941, green: 0.957, blue: 0.973),
        interactive: Color(red: 0.200, green: 0.306, blue: 0.408),
        progress: Color(red: 0.200, green: 0.306, blue: 0.408),
        backgroundPrimary: Color(red: 0.851, green: 0.886, blue: 0.925),
        backgroundSecondary: Color(red: 0.773, green: 0.816, blue: 0.871),
        ringTrack: Color(red: 0.510, green: 0.604, blue: 0.694),
        accentBackground: Color(red: 0.624, green: 0.702, blue: 0.784),
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
