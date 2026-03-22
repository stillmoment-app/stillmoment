//
//  ImportAudioButton.swift
//  Still Moment
//
//  Reusable import button for custom audio selection screens
//

import SwiftUI

/// Bordered import button placed below a selection list.
///
/// Used on BackgroundSoundSelectionView and AttunementSelectionView to
/// trigger a document picker for importing custom audio files.
struct ImportAudioButton: View {
    // MARK: Lifecycle

    init(accessibilityLabel: String, action: @escaping () -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    // MARK: Internal

    var body: some View {
        Button(action: self.action) {
            Label(
                NSLocalizedString("custom.audio.import.button", comment: ""),
                systemImage: "plus.circle"
            )
            .themeFont(.settingsLabel)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(self.theme.interactive)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .accessibilityLabel(self.accessibilityLabel)
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private let accessibilityLabel: String
    private let action: () -> Void
}
