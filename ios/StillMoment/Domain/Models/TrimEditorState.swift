//
//  TrimEditorState.swift
//  Still Moment
//
//  Domain Model - Trim editor state (shared-107)
//

import Foundation

/// Which trim point the editor is currently acting on.
enum TrimPoint: Equatable {
    case start
    case end
}

/// Immutable state of the waveform trim editor.
///
/// Holds the in-progress start/end selection while the user drags handles or nudges
/// points in the full-screen editor. Every transition returns a new instance (DDD value
/// object). Playhead, playing, and previewing are UI concerns and live in the View/ViewModel.
struct TrimEditorState: Equatable {
    // MARK: Lifecycle

    /// Initializes from a meditation, seeding start/end with its effective bounds.
    ///
    /// For files shorter than `minimumRange`, the full file range stays fixed and moves
    /// become no-ops — there is no room to honor the 25 s minimum distance.
    init(meditation: GuidedMeditation) {
        self.duration = meditation.duration
        self.activePoint = .start

        if meditation.duration < Self.minimumRange {
            self.start = 0
            self.end = meditation.duration
        } else {
            self.start = meditation.effectiveStart
            self.end = meditation.effectiveEnd
        }
    }

    private init(
        start: TimeInterval,
        end: TimeInterval,
        duration: TimeInterval,
        activePoint: TrimPoint
    ) {
        self.start = start
        self.end = end
        self.duration = duration
        self.activePoint = activePoint
    }

    // MARK: Internal

    /// Minimum distance (seconds) the editor enforces between start and end.
    static let minimumRange: TimeInterval = 25

    let start: TimeInterval
    let end: TimeInterval
    let duration: TimeInterval
    let activePoint: TrimPoint

    /// Value of the currently active point.
    var activeValue: TimeInterval {
        switch self.activePoint {
        case .start: self.start
        case .end: self.end
        }
    }

    /// Resolved start to persist — nil when at the boundary (`start <= 1 s`).
    var resultTrimStart: TimeInterval? {
        self.start <= Self.boundaryTolerance ? nil : self.start
    }

    /// Resolved end to persist — nil when at the boundary (`end >= duration - 1 s`).
    var resultTrimEnd: TimeInterval? {
        self.end >= self.duration - Self.boundaryTolerance ? nil : self.end
    }

    /// The selected range as a pair, or nil when it is practically the whole file
    /// (`start <= 1 s` AND `end >= duration - 1 s`).
    var trimResult: (start: TimeInterval, end: TimeInterval)? {
        if self.resultTrimStart == nil, self.resultTrimEnd == nil {
            return nil
        }
        return (self.start, self.end)
    }

    /// Returns a copy with a different active point.
    func selecting(_ point: TrimPoint) -> TrimEditorState {
        TrimEditorState(start: self.start, end: self.end, duration: self.duration, activePoint: point)
    }

    /// Moves a point to a clamped time and makes it the active point.
    ///
    /// Start is clamped into `[0, end - minimumRange]`, end into `[start + minimumRange, duration]`.
    /// For files shorter than `minimumRange` the range is fixed and this is a no-op except for
    /// selecting the point.
    func moving(_ point: TrimPoint, to time: TimeInterval) -> TrimEditorState {
        guard self.duration >= Self.minimumRange else {
            return self.selecting(point)
        }

        switch point {
        case .start:
            let clamped = min(max(time, 0), self.end - Self.minimumRange)
            return TrimEditorState(start: clamped, end: self.end, duration: self.duration, activePoint: .start)
        case .end:
            let clamped = max(min(time, self.duration), self.start + Self.minimumRange)
            return TrimEditorState(start: self.start, end: clamped, duration: self.duration, activePoint: .end)
        }
    }

    /// Nudges the active point by a delta (±1 s) through the same clamping as `moving`.
    func nudgingActivePoint(by delta: TimeInterval) -> TrimEditorState {
        self.moving(self.activePoint, to: self.activeValue + delta)
    }

    /// Resets the selection to the full file; editing restarts at the start point.
    func usingWholeFile() -> TrimEditorState {
        TrimEditorState(start: 0, end: self.duration, duration: self.duration, activePoint: .start)
    }

    // MARK: Private

    /// Tolerance (seconds) within which a point counts as sitting at the file boundary.
    private static let boundaryTolerance: TimeInterval = 1
}
