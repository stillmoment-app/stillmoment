//
//  SoundAttributionsView.swift
//  Still Moment
//
//  Presentation Layer - Static sound attribution credits screen
//

import SwiftUI

/// Static screen listing the source of all sounds used in the app.
///
/// All sounds are from Pixabay (Pixabay Content License).
/// Attribution is not legally required, but shown as voluntary transparency.
/// Sources: `dev-docs/reference/audio-sources.md`
struct SoundAttributionsView: View {
    @Environment(\.themeColors)
    private var theme

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            Form {
                self.gongSoundsSection
                self.intervalSoundsSection
                self.backgroundSoundsSection
            }
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("app.settings.soundAttributions.page.title", bundle: .main)
                        .themeFont(.inlineNavigationTitle)
                }
            }
        }
    }

    // MARK: - Sections

    private var gongSoundsSection: some View {
        Section {
            self.soundRow(
                name: NSLocalizedString("gong.temple-bell", comment: ""),
                url: URL(string: "https://pixabay.com/sound-effects/tibetan-singing-bowl-55786/")
            )
            self.soundRow(
                name: NSLocalizedString("gong.classic-bowl", comment: ""),
                url: URL(string: "https://pixabay.com/sound-effects/film-special-effects-singing-bowl-hit-3-33366/")
            )
            self.soundRow(
                name: NSLocalizedString("gong.deep-resonance", comment: ""),
                url: URL(string: "https://pixabay.com/sound-effects/singing-bowl-male-frequency-29714/")
            )
            self.soundRow(
                name: NSLocalizedString("gong.clear-strike", comment: ""),
                url: URL(string: "https://pixabay.com/sound-effects/singing-bowl-strike-sound-84682/")
            )
        } header: {
            Text("app.settings.soundAttributions.gongs.header", bundle: .main)
                .foregroundColor(self.theme.textSecondary)
        } footer: {
            Text("app.settings.soundAttributions.license.footer", bundle: .main)
                .foregroundColor(self.theme.textSecondary)
        }
    }

    private var intervalSoundsSection: some View {
        Section {
            self.soundRow(
                name: NSLocalizedString("gong.soft-interval", comment: ""),
                url: URL(string: "https://pixabay.com/sound-effects/triangle-40209/")
            )
        } header: {
            Text("app.settings.soundAttributions.interval.header", bundle: .main)
                .foregroundColor(self.theme.textSecondary)
        }
    }

    private var backgroundSoundsSection: some View {
        Section {
            self.soundRow(
                name: NSLocalizedString("app.settings.soundAttributions.forest.name", comment: ""),
                url: URL(string: "https://pixabay.com/sound-effects/nature-forest-ambience-296528/")
            )
        } header: {
            Text("app.settings.soundAttributions.background.header", bundle: .main)
                .foregroundColor(self.theme.textSecondary)
        }
    }

    // MARK: - Row Helper

    private func soundRow(name: String, url: URL?) -> some View {
        HStack {
            Text(name)
                .themeFont(.settingsLabel)
            if let url {
                Spacer()
                Link(NSLocalizedString("app.settings.soundAttributions.source", comment: ""), destination: url)
                    .themeFont(.settingsLabel, color: \.interactive)
            }
        }
        .cardRowBackground()
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        SoundAttributionsView()
    }
}
