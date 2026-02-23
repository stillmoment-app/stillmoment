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
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @ObservedObject private var viewModel: PraxisEditorViewModel

    private var soundsSection: some View {
        Section {
            self.silenceRow

            ForEach(self.viewModel.availableBackgroundSounds) { sound in
                self.soundRow(for: sound)
            }
        }
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
