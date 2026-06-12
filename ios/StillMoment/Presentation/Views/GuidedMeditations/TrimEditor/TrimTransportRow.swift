//
//  TrimTransportRow.swift
//  Still Moment
//
//  Presentation Layer — −1s / Play-Pause / +1s transport row (shared-107).
//

import SwiftUI

/// Transport controls of the trim editor: −1 s nudge, a 66-pt circular play/pause
/// button (plays from the playhead, pause keeps it), and +1 s nudge.
struct TrimTransportRow: View {
    // MARK: Internal

    let isPlaying: Bool
    let onNudge: (TimeInterval) -> Void
    let onTogglePlayback: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            self.nudgeButton(
                delta: -1,
                label: "trim_editor.nudge.minus",
                accessibility: "trim_editor.a11y.nudgeBack"
            )
            self.playButton
            self.nudgeButton(
                delta: 1,
                label: "trim_editor.nudge.plus",
                accessibility: "trim_editor.a11y.nudgeForward"
            )
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private static let playDiameter: CGFloat = 66

    private func nudgeButton(
        delta: TimeInterval,
        label: LocalizedStringKey,
        accessibility: LocalizedStringKey
    ) -> some View {
        Button {
            self.onNudge(delta)
        } label: {
            Text(label)
                .textStyle(.body, monospacedDigits: true, color: \.textPrimary)
                .frame(minWidth: 58, minHeight: 46)
                .background(
                    Capsule().fill(self.theme.cardBackground)
                )
                .overlay(
                    Capsule().strokeBorder(self.theme.cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibility))
    }

    private var playButton: some View {
        Button(action: self.onTogglePlayback) {
            Image(systemName: self.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(self.theme.textOnInteractive)
                .offset(x: self.isPlaying ? 0 : 3)
                .frame(width: Self.playDiameter, height: Self.playDiameter)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [self.theme.playGradientTop, self.theme.playGradientBot],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .shadow(color: self.theme.interactive.opacity(0.6), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(self.isPlaying ? "trim_editor.a11y.pause" : "trim_editor.a11y.play"))
    }
}
