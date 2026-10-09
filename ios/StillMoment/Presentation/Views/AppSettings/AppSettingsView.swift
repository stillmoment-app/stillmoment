//
//  AppSettingsView.swift
//  Still Moment
//
//  Presentation Layer - App-wide settings tab (Appearance, Info & Legal)
//

import SwiftUI
import UIKit

/// App settings tab: Appearance (theme, appearance mode) and Info & Legal.
///
/// Theme/Appearance are handled by the reusable `GeneralSettingsSection`.
/// Info rows navigate to sub-screens or open external links.
struct AppSettingsView: View {
    // MARK: Internal

    /// Persists the guided-meditation settings (preparation time).
    let settingsRepository: GuidedSettingsRepository

    @Environment(\.themeColors)
    private var theme

    @Environment(\.openURL)
    private var openURL

    @State private var showsNoMailAppAlert = false

    private let privacyURL = URL(string: "https://stillmoment-app.github.io/stillmoment/privacy.html")

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            Form {
                GeneralSettingsSection()
                GuidedMeditationSettingsSection(settingsRepository: self.settingsRepository)
                self.infoSection
                #if DEBUG
                self.debugSection
                #endif
            }
            .scrollContentBackground(.hidden)
            .screenTitleBar("tab.settings")
        }
        .alert(
            NSLocalizedString("app.settings.writeToUs.noMailApp.title", comment: ""),
            isPresented: self.$showsNoMailAppAlert
        ) {
            Button(NSLocalizedString("app.settings.writeToUs.noMailApp.copy", comment: "")) {
                UIPasteboard.general.string = FeedbackLinks.contactAddress
            }
            Button(NSLocalizedString("common.ok", comment: ""), role: .cancel) {}
        } message: {
            Text(String(
                format: NSLocalizedString("app.settings.writeToUs.noMailApp.message", comment: ""),
                FeedbackLinks.contactAddress
            ))
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

            self.rateAppRow
            self.writeToUsRow

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
                .textStyle(.section, color: \.textSecondary)
                .textCase(nil)
        }
    }

    // MARK: - Feedback Rows

    @ViewBuilder private var rateAppRow: some View {
        if let url = FeedbackLinks.rateAppURL {
            Link(destination: url) {
                Text("app.settings.rateApp.title", bundle: .main)
                    .textStyle(.body, color: \.textPrimary)
            }
            .accessibilityIdentifier("app.settings.row.rateApp")
            .accessibilityHint(
                NSLocalizedString("accessibility.appSettings.rateApp.hint", comment: "")
            )
            .cardRowBackground()
        }
    }

    private var writeToUsRow: some View {
        Button(action: self.openWriteToUsMail) {
            VStack(alignment: .leading, spacing: 3) {
                Text("app.settings.writeToUs.title", bundle: .main)
                    .textStyle(.body, color: \.textPrimary)
                Text("app.settings.writeToUs.subtitle", bundle: .main)
                    .textStyle(.caption, color: \.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier("app.settings.row.writeToUs")
        .accessibilityHint(
            NSLocalizedString("accessibility.appSettings.writeToUs.hint", comment: "")
        )
        .cardRowBackground()
    }

    /// Opens a prepared mail; if no mail app can take it, shows the address to copy instead.
    private func openWriteToUsMail() {
        guard let url = FeedbackLinks.writeToUsURL(
            appVersion: self.appVersion,
            build: self.buildNumber,
            osVersion: UIDevice.current.systemVersion
        ) else {
            self.showsNoMailAppAlert = true
            return
        }
        self.openURL(url) { accepted in
            if !accepted {
                self.showsNoMailAppAlert = true
            }
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
                .textStyle(.section, color: \.textSecondary)
                .textCase(nil)
        }
    }
    #endif

    // MARK: - Private

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}
