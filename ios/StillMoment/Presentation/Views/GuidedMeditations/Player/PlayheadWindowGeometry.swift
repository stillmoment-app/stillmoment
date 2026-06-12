//
//  PlayheadWindowGeometry.swift
//  Still Moment
//
//  Presentation Layer — pure sec↔x mapping for the scrolling "Tonkopf" window (shared-109).
//

import CoreGraphics
import Foundation

/// Pure, unit-testable mapping for the waveform player's scrolling window.
///
/// Unlike `TrimGeometry` (a static `[0, duration]` or fixed zoom window), the player's
/// window *glides*: it stays centered on `now`, so the current position is always at the
/// screen center (the fixed "now"-line). For any screen-x:
/// `sec = now + (x − center) / pxPerSec`. Times left of center are in the past, right in
/// the future. Rendering leaves `x`/`sec` unclamped (off-track bars are simply skipped);
/// only the drag result is clamped into the playable bounds.
enum PlayheadWindowGeometry {
    /// Horizontal density: how many points one second of audio occupies.
    static func pxPerSec(windowSec: TimeInterval, width: CGFloat) -> CGFloat {
        guard windowSec > 0, width > 0 else {
            return 0
        }
        return width / CGFloat(windowSec)
    }

    /// Maps an absolute time to a screen-x in a window centered on `now`. Not clamped —
    /// callers skip bars that fall outside `[0, width]`.
    static func x(forSec sec: TimeInterval, now: TimeInterval, windowSec: TimeInterval, width: CGFloat) -> CGFloat {
        let center = width / 2
        let density = self.pxPerSec(windowSec: windowSec, width: width)
        return center + CGFloat(sec - now) * density
    }

    /// Maps a screen-x back to an absolute time in a window centered on `now`. Not clamped.
    static func sec(
        forX positionX: CGFloat,
        now: TimeInterval,
        windowSec: TimeInterval,
        width: CGFloat
    ) -> TimeInterval {
        let center = width / 2
        let density = self.pxPerSec(windowSec: windowSec, width: width)
        guard density > 0 else {
            return now
        }
        return now + TimeInterval((positionX - center) / density)
    }

    /// Maps a drag translation to a new position, anchored at `startNow`.
    ///
    /// Dragging the wave LEFT (negative translation) moves the position FORWARD, dragging
    /// RIGHT moves it BACKWARD — the band scrolls under a fixed playhead. The result is
    /// clamped into `bounds` (the trimmed playable range), so the player never scrubs past
    /// the trim edges. `translation` is the cumulative `DragGesture` translation, so it is
    /// always applied to the fixed `startNow`, never to an already-moved position.
    static func draggedNow(
        startNow: TimeInterval,
        translation: CGFloat,
        windowSec: TimeInterval,
        width: CGFloat,
        bounds: ClosedRange<TimeInterval>
    ) -> TimeInterval {
        let density = self.pxPerSec(windowSec: windowSec, width: width)
        guard density > 0 else {
            return min(max(startNow, bounds.lowerBound), bounds.upperBound)
        }
        let proposed = startNow - TimeInterval(translation / density)
        return min(max(proposed, bounds.lowerBound), bounds.upperBound)
    }
}
