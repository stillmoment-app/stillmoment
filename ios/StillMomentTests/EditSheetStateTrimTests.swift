//
//  EditSheetStateTrimTests.swift
//  Still Moment
//
//  Domain Tests - Trim point editing in the edit sheet (shared-105)
//

import XCTest
@testable import StillMoment

final class EditSheetStateTrimTests: XCTestCase {
    // MARK: - Prefill

    func testTrimFieldsPrefilledFromMeditation() {
        // Given
        let meditation = self.makeMeditation(duration: 600, trimStart: 90, trimEnd: 480)

        // When
        let state = EditSheetState(meditation: meditation)

        // Then
        XCTAssertEqual(state.editedTrimStartText, "1:30")
        XCTAssertEqual(state.editedTrimEndText, "8:00")
    }

    func testTrimFieldsEmptyWhenMeditationHasNoTrim() {
        // Given
        let meditation = self.makeMeditation(duration: 600)

        // When
        let state = EditSheetState(meditation: meditation)

        // Then
        XCTAssertEqual(state.editedTrimStartText, "")
        XCTAssertEqual(state.editedTrimEndText, "")
    }

    // MARK: - Applying Changes

    func testEmptyTrimFieldsMeanNoTrim() {
        // Given
        var state = self.makeState(duration: 600)
        state.editedTrimStartText = ""
        state.editedTrimEndText = ""

        // Then
        XCTAssertTrue(state.isValid)
        let updated = state.applyChanges()
        XCTAssertNil(updated.trimStart)
        XCTAssertNil(updated.trimEnd)
    }

    func testSettingTrimPointsAppliesThem() {
        // Given
        var state = self.makeState(duration: 600)
        state.editedTrimStartText = "0:45"
        state.editedTrimEndText = "9:00"

        // Then
        XCTAssertTrue(state.isValid)
        let updated = state.applyChanges()
        XCTAssertEqual(updated.trimStart, 45)
        XCTAssertEqual(updated.trimEnd, 540)
    }

    func testClearingTrimRemovesIt() {
        // Given
        let meditation = self.makeMeditation(duration: 600, trimStart: 90, trimEnd: 480)
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedTrimStartText = ""
        state.editedTrimEndText = ""

        // Then
        XCTAssertTrue(state.hasChanges)
        let updated = state.applyChanges()
        XCTAssertNil(updated.trimStart)
        XCTAssertNil(updated.trimEnd)
    }

    func testTrimChangeCountsAsChange() {
        // Given
        var state = self.makeState(duration: 600)

        // When
        state.editedTrimStartText = "0:30"

        // Then
        XCTAssertTrue(state.hasChanges)
    }

    func testUnchangedTrimIsNoChange() {
        // Given
        let meditation = self.makeMeditation(duration: 600, trimStart: 90, trimEnd: 480)
        let state = EditSheetState(meditation: meditation)

        // Then
        XCTAssertFalse(state.hasChanges)
    }

    // MARK: - Validation

    func testStartMustBeBeforeEnd() {
        // Given
        var state = self.makeState(duration: 600)
        state.editedTrimStartText = "5:00"
        state.editedTrimEndText = "4:00"

        // Then
        XCTAssertFalse(state.isValid)
    }

    func testEndBeyondFileDurationIsInvalid() {
        // Given
        var state = self.makeState(duration: 600)
        state.editedTrimEndText = "11:00"

        // Then
        XCTAssertFalse(state.isValid)
    }

    func testStartBeyondFileDurationIsInvalid() {
        // Given
        var state = self.makeState(duration: 600)
        state.editedTrimStartText = "10:00"

        // Then
        XCTAssertFalse(state.isValid)
    }

    func testGarbageInputIsInvalid() {
        // Given
        var state = self.makeState(duration: 600)
        state.editedTrimStartText = "abc"

        // Then
        XCTAssertFalse(state.isValid)
    }

    func testHoursFormatIsParsed() {
        // Given: 90-minute file
        var state = self.makeState(duration: 5400)
        state.editedTrimEndText = "1:02:03"

        // Then
        XCTAssertTrue(state.isValid)
        XCTAssertEqual(state.applyChanges().trimEnd, 3723)
    }

    func testPlainMinutesAreParsed() {
        // Given
        var state = self.makeState(duration: 600)
        state.editedTrimStartText = "2"

        // Then: a single number means minutes
        XCTAssertTrue(state.isValid)
        XCTAssertEqual(state.applyChanges().trimStart, 120)
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

    private func makeState(duration: TimeInterval) -> EditSheetState {
        EditSheetState(meditation: self.makeMeditation(duration: duration))
    }
}
