//
//  MeditationGongSoundPicker.swift
//  Still Moment
//
//  Presentation Layer - Per-meditation gong sound selection (shared-106, redesigned shared-116)
//

import SwiftUI

/// Card-based sound selection for the per-meditation gong in the edit sheet.
///
/// Reuses the timer's `GongSoundRow` (shared-115) so the selection looks and feels
/// identical on both screens. Offers the same gongs as the timer, deliberately
/// without the vibration option. Tapping a row selects it and plays a preview;
/// tapping only the preview button previews without changing the selection.
///
/// The list draws its own subtle card surface (PlaybackRangeCard style) so it sits
/// consistently among the editor's other cards rather than the bolder timer card.
struct MeditationGongSoundPicker: View {
    @Binding var selectedSoundId: String

    /// Called when a sound should be previewed (row tap or preview-button tap).
    let onPreview: (GongSound) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(GongSound.allMeditationGongSounds.enumerated()), id: \.element.id) { index, sound in
                if index > 0 {
                    Divider()
                        .overlay(self.theme.divider)
                }
                GongSoundRow(
                    sound: sound,
                    isSelected: self.selectedSoundId == sound.id,
                    isPreviewing: self.previewingSoundId == sound.id,
                    onSelect: {
                        self.selectedSoundId = sound.id
                        self.preview(sound)
                    },
                    onPreview: {
                        self.preview(sound)
                    },
                    identifierPrefix: "editSheet.gong"
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(self.theme.cardBackground.opacity(.opacitySecondary))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(self.theme.cardBorder, lineWidth: 0.5)
        )
        .onDisappear {
            self.previewTask?.cancel()
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    /// ID of the row whose preview is currently sounding (drives the ring).
    @State private var previewingSoundId: String?
    @State private var previewTask: Task<Void, Never>?

    /// Plays a preview and drives the ring for ~1.5s (mirrors `GongSelectionView.preview`).
    private func preview(_ sound: GongSound) {
        self.onPreview(sound)
        self.previewingSoundId = sound.id
        self.previewTask?.cancel()
        self.previewTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled, self.previewingSoundId == sound.id
            else { return }
            self.previewingSoundId = nil
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Gong Sound Picker") {
    ThemeRootView {
        Form {
            Section {
                MeditationGongSoundPicker(
                    selectedSoundId: .constant(GongSound.defaultSoundId)
                ) { _ in }
            }
        }
        .scrollContentBackground(.hidden)
    }
}
#endif
