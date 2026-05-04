//
//  ImportTypeSelectionView.swift
//  Still Moment
//
//  Presentation - Import type selection sheet for shared audio files (shared-073)
//

import SwiftUI

/// Half-sheet presenting two import type options when a user shares an audio file.
///
/// Each row shows an SF Symbol icon, a title, and a description.
/// The sheet calls back with the selected type or dismisses on cancel.
struct ImportTypeSelectionView: View {
    // MARK: Internal

    let onTypeSelected: (ImportAudioType) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(NSLocalizedString("import.type.title", comment: ""))
                .themeFont(.screenTitle)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .accessibilityAddTraits(.isHeader)

            Spacer().frame(height: 16)

            ImportTypeRow(
                icon: "play.circle",
                title: NSLocalizedString("import.type.guided", comment: ""),
                description: NSLocalizedString("import.type.guided.description", comment: "")
            ) { self.onTypeSelected(.guidedMeditation) }

            ImportTypeRow(
                icon: "waveform.circle",
                title: NSLocalizedString("import.type.soundscape", comment: ""),
                description: NSLocalizedString("import.type.soundscape.description", comment: "")
            ) { self.onTypeSelected(.soundscape) }

            Button(action: self.onCancel) {
                Text(NSLocalizedString("import.type.cancel", comment: ""))
                    .themeFont(.settingsLabel)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(self.theme.interactive)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
}

// MARK: - ImportTypeRow

private struct ImportTypeRow: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        Button(action: self.action) {
            HStack(spacing: 16) {
                Image(systemName: self.icon)
                    .font(.title2)
                    .foregroundColor(self.theme.interactive)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(self.title)
                        .themeFont(.settingsLabel)

                    Text(self.description)
                        .themeFont(.settingsDescription)
                }

                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(self.title) — \(self.description)")
    }
}
