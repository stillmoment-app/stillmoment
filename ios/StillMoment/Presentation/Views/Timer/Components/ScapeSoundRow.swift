//
//  ScapeSoundRow.swift
//  Still Moment
//
//  Presentation Layer — single row in the soundscape selection card (shared-121).
//
//  From left: a play/stop preview button, the sound name + description; the selected
//  row adds a checkmark and a tinted background. Custom (user-imported) rows show a
//  "more" (ellipsis) button on the right that opens a menu with Rename and Remove
//  (destructive); for a selected custom row the checkmark sits left of that button.
//  Tapping the row selects + previews; tapping only the preview button toggles the
//  loop preview without changing the selection.
//

import SwiftUI

/// One selectable soundscape row.
struct ScapeSoundRow: View {
    let soundId: String
    let name: String
    /// Secondary line under the name (built-in: scene description; custom: duration).
    var description: String?
    let isSelected: Bool
    /// True for the "Silence" row (mute glyph, flat line, plays nothing).
    let isSilent: Bool
    /// True while this row's loop preview is currently sounding.
    let isPlaying: Bool
    /// Whether the row offers the rename/remove "more" menu (custom rows only).
    var isCustom: Bool = false
    let onSelect: () -> Void
    let onPreview: () -> Void
    /// Opens the rename dialog (custom rows only).
    var onRename: (() -> Void)?
    /// Triggers the delete confirmation (custom rows only).
    var onRemove: (() -> Void)?

    /// Prefix for the row's accessibility identifiers.
    var identifierPrefix: String = "praxis.background"

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        HStack(spacing: 14) {
            self.previewButton
            self.selectArea
            if self.showsMenu {
                self.moreMenu
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(self.isSelected ? self.theme.interactive.opacity(0.12) : Color.clear)
    }

    // MARK: - Select area (name + description + check)

    private var selectArea: some View {
        Button(action: self.onSelect) {
            HStack(spacing: 14) {
                self.labels
                Spacer(minLength: 12)
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
        .accessibilityLabel(Text(self.accessibilityLabel))
        .accessibilityHint(Text("accessibility.sound.select.hint"))
        .accessibilityAddTraits(self.isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("\(self.identifierPrefix).\(self.soundId)")
    }

    /// Name above an optional secondary description; both clip to one line so a
    /// long name never overflows the row.
    private var labels: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(self.name)
                .textStyle(self.isSelected ? .bodyEmphasis : .body, color: \.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
            if let description, !description.isEmpty {
                Text(description)
                    .textStyle(.caption, color: \.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    private var accessibilityLabel: String {
        guard let description, !description.isEmpty else {
            return self.name
        }
        return "\(self.name), \(description)"
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

    // MARK: - More menu (custom rows)

    private var showsMenu: Bool {
        self.isCustom && (self.onRename != nil || self.onRemove != nil)
    }

    private var moreMenu: some View {
        Menu {
            Button {
                self.onRename?()
            } label: {
                Label("guided_meditations.edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                self.onRemove?()
            } label: {
                Label("custom.audio.delete.confirm.button", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(self.theme.interactive)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("accessibility.library.overflow")
        .accessibilityHint("accessibility.library.overflow.hint")
        .accessibilityIdentifier("\(self.identifierPrefix).overflow.\(self.soundId)")
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
                description: "Vollkommene Ruhe — kein Klang",
                isSelected: false,
                isSilent: true,
                isPlaying: false,
                onSelect: {},
                onPreview: {}
            )
            ScapeSoundRow(
                soundId: "forest",
                name: "Waldatmosphäre",
                description: "Sanftes Blätterrauschen, ferne Vögel",
                isSelected: true,
                isSilent: false,
                isPlaying: true,
                onSelect: {},
                onPreview: {}
            )
            ScapeSoundRow(
                soundId: "cozy-rain",
                name: "Ein wirklich sehr langer eigener Dateiname zum Testen",
                description: "3:45",
                isSelected: true,
                isSilent: false,
                isPlaying: false,
                isCustom: true,
                onSelect: {},
                onPreview: {},
                onRename: {},
                onRemove: {}
            )
        }
        .modifier(GongCardBackground())
        .padding()
    }
}
#endif
