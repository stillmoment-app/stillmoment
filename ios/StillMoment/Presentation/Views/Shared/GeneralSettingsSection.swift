//
//  GeneralSettingsSection.swift
//  Still Moment
//
//  Presentation Layer - Reusable general settings section for both tabs.
//

import SwiftUI

/// Reusable settings section for app-wide settings (theme and appearance selection).
///
/// Embedded at the bottom of both Timer Settings and Library Settings
/// to provide consistent access to general preferences from either tab.
struct GeneralSettingsSection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        Section {
            Picker(selection: self.$themeManager.selectedTheme) {
                ForEach(ColorTheme.allCases, id: \.self) { colorTheme in
                    Text(colorTheme.localizedName)
                        .tag(colorTheme)
                }
            } label: {
                Text("settings.theme.title", bundle: .main)
                    .themeFont(.settingsLabel)
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("settings.picker.theme")
            .accessibilityLabel("settings.theme.title")
            .listRowBackground(self.theme.cardBackground)

            VStack(alignment: .leading, spacing: 8) {
                Text("settings.appearance.title", bundle: .main)
                    .themeFont(.settingsLabel)

                Picker(selection: self.$themeManager.appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.localizedName)
                            .tag(mode)
                    }
                } label: {
                    Text("settings.appearance.title", bundle: .main)
                        .themeFont(.settingsLabel)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("settings.picker.appearance")
                .accessibilityLabel(
                    NSLocalizedString("settings.appearance.title", comment: "")
                )
            }
            .listRowBackground(self.theme.cardBackground)
        } header: {
            Text("settings.general.header", bundle: .main)
                .foregroundColor(self.theme.textSecondary)
        }
    }
}
