//
//  GongSelectionView.swift
//  Still Moment
//
//  Presentation Layer - Start/End gong selection for Praxis editor
//

import SwiftUI
import UIKit

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
                if self.viewModel.startGongSoundId != GongSound.vibrationId {
                    self.volumeSection
                }
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

    private var supportsVibration: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    private var availableSounds: [GongSound] {
        self.supportsVibration ? GongSound.allSounds : GongSound.allSounds.filter { $0.id != GongSound.vibrationId }
    }

    private var soundsSection: some View {
        Section {
            ForEach(self.availableSounds) { sound in
                let isSelected = self.viewModel.startGongSoundId == sound.id
                HStack {
                    Text(sound.name)
                        .themeFont(.settingsLabel)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(self.theme.interactive)
                            .accessibilityHidden(true)
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
                .accessibilityElement(children: .combine)
                .accessibilityHint(NSLocalizedString("accessibility.sound.select.hint", comment: ""))
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
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
        GongSelectionView(viewModel: PraxisEditorViewModel(praxis: .default) { _ in })
    }
}
#endif
