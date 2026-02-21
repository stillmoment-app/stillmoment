//
//  VolumeSliderRow.swift
//  Still Moment
//
//  Reusable volume slider row component for settings
//

import SwiftUI

/// Volume slider with speaker icons, no text label
/// Speaker icons are self-explanatory per shared-019/shared-020
struct VolumeSliderRow: View {
    @Environment(\.themeColors)
    private var theme
    @Binding var volume: Float
    let accessibilityTitleKey: String
    let accessibilityIdentifier: String
    let accessibilityHintKey: String
    let onSliderReleased: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "speaker.fill")
                .foregroundColor(self.theme.textSecondary)
                .font(.settingsIcon)
            ThemedSlider(
                value: Binding(
                    get: { Double(self.volume) },
                    set: { self.volume = Float($0) }
                ),
                range: 0...1,
                step: 0.01
            ) { editing in
                if !editing {
                    self.onSliderReleased()
                }
            }
            Image(systemName: "speaker.wave.3.fill")
                .foregroundColor(self.theme.textSecondary)
                .font(.settingsIcon)
        }
        .accessibilityIdentifier(self.accessibilityIdentifier)
        .accessibilityLabel(NSLocalizedString(self.accessibilityTitleKey, comment: ""))
        .accessibilityValue(String(format: "%.0f%%", self.volume * 100))
        .accessibilityHint(NSLocalizedString(self.accessibilityHintKey, comment: ""))
        .cardRowBackground()
    }
}
