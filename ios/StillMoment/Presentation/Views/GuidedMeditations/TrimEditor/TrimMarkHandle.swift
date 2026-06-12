//
//  TrimMarkHandle.swift
//  Still Moment
//
//  Presentation Layer — purely visual trim mark (cut edge + grip knob) (shared-107).
//

import SwiftUI

/// A single trim mark (start or end): a thin full-height cut edge plus a grip knob
/// sitting clearly in the lower half of the waveform.
///
/// Purely visual — it never participates in hit testing. Touches are resolved
/// geometrically by the single track gesture in `TrimWaveformSection`, so overlapping
/// marks can never steal each other's touch. The active mark is wider, carries a glow
/// ring and a slow pulse (paused while dragging and under Reduce Motion). Exposed as
/// an adjustable accessibility element (±1 s nudges).
struct TrimMarkHandle: View {
    // MARK: Internal

    let time: TimeInterval
    let isActive: Bool
    let isDragging: Bool
    let trackWidth: CGFloat
    let duration: TimeInterval
    let onNudge: (TimeInterval) -> Void
    let accessibilityLabelText: String

    var body: some View {
        ZStack(alignment: .top) {
            self.bubble
            self.cutEdge
            self.knob
        }
        .frame(width: Self.layoutWidth, height: TrimWaveformView.height + Self.verticalOverhang * 2)
        .offset(x: self.markX - Self.layoutWidth / 2, y: -Self.verticalOverhang)
        .accessibilityElement()
        .accessibilityLabel(Text(self.accessibilityLabelText))
        .accessibilityValue(Text(EditSheetState.formatTime(self.time)))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: self.onNudge(1)
            case .decrement: self.onNudge(-1)
            @unknown default: break
            }
        }
        .onChange(of: self.isDragging) { dragging in
            self.updatePulse(dragging: dragging)
        }
        .onChange(of: self.isActive) { _ in
            self.updatePulse(dragging: self.isDragging)
        }
        .onAppear { self.updatePulse(dragging: false) }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var pulsing = false

    private static let layoutWidth: CGFloat = 44
    /// How far the cut edge extends beyond the waveform top/bottom.
    private static let verticalOverhang: CGFloat = 12
    /// Vertical center of the knob, as fraction of the waveform height — clearly
    /// in the lower (mark) zone so the visual matches the touch split.
    private static let knobCenterFraction: CGFloat = 0.74

    private var markX: CGFloat {
        TrimGeometry.x(for: self.time, duration: self.duration, width: self.trackWidth)
    }

    private var markGradient: LinearGradient {
        LinearGradient(
            colors: [self.theme.playGradientTop, self.theme.playGradientBot],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var cutEdge: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(self.markGradient)
            .frame(width: self.isActive ? 4 : 3)
            .opacity(self.isActive ? 1 : 0.7)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeOut(duration: 0.12), value: self.isActive)
    }

    private var knob: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(self.markGradient)
            .frame(width: self.isActive ? 20 : 16, height: self.isActive ? 44 : 38)
            .overlay(
                HStack(spacing: 3) {
                    self.grip
                    self.grip
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(self.theme.interactive.opacity(self.isActive ? 0.35 : 0), lineWidth: 2)
                    .padding(-2)
            )
            .shadow(color: self.theme.cardShadow, radius: 4, y: 2)
            .scaleEffect(self.pulsing ? 1.1 : 1)
            .animation(.easeOut(duration: 0.12), value: self.isActive)
            .position(
                x: Self.layoutWidth / 2,
                y: Self.verticalOverhang + TrimWaveformView.height * Self.knobCenterFraction
            )
    }

    private var grip: some View {
        Capsule()
            .fill(self.theme.textOnInteractive.opacity(0.5))
            .frame(width: 2, height: 13)
    }

    @ViewBuilder private var bubble: some View {
        if self.isDragging {
            TrimTimeBubble(
                time: self.time,
                anchorX: self.markX,
                trackWidth: self.trackWidth,
                background: self.theme.interactive,
                textColor: self.theme.textOnInteractive
            )
            .offset(y: -30)
        }
    }

    private func updatePulse(dragging: Bool) {
        let shouldPulse = self.isActive && !dragging && !self.reduceMotion
        guard shouldPulse else {
            self.pulsing = false
            return
        }
        withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: true)) {
            self.pulsing = true
        }
    }
}
