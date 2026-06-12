//
//  TrimHitTesting.swift
//  Still Moment
//
//  Presentation Layer — geometric drag resolution for the trim editor (shared-107).
//

import CoreGraphics
import Foundation

/// What a drag on the trim track acts on.
enum TrimDragTarget: Equatable {
    case playhead
    case mark(TrimPoint)
}

/// Resolved drag: the target plus the px offset between the grabbed element and the
/// finger. A direct grab keeps this offset for the whole drag so the element never
/// jumps under the finger; a touch on free area uses offset 0 (element jumps there).
struct TrimDragSession: Equatable {
    let target: TrimDragTarget
    let offset: CGFloat
}

/// Pixel layout of the waveform track at finger-down: its height plus the x-positions
/// of the three draggable elements.
struct TrimTrackGeometry {
    let waveformHeight: CGFloat
    let headX: CGFloat
    let startX: CGFloat
    let endX: CGFloat
}

/// Pure, unit-testable hit-testing for the trim track (handoff "Trim-Editor —
/// touch-robuste Punkt-Bedienung"). All grips are purely visual; a single pointer-down
/// is resolved here from x/y alone:
///
/// - Upper 45 % of the waveform → playhead.
/// - Lower zone → marks: a direct grab within `grabRadius` wins; when both marks are
///   in reach (cluster) the *active* mark always wins; free area moves the active mark.
enum TrimHitTesting {
    /// Touches within this distance (pt) of a grip count as a direct, relative grab.
    static let grabRadius: CGFloat = 22
    /// Fraction of the waveform height belonging to the playhead (upper) zone.
    static let verticalSplit: CGFloat = 0.45

    /// Resolves a pointer-down inside the waveform track into a drag session.
    /// `location` is relative to the track's top-left corner.
    static func beginDrag(
        at location: CGPoint,
        in geometry: TrimTrackGeometry,
        activePoint: TrimPoint
    ) -> TrimDragSession {
        let playheadZoneMaxY = geometry.waveformHeight * Self.verticalSplit
        if location.y < playheadZoneMaxY {
            let offset = abs(location.x - geometry.headX) <= Self.grabRadius ? geometry.headX - location.x : 0
            return TrimDragSession(target: .playhead, offset: offset)
        }
        return self.markSession(
            touchX: location.x,
            startX: geometry.startX,
            endX: geometry.endX,
            activePoint: activePoint
        )
    }

    // MARK: Private

    private static func markSession(
        touchX: CGFloat,
        startX: CGFloat,
        endX: CGFloat,
        activePoint: TrimPoint
    ) -> TrimDragSession {
        let startDistance = abs(touchX - startX)
        let endDistance = abs(touchX - endX)
        let activeX = activePoint == .start ? startX : endX

        if startDistance <= Self.grabRadius, endDistance <= Self.grabRadius {
            return TrimDragSession(target: .mark(activePoint), offset: activeX - touchX)
        }
        if startDistance <= Self.grabRadius {
            return TrimDragSession(target: .mark(.start), offset: startX - touchX)
        }
        if endDistance <= Self.grabRadius {
            return TrimDragSession(target: .mark(.end), offset: endX - touchX)
        }
        return TrimDragSession(target: .mark(activePoint), offset: 0)
    }
}
