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
        .alert(
            NSLocalizedString("custom.audio.rename.title", comment: ""),
            isPresented: self.$showRenameAlert,
            presenting: self.fileToRename
        ) { file in
            TextField(
                NSLocalizedString("custom.audio.rename.placeholder", comment: ""),
                text: self.$renameText
            )
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) {}
            Button(NSLocalizedString("common.save", comment: "")) {
                self.viewModel.renameCustomAudio(file, newName: self.renameText)
            }
        } message: { _ in
            Text("custom.audio.rename.message", bundle: .main)
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @ObservedObject private var viewModel: PraxisEditorViewModel
    @State private var showImportPicker = false
    @State private var fileToDelete: CustomAudioFile?
    @State private var showDeleteConfirmation = false
    @State private var fileToRename: CustomAudioFile?
    @State private var renameText: String = ""
    @State private var showRenameAlert = false

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
        let isSelected = self.viewModel.backgroundSoundId == file.id.uuidString
        return HStack {
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(isSelected ? self.theme.interactive : self.theme.textSecondary)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .themeFont(.settingsLabel)
                    Text(file.formattedDuration)
                        .themeFont(.settingsDescription)
                        .foregroundColor(self.theme.textSecondary)
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                self.viewModel.backgroundSoundId = file.id.uuidString
                self.viewModel.playBackgroundPreview(
                    soundId: file.id.uuidString,
                    volume: self.viewModel.backgroundSoundVolume
                )
            }
            self.overflowMenu(for: file)
        }
        .cardRowBackground()
        .accessibilityIdentifier("praxis.background.custom.\(file.id.uuidString)")
    }

    private func overflowMenu(for file: CustomAudioFile) -> some View {
        Menu {
            Button {
                self.fileToRename = file
                self.renameText = file.name
                self.showRenameAlert = true
            } label: {
                Label("guided_meditations.edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                self.fileToDelete = file
                self.showDeleteConfirmation = true
            } label: {
                Label("custom.audio.delete.confirm.button", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundColor(self.theme.interactive)
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("accessibility.library.overflow")
        .accessibilityHint("accessibility.library.overflow.hint")
        .accessibilityIdentifier("praxis.background.overflow.\(file.id.uuidString)")
    }

    private var silenceRow: some View {
        let isSelected = self.viewModel.backgroundSoundId == "silent"
        return HStack {
            Image(systemName: isSelected ? "speaker.slash.fill" : "speaker.slash")
                .foregroundColor(isSelected ? self.theme.interactive : self.theme.textSecondary)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text("praxis.editor.background.silence", bundle: .main)
                .themeFont(.settingsLabel)
            Spacer()
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
        let isSelected = self.viewModel.backgroundSoundId == sound.id
        let baseIcon = sound.iconName.hasSuffix(".fill")
            ? String(sound.iconName.dropLast(5))
            : sound.iconName
        let iconName = isSelected ? "\(baseIcon).fill" : baseIcon
        return HStack {
            Image(systemName: iconName)
                .foregroundColor(isSelected ? self.theme.interactive : self.theme.textSecondary)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(sound.name)
                .themeFont(.settingsLabel)
            Spacer()
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
        BackgroundSoundSelectionView(viewModel: PraxisEditorViewModel(praxis: .default) { _ in })
    }
}
#endif
