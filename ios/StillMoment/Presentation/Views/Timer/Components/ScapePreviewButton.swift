//
//  ScapePreviewButton.swift
//  Still Moment
//
//  Presentation Layer — preview button on each soundscape selection row (shared-121).
//
//  Unlike the gong preview button (a one-shot play that fires an expanding ring),
//  the soundscape preview loops, so this button is a play/stop TOGGLE:
//  - Idle audible sound: play glyph.
//  - Playing: stop glyph (square) + a calm, continuously breathing glow ring
//    (~1.6s, autoreverses) — not the gong's single expanding ring.
//  - "Silence": a muted speaker glyph; the button plays nothing.
//
//  Under Reduce Motion the glow stands still.
//

import SwiftUI

/// The circular preview button shown on the left of each soundscape row.
struct ScapePreviewButton: View {
    let isSelected: Bool
    /// "Silence" row: shows a mute glyph and never plays.
    let isSilent: Bool
    /// True while this row's loop preview is currently sounding.
    let isPlaying: Bool

    @Environment(\.themeColors)
    private var theme
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        ZStack {
            if self.showsGlow {
                self.glow
            }
            self.disc
        }
        .frame(width: Self.diameter, height: Self.diameter)
    }

    // MARK: - Disc

    private var disc: some View {
        ZStack {
            Circle()
                .fill(self
                    .isSelected ? AnyShapeStyle(self.theme.interactive) : AnyShapeStyle(self.theme.cardBackground))
                .overlay(
                    Circle()
                        .strokeBorder(self.theme.cardBorder, lineWidth: self.isSelected ? 0 : 1)
                )
            self.icon
        }
    }

    private var iconColor: Color {
        self.isSelected ? self.theme.textOnInteractive : self.theme.interactive
    }

    @ViewBuilder private var icon: some View {
        if self.isSilent {
            Image(systemName: "speaker.slash.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(self.iconColor)
        } else if self.isPlaying {
            Image(systemName: "stop.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(self.iconColor)
        } else {
            Image(systemName: "play.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(self.iconColor)
                .offset(x: 1)
        }
    }

    // MARK: - Breathing glow

    private var showsGlow: Bool {
        self.isPlaying && !self.isSilent
    }

    private var glowActive: Bool {
        self.showsGlow && !self.reduceMotion
    }

    private var glow: some View {
        Circle()
            .stroke(self.theme.interactive, lineWidth: 2)
            .frame(width: Self.diameter, height: Self.diameter)
            .scaleEffect(self.glowActive ? Self.glowMaxScale : 1)
            .opacity(self.glowActive ? Self.glowMinOpacity : Self.glowMaxOpacity)
            .animation(
                self.glowActive
                    ? .easeInOut(duration: Self.glowDuration).repeatForever(autoreverses: true)
                    : nil,
                value: self.glowActive
            )
            .allowsHitTesting(false)
    }

    // MARK: - Constants

    private static let diameter: CGFloat = 40
    private static let glowMaxScale: CGFloat = 1.35
    private static let glowMaxOpacity: Double = 0.55
    private static let glowMinOpacity: Double = 0.15
    private static let glowDuration: Double = 1.6
}

// MARK: - Previews

#if DEBUG
#Preview("Scape Preview Buttons") {
    ThemeRootView {
        HStack(spacing: 20) {
            ScapePreviewButton(isSelected: true, isSilent: false, isPlaying: true)
            ScapePreviewButton(isSelected: false, isSilent: false, isPlaying: false)
            ScapePreviewButton(isSelected: true, isSilent: true, isPlaying: false)
            ScapePreviewButton(isSelected: false, isSilent: true, isPlaying: false)
        }
        .padding()
    }
}
#endif
