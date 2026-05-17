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
//  Two font families ship in the bundle: Newsreader (Serif, "display") for content
//  and numerals; Geist (Sans, "ui") for labels and controls. The mapping per role
//  follows the Kerzenschein 2.0 handoff (`handoffs/handoff_typografie/...`).
//

import SwiftUI

// MARK: - Typography Role

/// Semantic typography roles for the app's design system.
///
/// Each role defines font size, weight, family, and text color in one place.
/// Dark mode font weight compensation is applied automatically — views never
/// need to read `colorScheme` for font purposes.
enum TypographyRole: CaseIterable {
    // Timer
    case timerCountdown
    case timerRunning

    // Headings
    case screenTitle
    case inlineNavigationTitle
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
    case playerRemainingTime

    // List
    case listTitle
    case listSubtitle
    case listBody
    case listSectionTitle
    case listActionLabel

    // Edit
    case editLabel
    case editCaption

    // Dialog
    case dialogTitle
    case dialogBody

    /// Setting Card (shared-086)
    case cardLabel

    // Breath Dial (shared-086)
    case dialValue
    case dialUnit
}

// MARK: - Font Family

extension TypographyRole {
    /// Two custom font families ship in the bundle (see Resources/Fonts).
    /// `display` carries content and numerals (Newsreader, Serif).
    /// `ui` carries labels and controls (Geist, Sans).
    enum Family: Equatable {
        case display
        case ui

        /// Returns the PostScript name for this family at the requested weight.
        /// Both families only ship in three weights (Light/Regular/Medium); any
        /// lighter system weight clamps up to Light, anything heavier clamps to Medium.
        func postScriptName(for weight: Font.Weight) -> String {
            let suffix = Self.weightSuffix(for: weight)
            switch self {
            case .display:
                return "Newsreader16pt-\(suffix)"
            case .ui:
                return "Geist-\(suffix)"
            }
        }

        private static func weightSuffix(for weight: Font.Weight) -> String {
            switch weight {
            case .ultraLight,
                 .thin,
                 .light:
                "Light"
            case .regular:
                "Regular"
            default:
                // .medium, .semibold, .bold, .heavy, .black — clamp to Medium
                "Medium"
            }
        }
    }
}

// MARK: - Font Spec (Single Source of Truth)

extension TypographyRole {
    enum FontSpec: Equatable {
        /// Fixed-size font with explicit weight (timer, headings, etc.)
        case fixed(size: CGFloat, weight: Font.Weight)
        /// Dynamic Type font that scales with user text size preference
        case dynamic(style: Font.TextStyle, weight: Font.Weight?)
    }

    var fontSpec: FontSpec {
        switch self {
        // Timer — ultraLight/thin for large numerals
        case .timerCountdown: .fixed(size: 100, weight: .ultraLight)
        case .timerRunning: .fixed(size: 64, weight: .thin)
        // Headings
        case .screenTitle: .fixed(size: 28, weight: .light)
        // .headline is inherently semibold — halation compensation not needed
        case .inlineNavigationTitle: .dynamic(style: .headline, weight: nil)
        case .sectionTitle: .fixed(size: 20, weight: .light)
        // Body
        case .bodyPrimary: .fixed(size: 16, weight: .regular)
        case .bodySecondary: .fixed(size: 15, weight: .light)
        case .caption: .dynamic(style: .caption, weight: .regular)
        // Settings
        case .settingsLabel: .fixed(size: 17, weight: .regular)
        case .settingsDescription: .fixed(size: 13, weight: .regular)
        // Player — heavier weights, no compensation needed but still centralized
        case .playerTitle: .fixed(size: 28, weight: .semibold)
        case .playerTeacher: .fixed(size: 20, weight: .medium)
        case .playerTimestamp: .dynamic(style: .caption, weight: .regular)
        case .playerCountdown: .fixed(size: 32, weight: .light)
        // Restzeit-Label im Atemkreis-Player — sekundaer, ruhig, soll nicht mit
        // dem Meditationstitel oben konkurrieren.
        case .playerRemainingTime: .fixed(size: 14, weight: .medium)
        // List — Geist Regular 400 across the board (Handoff: "Sans steuert").
        // Sizes folgen direkt der Library-Spec: Author-Header 14, Track-Titel 16.
        case .listTitle: .fixed(size: 14, weight: .regular)
        case .listSubtitle: .dynamic(style: .subheadline, weight: .regular)
        case .listBody: .dynamic(style: .body, weight: .regular)
        case .listSectionTitle: .dynamic(style: .title2, weight: .medium)
        case .listActionLabel: .fixed(size: 16, weight: .regular)
        // Edit
        case .editLabel: .dynamic(style: .subheadline, weight: .medium)
        case .editCaption: .dynamic(style: .caption, weight: .regular)
        // Dialog — small modal text (e.g. download progress)
        case .dialogTitle: .fixed(size: 18, weight: .light)
        case .dialogBody: .fixed(size: 12, weight: .regular)
        // Setting Card (shared-086) — sentence-case label
        case .cardLabel: .fixed(size: 11, weight: .regular)
        // Breath Dial (shared-086) — center value (default 62, scales bis 76 via size override)
        case .dialValue: .fixed(size: 62, weight: .light)
        // Breath Dial (shared-086) — "Minuten"-Label unter dem Wert
        case .dialUnit: .fixed(size: 10, weight: .regular)
        }
    }

    /// Family-Mapping nach Handoff "Kerzenschein 2.0" (Sektion Typografie).
    /// Display = Newsreader (Stimme, Inhalt, Numerik), UI = Geist (Labels, Werte, Steuerung).
    var fontFamily: Family {
        switch self {
        // Display — Numerik, Headlines, Body-Display, Dialog-Titel
        case .timerCountdown,
             .timerRunning,
             .screenTitle,
             .inlineNavigationTitle,
             .sectionTitle,
             .bodyPrimary,
             .bodySecondary,
             .playerTitle,
             .playerTeacher,
             .playerCountdown,
             .dialogTitle,
             .dialValue:
            .display
        // UI — Labels, Werte, Eyebrows, Listen, Edit, Dial-Einheit
        case .caption,
             .settingsLabel,
             .settingsDescription,
             .playerTimestamp,
             .playerRemainingTime,
             .listTitle,
             .listSubtitle,
             .listBody,
             .listSectionTitle,
             .listActionLabel,
             .editLabel,
             .editCaption,
             .dialogBody,
             .cardLabel,
             .dialUnit:
            .ui
        }
    }

    /// Letter-Spacing pro Rolle. Default 0 — nur einzelne Rollen mit
    /// bewusstem Tracking-Bedarf weichen ab.
    var tracking: CGFloat {
        switch self {
        case .dialValue: -1.5
        // ios-046: Restzeit braucht negatives Tracking analog zum Handoff
        // (-0.02em bei 64 pt = -1.28 pt) — kompakte grosse Ziffer.
        case .timerRunning: -1.28
        default: 0
        }
    }

    var textColor: KeyPath<ThemeColors, Color> {
        switch self {
        case .timerCountdown,
             .timerRunning: \.textPrimary
        case .screenTitle,
             .inlineNavigationTitle,
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
        case .playerRemainingTime: \.textSecondary
        case .listTitle,
             .listSectionTitle: \.textPrimary
        case .listSubtitle,
             .listBody: \.textSecondary
        case .listActionLabel: \.textPrimary
        case .editLabel: \.textPrimary
        case .editCaption: \.textSecondary
        case .dialogTitle: \.textPrimary
        case .dialogBody: \.textSecondary
        case .cardLabel: \.textSecondary
        case .dialValue: \.textPrimary
        case .dialUnit: \.textSecondary
        }
    }
}

// MARK: - Dark Mode Font Weight Compensation

extension Font.Weight {
    /// Returns one step heavier weight in dark mode to compensate for halation
    /// (light text on dark backgrounds appears thinner than dark text on light backgrounds).
    /// Only the thin range needs compensation — Regular and heavier already render
    /// strongly on dark backgrounds; bumping them further would make UI labels read
    /// as bold instead of named-but-restful elements.
    func darkModeCompensated(_ colorScheme: ColorScheme) -> Font.Weight {
        guard colorScheme == .dark else {
            return self
        }
        switch self {
        case .ultraLight: return .thin
        case .thin: return .light
        case .light: return .regular
        default: return self
        }
    }
}

// MARK: - Dynamic Type Base Size

/// Default base sizes for Dynamic Type text styles (matching Apple's defaults
/// at the "Large" Dynamic Type setting). Used when building custom fonts that
/// should scale relative to a TextStyle.
private let dynamicTypeBaseSizes: [Font.TextStyle: CGFloat] = [
    .largeTitle: 34,
    .title: 28,
    .title2: 22,
    .title3: 20,
    .headline: 17,
    .body: 17,
    .callout: 16,
    .subheadline: 15,
    .footnote: 13,
    .caption: 12,
    .caption2: 11
]

private func defaultBaseSize(for style: Font.TextStyle) -> CGFloat {
    dynamicTypeBaseSizes[style] ?? 17
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
            .tracking(self.role.tracking)
            .foregroundColor(self.theme[keyPath: self.colorOverride ?? self.role.textColor])
    }

    private var resolvedFont: Font {
        let family = self.role.fontFamily
        switch self.role.fontSpec {
        case let .fixed(size, weight):
            let actualSize = self.sizeOverride ?? size
            let compensated = weight.darkModeCompensated(self.colorScheme)
            return .custom(family.postScriptName(for: compensated), size: actualSize)
        case let .dynamic(style, weight):
            assert(
                self.sizeOverride == nil,
                "sizeOverride is not supported for Dynamic Type roles (\(self.role)). Use a .fixed role instead."
            )
            // For dynamic roles without an explicit weight we fall back to regular
            // (e.g. .headline is inherently semibold for system, but our display
            // family caps at medium — using regular keeps the visual hierarchy
            // close to the previous behaviour without over-emphasising).
            let resolvedWeight = (weight ?? .regular).darkModeCompensated(self.colorScheme)
            return .custom(
                family.postScriptName(for: resolvedWeight),
                size: defaultBaseSize(for: style),
                relativeTo: style
            )
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
    ///     Text("timer.idle.headline", bundle: .main)
    ///         .themeFont(.screenTitle)
    ///
    ///     Text(viewModel.formattedRemainingMinutes)
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
