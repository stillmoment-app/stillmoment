//
//  GongSelectionView.swift
//  Still Moment
//
//  Presentation Layer - Start/End gong selection for Praxis editor
//

import SwiftUI

/// Selection list for choosing the start and end gong sound with volume control.
///
/// Shows all available gong sounds with a checkmark on the selected one.
/// Tapping a sound selects it and plays a preview. Volume slider is always visible.
struct GongSelectionView: View {
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
                self.volumeSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("praxis.editor.startGong.title", bundle: .main)
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
            ForEach(GongSound.allSounds) { sound in
                HStack {
                    Text(sound.name)
                        .themeFont(.settingsLabel)
                    Spacer()
                    if self.viewModel.startGongSoundId == sound.id {
                        Image(systemName: "checkmark")
                            .foregroundColor(self.theme.interactive)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    self.viewModel.startGongSoundId = sound.id
                    self.viewModel.playGongPreview(
                        soundId: sound.id,
                        volume: self.viewModel.gongVolume
                    )
                }
                .cardRowBackground()
                .accessibilityIdentifier("praxis.gong.\(sound.id)")
            }
        }
    }

    private var volumeSection: some View {
        Section {
            VolumeSliderRow(
                volume: self.$viewModel.gongVolume,
                accessibilityTitleKey: "settings.gongVolume.title",
                accessibilityIdentifier: "praxis.editor.slider.gongVolume",
                accessibilityHintKey: "accessibility.gongVolume.hint"
            ) {
                self.viewModel.playGongPreview(
                    soundId: self.viewModel.startGongSoundId,
                    volume: self.viewModel.gongVolume
                )
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Gong Selection") {
    NavigationStack {
        GongSelectionView(viewModel: PraxisEditorViewModel(
            praxis: .default,
            onSaved: { _ in },
            onDeleted: {}
        ))
    }
}
#endif
