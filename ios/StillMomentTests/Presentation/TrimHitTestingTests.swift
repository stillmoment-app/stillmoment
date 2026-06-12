//
//  TrimHitTestingTests.swift
//  Still Moment
//
//  Tests for the geometric drag resolution of the waveform trim editor
//  (shared-107, reworked touch concept).
//

import XCTest
@testable import StillMoment

/// Fachliche Erwartung: Auf der schmalen Spur konkurrieren drei ziehbare Elemente
/// (Abspielposition + 2 Marken) um denselben Fingertipp. Die Aufloesung ist rein
/// geometrisch innerhalb der Wellenform: die obere Zone (45 %) trifft immer die
/// Abspielposition, die untere Zone die Marken — bei Clustern gewinnt die aktive Marke.
final class TrimHitTestingTests: XCTestCase {
    // MARK: - Vertical zones

    func testTouchAtTheTopTargetsPlayheadRegardlessOfMarks() {
        // Given a touch near the top edge exactly on the start mark's x
        let session = self.beginDrag(x: 100, y: 10, startX: 100, endX: 300, activePoint: .end)

        // Then the playhead wins — the upper zone belongs to it alone
        XCTAssertEqual(session.target, .playhead)
    }

    func testTouchInUpperWaveformZoneTargetsPlayhead() {
        // Given a touch just above the 45 % split line (108 * 0.45 = 48.6)
        let session = self.beginDrag(x: 200, y: 47, startX: 100, endX: 300, activePoint: .start)

        // Then it moves the playhead
        XCTAssertEqual(session.target, .playhead)
    }

    func testTouchInLowerWaveformZoneTargetsMark() {
        // Given a touch just below the split line
        let session = self.beginDrag(x: 200, y: 50, startX: 100, endX: 300, activePoint: .start)

        // Then it acts on a mark, never on the playhead
        XCTAssertEqual(session.target, .mark(.start))
    }

    // MARK: - Playhead grab vs. jump

    func testPlayheadGrabNearHeadKeepsRelativeOffset() {
        // Given the head sits at x=150 and the finger lands 10 px beside it
        let session = self.beginDrag(x: 140, y: 10, headX: 150, startX: 0, endX: 300, activePoint: .start)

        // Then the grab is relative — the head must not jump under the finger
        XCTAssertEqual(session.offset, 10, accuracy: 0.001)
    }

    func testPlayheadTouchFarFromHeadJumpsThere() {
        // Given the finger lands far away from the head
        let session = self.beginDrag(x: 40, y: 10, headX: 200, startX: 0, endX: 300, activePoint: .start)

        // Then the head jumps to the finger (offset 0)
        XCTAssertEqual(session.target, .playhead)
        XCTAssertEqual(session.offset, 0)
    }

    // MARK: - Mark resolution in the lower zone

    func testClusterIsAlwaysWonByTheActiveMark() {
        // Given start and end sit on top of each other and the finger lands between them
        let session = self.beginDrag(x: 150, y: 80, startX: 145, endX: 155, activePoint: .end)

        // Then the active mark wins — never grabs the wrong one
        XCTAssertEqual(session.target, .mark(.end))
        XCTAssertEqual(session.offset, 5, accuracy: 0.001)
    }

    func testDirectGrabOnStartMarkKeepsRelativeOffset() {
        // Given the finger lands 12 px beside the isolated start mark
        let session = self.beginDrag(x: 112, y: 80, startX: 100, endX: 300, activePoint: .end)

        // Then start is grabbed directly (relative, no jump) and becomes the drag target
        XCTAssertEqual(session.target, .mark(.start))
        XCTAssertEqual(session.offset, -12, accuracy: 0.001)
    }

    func testDirectGrabOnEndMark() {
        let session = self.beginDrag(x: 295, y: 80, startX: 100, endX: 300, activePoint: .start)

        XCTAssertEqual(session.target, .mark(.end))
        XCTAssertEqual(session.offset, 5, accuracy: 0.001)
    }

    func testWhenBothMarksInReachTheActiveOneWinsEvenIfFarther() {
        // Given both marks within grab range, start clearly closer, but end is active
        let session = self.beginDrag(x: 105, y: 80, startX: 100, endX: 125, activePoint: .end)

        // Then the active mark wins the touch (Prinzip B) — predictable in tight clusters
        XCTAssertEqual(session.target, .mark(.end))
        XCTAssertEqual(session.offset, 20, accuracy: 0.001)
    }

    func testEmptyAreaMovesTheActiveMarkThere() {
        // Given a touch on free waveform area far from both marks
        let session = self.beginDrag(x: 200, y: 80, startX: 50, endX: 350, activePoint: .end)

        // Then the active mark jumps to the finger (offset 0)
        XCTAssertEqual(session.target, .mark(.end))
        XCTAssertEqual(session.offset, 0)
    }

    // MARK: Private

    private func beginDrag(
        x: CGFloat,
        y: CGFloat,
        headX: CGFloat = 0,
        startX: CGFloat,
        endX: CGFloat,
        activePoint: TrimPoint
    ) -> TrimDragSession {
        TrimHitTesting.beginDrag(
            at: CGPoint(x: x, y: y),
            in: TrimTrackGeometry(
                waveformHeight: 108,
                headX: headX,
                startX: startX,
                endX: endX
            ),
            activePoint: activePoint
        )
    }
}
