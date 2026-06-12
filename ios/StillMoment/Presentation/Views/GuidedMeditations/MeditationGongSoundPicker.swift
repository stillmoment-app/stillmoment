//
//  MeditationGongSoundPicker.swift
//  Still Moment
//
//  Presentation Layer - Per-meditation gong sound selection (shared-106)
//

import SwiftUI

/// Inline sound selection rows for the per-meditation gong in the edit sheet.
///
/// Offers the same gongs as the timer, deliberately without the vibration
/// option. Tapping a sound selects it and plays a preview via `onPreview`.
struct MeditationGongSoundPicker: View {
    @Binding var selectedSoundId: String

    /// Called after a sound was selected so the caller can play a preview.
    let onPreview: (GongSound) -> Void

    var body: some View {
        ForEach(GongSound.allMeditationGongSounds) { sound in
            let isSelected = self.selectedSoundId == sound.id
            HStack {
                Text(sound.name)
                    .textStyle(.body, color: \.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(self.theme.interactive)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                self.selectedSoundId = sound.id
                self.onPreview(sound)
            }
            .accessibilityElement(children: .combine)
            .accessibilityHint(NSLocalizedString("accessibility.sound.select.hint", comment: ""))
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .accessibilityIdentifier("editSheet.gongSound.\(sound.id)")
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Gong Sound Picker") {
    Form {
        Section {
            MeditationGongSoundPicker(
                selectedSoundId: .constant(GongSound.defaultSoundId)
            ) { _ in }
        }
    }
}
#endif
