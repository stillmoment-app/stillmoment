//
//  GongSoundRow.swift
//  Still Moment
//
//  Presentation Layer — single row in the gong selection card (shared-115).
//
//  From left: preview button, sound name, mini waveform; the selected row adds
//  a checkmark and a tinted background. Tapping the row selects + previews;
//  tapping only the preview button previews without changing the selection.
//

import SwiftUI

/// One selectable gong sound row.
struct GongSoundRow: View {
    let sound: GongSound
    let isSelected: Bool
    let isPreviewing: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        Button(action: self.onSelect) {
            HStack(spacing: 14) {
                self.previewButton
                Text(self.sound.name)
                    .textStyle(self.isSelected ? .bodyEmphasis : .body, color: \.textPrimary)
                Spacer(minLength: 12)
                GongWaveform(soundId: self.sound.id, isSelected: self.isSelected)
                if self.isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(self.theme.interactive)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(self.isSelected ? self.theme.interactive.opacity(0.12) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(self.sound.name))
        .accessibilityHint(Text("accessibility.sound.select.hint"))
        .accessibilityAddTraits(self.isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("praxis.gong.\(self.sound.id)")
    }

    // MARK: - Private

    private var isVibration: Bool {
        self.sound.id == GongSound.vibrationId
    }

    private var previewButton: some View {
        Button(action: self.onPreview) {
            GongPreviewButton(
                isSelected: self.isSelected,
                isVibration: self.isVibration,
                isPreviewing: self.isPreviewing
            )
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            Text(
                String(
                    format: NSLocalizedString("accessibility.gong.preview", comment: ""),
                    self.sound.name
                )
            )
        )
        .accessibilityIdentifier("praxis.gong.preview.\(self.sound.id)")
    }
}
