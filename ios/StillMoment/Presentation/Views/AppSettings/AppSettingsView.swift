//
//  AppSettingsView.swift
//  Still Moment
//
//  Presentation Layer - App-wide settings tab (Appearance, Info & Legal)
//

import SwiftUI

/// App settings tab: Appearance (theme, appearance mode) and Info & Legal.
///
/// Theme/Appearance are handled by the reusable `GeneralSettingsSection`.
/// Info rows navigate to sub-screens or open external links.
struct AppSettingsView: View {
    @Environment(\.themeColors)
    private var theme

    private let privacyURL = URL(string: "https://stillmoment-app.github.io/stillmoment/privacy.html")

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            Form {
                GeneralSettingsSection()
                self.infoSection
            }
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("tab.settings", bundle: .main)
                        .themeFont(.inlineNavigationTitle)
                }
            }
        }
    }

    // MARK: - Info & Legal Section

    private var infoSection: some View {
        Section {
            NavigationLink {
                SoundAttributionsView()
            } label: {
                Text("app.settings.soundAttributions.title", bundle: .main)
                    .themeFont(.settingsLabel)
            }
            .accessibilityIdentifier("app.settings.row.soundAttributions")
            .accessibilityHint(
                NSLocalizedString("accessibility.appSettings.soundAttributions.hint", comment: "")
            )
            .cardRowBackground()

            if let url = self.privacyURL {
                Link(destination: url) {
                    Text("app.settings.privacy.title", bundle: .main)
                        .themeFont(.settingsLabel)
                }
                .accessibilityIdentifier("app.settings.row.privacy")
                .accessibilityHint(
                    NSLocalizedString("accessibility.appSettings.privacy.hint", comment: "")
                )
                .cardRowBackground()
            }

            HStack {
                Text("app.settings.version.label", bundle: .main)
                    .themeFont(.settingsLabel)
                Spacer()
                Text(self.appVersion)
                    .themeFont(.settingsLabel, color: \.textSecondary)
            }
            .cardRowBackground()
        } header: {
            Text("app.settings.info.header", bundle: .main)
                .foregroundColor(self.theme.textSecondary)
        }
    }

    // MARK: - Private

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        AppSettingsView()
    }
}
