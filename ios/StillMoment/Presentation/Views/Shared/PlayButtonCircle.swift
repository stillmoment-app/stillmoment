//
//  PlayButtonCircle.swift
//  Still Moment
//
//  Presentation Layer - Plastic round play/stop button (shared-094).
//
//  Reusable circle button used in Library list rows, search-result rows,
//  the gong preview and — enlarged — as the Timer start button (shared-126).
//  Renders the theme's play-gradient + inner highlight rim + warm drop shadow,
//  matching the CTA capsule's plastic style.
//

import SwiftUI

/// Plastic round play/stop button used on track rows.
///
/// Provides only the visual element. Tap + long-press gestures stay on the
/// caller so the same circle can drive different actions (open vs. preview).
struct PlayButtonCircle: View {
    /// Diameter the icon size and optical offset are designed for.
    static let defaultDiameter: CGFloat = 36

    let isPlaying: Bool
    var diameter: CGFloat = Self.defaultDiameter

    @Environment(\.themeColors)
    private var theme

    /// Scale factor relative to the 36pt design size — icon and optical
    /// offset grow proportionally with the circle.
    private var scale: CGFloat {
        self.diameter / Self.defaultDiameter
    }

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
                .font(.system(size: 14 * self.scale, weight: .semibold))
                .foregroundColor(self.theme.textOnInteractive)
                // Optical centering: the play triangle is right-heavy.
                .offset(x: self.isPlaying ? 0 : self.scale)
        }
        .frame(width: self.diameter, height: self.diameter)
    }
}
