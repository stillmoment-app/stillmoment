//
//  EditSheetStateTrimTests.swift
//  Still Moment
//
//  Domain Tests - Trim point handling in the edit sheet (shared-105, shared-107)
//

import XCTest
@testable import StillMoment

final class EditSheetStateTrimTests: XCTestCase {
    // MARK: - Prefill

    func testTrimPointsPrefilledFromMeditation() {
        // Given
        let meditation = self.makeMeditation(duration: 600, trimStart: 90, trimEnd: 480)

        // When
        let state = EditSheetState(meditation: meditation)

        // Then
        XCTAssertEqual(state.editedTrimStart, 90)
        XCTAssertEqual(state.editedTrimEnd, 480)
    }

    func testTrimPointsNilWhenMeditationHasNoTrim() {
        // Given
        let meditation = self.makeMeditation(duration: 600)

        // When
        let state = EditSheetState(meditation: meditation)

        // Then
        XCTAssertNil(state.editedTrimStart)
        XCTAssertNil(state.editedTrimEnd)
    }

    // MARK: - Applying Changes

    func testNilTrimPointsMeanNoTrim() {
        // Given
        var state = self.makeState(duration: 600)
        state.editedTrimStart = nil
        state.editedTrimEnd = nil

        // Then
        XCTAssertTrue(state.isValid)
        let updated = state.applyChanges()
        XCTAssertNil(updated.trimStart)
        XCTAssertNil(updated.trimEnd)
    }

    func testSettingTrimPointsAppliesThem() {
        // Given
        var state = self.makeState(duration: 600)
        state.editedTrimStart = 45
        state.editedTrimEnd = 540

        // Then
        XCTAssertTrue(state.isValid)
        let updated = state.applyChanges()
        XCTAssertEqual(updated.trimStart, 45)
        XCTAssertEqual(updated.trimEnd, 540)
    }

    func testClearingTrimRemovesIt() {
        // Given a trimmed meditation
        let meditation = self.makeMeditation(duration: 600, trimStart: 90, trimEnd: 480)
        var state = EditSheetState(meditation: meditation)

        // When clearing both points (e.g. "Zuschnitt entfernen")
        state.editedTrimStart = nil
        state.editedTrimEnd = nil

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
        state.editedTrimStart = 30

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

    // MARK: - Defensive Validation

    func testStartMustBeBeforeEnd() {
        // Given
        var state = self.makeState(duration: 600)
        state.editedTrimStart = 300
        state.editedTrimEnd = 240

        // Then
        XCTAssertFalse(state.isValid)
    }

    func testEndBeyondFileDurationIsInvalid() {
        // Given
        var state = self.makeState(duration: 600)
        state.editedTrimEnd = 660

        // Then
        XCTAssertFalse(state.isValid)
    }

    func testStartBeyondFileDurationIsInvalid() {
        // Given
        var state = self.makeState(duration: 600)
        state.editedTrimStart = 600

        // Then
        XCTAssertFalse(state.isValid)
    }

    func testConsistentTrimWithinDurationIsValid() {
        // Given
        var state = self.makeState(duration: 5400)
        state.editedTrimEnd = 3723

        // Then
        XCTAssertTrue(state.isValid)
        XCTAssertEqual(state.applyChanges().trimEnd, 3723)
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
