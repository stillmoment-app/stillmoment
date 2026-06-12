//
//  TrimGeometry.swift
//  Still Moment
//
//  Presentation Layer — pure time↔x mapping for the waveform trim editor (shared-107).
//

import CoreGraphics
import Foundation

/// Pure, unit-testable mapping between a time value (seconds) and an x-coordinate
/// inside the waveform track. Both directions clamp into valid bounds so callers
/// never need to guard against out-of-range drags.
enum TrimGeometry {
    /// Maps a time in `[0, duration]` to an x-coordinate in `[0, width]`.
    static func x(for time: TimeInterval, duration: TimeInterval, width: CGFloat) -> CGFloat {
        guard duration > 0, width > 0 else {
            return 0
        }
        let fraction = min(max(time / duration, 0), 1)
        return CGFloat(fraction) * width
    }

    /// Maps a drag update to a time, anchored at the handle's position when the drag began.
    ///
    /// `translation` is the cumulative drag translation (SwiftUI `DragGesture` semantics),
    /// so it must always be applied to the fixed `anchorX` — never to the handle's current,
    /// already-moved position, which would compound every update.
    static func draggedTime(
        anchorX: CGFloat,
        translation: CGFloat,
        duration: TimeInterval,
        width: CGFloat
    ) -> TimeInterval {
        self.time(forX: anchorX + translation, duration: duration, width: width)
    }

    /// Maps an x-coordinate in `[0, width]` back to a time in `[0, duration]`.
    static func time(forX positionX: CGFloat, duration: TimeInterval, width: CGFloat) -> TimeInterval {
        guard duration > 0, width > 0 else {
            return 0
        }
        let fraction = min(max(positionX / width, 0), 1)
        return TimeInterval(fraction) * duration
    }

    // MARK: Window mapping (zoom, shared-108)

    /// Tolerance (seconds) within which a time still counts as inside the window —
    /// grips sitting right at the window edge stay visible.
    static let windowTolerance: TimeInterval = 0.5

    /// Whether a time lies inside the visible window (± `windowTolerance`).
    /// Marks and the playhead are only rendered while in the window; an off-window
    /// mark shows an edge chip instead.
    static func isTime(_ time: TimeInterval, inWindow window: ClosedRange<TimeInterval>) -> Bool {
        time >= window.lowerBound - self.windowTolerance && time <= window.upperBound + self.windowTolerance
    }

    /// Maps a time to an x-coordinate relative to a visible window, clamped into
    /// `[0, width]` — for rendering (range highlight, axis-aligned elements).
    static func x(for time: TimeInterval, window: ClosedRange<TimeInterval>, width: CGFloat) -> CGFloat {
        let span = window.upperBound - window.lowerBound
        guard span > 0, width > 0 else {
            return 0
        }
        let fraction = min(max((time - window.lowerBound) / span, 0), 1)
        return CGFloat(fraction) * width
    }

    /// Maps a time to an x-coordinate relative to a visible window WITHOUT clamping —
    /// for hit testing: a mark outside the window lands outside the grab radius
    /// automatically, so `TrimHitTesting` needs no window awareness.
    static func unclampedX(for time: TimeInterval, window: ClosedRange<TimeInterval>, width: CGFloat) -> CGFloat {
        let span = window.upperBound - window.lowerBound
        guard span > 0, width > 0 else {
            return 0
        }
        return CGFloat((time - window.lowerBound) / span) * width
    }

    /// Maps an x-coordinate in `[0, width]` back to a time, clamped into the window.
    static func time(
        forX positionX: CGFloat,
        window: ClosedRange<TimeInterval>,
        width: CGFloat
    ) -> TimeInterval {
        let span = window.upperBound - window.lowerBound
        guard span > 0, width > 0 else {
            return window.lowerBound
        }
        let fraction = min(max(positionX / width, 0), 1)
        return window.lowerBound + TimeInterval(fraction) * span
    }
}
