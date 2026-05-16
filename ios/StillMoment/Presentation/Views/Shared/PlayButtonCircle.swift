//
//  PlayButtonCircle.swift
//  Still Moment
//
//  Presentation Layer - Plastic round play/stop button (shared-094).
//
//  Reusable circle button used in Library list rows and search-result rows.
//  Renders the theme's play-gradient + inner highlight rim + warm drop shadow,
//  matching the CTA capsule's plastic style.
//

import SwiftUI

/// Plastic round play/stop button used on track rows.
///
/// Provides only the visual element. Tap + long-press gestures stay on the
/// caller so the same circle can drive different actions (open vs. preview).
struct PlayButtonCircle: View {
    let isPlaying: Bool

    @Environment(\.themeColors)
    private var theme

    private let diameter: CGFloat = 36

    var body: some View {
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
                                colors: [
                                    Color.white.opacity(0.22),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: self.theme.playGradientBot.opacity(0.35),
                    radius: 8,
                    x: 0,
                    y: 3
                )
            Image(systemName: self.isPlaying ? "stop.fill" : "play.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(self.theme.textOnInteractive)
                // Optical centering: the play triangle is right-heavy.
                .offset(x: self.isPlaying ? 0 : 1)
        }
        .frame(width: self.diameter, height: self.diameter)
    }
}
