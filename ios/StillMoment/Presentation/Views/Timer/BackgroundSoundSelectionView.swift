//
//  BackgroundSoundSelectionView.swift
//  Still Moment
//
//  Presentation Layer - Background sound selection for Praxis editor
//

import SwiftUI

/// Selection list for choosing a background sound with volume control.
///
/// Shows "Silence" as first option, then all available background sounds.
/// Tapping a sound selects it and plays a preview. Volume slider appears
/// when a non-silent sound is selected.
struct BackgroundSoundSelectionView: View {
    // MARK: Lifecycle

    init(viewModel: PraxisEditorViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            List {
                self.soundsSection
                if self.viewModel.backgroundSoundId != "silent" {
                    self.volumeSection
                }
                self.mySoundsSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("praxis.editor.background.title", bundle: .main)
                    .themeFont(.inlineNavigationTitle)
            }
        }
        .onDisappear {
            self.viewModel.stopAllPreviews()
        }
        .sheet(isPresented: self.$showImportPicker) {
            DocumentPicker { url in
                self.viewModel.importCustomAudio(from: url, type: .soundscape)
            }
        }
        .alert(
            Text("custom.audio.delete.confirm.title", bundle: .main),
            isPresented: self.$showDeleteConfirmation,
            presenting: self.fileToDelete
        ) { file in
            Button(
                NSLocalizedString("custom.audio.delete.confirm.button", comment: ""),
                role: .destructive
            ) {
                self.viewModel.deleteCustomAudio(file)
            }
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) {}
        } message: { file in
            let count = self.viewModel.usageCount(for: file)
            let warning: String = if count == 1 {
                NSLocalizedString("custom.audio.delete.warning.single", comment: "")
            } else if count > 1 {
                String(
                    format: NSLocalizedString("custom.audio.delete.warning.multiple", comment: ""),
                    count
                )
            } else {
                NSLocalizedString("custom.audio.delete.confirm.message", comment: "")
            }
            Text(warning)
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @ObservedObject private var viewModel: PraxisEditorViewModel
    @State private var showImportPicker = false
    @State private var fileToDelete: CustomAudioFile?
    @State private var showDeleteConfirmation = false

    private var soundsSection: some View {
        Section {
            self.silenceRow

            ForEach(self.viewModel.availableBackgroundSounds) { sound in
                self.soundRow(for: sound)
            }
        }
    }

    private var mySoundsSection: some View {
        Section {
            Button {
                self.showImportPicker = true
            } label: {
                Label(
                    NSLocalizedString("custom.audio.import.button", comment: ""),
                    systemImage: "plus.circle"
                )
                .themeFont(.settingsLabel)
            }
            .cardRowBackground()
            .accessibilityLabel(
                NSLocalizedString(
                    "custom.audio.accessibility.importButton.soundscape",
                    comment: ""
                )
            )

            if self.viewModel.customSoundscapes.isEmpty {
                Text("custom.audio.empty.sounds", bundle: .main)
                    .themeFont(.settingsDescription)
                    .foregroundColor(self.theme.textSecondary)
                    .cardRowBackground()
            } else {
                ForEach(self.viewModel.customSoundscapes) { file in
                    self.customSoundRow(for: file)
                }
            }
        } header: {
            Text("custom.audio.section.mySounds", bundle: .main)
                .foregroundColor(self.theme.textSecondary)
        }
    }

    private func customSoundRow(for file: CustomAudioFile) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .themeFont(.settingsLabel)
                Text(file.formattedDuration)
                    .themeFont(.settingsDescription)
                    .foregroundColor(self.theme.textSecondary)
            }
            Spacer()
            if self.viewModel.backgroundSoundId == file.id.uuidString {
                Image(systemName: "checkmark")
                    .foregroundColor(self.theme.interactive)
            }
            Button {
                self.fileToDelete = file
                self.showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(self.theme.textSecondary)
            }
            .accessibilityLabel(
                String(
                    format: NSLocalizedString(
                        "custom.audio.accessibility.delete",
                        comment: ""
                    ),
                    file.name
                )
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            self.viewModel.backgroundSoundId = file.id.uuidString
            self.viewModel.stopAllPreviews()
        }
        .cardRowBackground()
        .accessibilityIdentifier("praxis.background.custom.\(file.id.uuidString)")
    }

    private var silenceRow: some View {
        HStack {
            Text("praxis.editor.background.silence", bundle: .main)
                .themeFont(.settingsLabel)
            Spacer()
            if self.viewModel.backgroundSoundId == "silent" {
                Image(systemName: "checkmark")
                    .foregroundColor(self.theme.interactive)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            self.viewModel.backgroundSoundId = "silent"
            self.viewModel.stopAllPreviews()
        }
        .cardRowBackground()
        .accessibilityIdentifier("praxis.background.silent")
    }

    private func soundRow(for sound: BackgroundSound) -> some View {
        HStack {
            Label(sound.name, systemImage: sound.iconName)
                .themeFont(.settingsLabel)
            Spacer()
            if self.viewModel.backgroundSoundId == sound.id {
                Image(systemName: "checkmark")
                    .foregroundColor(self.theme.interactive)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            self.viewModel.backgroundSoundId = sound.id
            self.viewModel.playBackgroundPreview(
                soundId: sound.id,
                volume: self.viewModel.backgroundSoundVolume
            )
        }
        .cardRowBackground()
        .accessibilityIdentifier("praxis.background.\(sound.id)")
    }

    private var volumeSection: some View {
        Section {
            VolumeSliderRow(
                volume: self.$viewModel.backgroundSoundVolume,
                accessibilityTitleKey: "settings.backgroundAudio.volume",
                accessibilityIdentifier: "praxis.editor.slider.backgroundVolume",
                accessibilityHintKey: "accessibility.backgroundVolume.hint"
            ) {
                self.viewModel.playBackgroundPreview(
                    soundId: self.viewModel.backgroundSoundId,
                    volume: self.viewModel.backgroundSoundVolume
                )
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Background Sound Selection") {
    NavigationStack {
        BackgroundSoundSelectionView(viewModel: PraxisEditorViewModel(
            praxis: .default,
            onSaved: { _ in },
            onDeleted: {}
        ))
    }
}
#endif
