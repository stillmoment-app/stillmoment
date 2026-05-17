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
                GuidedMeditationSettingsSection()
                self.infoSection
                #if DEBUG
                self.debugSection
                #endif
            }
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("tab.settings", bundle: .main)
                        .textStyle(.screenTitle, color: \.textPrimary)
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
                    .textStyle(.body, color: \.textPrimary)
            }
            .accessibilityIdentifier("app.settings.row.soundAttributions")
            .accessibilityHint(
                NSLocalizedString("accessibility.appSettings.soundAttributions.hint", comment: "")
            )
            .cardRowBackground()

            if let url = self.privacyURL {
                Link(destination: url) {
                    Text("app.settings.privacy.title", bundle: .main)
                        .textStyle(.body, color: \.textPrimary)
                }
                .accessibilityIdentifier("app.settings.row.privacy")
                .accessibilityHint(
                    NSLocalizedString("accessibility.appSettings.privacy.hint", comment: "")
                )
                .cardRowBackground()
            }

            HStack {
                Text("app.settings.version.label", bundle: .main)
                    .textStyle(.body, color: \.textPrimary)
                Spacer()
                Text(self.appVersion)
                    .textStyle(.body, color: \.textSecondary)
            }
            .cardRowBackground()
        } header: {
            Text("app.settings.info.header", bundle: .main)
                .foregroundColor(self.theme.textSecondary)
        }
    }

    // MARK: - Debug Section (DEBUG-only)

    #if DEBUG
    private var debugSection: some View {
        Section {
            NavigationLink {
                DebugTypographyReferenceView()
            } label: {
                Text("Typography Reference")
                    .textStyle(.body, color: \.textPrimary)
            }
            .cardRowBackground()
        } header: {
            Text("Debug")
                .foregroundColor(self.theme.textSecondary)
        }
    }
    #endif

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
