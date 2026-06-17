//
//  ScapeSoundRow.swift
//  Still Moment
//
//  Presentation Layer — single row in the soundscape selection card (shared-121).
//
//  From left: a play/stop preview button, the sound name, a looping mini waveform;
//  the selected row adds a checkmark and a tinted background. Custom (user-imported)
//  rows that are NOT selected show a trash button on the right that triggers a
//  delete confirmation. Tapping the row selects + previews; tapping only the preview
//  button toggles the loop preview without changing the selection.
//

import SwiftUI

/// One selectable soundscape row.
struct ScapeSoundRow: View {
    let soundId: String
    let name: String
    let isSelected: Bool
    /// True for the "Silence" row (mute glyph, flat line, plays nothing).
    let isSilent: Bool
    /// True while this row's loop preview is currently sounding.
    let isPlaying: Bool
    /// Whether a trash/remove affordance is offered (only for custom, unselected rows).
    var canRemove: Bool = false
    let onSelect: () -> Void
    let onPreview: () -> Void
    var onRemove: (() -> Void)?

    /// Prefix for the row's accessibility identifiers.
    var identifierPrefix: String = "praxis.background"

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        HStack(spacing: 14) {
            self.previewButton
            self.selectArea
            if self.showsRemove {
                self.removeButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(self.isSelected ? self.theme.interactive.opacity(0.12) : Color.clear)
    }

    // MARK: - Select area (name + waveform + check)

    private var selectArea: some View {
        Button(action: self.onSelect) {
            HStack(spacing: 14) {
                Text(self.name)
                    .textStyle(self.isSelected ? .bodyEmphasis : .body, color: \.textPrimary)
                Spacer(minLength: 12)
                ScapeWaveform(soundId: self.soundId, isSelected: self.isSelected, isPlaying: self.isPlaying)
                if self.isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(self.theme.interactive)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(self.name))
        .accessibilityHint(Text("accessibility.sound.select.hint"))
        .accessibilityAddTraits(self.isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("\(self.identifierPrefix).\(self.soundId)")
    }

    // MARK: - Preview button

    private var previewButton: some View {
        Button(action: self.onPreview) {
            ScapePreviewButton(
                isSelected: self.isSelected,
                isSilent: self.isSilent,
                isPlaying: self.isPlaying
            )
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(self.isSilent)
        .accessibilityLabel(
            Text(
                String(
                    format: NSLocalizedString(
                        self.isPlaying ? "accessibility.scape.preview.stop" : "accessibility.scape.preview.play",
                        comment: ""
                    ),
                    self.name
                )
            )
        )
        .accessibilityIdentifier("\(self.identifierPrefix).preview.\(self.soundId)")
    }

    // MARK: - Remove button (custom rows)

    private var showsRemove: Bool {
        self.canRemove && !self.isSelected && self.onRemove != nil
    }

    private var removeButton: some View {
        Button {
            self.onRemove?()
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(self.theme.textSecondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            Text(
                String(
                    format: NSLocalizedString("accessibility.scape.remove", comment: ""),
                    self.name
                )
            )
        )
        .accessibilityIdentifier("\(self.identifierPrefix).remove.\(self.soundId)")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Scape Sound Rows") {
    ThemeRootView {
        VStack(spacing: 0) {
            ScapeSoundRow(
                soundId: BackgroundSound.silentId,
                name: "Stille",
                isSelected: false,
                isSilent: true,
                isPlaying: false,
                onSelect: {},
                onPreview: {}
            )
            ScapeSoundRow(
                soundId: "forest",
                name: "Waldatmosphäre",
                isSelected: true,
                isSilent: false,
                isPlaying: true,
                onSelect: {},
                onPreview: {}
            )
            ScapeSoundRow(
                soundId: "cozy-rain",
                name: "Regen",
                isSelected: false,
                isSilent: false,
                isPlaying: false,
                canRemove: true,
                onSelect: {},
                onPreview: {},
                onRemove: {}
            )
        }
        .modifier(GongCardBackground())
        .padding()
    }
}
#endif
