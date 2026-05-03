//
//  ThemeColors.swift
//  Still Moment
//
//  Presentation Layer - Resolved color values for the active theme.
//
//  Views read colors via @Environment(\.themeColors). This enables
//  SwiftUI's observation system to re-render when the theme changes,
//  unlike static Color properties which are not reactive.
//

import SwiftUI

struct ThemeColors: Equatable, Hashable {
    // MARK: - Text Colors

    let textPrimary: Color
    let textSecondary: Color
    let textOnInteractive: Color

    // MARK: - Interactive Colors

    let interactive: Color
    let progress: Color
    let controlTrack: Color

    // MARK: - Background Colors

    let backgroundPrimary: Color
    let backgroundSecondary: Color
    let cardBackground: Color
    let cardBorder: Color
    let ringTrack: Color
    let accentBackground: Color

    // MARK: - Feedback Colors

    let error: Color

    // MARK: - Gradient

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [self.backgroundPrimary, self.backgroundSecondary, self.accentBackground],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Banner Tokens (shared-039b)

    /// Akzent-getoenter Hintergrund fuer Banner-Karten im Quellen-Sheet.
    var accentBannerBackground: Color {
        self.interactive.opacity(0.10)
    }

    /// Akzent-getoenter Border fuer Banner-Karten im Quellen-Sheet.
    var accentBannerBorder: Color {
        self.interactive.opacity(0.28)
    }

    /// Akzent-getoenter Hintergrund fuer kreisrunde Icon-Bubbles
    /// (Banner-Icon links, Step-Number-Badge in Anleitungen).
    var accentBubbleBackground: Color {
        self.interactive.opacity(0.18)
    }
}

// MARK: - Theme Resolution

extension ThemeColors {
    private static let palettes: [ColorTheme: (light: ThemeColors, dark: ThemeColors)] = [
        .candlelight: (light: .candlelightLight, dark: .candlelightDark),
        .forest: (light: .forestLight, dark: .forestDark),
        .moon: (light: .moonLight, dark: .moonDark)
    ]

    static func resolve(theme: ColorTheme, colorScheme: ColorScheme) -> ThemeColors {
        guard let palette = palettes[theme] else {
            return .candlelightLight
        }
        if colorScheme == .dark {
            return palette.dark
        }
        return palette.light
    }
}

// MARK: - Environment Key

private struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue: ThemeColors = .candlelightLight
}

extension EnvironmentValues {
    var themeColors: ThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }
}
