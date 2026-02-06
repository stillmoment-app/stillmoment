//
//  Font+Theme.swift
//  Still Moment
//
//  Presentation Layer - Centralized Typography System (Design Tokens)
//
//  Usage:
//  - .themeFont(.screenTitle) for themed text with automatic dark mode compensation
//  - .themeFont(.timerCountdown, size: isCompact ? 80 : nil) for responsive sizes
//  - .themeFont(.caption, color: \.error) for color override
//

import SwiftUI

// MARK: - Typography Role

/// Semantic typography roles for the app's design system.
///
/// Each role defines font size, weight, design, and text color in one place.
/// Dark mode font weight compensation is applied automatically — views never
/// need to read `colorScheme` for font purposes.
enum TypographyRole: CaseIterable {
    // Timer
    case timerCountdown
    case timerRunning

    // Headings
    case screenTitle
    case sectionTitle

    // Body
    case bodyPrimary
    case bodySecondary
    case caption

    // Settings
    case settingsLabel
    case settingsDescription

    // Player
    case playerTitle
    case playerTeacher
    case playerTimestamp
    case playerCountdown

    // List
    case listTitle
    case listSubtitle
    case listBody
    case listSectionTitle
    case listActionLabel

    // Edit
    case editLabel
    case editCaption
}

// MARK: - Font Spec (Single Source of Truth)

extension TypographyRole {
    enum FontSpec: Equatable {
        /// Fixed-size font with explicit weight (timer, headings, etc.)
        case fixed(size: CGFloat, weight: Font.Weight, design: Font.Design)
        /// Dynamic Type font that scales with user text size preference
        case dynamic(style: Font.TextStyle, weight: Font.Weight?, design: Font.Design)
    }

    var fontSpec: FontSpec {
        switch self {
        // Timer — ultraLight/thin for large numerals
        case .timerCountdown: .fixed(size: 100, weight: .ultraLight, design: .rounded)
        case .timerRunning: .fixed(size: 60, weight: .thin, design: .rounded)
        // Headings
        case .screenTitle: .fixed(size: 28, weight: .light, design: .rounded)
        case .sectionTitle: .fixed(size: 20, weight: .light, design: .rounded)
        // Body
        case .bodyPrimary: .fixed(size: 16, weight: .regular, design: .rounded)
        case .bodySecondary: .fixed(size: 15, weight: .light, design: .rounded)
        case .caption: .dynamic(style: .caption, weight: .regular, design: .rounded)
        // Settings
        case .settingsLabel: .fixed(size: 17, weight: .regular, design: .rounded)
        case .settingsDescription: .fixed(size: 13, weight: .regular, design: .rounded)
        // Player — heavier weights, no compensation needed but still centralized
        case .playerTitle: .fixed(size: 28, weight: .semibold, design: .rounded)
        case .playerTeacher: .fixed(size: 20, weight: .medium, design: .rounded)
        case .playerTimestamp: .dynamic(style: .caption, weight: .regular, design: .rounded)
        case .playerCountdown: .fixed(size: 32, weight: .light, design: .rounded)
        // List — Dynamic Type for accessibility
        // .headline is inherently semibold — halation compensation not needed (only ≤regular is adjusted)
        case .listTitle: .dynamic(style: .headline, weight: nil, design: .rounded)
        case .listSubtitle: .dynamic(style: .subheadline, weight: .regular, design: .rounded)
        case .listBody: .dynamic(style: .body, weight: .regular, design: .rounded)
        case .listSectionTitle: .dynamic(style: .title2, weight: .medium, design: .rounded)
        case .listActionLabel: .dynamic(style: .body, weight: .medium, design: .rounded)
        // Edit
        case .editLabel: .dynamic(style: .subheadline, weight: .medium, design: .rounded)
        case .editCaption: .dynamic(style: .caption, weight: .regular, design: .rounded)
        }
    }

    var textColor: KeyPath<ThemeColors, Color> {
        switch self {
        case .timerCountdown,
             .timerRunning: \.textPrimary
        case .screenTitle,
             .sectionTitle: \.textPrimary
        case .bodyPrimary: \.textPrimary
        case .bodySecondary,
             .caption: \.textSecondary
        case .settingsLabel: \.textPrimary
        case .settingsDescription: \.textSecondary
        case .playerTitle: \.textPrimary
        case .playerTeacher: \.interactive
        case .playerTimestamp: \.textSecondary
        case .playerCountdown: \.textPrimary
        case .listTitle,
             .listSectionTitle: \.textPrimary
        case .listSubtitle,
             .listBody: \.textSecondary
        case .listActionLabel: \.textPrimary
        case .editLabel: \.textPrimary
        case .editCaption: \.textSecondary
        }
    }
}

// MARK: - Dark Mode Font Weight Compensation

extension Font.Weight {
    /// Returns one step heavier weight in dark mode to compensate for halation
    /// (light text on dark backgrounds appears thinner than dark text on light backgrounds).
    func darkModeCompensated(_ colorScheme: ColorScheme) -> Font.Weight {
        guard colorScheme == .dark else {
            return self
        }
        switch self {
        case .ultraLight: return .thin
        case .thin: return .light
        case .light: return .regular
        case .regular: return .medium
        default: return self
        }
    }
}

// MARK: - Theme Typography Modifier

private struct ThemeTypographyModifier: ViewModifier {
    let role: TypographyRole
    let sizeOverride: CGFloat?
    let colorOverride: KeyPath<ThemeColors, Color>?

    @Environment(\.themeColors)
    private var theme
    @Environment(\.colorScheme)
    private var colorScheme

    func body(content: Content) -> some View {
        content
            .font(self.resolvedFont)
            .foregroundColor(self.theme[keyPath: self.colorOverride ?? self.role.textColor])
    }

    private var resolvedFont: Font {
        switch self.role.fontSpec {
        case let .fixed(size, weight, design):
            let actualSize = self.sizeOverride ?? size
            return .system(
                size: actualSize,
                weight: weight.darkModeCompensated(self.colorScheme),
                design: design
            )
        case let .dynamic(style, weight, design):
            assert(
                self.sizeOverride == nil,
                "sizeOverride is not supported for Dynamic Type roles (\(self.role)). Use a .fixed role instead."
            )
            if let weight {
                return .system(
                    style,
                    design: design,
                    weight: weight.darkModeCompensated(self.colorScheme)
                )
            }
            return .system(style, design: design)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply themed typography with automatic dark mode weight compensation.
    ///
    /// Uses the role's default size unless overridden for responsive layouts.
    /// Color defaults to the role's semantic color but can be overridden.
    ///
    ///     Text("welcome.title", bundle: .main)
    ///         .themeFont(.screenTitle)
    ///
    ///     Text(viewModel.formattedTime)
    ///         .themeFont(.timerCountdown, size: isCompact ? 80 : nil)
    ///
    ///     Text(error)
    ///         .themeFont(.caption, color: \.error)
    func themeFont(
        _ role: TypographyRole,
        size: CGFloat? = nil,
        color: KeyPath<ThemeColors, Color>? = nil
    ) -> some View {
        modifier(ThemeTypographyModifier(role: role, sizeOverride: size, colorOverride: color))
    }
}

// MARK: - Icon Font (not part of typography system)

extension Font {
    /// Font for small decorative icons in settings (12pt)
    static let settingsIcon = Font.system(size: 12)
}
