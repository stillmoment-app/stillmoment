//
//  Font+Theme.swift
//  Still Moment
//
//  Presentation Layer - Theme Font Definitions (Design Tokens)
//
//  Usage:
//  - Use semantic font roles for consistent typography
//  - .settingsLabel for form labels (17pt)
//  - .settingsDescription for secondary text (13pt)
//  - .settingsLabelStyle() for label with primary color
//  - .settingsDescriptionStyle() for description with secondary color
//

import SwiftUI

// MARK: - Semantic Font Roles

extension Font {
    /// Font for form labels and toggle titles (17pt rounded)
    static let settingsLabel = Font.system(size: 17, weight: .regular, design: .rounded)

    /// Font for descriptions and secondary text (13pt rounded)
    static let settingsDescription = Font.system(size: 13, weight: .regular, design: .rounded)

    /// Font for small decorative icons in settings (12pt)
    static let settingsIcon = Font.system(size: 12)
}

// MARK: - Text Style Modifiers

private struct SettingsLabelModifier: ViewModifier {
    @Environment(\.themeColors)
    private var theme

    func body(content: Content) -> some View {
        content
            .font(.settingsLabel)
            .foregroundColor(self.theme.textPrimary)
    }
}

private struct SettingsDescriptionModifier: ViewModifier {
    @Environment(\.themeColors)
    private var theme

    func body(content: Content) -> some View {
        content
            .font(.settingsDescription)
            .foregroundColor(self.theme.textSecondary)
    }
}

extension View {
    /// Settings label style: 17pt rounded + primary text color
    func settingsLabelStyle() -> some View {
        modifier(SettingsLabelModifier())
    }

    /// Settings description style: 13pt rounded + secondary text color
    func settingsDescriptionStyle() -> some View {
        modifier(SettingsDescriptionModifier())
    }
}
