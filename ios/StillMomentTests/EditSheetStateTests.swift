//
//  EditSheetStateTests.swift
//  Still Moment
//
//  Unit Tests for EditSheetState validation and change tracking logic
//

import XCTest
@testable import StillMoment

final class EditSheetStateTests: XCTestCase {
    // MARK: - Test Helpers

    private func makeTestMeditation(
        teacher: String = "Original Teacher",
        name: String = "Original Name",
        customTeacher: String? = nil,
        customName: String? = nil
    ) -> GuidedMeditation {
        GuidedMeditation(
            fileBookmark: Data(),
            fileName: "test.mp3",
            duration: 600,
            teacher: teacher,
            name: name,
            customTeacher: customTeacher,
            customName: customName
        )
    }

    // MARK: - Initialization Tests

    func testInitializesWithEffectiveValues() {
        // Given
        let meditation = self.makeTestMeditation(
            teacher: "Original",
            name: "Original Name",
            customTeacher: "Custom Teacher",
            customName: "Custom Name"
        )

        // When
        let state = EditSheetState(meditation: meditation)

        // Then - Should use effective values (custom if set)
        XCTAssertEqual(state.editedTeacher, "Custom Teacher")
        XCTAssertEqual(state.editedName, "Custom Name")
    }

    func testInitializesWithOriginalWhenNoCustomValues() {
        // Given
        let meditation = self.makeTestMeditation(
            teacher: "Original Teacher",
            name: "Original Name"
        )

        // When
        let state = EditSheetState(meditation: meditation)

        // Then
        XCTAssertEqual(state.editedTeacher, "Original Teacher")
        XCTAssertEqual(state.editedName, "Original Name")
    }

    // MARK: - hasChanges Tests

    func testHasChangesIsFalseWhenUnchanged() {
        // Given
        let meditation = self.makeTestMeditation()
        let state = EditSheetState(meditation: meditation)

        // When / Then
        XCTAssertFalse(state.hasChanges)
    }

    func testHasChangesIsTrueWhenTeacherChanged() {
        // Given
        let meditation = self.makeTestMeditation()
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedTeacher = "New Teacher"

        // Then
        XCTAssertTrue(state.hasChanges)
    }

    func testHasChangesIsTrueWhenNameChanged() {
        // Given
        let meditation = self.makeTestMeditation()
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedName = "New Name"

        // Then
        XCTAssertTrue(state.hasChanges)
    }

    func testHasChangesIsTrueWhenBothChanged() {
        // Given
        let meditation = self.makeTestMeditation()
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedTeacher = "New Teacher"
        state.editedName = "New Name"

        // Then
        XCTAssertTrue(state.hasChanges)
    }

    // MARK: - isValid Tests

    func testIsValidWhenBothFieldsFilled() {
        // Given
        let meditation = self.makeTestMeditation()
        let state = EditSheetState(meditation: meditation)

        // When / Then
        XCTAssertTrue(state.isValid)
    }

    func testIsValidIsFalseWhenTeacherEmpty() {
        // Given
        let meditation = self.makeTestMeditation()
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedTeacher = ""

        // Then
        XCTAssertFalse(state.isValid)
    }

    func testIsValidIsFalseWhenNameEmpty() {
        // Given
        let meditation = self.makeTestMeditation()
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedName = ""

        // Then
        XCTAssertFalse(state.isValid)
    }

    func testIsValidIsFalseWhenBothEmpty() {
        // Given
        let meditation = self.makeTestMeditation()
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedTeacher = ""
        state.editedName = ""

        // Then
        XCTAssertFalse(state.isValid)
    }

    func testIsValidIsFalseWhenTeacherOnlyWhitespace() {
        // Given
        let meditation = self.makeTestMeditation()
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedTeacher = "   "

        // Then
        XCTAssertFalse(state.isValid)
    }

    func testIsValidIsFalseWhenNameOnlyWhitespace() {
        // Given
        let meditation = self.makeTestMeditation()
        var state = EditSheetState(meditation: meditation)

        // When
        state.editedName = "\t\n  "

        // Then
        XCTAssertFalse(state.isValid)
    }

    // MARK: - applyChanges Tests

    func testApplyChangesSetsCustomValuesWhenChanged() {
        // Given
        let meditation = self.makeTestMeditation()
        var state = EditSheetState(meditation: meditation)
        state.editedTeacher = "New Teacher"
        state.editedName = "New Name"

        // When
        let updated = state.applyChanges()

        // Then
        XCTAssertEqual(updated.customTeacher, "New Teacher")
        XCTAssertEqual(updated.customName, "New Name")
    }

    func testApplyChangesDoesNotSetCustomWhenUnchanged() {
        // Given
        let meditation = self.makeTestMeditation()
        let state = EditSheetState(meditation: meditation)

        // When
        let updated = state.applyChanges()

        // Then - Should be nil, not set to original value
        XCTAssertNil(updated.customTeacher)
        XCTAssertNil(updated.customName)
    }

    func testApplyChangesSetsOnlyChangedFields() {
        // Given
        let meditation = self.makeTestMeditation()
        var state = EditSheetState(meditation: meditation)
        state.editedTeacher = "New Teacher"
        // Name unchanged

        // When
        let updated = state.applyChanges()

        // Then
        XCTAssertEqual(updated.customTeacher, "New Teacher")
        XCTAssertNil(updated.customName)
    }

    func testApplyChangesPreservesOriginalMeditationId() {
        // Given
        let meditation = self.makeTestMeditation()
        var state = EditSheetState(meditation: meditation)
        state.editedTeacher = "New Teacher"

        // When
        let updated = state.applyChanges()

        // Then
        XCTAssertEqual(updated.id, meditation.id)
    }

    func testApplyChangesPreservesOtherFields() {
        // Given
        let meditation = self.makeTestMeditation()
        var state = EditSheetState(meditation: meditation)
        state.editedTeacher = "New Teacher"

        // When
        let updated = state.applyChanges()

        // Then
        XCTAssertEqual(updated.fileName, meditation.fileName)
        XCTAssertEqual(updated.duration, meditation.duration)
        XCTAssertEqual(updated.dateAdded, meditation.dateAdded)
        XCTAssertEqual(updated.fileBookmark, meditation.fileBookmark)
    }

    // MARK: - reset Tests

    func testResetRestoresOriginalValues() {
        // Given
        let meditation = self.makeTestMeditation(
            teacher: "Original Teacher",
            name: "Original Name"
        )
        var state = EditSheetState(meditation: meditation)
        state.editedTeacher = "Changed Teacher"
        state.editedName = "Changed Name"

        // When
        state.reset()

        // Then
        XCTAssertEqual(state.editedTeacher, "Original Teacher")
        XCTAssertEqual(state.editedName, "Original Name")
    }

    func testResetClearsHasChanges() {
        // Given
        let meditation = self.makeTestMeditation()
        var state = EditSheetState(meditation: meditation)
        state.editedTeacher = "Changed"
        XCTAssertTrue(state.hasChanges)

        // When
        state.reset()

        // Then
        XCTAssertFalse(state.hasChanges)
    }
}
