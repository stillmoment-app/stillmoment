//
//  ThemeColors+Palettes.swift
//  Still Moment
//
//  Presentation Layer - Concrete color values for the single theme in light + dark mode.
//
//  All colors are inline RGB (sRGB color space). Verfeinerung erfolgt in einem
//  separaten Refinement-Schritt; die Werte stammen aus dem fruehen Kerzenschein-Theme.
//

import SwiftUI

extension ThemeColors {
    /// Morning Glow - warmer Sonnenaufgang-Gradient
    static let light = ThemeColors(
        textPrimary: Color(red: 0.290, green: 0.231, blue: 0.196),
        textSecondary: Color(red: 0.541, green: 0.353, blue: 0.325),
        textOnInteractive: .white,
        interactive: Color(red: 0.620, green: 0.325, blue: 0.267),
        progress: Color(red: 0.620, green: 0.325, blue: 0.267),
        controlTrack: Color(red: 0.580, green: 0.490, blue: 0.435),
        backgroundPrimary: Color(red: 1.000, green: 0.984, blue: 0.961),
        backgroundSecondary: Color(red: 1.000, green: 0.894, blue: 0.839),
        cardBackground: Color(red: 1.000, green: 0.984, blue: 0.961),
        cardBorder: .clear,
        ringTrack: Color(red: 0.784, green: 0.655, blue: 0.588),
        accentBackground: Color(red: 1.000, green: 0.796, blue: 0.643),
        error: Color(red: 0.729, green: 0.102, blue: 0.102)
    )

    /// Evening Cocoa - gedämpftes Terrakotta auf dunklem Kakao-Grund
    static let dark = ThemeColors(
        textPrimary: Color(red: 0.898, green: 0.863, blue: 0.804),
        textSecondary: Color(red: 0.651, green: 0.541, blue: 0.502),
        textOnInteractive: Color(red: 0.102, green: 0.063, blue: 0.047),
        interactive: Color(red: 0.780, green: 0.490, blue: 0.388),
        progress: Color(red: 0.780, green: 0.490, blue: 0.388),
        controlTrack: Color(red: 0.510, green: 0.412, blue: 0.376),
        backgroundPrimary: Color(red: 0.102, green: 0.063, blue: 0.047),
        backgroundSecondary: Color(red: 0.196, green: 0.122, blue: 0.098),
        cardBackground: Color(red: 0.145, green: 0.137, blue: 0.133),
        cardBorder: Color(red: 0.245, green: 0.237, blue: 0.233),
        ringTrack: Color(red: 0.632, green: 0.377, blue: 0.307),
        accentBackground: Color(red: 0.365, green: 0.227, blue: 0.184),
        error: Color(red: 0.878, green: 0.380, blue: 0.318)
    )
}
