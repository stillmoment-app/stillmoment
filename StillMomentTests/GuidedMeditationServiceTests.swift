//
//  GuidedMeditationServiceTests.swift
//  Still Moment
//
//  Tests for GuidedMeditationService business logic (persistence, CRUD operations, sorting)
//  Note: File I/O and bookmark operations are excluded (require simulator/real files)

import XCTest
@testable import StillMoment

final class GuidedMeditationServiceTests: XCTestCase {
    // MARK: Internal

    var sut: GuidedMeditationService?
    var testUserDefaults: UserDefaults?

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Create isolated UserDefaults for testing
        let suiteName = "test.stillmoment.GuidedMeditationServiceTests.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        self.testUserDefaults = userDefaults
        self.testUserDefaults?.removePersistentDomain(forName: suiteName)

        self.sut = GuidedMeditationService(userDefaults: userDefaults)
    }

    override func tearDown() {
        // Clean up test data
        if let suiteName = testUserDefaults.dictionaryRepresentation().keys.first {
            self.testUserDefaults.removePersistentDomain(forName: suiteName)
        }
        self.testUserDefaults = nil
        self.sut = nil

        super.tearDown()
    }

    // MARK: - Load Tests

    func testLoadMeditations_EmptyUserDefaults_ReturnsEmptyArray() throws {
        // Given - Fresh UserDefaults (no data)
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When
        let meditations = try sut.loadMeditations()

        // Then
        XCTAssertTrue(meditations.isEmpty)
    }

    func testLoadMeditations_ValidData_ReturnsDecodedMeditations() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let meditation1 = self.createTestMeditation(teacher: "Teacher A", name: "Meditation 1")
        let meditation2 = self.createTestMeditation(teacher: "Teacher B", name: "Meditation 2")
        try sut.saveMeditations([meditation1, meditation2])

        // When
        let loaded = try sut.loadMeditations()

        // Then
        XCTAssertEqual(loaded.count, 2)
        XCTAssertTrue(loaded.contains { $0.id == meditation1.id })
        XCTAssertTrue(loaded.contains { $0.id == meditation2.id })
    }

    func testLoadMeditations_InvalidJSON_ThrowsPersistenceFailed() throws {
        // Given - Store invalid JSON data
        guard let sut, let testUserDefaults else {
            XCTFail("SUT not initialized")
            return
        }
        testUserDefaults.set(Data("invalid json".utf8), forKey: "guidedMeditationsLibrary")

        // When/Then
        XCTAssertThrowsError(try sut.loadMeditations()) { error in
            guard case GuidedMeditationError.persistenceFailed = error else {
                XCTFail("Expected persistenceFailed error")
                return
            }
        }
    }

    // MARK: - Save Tests

    func testSaveMeditations_ValidData_PersistsToUserDefaults() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let meditation = self.createTestMeditation(teacher: "Teacher", name: "Test")

        // When
        try sut.saveMeditations([meditation])

        // Then - Verify persistence by loading
        let loaded = try sut.loadMeditations()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, meditation.id)
        XCTAssertEqual(loaded.first?.teacher, "Teacher")
        XCTAssertEqual(loaded.first?.name, "Test")
    }

    func testSaveMeditations_MultipleMeditations_PersistsAll() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let meditation1 = self.createTestMeditation(teacher: "A", name: "First")
        let meditation2 = self.createTestMeditation(teacher: "B", name: "Second")
        let meditation3 = self.createTestMeditation(teacher: "C", name: "Third")

        // When
        try sut.saveMeditations([meditation1, meditation2, meditation3])

        // Then
        let loaded = try sut.loadMeditations()
        XCTAssertEqual(loaded.count, 3)
    }

    // MARK: - Update Tests

    func testUpdateMeditation_ExistingID_UpdatesMeditation() throws {
        // Given - Save initial meditation
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let originalID = UUID()
        let original = self.createTestMeditation(id: originalID, teacher: "Original", name: "Original")
        try sut.saveMeditations([original])

        // When - Update with same ID but different properties
        var updated = original
        updated.teacher = "Updated Teacher"
        updated.name = "Updated Name"
        try sut.updateMeditation(updated)

        // Then
        let loaded = try sut.loadMeditations()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, originalID)
        XCTAssertEqual(loaded.first?.teacher, "Updated Teacher")
        XCTAssertEqual(loaded.first?.name, "Updated Name")
    }

    func testUpdateMeditation_NonExistingID_ThrowsMeditationNotFound() throws {
        // Given - Save one meditation
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let existing = self.createTestMeditation(teacher: "Existing", name: "Existing")
        try sut.saveMeditations([existing])

        // When - Try to update with non-existing ID
        let nonExisting = self.createTestMeditation(id: UUID(), teacher: "Non-Existing", name: "Non-Existing")

        // Then
        XCTAssertThrowsError(try sut.updateMeditation(nonExisting)) { error in
            guard case let GuidedMeditationError.meditationNotFound(id) = error else {
                XCTFail("Expected meditationNotFound error")
                return
            }
            XCTAssertEqual(id, nonExisting.id)
        }
    }

    func testUpdateMeditation_MultipleItems_OnlyUpdatesCorrectOne() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let id1 = UUID()
        let id2 = UUID()
        let meditation1 = self.createTestMeditation(id: id1, teacher: "Teacher 1", name: "Name 1")
        let meditation2 = self.createTestMeditation(id: id2, teacher: "Teacher 2", name: "Name 2")
        try sut.saveMeditations([meditation1, meditation2])

        // When - Update only meditation1
        var updated = meditation1
        updated.teacher = "Updated Teacher"
        try sut.updateMeditation(updated)

        // Then
        let loaded = try sut.loadMeditations()
        let loadedMed1 = loaded.first { $0.id == id1 }
        let loadedMed2 = loaded.first { $0.id == id2 }

        XCTAssertEqual(loadedMed1?.teacher, "Updated Teacher")
        XCTAssertEqual(loadedMed2?.teacher, "Teacher 2") // Unchanged
    }

    // MARK: - Delete Tests

    func testDeleteMeditation_ExistingID_RemovesMeditation() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let meditation = self.createTestMeditation(teacher: "Test", name: "Test")
        try sut.saveMeditations([meditation])

        // When
        try sut.deleteMeditation(id: meditation.id)

        // Then
        let loaded = try sut.loadMeditations()
        XCTAssertTrue(loaded.isEmpty)
    }

    func testDeleteMeditation_NonExistingID_ThrowsMeditationNotFound() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let meditation = self.createTestMeditation(teacher: "Test", name: "Test")
        try sut.saveMeditations([meditation])

        // When/Then
        let nonExistingID = UUID()
        XCTAssertThrowsError(try sut.deleteMeditation(id: nonExistingID)) { error in
            guard case let GuidedMeditationError.meditationNotFound(id) = error else {
                XCTFail("Expected meditationNotFound error")
                return
            }
            XCTAssertEqual(id, nonExistingID)
        }
    }

    func testDeleteMeditation_MultipleItems_OnlyDeletesCorrectOne() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let id1 = UUID()
        let id2 = UUID()
        let meditation1 = self.createTestMeditation(id: id1, teacher: "Teacher 1", name: "Name 1")
        let meditation2 = self.createTestMeditation(id: id2, teacher: "Teacher 2", name: "Name 2")
        try sut.saveMeditations([meditation1, meditation2])

        // When - Delete only meditation1
        try sut.deleteMeditation(id: id1)

        // Then
        let loaded = try sut.loadMeditations()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, id2)
        XCTAssertEqual(loaded.first?.teacher, "Teacher 2")
    }

    // MARK: - Sorting Tests

    func testLoadMeditations_SortsByTeacher_ThenName() throws {
        // Given - Deliberately unsorted meditations
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let med1 = self.createTestMeditation(teacher: "Zulu", name: "Alpha")
        let med2 = self.createTestMeditation(teacher: "Alpha", name: "Zulu")
        let med3 = self.createTestMeditation(teacher: "Alpha", name: "Alpha")
        let med4 = self.createTestMeditation(teacher: "Bravo", name: "Charlie")

        // Save in random order
        try sut.saveMeditations([med1, med2, med3, med4])

        // When
        let loaded = try sut.loadMeditations()

        // Then - Should be sorted: Alpha/Alpha, Alpha/Zulu, Bravo/Charlie, Zulu/Alpha
        XCTAssertEqual(loaded.count, 4)
        XCTAssertEqual(loaded[0].teacher, "Alpha")
        XCTAssertEqual(loaded[0].name, "Alpha")
        XCTAssertEqual(loaded[1].teacher, "Alpha")
        XCTAssertEqual(loaded[1].name, "Zulu")
        XCTAssertEqual(loaded[2].teacher, "Bravo")
        XCTAssertEqual(loaded[2].name, "Charlie")
        XCTAssertEqual(loaded[3].teacher, "Zulu")
        XCTAssertEqual(loaded[3].name, "Alpha")
    }

    func testLoadMeditations_SortingIsCaseInsensitive() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let med1 = self.createTestMeditation(teacher: "beta", name: "item")
        let med2 = self.createTestMeditation(teacher: "Alpha", name: "item")
        let med3 = self.createTestMeditation(teacher: "CHARLIE", name: "item")

        try sut.saveMeditations([med1, med2, med3])

        // When
        let loaded = try sut.loadMeditations()

        // Then - Should be sorted alphabetically ignoring case
        XCTAssertEqual(loaded[0].teacher, "Alpha")
        XCTAssertEqual(loaded[1].teacher, "beta")
        XCTAssertEqual(loaded[2].teacher, "CHARLIE")
    }

    func testLoadMeditations_UsesEffectiveTeacherForSorting() throws {
        // Given - Meditation with customTeacher set
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        var med1 = self.createTestMeditation(teacher: "Zulu", name: "Test")
        med1.customTeacher = "Alpha" // Override to "Alpha"

        let med2 = self.createTestMeditation(teacher: "Bravo", name: "Test")

        try sut.saveMeditations([med1, med2])

        // When
        let loaded = try sut.loadMeditations()

        // Then - Should sort by effectiveTeacher (Alpha comes before Bravo)
        XCTAssertEqual(loaded[0].effectiveTeacher, "Alpha")
        XCTAssertEqual(loaded[1].effectiveTeacher, "Bravo")
    }

    func testLoadMeditations_UsesEffectiveNameForSorting() throws {
        // Given - Two meditations with same teacher, different names
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        var med1 = self.createTestMeditation(teacher: "Teacher", name: "Zulu")
        med1.customName = "Alpha" // Override to "Alpha"

        let med2 = self.createTestMeditation(teacher: "Teacher", name: "Bravo")

        try sut.saveMeditations([med1, med2])

        // When
        let loaded = try sut.loadMeditations()

        // Then - Should sort by effectiveName (Alpha comes before Bravo)
        XCTAssertEqual(loaded[0].effectiveName, "Alpha")
        XCTAssertEqual(loaded[1].effectiveName, "Bravo")
    }

    // MARK: Private

    // MARK: - Helper Methods

    private func createTestMeditation(
        id: UUID = UUID(),
        teacher: String,
        name: String,
        duration: TimeInterval = 600
    ) -> GuidedMeditation {
        GuidedMeditation(
            id: id,
            fileBookmark: Data(),
            fileName: "\(name).mp3",
            duration: duration,
            teacher: teacher,
            name: name
        )
    }
}
