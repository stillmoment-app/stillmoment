//
//  PraxisEditorView.swift
//  Still Moment
//
//  Presentation Layer - Editor for a single Praxis
//

import SwiftUI

/// Editor for a Praxis — pushed via NavigationLink (not a sheet).
///
/// Provides form sections for name, duration, preparation, audio/sounds, gongs,
/// and a delete action. Each audio sub-screen is a pushed NavigationLink destination.
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
                self.nameAndDurationSection
                self.preparationSection
                self.audioSection
                self.gongsSection
                self.deleteSection
            }
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("common.cancel", comment: "")) {
                        self.viewModel.stopAllPreviews()
                        self.dismiss()
                    }
                    .foregroundColor(self.theme.interactive)
                    .accessibilityIdentifier("praxis.editor.button.cancel")
                    .accessibilityLabel(NSLocalizedString("accessibility.praxis.editor.cancel", comment: ""))
                    .accessibilityHint(NSLocalizedString("accessibility.praxis.editor.cancel.hint", comment: ""))
                }
                ToolbarItem(placement: .principal) {
                    Text("praxis.editor.title", bundle: .main)
                        .themeFont(.inlineNavigationTitle)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("button.done", comment: "")) {
                        self.viewModel.save()
                        self.dismiss()
                    }
                    .foregroundColor(self.theme.interactive)
                    .disabled(!self.viewModel.canSave)
                    .accessibilityIdentifier("praxis.editor.button.done")
                    .accessibilityLabel(NSLocalizedString("accessibility.praxis.editor.done", comment: ""))
                    .accessibilityHint(NSLocalizedString("accessibility.praxis.editor.done.hint", comment: ""))
                }
            }
        }
        .alert(
            NSLocalizedString("praxis.editor.delete.title", comment: ""),
            isPresented: self.$viewModel.showDeleteConfirmation
        ) {
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) {}
            Button(NSLocalizedString("praxis.editor.delete.confirm", comment: ""), role: .destructive) {
                self.viewModel.confirmDelete()
                self.dismiss()
            }
        } message: {
            Text("praxis.editor.delete.message", bundle: .main)
        }
        .alert(
            NSLocalizedString("common.error", comment: ""),
            isPresented: .constant(self.viewModel.errorMessage != nil)
        ) {
            Button(NSLocalizedString("common.ok", comment: "")) {
                self.viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = self.viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: Private

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.themeColors)
    private var theme
    @ObservedObject private var viewModel: PraxisEditorViewModel

    // MARK: - Name & Duration

    private var nameAndDurationSection: some View {
        Section {
            TextField(
                NSLocalizedString("praxis.editor.name.placeholder", comment: ""),
                text: self.$viewModel.name
            )
            .themeFont(.settingsLabel)
            .cardRowBackground()
            .accessibilityIdentifier("praxis.editor.field.name")
            .accessibilityLabel(NSLocalizedString("accessibility.praxis.editor.name", comment: ""))
            .accessibilityHint(NSLocalizedString("accessibility.praxis.editor.name.hint", comment: ""))

            Picker(selection: self.$viewModel.durationMinutes) {
                ForEach(1...60, id: \.self) { minute in
                    Text(String(
                        format: NSLocalizedString("duration.minutes", comment: ""),
                        minute
                    ))
                    .tag(minute)
                }
            } label: {
                Text("praxis.editor.duration.label", bundle: .main)
                    .themeFont(.settingsLabel)
            }
            .pickerStyle(.menu)
            .cardRowBackground()
            .accessibilityIdentifier("praxis.editor.picker.duration")
        }
    }

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

    // MARK: - Delete

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                self.viewModel.requestDelete()
            } label: {
                Text("praxis.editor.delete.button", bundle: .main)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .cardRowBackground()
            .accessibilityIdentifier("praxis.editor.button.delete")
            .accessibilityLabel(NSLocalizedString("accessibility.praxis.editor.delete", comment: ""))
            .accessibilityHint(NSLocalizedString("accessibility.praxis.editor.delete.hint", comment: ""))
        }
    }

    // MARK: - Label Helpers

    private var currentIntroductionLabel: String {
        guard let introId = self.viewModel.introductionId,
              let intro = self.viewModel.availableIntroductions.first(where: { $0.id == introId })
        else {
            return NSLocalizedString("praxis.editor.introduction.none", comment: "")
        }
        return intro.name
    }

    private var currentBackgroundLabel: String {
        guard self.viewModel.backgroundSoundId != "silent",
              let sound = self.viewModel.availableBackgroundSounds.first(
                  where: { $0.id == self.viewModel.backgroundSoundId }
              )
        else {
            return NSLocalizedString("praxis.editor.background.silence", comment: "")
        }
        return sound.name
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
        PraxisEditorView(viewModel: PraxisEditorViewModel(
            praxis: .default,
            onSaved: { _ in },
            onDeleted: {}
        ))
    }
}
#endif
