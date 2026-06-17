//
//  GongVolumeCard.swift
//  Still Moment
//
//  Presentation Layer — minimalist volume card for gong selection (shared-115).
//
//  A single slider row flanked by a small and a large speaker icon. No percentage,
//  no caption. Uses `ThemedSlider` (which already encapsulates the SwiftUI-native
//  track so no UIKit `.id(theme)` workaround is needed).
//

import SwiftUI

/// Standalone volume card (eyebrow handled by the caller).
struct GongVolumeCard: View {
    @Binding var volume: Float
    let onChangeCommitted: () -> Void

    /// Accessibility identifier for the slider. Defaults to the gong volume anchor;
    /// the soundscape screen passes its own so both can be addressed in UI tests.
    var accessibilityIdentifier: String = "praxis.editor.slider.gongVolume"

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(self.theme.textSecondary)

            ThemedSlider(
                value: Binding(
                    get: { Double(self.volume) },
                    set: { self.volume = Float($0) }
                ),
                range: 0...1,
                step: 0.01
            ) { editing in
                if !editing {
                    self.onChangeCommitted()
                }
            }

            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(self.theme.textSecondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .modifier(GongCardBackground())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("settings.gongVolume.title"))
        .accessibilityValue(String(format: "%.0f%%", self.volume * 100))
        .accessibilityHint(Text("accessibility.gongVolume.hint"))
        .accessibilityIdentifier(self.accessibilityIdentifier)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Volume Card") {
    ThemeRootView {
        GongVolumeCard(volume: .constant(0.78)) {}
            .padding()
    }
}
#endif
