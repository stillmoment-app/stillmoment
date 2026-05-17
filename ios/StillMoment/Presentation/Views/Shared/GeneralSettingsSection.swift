//
//  GeneralSettingsSection.swift
//  Still Moment
//
//  Presentation Layer - Reusable general settings section for both tabs.
//

import SwiftUI
import UIKit

/// Reusable settings section for app-wide settings (appearance selection).
///
/// Used in the App Settings tab to provide appearance controls.
struct GeneralSettingsSection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        Section {
            Picker(selection: self.$themeManager.appearanceMode) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Text(mode.localizedName)
                        .tag(mode)
                }
            } label: {
                Text("settings.appearance.title", bundle: .main)
                    .textStyle(.body, color: \.textPrimary)
            }
            .pickerStyle(.menu)
            .onChange(of: self.themeManager.appearanceMode) { _ in
                HapticFeedback.selection()
            }
            .accessibilityIdentifier("settings.picker.appearance")
            .accessibilityLabel(
                NSLocalizedString("settings.appearance.title", comment: "")
            )
            .cardRowBackground()
        } header: {
            Text("settings.general.header", bundle: .main)
                .foregroundColor(self.theme.textSecondary)
        }
    }
}
