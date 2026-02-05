//
//  GeneralSettingsSection.swift
//  Still Moment
//
//  Presentation Layer - Reusable general settings section for both tabs.
//

import SwiftUI

/// Reusable settings section for app-wide settings (theme selection).
///
/// Embedded at the bottom of both Timer Settings and Library Settings
/// to provide consistent access to general preferences from either tab.
struct GeneralSettingsSection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        Section {
            Picker(
                NSLocalizedString("settings.theme.title", comment: ""),
                selection: self.$themeManager.selectedTheme
            ) {
                ForEach(ColorTheme.allCases, id: \.self) { colorTheme in
                    Text(colorTheme.localizedName)
                        .tag(colorTheme)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("settings.picker.theme")
            .accessibilityLabel("settings.theme.title")
            .listRowBackground(self.theme.backgroundPrimary)
        } header: {
            Text("settings.general.header", bundle: .main)
        }
    }
}
