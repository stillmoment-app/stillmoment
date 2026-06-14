//
//  GongSelectionView.swift
//  Still Moment
//
//  Presentation Layer - Start/End gong selection for Praxis editor (redesigned, shared-115).
//

import SwiftUI
import UIKit

/// Selection screen for choosing the start and end gong sound with volume control.
///
/// Card-based layout (shared-115): an eyebrow-labelled "KLANG" card lists every
/// available sound with a preview button, name and character-carrying mini
/// waveform; the selected row is tinted and checked. Below, a "LAUTSTÄRKE" card
/// carries the volume slider — except for the vibration option, which hides the
/// volume card and shows an explanatory helper text instead.
///
/// Tapping a row selects + previews; tapping the preview button only previews.
struct GongSelectionView: View {
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
                    self.soundSection
                    if self.isVibrationSelected {
                        self.vibrationHelper
                    }
                    if GongSelectionLogic.isVolumeCardVisible(soundId: self.viewModel.startGongSoundId) {
                        self.volumeSection
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 28)
            }
        }
        .screenTitleBar("praxis.editor.startGong.title")
        .onDisappear {
            self.previewTask?.cancel()
            self.viewModel.stopAllPreviews()
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @ObservedObject private var viewModel: PraxisSettingsViewModel

    /// ID of the row whose preview is currently sounding (drives the ring).
    @State private var previewingSoundId: String?
    @State private var previewTask: Task<Void, Never>?

    private var isVibrationSelected: Bool {
        self.viewModel.startGongSoundId == GongSound.vibrationId
    }

    private var supportsVibration: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    private var availableSounds: [GongSound] {
        self.supportsVibration
            ? GongSound.allSounds
            : GongSound.allSounds.filter { $0.id != GongSound.vibrationId }
    }

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("praxis.gong.section.sound")
                .textStyle(.eyebrow, color: \.textSecondary)
                .padding(.horizontal, 6)
            self.soundCard
        }
    }

    private var soundCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(self.availableSounds.enumerated()), id: \.element.id) { index, sound in
                if index > 0 {
                    Divider()
                        .overlay(self.theme.divider)
                }
                GongSoundRow(
                    sound: sound,
                    isSelected: self.viewModel.startGongSoundId == sound.id,
                    isPreviewing: self.previewingSoundId == sound.id,
                    onSelect: {
                        self.viewModel.startGongSoundId = sound.id
                        self.preview(soundId: sound.id)
                    },
                    onPreview: {
                        self.preview(soundId: sound.id)
                    }
                )
            }
        }
        .modifier(GongCardBackground())
    }

    private var vibrationHelper: some View {
        Text("praxis.gong.vibration.helper")
            .textStyle(.body, color: \.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("praxis.gong.section.volume")
                .textStyle(.eyebrow, color: \.textSecondary)
                .padding(.horizontal, 6)
            GongVolumeCard(volume: self.$viewModel.gongVolume) {
                self.preview(soundId: self.viewModel.startGongSoundId)
            }
        }
        .padding(.top, 18)
    }

    /// Plays a preview and drives the ring for ~1.5s.
    private func preview(soundId: String) {
        self.viewModel.playGongPreview(soundId: soundId, volume: self.viewModel.gongVolume)
        self.previewingSoundId = soundId
        self.previewTask?.cancel()
        self.previewTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled, self.previewingSoundId == soundId
            else { return }
            self.previewingSoundId = nil
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Gong Selection") {
    NavigationStack {
        GongSelectionView(viewModel: PraxisSettingsViewModel(praxis: .default) { _ in })
    }
}
#endif
