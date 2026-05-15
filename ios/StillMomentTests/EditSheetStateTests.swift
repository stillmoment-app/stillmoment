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
        name: String = "Original Name"
    ) -> GuidedMeditation {
        GuidedMeditation(
            fileBookmark: Data(),
            fileName: "test.mp3",
            duration: 600,
            teacher: teacher,
            name: name
        )
    }

    // MARK: - Initialization Tests

    func testInitializesWithMeditationValues() {
        // Given
        let meditation = self.makeTestMeditation(
            teacher: "Tara Brach",
            name: "Body Scan"
        )

        // When
        let state = EditSheetState(meditation: meditation)

        // Then
        XCTAssertEqual(state.editedTeacher, "Tara Brach")
        XCTAssertEqual(state.editedName, "Body Scan")
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

    func testApplyChangesSetsEditedValuesDirectly() {
        // Given
        let meditation = self.makeTestMeditation()
        var state = EditSheetState(meditation: meditation)
        state.editedTeacher = "New Teacher"
        state.editedName = "New Name"

        // When
        let updated = state.applyChanges()

        // Then
        XCTAssertEqual(updated.teacher, "New Teacher")
        XCTAssertEqual(updated.name, "New Name")
    }

    func testApplyChangesReturnsOriginalValuesWhenUnchanged() {
        // Given
        let meditation = self.makeTestMeditation()
        let state = EditSheetState(meditation: meditation)

        // When
        let updated = state.applyChanges()

        // Then
        XCTAssertEqual(updated.teacher, meditation.teacher)
        XCTAssertEqual(updated.name, meditation.name)
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
}
