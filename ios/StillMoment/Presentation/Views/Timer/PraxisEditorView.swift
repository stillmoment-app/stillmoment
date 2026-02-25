//
//  PraxisEditorView.swift
//  Still Moment
//
//  Presentation Layer - Editor for the current Praxis configuration
//

import SwiftUI

/// Editor for the current Praxis configuration — pushed via NavigationLink (not a sheet).
///
/// Uses auto-save: changes are persisted when the user navigates back (iOS Settings pattern).
/// No Cancel/Done buttons — only the iOS back button for consistent navigation context.
/// Each audio sub-screen is a pushed NavigationLink destination.
struct PraxisEditorView: View {
    // MARK: Lifecycle

    init(viewModel: PraxisEditorViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            Form {
                self.preparationSection
                self.audioSection
                self.gongsSection
            }
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("praxis.editor.title", bundle: .main)
                        .themeFont(.inlineNavigationTitle)
                }
            }
            .onDisappear { self.viewModel.stopAllPreviews() }
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @ObservedObject private var viewModel: PraxisEditorViewModel

    // MARK: - Preparation

    private var preparationSection: some View {
        Section {
            Toggle(isOn: self.$viewModel.preparationTimeEnabled) {
                Text("settings.preparationTime.title", bundle: .main)
                    .themeFont(.settingsLabel)
            }
            .themedToggle()
            .cardRowBackground()
            .accessibilityIdentifier("praxis.editor.toggle.preparation")

            if self.viewModel.preparationTimeEnabled {
                Picker(selection: self.$viewModel.preparationTimeSeconds) {
                    Text("settings.preparationTime.5s", bundle: .main).tag(5)
                    Text("settings.preparationTime.10s", bundle: .main).tag(10)
                    Text("settings.preparationTime.15s", bundle: .main).tag(15)
                    Text("settings.preparationTime.20s", bundle: .main).tag(20)
                    Text("settings.preparationTime.30s", bundle: .main).tag(30)
                    Text("settings.preparationTime.45s", bundle: .main).tag(45)
                } label: {
                    Text("settings.preparationTime.duration", bundle: .main)
                        .themeFont(.settingsLabel)
                }
                .pickerStyle(.menu)
                .cardRowBackground()
                .accessibilityIdentifier("praxis.editor.picker.preparationSeconds")
            }
        } header: {
            Label {
                Text("praxis.editor.section.preparation", bundle: .main)
            } icon: {
                Image(systemName: "hourglass")
            }
            .foregroundColor(self.theme.textSecondary)
        }
    }

    // MARK: - Audio

    private var audioSection: some View {
        Section {
            NavigationLink {
                IntroductionSelectionView(viewModel: self.viewModel)
            } label: {
                HStack {
                    Text("praxis.editor.introduction.row", bundle: .main)
                        .themeFont(.settingsLabel)
                    Spacer()
                    Text(self.currentIntroductionLabel)
                        .themeFont(.settingsDescription)
                        .foregroundColor(self.theme.textSecondary)
                }
            }
            .cardRowBackground()
            .accessibilityIdentifier("praxis.editor.link.introduction")

            NavigationLink {
                BackgroundSoundSelectionView(viewModel: self.viewModel)
            } label: {
                HStack {
                    Text("praxis.editor.background.row", bundle: .main)
                        .themeFont(.settingsLabel)
                    Spacer()
                    Text(self.currentBackgroundLabel)
                        .themeFont(.settingsDescription)
                        .foregroundColor(self.theme.textSecondary)
                }
            }
            .cardRowBackground()
            .accessibilityIdentifier("praxis.editor.link.background")
        } header: {
            Label {
                Text("praxis.editor.section.audio", bundle: .main)
            } icon: {
                Image(systemName: "wind")
            }
            .foregroundColor(self.theme.textSecondary)
        }
    }

    // MARK: - Gongs

    private var gongsSection: some View {
        Section {
            NavigationLink {
                GongSelectionView(viewModel: self.viewModel)
            } label: {
                HStack {
                    Text("praxis.editor.startGong.row", bundle: .main)
                        .themeFont(.settingsLabel)
                    Spacer()
                    Text(self.currentGongLabel)
                        .themeFont(.settingsDescription)
                        .foregroundColor(self.theme.textSecondary)
                }
            }
            .cardRowBackground()
            .accessibilityIdentifier("praxis.editor.link.gong")

            NavigationLink {
                IntervalGongsEditorView(viewModel: self.viewModel)
            } label: {
                HStack {
                    Text("praxis.editor.intervalGongs.row", bundle: .main)
                        .themeFont(.settingsLabel)
                    Spacer()
                    Text(self.currentIntervalLabel)
                        .themeFont(.settingsDescription)
                        .foregroundColor(self.theme.textSecondary)
                }
            }
            .cardRowBackground()
            .accessibilityIdentifier("praxis.editor.link.intervalGongs")
        } header: {
            Label {
                Text("praxis.editor.section.gongs", bundle: .main)
            } icon: {
                Image(systemName: "bell")
            }
            .foregroundColor(self.theme.textSecondary)
        }
    }

    // MARK: - Label Helpers

    private var currentIntroductionLabel: String {
        guard let introId = self.viewModel.introductionId,
              let intro = self.viewModel.availableIntroductions.first(where: { $0.id == introId })
        else {
            // Check custom attunements
            if let introId = self.viewModel.introductionId,
               let customFile = self.viewModel.customAttunements.first(where: { $0.id.uuidString == introId }) {
                return customFile.name
            }
            return NSLocalizedString("praxis.editor.introduction.none", comment: "")
        }
        return intro.name
    }

    private var currentBackgroundLabel: String {
        if self.viewModel.backgroundSoundId == "silent" {
            return NSLocalizedString("praxis.editor.background.silence", comment: "")
        }
        if let sound = self.viewModel.availableBackgroundSounds.first(
            where: { $0.id == self.viewModel.backgroundSoundId }
        ) {
            return sound.name
        }
        if let customFile = self.viewModel.customSoundscapes.first(
            where: { $0.id.uuidString == self.viewModel.backgroundSoundId }
        ) {
            return customFile.name
        }
        return NSLocalizedString("praxis.editor.background.silence", comment: "")
    }

    private var currentGongLabel: String {
        GongSound.findOrDefault(byId: self.viewModel.startGongSoundId).name
    }

    private var currentIntervalLabel: String {
        guard self.viewModel.intervalGongsEnabled else {
            return NSLocalizedString("common.off", comment: "")
        }
        return String(
            format: NSLocalizedString("settings.intervalGongs.stepper", comment: ""),
            self.viewModel.intervalMinutes
        )
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Praxis Editor") {
    NavigationStack {
        PraxisEditorView(viewModel: PraxisEditorViewModel(praxis: .default) { _ in })
    }
}
#endif
