//
//  Color+Theme.swift
//  Still Moment
//
//  Presentation Layer - Theme Color Definitions (Design Tokens)
//
//  Primary colors are defined in Assets.xcassets/Colors/ and automatically
//  available via Xcode's generated asset symbols (e.g., Color.warmCream).
//
//  This file contains:
//  - Semantic color roles (textPrimary, textSecondary, interactive, etc.)
//  - Computed properties (warmGradient)
//
//  Usage:
//  - Use semantic roles for consistent theming: .textPrimary instead of .warmBlack
//  - This enables future theme switching and dark mode support
//

import SwiftUI

// MARK: - Opacity Design Tokens

extension Double {
    /// Opacity for overlay backgrounds (loading states, modals)
    static let opacityOverlay: Double = 0.2

    /// Opacity for shadow effects
    static let opacityShadow: Double = 0.3

    /// Opacity for secondary/disabled UI elements
    static let opacitySecondary: Double = 0.5

    /// Opacity for tertiary/hint UI elements
    static let opacityTertiary: Double = 0.7
}

// MARK: - Semantic Color Roles

extension Color {
    // MARK: - Text Colors

    /// Primary text color for headings and important content
    static var textPrimary: Color { .warmBlack }

    /// Secondary text color for descriptions and hints
    static var textSecondary: Color { .warmGray }

    /// Text color on interactive/colored backgrounds (e.g., primary buttons)
    static var textOnInteractive: Color { .white }

    // MARK: - Interactive Colors

    /// Color for interactive elements (buttons, icons, controls)
    static var interactive: Color { .terracotta }

    /// Color for progress indicators (timer ring, sliders)
    static var progress: Color { .terracotta }

    // MARK: - Background Colors

    /// Primary background color
    static var backgroundPrimary: Color { .warmCream }

    /// Secondary background color
    static var backgroundSecondary: Color { .warmSand }

    // MARK: - Feedback Colors

    /// Color for error states and warnings
    static var error: Color { .warmError }

    // MARK: - Gradients

    /// Main background gradient for views
    static var warmGradient: LinearGradient {
        LinearGradient(
            colors: [
                .warmCream, // top
                .warmSand, // middle
                .paleApricot // bottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
