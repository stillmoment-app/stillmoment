//
//  GongPreviewButton.swift
//  Still Moment
//
//  Presentation Layer — preview button on each gong selection row (shared-115).
//
//  Three visual states:
//  - Selected audible sound: plastic disc (reuses `PlayButtonCircle`).
//  - Unselected audible sound: flat circle with border + accent icon.
//  - Vibration: haptic icon instead of a play triangle, in both selection states.
//
//  While a row is previewing, a soft expanding ring radiates around the button
//  (~1.5s, subtle). The ring is disabled under Reduce Motion.
//

import SwiftUI

/// The circular preview button shown on the left of each gong row.
struct GongPreviewButton: View {
    let isSelected: Bool
    let isVibration: Bool
    /// True while this row's preview is currently sounding (drives the ring).
    let isPreviewing: Bool

    @Environment(\.themeColors)
    private var theme
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        ZStack {
            if self.shouldShowRing {
                self.ring
            }
            self.disc
        }
        .frame(width: Self.diameter, height: Self.diameter)
    }

    // MARK: - Disc variants

    @ViewBuilder private var disc: some View {
        if self.isSelected {
            self.selectedDisc
        } else {
            self.flatDisc
        }
    }

    private var selectedDisc: some View {
        ZStack {
            PlayButtonCircle(isPlaying: false)
            if self.isVibration {
                self.icon(color: self.theme.textOnInteractive)
            }
        }
    }

    private var flatDisc: some View {
        ZStack {
            Circle()
                .fill(self.theme.cardBackground)
                .overlay(
                    Circle()
                        .strokeBorder(self.theme.cardBorder, lineWidth: 1)
                )
            self.icon(color: self.theme.interactive)
        }
        .frame(width: Self.diameter, height: Self.diameter)
    }

    @ViewBuilder
    private func icon(color: Color) -> some View {
        if self.isVibration {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(color)
        } else {
            // Hidden when selected: PlayButtonCircle already draws the triangle.
            if !self.isSelected {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                    .offset(x: 1)
            }
        }
    }

    // MARK: - Ring animation

    private var shouldShowRing: Bool {
        self.isPreviewing && !self.reduceMotion
    }

    private var ring: some View {
        Circle()
            .stroke(self.theme.interactive, lineWidth: 2)
            .frame(width: Self.diameter, height: Self.diameter)
            .scaleEffect(self.isPreviewing ? Self.ringMaxScale : 1)
            .opacity(self.isPreviewing ? 0 : Self.ringStartOpacity)
            .animation(
                .easeOut(duration: Self.ringDuration).repeatForever(autoreverses: false),
                value: self.isPreviewing
            )
            .allowsHitTesting(false)
    }

    // MARK: - Constants

    private static let diameter: CGFloat = 40
    private static let ringMaxScale: CGFloat = 1.7
    private static let ringStartOpacity: Double = 0.5
    private static let ringDuration: Double = 1.5
}

// MARK: - Previews

#if DEBUG
#Preview("Preview Buttons") {
    ThemeRootView {
        HStack(spacing: 20) {
            GongPreviewButton(isSelected: true, isVibration: false, isPreviewing: true)
            GongPreviewButton(isSelected: false, isVibration: false, isPreviewing: false)
            GongPreviewButton(isSelected: true, isVibration: true, isPreviewing: false)
            GongPreviewButton(isSelected: false, isVibration: true, isPreviewing: false)
        }
        .padding()
    }
}
#endif
