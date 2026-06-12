//
//  TrimPlayheadLane.swift
//  Still Moment
//
//  Presentation Layer — dedicated playhead lane above the waveform (shared-107).
//

import SwiftUI

/// The narrow labelled lane above the waveform where the sage playhead grabber lives.
///
/// Purely visual — the actual dragging is resolved geometrically by the single track
/// gesture in `TrimWaveformSection` (the whole lane belongs to the playhead). Exposed
/// as an adjustable accessibility element (±1 s seeks).
struct TrimPlayheadLane: View {
    // MARK: Internal

    static let height: CGFloat = 34

    let playheadTime: TimeInterval
    /// Visible time window (zoom, shared-108) — the whole file in the overview.
    /// An off-window playhead shows no grabber (never glued to the edge).
    let window: ClosedRange<TimeInterval>
    let trackWidth: CGFloat
    let isDragging: Bool
    let onNudge: (TimeInterval) -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            self.label
            self.rail
            if self.trackWidth > 0, TrimGeometry.isTime(self.playheadTime, inWindow: self.window) {
                self.grabber
            }
        }
        .frame(height: Self.height)
        .accessibilityElement()
        .accessibilityLabel(Text("trim_editor.a11y.playhead"))
        .accessibilityValue(Text(EditSheetState.formatTime(self.playheadTime)))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: self.onNudge(1)
            case .decrement: self.onNudge(-1)
            @unknown default: break
            }
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private static let grabberSize = CGSize(width: 32, height: 20)

    private var headX: CGFloat {
        TrimGeometry.x(for: self.playheadTime, window: self.window, width: self.trackWidth)
    }

    private var label: some View {
        Text("trim_editor.lane.playhead")
            .textStyle(.eyebrow)
            .foregroundColor(self.theme.playheadAccent.opacity(0.7))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var rail: some View {
        Capsule()
            .fill(self.theme.playheadTrack)
            .frame(height: 2)
            .padding(.bottom, 2)
    }

    private var grabber: some View {
        VStack(spacing: -1) {
            RoundedRectangle(cornerRadius: 7)
                .fill(
                    LinearGradient(
                        colors: [self.theme.playheadAccentHi, self.theme.playheadAccent],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: Self.grabberSize.width, height: Self.grabberSize.height)
                .overlay(
                    HStack(spacing: 3) {
                        self.grip
                        self.grip
                    }
                )
                .shadow(color: self.theme.cardShadow, radius: 4, y: 2)
            Triangle()
                .fill(self.theme.playheadAccent)
                .frame(width: 10, height: 6)
        }
        .overlay(alignment: .top) {
            if self.isDragging {
                TrimTimeBubble(
                    time: self.playheadTime,
                    anchorX: self.headX,
                    trackWidth: self.trackWidth,
                    background: self.theme.playheadAccentHi,
                    textColor: self.theme.textOnPlayhead
                )
                .offset(y: -30)
            }
        }
        .offset(x: self.headX - Self.grabberSize.width / 2)
    }

    private var grip: some View {
        Capsule()
            .fill(self.theme.textOnPlayhead.opacity(0.55))
            .frame(width: 2, height: 9)
    }
}

/// Downward-pointing tip below the playhead grabber.
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
