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
}
