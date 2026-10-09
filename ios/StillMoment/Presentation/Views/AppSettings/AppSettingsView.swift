//
//  AppSettingsView.swift
//  Still Moment
//
//  Presentation Layer - App-wide settings tab (Appearance, Guided Meditations, Feedback, Info & Legal)
//

import SwiftUI
import UIKit

/// App settings tab: Appearance (theme, appearance mode), Guided Meditations, Feedback and Info & Legal.
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
                self.feedbackSection
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

    // MARK: - Feedback Section

    private var feedbackSection: some View {
        Section {
            self.rateAppRow
            self.writeToUsRow
        } header: {
            Text("app.settings.feedback.header", bundle: .main)
                .textStyle(.section, color: \.textSecondary)
                .textCase(nil)
        }
    }

    @ViewBuilder private var rateAppRow: some View {
        if let url = FeedbackLinks.rateAppURL {
            Link(destination: url) {
                self.feedbackRowLabel(
                    title: "app.settings.rateApp.title",
                    subtitle: "app.settings.rateApp.subtitle"
                )
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
            self.feedbackRowLabel(
                title: "app.settings.writeToUs.title",
                subtitle: "app.settings.writeToUs.subtitle"
            )
        }
        .accessibilityIdentifier("app.settings.row.writeToUs")
        .accessibilityHint(
            NSLocalizedString("accessibility.appSettings.writeToUs.hint", comment: "")
        )
        .cardRowBackground()
    }

    /// Title with subtitle, same pattern as the preparation time row in `GuidedMeditationSettingsSection`.
    private func feedbackRowLabel(title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title, bundle: .main)
                .textStyle(.body, color: \.textPrimary)
            Text(subtitle, bundle: .main)
                .textStyle(.caption, color: \.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
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
