//
//  TrimEditorStateTests.swift
//  Still Moment
//
//  Domain Tests - Trim editor state (shared-107)
//

import XCTest
@testable import StillMoment

final class TrimEditorStateTests: XCTestCase {
    // MARK: - Initialization

    func testInitFromUntrimmedMeditationUsesWholeFile() {
        // Given an untrimmed 19:05 file
        let meditation = self.makeMeditation(duration: 1145)

        // When
        let state = TrimEditorState(meditation: meditation)

        // Then it spans the whole file, start is active
        XCTAssertEqual(state.start, 0)
        XCTAssertEqual(state.end, 1145)
        XCTAssertEqual(state.duration, 1145)
        XCTAssertEqual(state.activePoint, .start)
    }

    func testInitFromTrimmedMeditationUsesEffectiveBounds() {
        // Given
        let meditation = self.makeMeditation(duration: 1145, trimStart: 84, trimEnd: 1110)

        // When
        let state = TrimEditorState(meditation: meditation)

        // Then
        XCTAssertEqual(state.start, 84)
        XCTAssertEqual(state.end, 1110)
        XCTAssertEqual(state.duration, 1145)
    }

    // MARK: - Selecting

    func testSelectingSwitchesActivePoint() {
        // Given
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 600))

        // When
        let updated = state.selecting(.end)

        // Then
        XCTAssertEqual(updated.activePoint, .end)
        // Original is unchanged (immutable)
        XCTAssertEqual(state.activePoint, .start)
    }

    func testActiveValueReturnsActivePointValue() {
        // Given
        let meditation = self.makeMeditation(duration: 600, trimStart: 60, trimEnd: 540)
        let state = TrimEditorState(meditation: meditation)

        // Then
        XCTAssertEqual(state.activeValue, 60)
        XCTAssertEqual(state.selecting(.end).activeValue, 540)
    }

    // MARK: - Moving with clamping

    func testMovingStartClampsToZero() {
        // Given
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 600))

        // When dragging start below zero
        let updated = state.moving(.start, to: -50)

        // Then
        XCTAssertEqual(updated.start, 0)
        XCTAssertEqual(updated.activePoint, .start)
    }

    func testMovingEndClampsToDuration() {
        // Given
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 600))

        // When dragging end beyond the file end
        let updated = state.moving(.end, to: 999)

        // Then
        XCTAssertEqual(updated.end, 600)
        XCTAssertEqual(updated.activePoint, .end)
    }

    func testMovingStartHonorsMinimumDistanceToEnd() {
        // Given end at 100
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 600))
            .moving(.end, to: 100)

        // When pushing start up to 90 (would leave only 10 s)
        let updated = state.moving(.start, to: 90)

        // Then start cannot exceed end - 25 = 75
        XCTAssertEqual(updated.start, 75)
    }

    func testMovingEndHonorsMinimumDistanceToStart() {
        // Given start at 100
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 600))
            .moving(.start, to: 100)

        // When pulling end down to 110 (would leave only 10 s)
        let updated = state.moving(.end, to: 110)

        // Then end cannot be below start + 25 = 125
        XCTAssertEqual(updated.end, 125)
    }

    func testMovingStartWithinRangeSetsExactValue() {
        // Given
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 600))

        // When
        let updated = state.moving(.start, to: 90)

        // Then
        XCTAssertEqual(updated.start, 90)
    }

    func testMovingSelectsThePointBeingMoved() {
        // Given start active
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 600))

        // When moving the end
        let updated = state.moving(.end, to: 500)

        // Then end becomes active
        XCTAssertEqual(updated.activePoint, .end)
    }

    // MARK: - Nudging

    func testNudgingActivePointMovesByDelta() {
        // Given start active at 60
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 600))
            .moving(.start, to: 60)

        // When
        let later = state.nudgingActivePoint(by: 1)
        let earlier = state.nudgingActivePoint(by: -1)

        // Then
        XCTAssertEqual(later.start, 61)
        XCTAssertEqual(earlier.start, 59)
    }

    func testNudgingActiveEndPointMovesEnd() {
        // Given end active at 540
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 600))
            .moving(.end, to: 540)

        // When
        let updated = state.nudgingActivePoint(by: -1)

        // Then
        XCTAssertEqual(updated.end, 539)
        XCTAssertEqual(updated.activePoint, .end)
    }

    func testNudgingRespectsMinimumDistance() {
        // Given start at 75, end at 100 (exactly 25 s apart), start active
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 600))
            .moving(.end, to: 100)
            .moving(.start, to: 75)

        // When nudging start up by 1 (would break the 25 s minimum)
        let updated = state.nudgingActivePoint(by: 1)

        // Then start stays clamped at 75
        XCTAssertEqual(updated.start, 75)
    }

    // MARK: - Whole file

    func testUsingWholeFileResetsToFullRange() {
        // Given a trimmed state acting on the end point
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 600, trimStart: 60, trimEnd: 500))
            .selecting(.end)

        // When
        let updated = state.usingWholeFile()

        // Then the full range is restored and editing restarts at the start point
        XCTAssertEqual(updated.start, 0)
        XCTAssertEqual(updated.end, 600)
        XCTAssertEqual(updated.activePoint, .start)
    }

    // MARK: - Result mapping

    func testWholeFileMapsToNoTrim() {
        // Given the full range
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 1145))

        // Then no trim
        XCTAssertNil(state.resultTrimStart)
        XCTAssertNil(state.resultTrimEnd)
        XCTAssertNil(state.trimResult)
    }

    func testOnlyStartTrimmedKeepsStartDropsEnd() {
        // Given start moved in, end still at file end
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 1145))
            .moving(.start, to: 84)

        // Then only the start counts; end is at the boundary -> nil
        XCTAssertEqual(state.resultTrimStart, 84)
        XCTAssertNil(state.resultTrimEnd)
        XCTAssertNotNil(state.trimResult)
        XCTAssertEqual(state.trimResult?.start, 84)
        XCTAssertEqual(state.trimResult?.end, 1145)
    }

    func testOnlyEndTrimmedKeepsEndDropsStart() {
        // Given start 0, end pulled in to 600 of a 1145 s file
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 1145))
            .moving(.end, to: 600)

        // Then only the end counts; start at boundary -> nil
        XCTAssertNil(state.resultTrimStart)
        XCTAssertEqual(state.resultTrimEnd, 600)
        XCTAssertEqual(state.trimResult?.start, 0)
        XCTAssertEqual(state.trimResult?.end, 600)
    }

    func testBothTrimmedKeepsBoth() {
        // Given
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 1145))
            .moving(.start, to: 84)
            .moving(.end, to: 1110)

        // Then
        XCTAssertEqual(state.resultTrimStart, 84)
        XCTAssertEqual(state.resultTrimEnd, 1110)
    }

    func testBoundaryToleranceTreatsNearEdgesAsNoTrim() {
        // Given start <= 1 and end >= duration - 1
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 1145))
            .moving(.start, to: 0.5)
            .moving(.end, to: 1144.5)

        // Then both are treated as boundary -> no trim
        XCTAssertNil(state.resultTrimStart)
        XCTAssertNil(state.resultTrimEnd)
        XCTAssertNil(state.trimResult)
    }

    // MARK: - Short files (< 25 s)

    func testShortFileKeepsFullRangeFixed() {
        // Given a 20 s file (shorter than the 25 s minimum)
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 20))

        // Then it spans the whole file without start > end
        XCTAssertEqual(state.start, 0)
        XCTAssertEqual(state.end, 20)
        XCTAssertLessThanOrEqual(state.start, state.end)
    }

    func testShortFileMovesAreNoOps() {
        // Given a 20 s file
        let state = TrimEditorState(meditation: self.makeMeditation(duration: 20))

        // When trying to move either point
        let movedStart = state.moving(.start, to: 5)
        let movedEnd = state.moving(.end, to: 15)

        // Then the range stays fixed at the full file
        XCTAssertEqual(movedStart.start, 0)
        XCTAssertEqual(movedStart.end, 20)
        XCTAssertEqual(movedEnd.start, 0)
        XCTAssertEqual(movedEnd.end, 20)
    }

    // MARK: - Helpers

    private func makeMeditation(
        duration: TimeInterval,
        trimStart: TimeInterval? = nil,
        trimEnd: TimeInterval? = nil
    ) -> GuidedMeditation {
        GuidedMeditation(
            localFilePath: "test.mp3",
            fileName: "test.mp3",
            duration: duration,
            teacher: "Test Teacher",
            name: "Test Meditation",
            trimStart: trimStart,
            trimEnd: trimEnd
        )
    }
}
