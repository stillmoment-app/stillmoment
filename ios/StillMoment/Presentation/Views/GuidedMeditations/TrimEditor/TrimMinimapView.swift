//
//  TrimMinimapView.swift
//  Still Moment
//
//  Presentation Layer — whole-file minimap of the zoomed trim editor (shared-108).
//

import SwiftUI

/// Thin whole-file strip shown above the track while zoomed: range fill between the
/// marks, two mark ticks, a playhead tick, and a sage frame at the window's position.
/// Tapping or dragging pans the zoom window (`onPan` receives the new center time).
///
/// Exposed as an adjustable accessibility element — increment/decrement pans the
/// window by half its span.
struct TrimMinimapView: View {
    // MARK: Internal

    static let height: CGFloat = 26

    let start: TimeInterval
    let end: TimeInterval
    let playheadTime: TimeInterval
    let window: ClosedRange<TimeInterval>
    let duration: TimeInterval
    let onPan: (TimeInterval) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                self.background
                self.rangeFill(width: proxy.size.width)
                self.markTick(at: self.start, width: proxy.size.width)
                self.markTick(at: self.end, width: proxy.size.width)
                self.playheadTick(width: proxy.size.width)
                self.windowFrame(width: proxy.size.width)
            }
            .contentShape(Rectangle())
            // High priority so panning wins over the sheet's interactive swipe-to-dismiss.
            .highPriorityGesture(self.panGesture(width: proxy.size.width))
        }
        .frame(height: Self.height)
        .accessibilityElement()
        .accessibilityLabel(Text("trim_editor.a11y.minimap"))
        .accessibilityValue(Text(self.accessibilityWindowValue))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: self.onPan(self.windowCenter + self.windowSpan / 2)
            case .decrement: self.onPan(self.windowCenter - self.windowSpan / 2)
            @unknown default: break
            }
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private var windowSpan: TimeInterval {
        self.window.upperBound - self.window.lowerBound
    }

    private var windowCenter: TimeInterval {
        (self.window.lowerBound + self.window.upperBound) / 2
    }

    private var accessibilityWindowValue: String {
        String(
            format: NSLocalizedString("trim_editor.a11y.minimapValue", comment: "Minimap window range"),
            EditSheetState.formatTime(self.window.lowerBound),
            EditSheetState.formatTime(self.window.upperBound)
        )
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(self.theme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(self.theme.cardBorder, lineWidth: 1)
            )
    }

    /// Copper fill between the two marks — the audible range in file coordinates.
    private func rangeFill(width: CGFloat) -> some View {
        let startX = TrimGeometry.x(for: self.start, duration: self.duration, width: width)
        let endX = TrimGeometry.x(for: self.end, duration: self.duration, width: width)
        return Rectangle()
            .fill(self.theme.interactive.opacity(0.20))
            .frame(width: max(endX - startX, 0))
            .offset(x: startX)
    }

    private func markTick(at time: TimeInterval, width: CGFloat) -> some View {
        Rectangle()
            .fill(self.theme.interactive)
            .frame(width: 2)
            .padding(.vertical, 2)
            .offset(x: TrimGeometry.x(for: time, duration: self.duration, width: width) - 1)
    }

    private func playheadTick(width: CGFloat) -> some View {
        // Sage, not copper — consistent with the playhead on the main track.
        Rectangle()
            .fill(self.theme.playheadAccentHi)
            .frame(width: 2)
            .offset(x: TrimGeometry.x(for: self.playheadTime, duration: self.duration, width: width) - 1)
    }

    /// Sage frame marking the zoom window inside the whole file.
    private func windowFrame(width: CGFloat) -> some View {
        let lowerX = TrimGeometry.x(for: self.window.lowerBound, duration: self.duration, width: width)
        let upperX = TrimGeometry.x(for: self.window.upperBound, duration: self.duration, width: width)
        return RoundedRectangle(cornerRadius: 6)
            .fill(self.theme.playheadAccent.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(self.theme.playheadAccentHi, lineWidth: 1.5)
            )
            .frame(width: max(upperX - lowerX, 0))
            .padding(.vertical, 1)
            .offset(x: lowerX)
    }

    private func panGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard width > 0 else {
                    return
                }
                self.onPan(TrimGeometry.time(forX: value.location.x, duration: self.duration, width: width))
            }
    }
}
