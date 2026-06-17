//
//  BackgroundSoundSelectionView.swift
//  Still Moment
//
//  Presentation Layer - Background sound selection for Praxis editor (redesigned, shared-121).
//

import SwiftUI

/// Selection screen for choosing a looping background sound with volume control.
///
/// Card-based layout (shared-121, matching the gong picker): an intro text, a
/// "KLANG" card listing the built-in scenes, a "MEINE KLÄNGE" card for imported
/// files (or a dashed empty card) plus an import button, and a "LAUTSTÄRKE" card —
/// except for "Silence", which hides the volume card and shows a helper text.
///
/// Background sounds loop, so the preview is a play/stop toggle: tapping a row
/// selects + starts the loop preview; tapping the preview button toggles it
/// without changing the selection. Only one sound plays at a time.
struct BackgroundSoundSelectionView: View {
    // MARK: Lifecycle

    init(viewModel: PraxisSettingsViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    self.intro
                    self.soundSection
                    self.mySoundsSection
                    if self.isSilentSelected {
                        self.silenceHelper
                    } else {
                        self.volumeSection
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 28)
            }
        }
        .screenTitleBar("praxis.editor.background.title")
        .onDisappear {
            self.viewModel.stopAllPreviews()
            self.previewingSoundscapeId = nil
        }
        .sheet(isPresented: self.$showImportPicker) {
            DocumentPicker { url in
                self.viewModel.importCustomAudio(from: url)
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
            Text(self.deleteWarning(for: file))
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @ObservedObject private var viewModel: PraxisSettingsViewModel

    /// ID of the row whose loop preview is currently sounding (nil = nothing playing).
    @State private var previewingSoundscapeId: String?
    @State private var showImportPicker = false
    @State private var fileToDelete: CustomAudioFile?
    @State private var showDeleteConfirmation = false

    private var isSilentSelected: Bool {
        self.viewModel.backgroundSoundId == BackgroundSound.silentId
    }

    private func deleteWarning(for file: CustomAudioFile) -> String {
        let count = self.viewModel.usageCount(for: file)
        if count == 1 {
            return NSLocalizedString("custom.audio.delete.warning.single", comment: "")
        } else if count > 1 {
            return String(
                format: NSLocalizedString("custom.audio.delete.warning.multiple", comment: ""),
                count
            )
        }
        return NSLocalizedString("custom.audio.delete.confirm.message", comment: "")
    }
}

// MARK: - Preview & selection actions

private extension BackgroundSoundSelectionView {
    /// Selects a sound and starts its loop preview (or stops everything for "Silence").
    func select(soundId: String) {
        self.viewModel.backgroundSoundId = soundId
        if soundId == BackgroundSound.silentId {
            self.stopPreview()
        } else {
            self.startPreview(soundId: soundId)
        }
    }

    /// Toggles the loop preview for a sound without changing the selection.
    func togglePreview(soundId: String) {
        guard soundId != BackgroundSound.silentId else {
            return
        }
        if self.previewingSoundscapeId == soundId {
            self.stopPreview()
        } else {
            self.startPreview(soundId: soundId)
        }
    }

    func startPreview(soundId: String) {
        self.viewModel.playBackgroundPreview(
            soundId: soundId,
            volume: self.viewModel.backgroundSoundVolume
        )
        self.previewingSoundscapeId = soundId
    }

    func stopPreview() {
        self.viewModel.stopAllPreviews()
        self.previewingSoundscapeId = nil
    }
}

// MARK: - Sections

private extension BackgroundSoundSelectionView {
    var intro: some View {
        Text("praxis.background.intro")
            .textStyle(.bodyItalic, color: \.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.bottom, 18)
    }

    var soundSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("praxis.gong.section.sound")
                .textStyle(.eyebrow, color: \.textSecondary)
                .padding(.horizontal, 6)
            self.soundCard
        }
    }

    var soundCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(self.viewModel.availableBackgroundSounds.enumerated()), id: \.element.id) { index, sound in
                if index > 0 {
                    Divider()
                        .overlay(self.theme.divider)
                }
                ScapeSoundRow(
                    soundId: sound.id,
                    name: sound.name,
                    isSelected: self.viewModel.backgroundSoundId == sound.id,
                    isSilent: sound.id == BackgroundSound.silentId,
                    isPlaying: self.previewingSoundscapeId == sound.id,
                    onSelect: { self.select(soundId: sound.id) },
                    onPreview: { self.togglePreview(soundId: sound.id) }
                )
            }
        }
        .modifier(GongCardBackground())
    }

    var mySoundsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("custom.audio.section.mySounds")
                .textStyle(.eyebrow, color: \.textSecondary)
                .padding(.horizontal, 6)
            if self.viewModel.customSoundscapes.isEmpty {
                self.emptyCard
            } else {
                self.customCard
            }
            self.importButton
        }
        .padding(.top, 18)
    }

    var emptyCard: some View {
        Text("praxis.background.empty.hint")
            .textStyle(.bodyItalic, color: \.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(
                        self.theme.cardBorder,
                        style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                    )
            )
    }

    var customCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(self.viewModel.customSoundscapes.enumerated()), id: \.element.id) { index, file in
                if index > 0 {
                    Divider()
                        .overlay(self.theme.divider)
                }
                self.customRow(for: file)
            }
        }
        .modifier(GongCardBackground())
    }

    func customRow(for file: CustomAudioFile) -> some View {
        let id = file.id.uuidString
        return ScapeSoundRow(
            soundId: id,
            name: file.name,
            isSelected: self.viewModel.backgroundSoundId == id,
            isSilent: false,
            isPlaying: self.previewingSoundscapeId == id,
            canRemove: true,
            onSelect: { self.select(soundId: id) },
            onPreview: { self.togglePreview(soundId: id) },
            onRemove: {
                self.fileToDelete = file
                self.showDeleteConfirmation = true
            }
        )
    }

    var importButton: some View {
        ImportAudioButton(
            accessibilityLabel: NSLocalizedString(
                "custom.audio.accessibility.importButton.soundscape",
                comment: ""
            )
        ) {
            self.showImportPicker = true
        }
    }

    var volumeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("praxis.gong.section.volume")
                .textStyle(.eyebrow, color: \.textSecondary)
                .padding(.horizontal, 6)
            GongVolumeCard(
                volume: self.$viewModel.backgroundSoundVolume,
                onChangeCommitted: {},
                accessibilityIdentifier: "praxis.editor.slider.backgroundVolume"
            )
            .onChange(of: self.viewModel.backgroundSoundVolume) { newValue in
                // Live level for a running preview — no restart.
                self.viewModel.setBackgroundPreviewVolume(newValue)
            }
        }
        .padding(.top, 18)
    }

    var silenceHelper: some View {
        Text("praxis.background.silence.helper")
            .textStyle(.body, color: \.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.top, 18)
            .padding(.bottom, 4)
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Background Sound Selection") {
    NavigationStack {
        BackgroundSoundSelectionView(viewModel: PraxisSettingsViewModel(praxis: .default) { _ in })
    }
}
#endif
