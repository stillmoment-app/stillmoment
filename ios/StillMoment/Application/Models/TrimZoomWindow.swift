//
//  TrimZoomWindow.swift
//  Still Moment
//
//  Application Layer — pure zoom-window math for the trim editor (shared-108).
//

import Foundation

/// Pure functions computing the visible time window of the zoomed trim editor.
///
/// The window is UI state (lives in `TrimEditorViewModel`), deliberately kept out of
/// the domain's `TrimEditorState`. All math follows the design handoff
/// "Präzises Zuschneiden an den Rändern": the span scales with the file (18 %, at
/// least 120 s), `frame` places a mark ~25 % from its near edge, `pan` recenters.
/// For files no longer than the span every function returns the whole file —
/// there is effectively no zoom.
enum TrimZoomWindow {
    // MARK: Internal

    /// Width (seconds) of the zoom window for a file of the given duration:
    /// 18 % of the file, at least 120 s, never more than the file itself.
    static func zoomSpan(duration: TimeInterval) -> TimeInterval {
        min(duration, max(self.minimumSpan, (duration * self.spanFraction).rounded()))
    }

    /// Frames a mark in a zoom window, placing it ~25 % from its near edge
    /// (start: left edge, end: right edge). Clamped into `[0, duration]`.
    static func frame(
        around mark: TimeInterval,
        point: TrimPoint,
        duration: TimeInterval
    ) -> ClosedRange<TimeInterval> {
        let span = self.zoomSpan(duration: duration)
        guard duration > span else {
            return 0...max(duration, 0)
        }
        switch point {
        case .start:
            let lower = (mark - span * Self.markEdgeFraction).clamped(to: 0...(duration - span))
            return lower...(lower + span)
        case .end:
            let upper = (mark + span * Self.markEdgeFraction).clamped(to: span...duration)
            return (upper - span)...upper
        }
    }

    /// Moves the zoom window so it is centered on `center`, keeping its span.
    /// Clamped into `[0, duration]`.
    static func pan(toCenter center: TimeInterval, duration: TimeInterval) -> ClosedRange<TimeInterval> {
        let span = self.zoomSpan(duration: duration)
        guard duration > span else {
            return 0...max(duration, 0)
        }
        let lower = (center - span / 2).clamped(to: 0...(duration - span))
        return lower...(lower + span)
    }

    // MARK: Private

    private static let minimumSpan: TimeInterval = 120
    private static let spanFraction: Double = 0.18
    /// Fraction of the span between the framed mark and its near window edge.
    private static let markEdgeFraction: Double = 0.25
}

private extension TimeInterval {
    func clamped(to range: ClosedRange<TimeInterval>) -> TimeInterval {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
