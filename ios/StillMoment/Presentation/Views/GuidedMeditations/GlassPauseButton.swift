//
//  GlassPauseButton.swift
//  Still Moment
//
//  Presentation Layer — Glas-Pause/Play-Button im Atemkreis-Player.
//

import SwiftUI

/// 80×80 Glas-Style-Button mit Pause/Play-Glyph.
///
/// Sitzt mittig im Atemkreis (`BreathingCircleView`) und ist die einzige
/// sichtbare Geste der Hauptphase. Visuell:
/// - Halbtransparenter Glas-Stil (`ultraThinMaterial` Backdrop)
/// - Subtiler Border in `theme.interactive` mit niedriger Opacity
/// - Pause/Play-Glyph in `theme.interactive`, mit 200 ms Cross-Fade beim Toggle
struct GlassPauseButton: View {
    let isPlaying: Bool
    let action: () -> Void

    @Environment(\.themeColors)
    private var theme

    private let size: CGFloat = 80
    private let glyphSize: CGFloat = 30

    var body: some View {
        Button(action: self.action) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)

                Circle()
                    .strokeBorder(self.theme.interactive.opacity(0.25), lineWidth: 1)

                Image(systemName: self.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: self.glyphSize, weight: .medium, design: .rounded))
                    .foregroundColor(self.theme.interactive)
                    .offset(x: self.isPlaying ? 0 : 2) // Play-Glyph optisch zentrieren
                    .id(self.isPlaying) // sorgt fuer Cross-Fade ueber transition
                    .transition(.opacity)
            }
            .frame(width: self.size, height: self.size)
            .contentShape(Circle())
        }
        .accessibilityIdentifier("player.button.playPause")
        .accessibilityLabel(self.isPlaying
            ? NSLocalizedString("guided_meditations.player.pause", comment: "")
            : NSLocalizedString("guided_meditations.player.play", comment: ""))
        .animation(.easeInOut(duration: 0.2), value: self.isPlaying)
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Pause (Playing)") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.18, green: 0.10, blue: 0.06),
                Color(red: 0.08, green: 0.05, blue: 0.04)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        GlassPauseButton(isPlaying: true) {}
    }
}

@available(iOS 17.0, *)
#Preview("Play (Paused)") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.18, green: 0.10, blue: 0.06),
                Color(red: 0.08, green: 0.05, blue: 0.04)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        GlassPauseButton(isPlaying: false) {}
    }
}
