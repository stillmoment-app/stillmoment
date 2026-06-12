//
//  TrimPlayheadGrabber.swift
//  Still Moment
//
//  Presentation Layer — sage playhead grabber in the waveform's upper zone (shared-108).
//

import SwiftUI

/// The sage playhead grabber, rendered as a full-size overlay over the waveform and
/// positioned in the upper (playhead) touch zone. The full-height playhead line is
/// drawn by `TrimWaveformView`; this is only the grip.
///
/// Purely visual — the actual dragging is resolved geometrically by the single track
/// gesture in `TrimWaveformSection` (the upper 45 % of the waveform belongs to the
/// playhead). Exposed as an adjustable accessibility element (±1 s seeks), also while
/// the playhead is outside the zoom window and the grip is hidden.
struct TrimPlayheadGrabber: View {
    // MARK: Internal

    let playheadTime: TimeInterval
    /// Visible time window (zoom, shared-108) — an off-window playhead shows no grip
    /// (never glued to the edge).
    let window: ClosedRange<TimeInterval>
    let trackWidth: CGFloat
    let isDragging: Bool
    let onNudge: (TimeInterval) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            if self.trackWidth > 0, TrimGeometry.isTime(self.playheadTime, inWindow: self.window) {
                self.grabber
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
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
    private static let tipSize = CGSize(width: 10, height: 6)

    private var headX: CGFloat {
        TrimGeometry.x(for: self.playheadTime, window: self.window, width: self.trackWidth)
    }

    /// Vertical center of the playhead (upper) touch zone.
    private var zoneCenterY: CGFloat {
        TrimWaveformView.height * TrimHitTesting.verticalSplit / 2
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
                .frame(width: Self.tipSize.width, height: Self.tipSize.height)
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
        .offset(
            x: self.headX - Self.grabberSize.width / 2,
            y: self.zoneCenterY - (Self.grabberSize.height + Self.tipSize.height) / 2
        )
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
