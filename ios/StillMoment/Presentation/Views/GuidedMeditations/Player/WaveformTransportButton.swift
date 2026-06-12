//
//  WaveformTransportButton.swift
//  Still Moment
//
//  Presentation Layer — large plastic play/pause button of the waveform player (shared-109).
//

import SwiftUI

/// The 74×74 plastic play/pause button at the bottom of the waveform player. Mirrors the
/// play-gradient style of `PlayButtonCircle` (track rows) but is larger and toggles
/// play/pause (not stop), matching the handoff.
struct WaveformTransportButton: View {
    // MARK: Internal

    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.impact(.soft)
            self.action()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [self.theme.playGradientTop, self.theme.playGradientBot],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.white.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .center
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: self.theme.playGradientBot.opacity(0.45), radius: 16, x: 0, y: 8)

                Image(systemName: self.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(self.theme.textOnInteractive)
                    // Optical centering: the play triangle is right-heavy.
                    .offset(x: self.isPlaying ? 0 : 2)
            }
            .frame(width: Self.diameter, height: Self.diameter)
        }
        .buttonStyle(.plain)
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private static let diameter: CGFloat = 74
}
