//
//  GuidedMeditationServiceTests+Advanced.swift
//  Still Moment
//
//  Advanced tests for GuidedMeditationService (file copy, local storage, persistence)
//  Note: File I/O operations are tested with temporary files

import XCTest
@testable import StillMoment

// MARK: - Meditations Directory Tests

extension GuidedMeditationServiceTests {
    func testGetMeditationsDirectory_ReturnsValidPath() {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        // When
        let directory = sut.getMeditationsDirectory()

        // Then
        XCTAssertTrue(directory.path.contains("Meditations"))
        XCTAssertTrue(directory.path.contains("Application Support"))
    }
}

// MARK: - Add Meditation Tests

extension GuidedMeditationServiceTests {
    func testAddMeditation_WithValidDraft_CreatesMeditation() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        // Create a temporary file for testing
        let tempURL = createTemporaryAudioFile()
        defer {
            try? FileManager.default.removeItem(at: tempURL)
            // Clean up copied file
            let meditationsDir = sut.getMeditationsDirectory()
            try? FileManager.default.removeItem(at: meditationsDir)
        }

        let draft = self.makeImportDraft(
            for: tempURL,
            teacher: "Test Teacher",
            name: "Test Meditation",
            duration: 600
        )

        // When
        let meditation = try sut.addMeditation(from: tempURL, draft: draft)

        // Then — the draft is persisted as-is, including its id
        XCTAssertEqual(meditation.id, draft.id)
        XCTAssertEqual(meditation.name, "Test Meditation")
        XCTAssertEqual(meditation.teacher, "Test Teacher")
        XCTAssertEqual(meditation.duration, 600)
        XCTAssertEqual(meditation.fileName, tempURL.lastPathComponent)
        XCTAssertNotNil(meditation.localFilePath)
        XCTAssertNotNil(sut.fileURL(for: meditation))

        // Verify it was saved
        let loaded = try sut.loadMeditations()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, meditation.id)
    }

    func testAddMeditation_PersistsTeacherAndNameVerbatim() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        let tempURL = createTemporaryAudioFile()
        defer {
            try? FileManager.default.removeItem(at: tempURL)
            let meditationsDir = sut.getMeditationsDirectory()
            try? FileManager.default.removeItem(at: meditationsDir)
        }

        // When — caller passes teacher/name in the draft directly.
        let meditation = try sut.addMeditation(
            from: tempURL,
            draft: self.makeImportDraft(for: tempURL, teacher: "Custom Teacher", name: "Custom Title")
        )

        // Then — service stores the caller-provided values; no implicit defaults.
        XCTAssertEqual(meditation.teacher, "Custom Teacher")
        XCTAssertEqual(meditation.name, "Custom Title")
    }

    func testAddMeditation_AcceptsEmptyTeacherAndName() throws {
        // Empty strings are a valid input — the Edit-Sheet (ios-044) is responsible for
        // validation. The service must not reject them.
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        let tempURL = createTemporaryAudioFile()
        defer {
            try? FileManager.default.removeItem(at: tempURL)
            let meditationsDir = sut.getMeditationsDirectory()
            try? FileManager.default.removeItem(at: meditationsDir)
        }

        let meditation = try sut.addMeditation(
            from: tempURL,
            draft: self.makeImportDraft(for: tempURL, teacher: "", name: "")
        )

        XCTAssertEqual(meditation.teacher, "")
        XCTAssertEqual(meditation.name, "")
    }

    func testAddMeditation_MultipleTimes_AppendsToCollection() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        let url1 = createTemporaryAudioFile(filename: "med1.mp3")
        let url2 = createTemporaryAudioFile(filename: "med2.mp3")
        defer {
            try? FileManager.default.removeItem(at: url1)
            try? FileManager.default.removeItem(at: url2)
            let meditationsDir = sut.getMeditationsDirectory()
            try? FileManager.default.removeItem(at: meditationsDir)
        }

        // When
        let med1 = try sut.addMeditation(
            from: url1,
            draft: self.makeImportDraft(for: url1, teacher: "Teacher", name: "First", duration: 300)
        )
        let med2 = try sut.addMeditation(
            from: url2,
            draft: self.makeImportDraft(for: url2, teacher: "Teacher", name: "Second", duration: 600)
        )

        // Then
        let loaded = try sut.loadMeditations()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertTrue(loaded.contains { $0.id == med1.id })
        XCTAssertTrue(loaded.contains { $0.id == med2.id })
    }

    func testAddMeditation_CopiesFileToMeditationsDirectory() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        let tempURL = createTemporaryAudioFile()
        defer {
            try? FileManager.default.removeItem(at: tempURL)
            let meditationsDir = sut.getMeditationsDirectory()
            try? FileManager.default.removeItem(at: meditationsDir)
        }

        // When
        let meditation = try sut.addMeditation(
            from: tempURL,
            draft: self.makeImportDraft(for: tempURL, teacher: "Teacher", name: "Test")
        )

        // Then - File should exist at resolved fileURL
        guard let fileURL = sut.fileURL(for: meditation) else {
            XCTFail("fileURL should not be nil")
            return
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
}

// MARK: - Persistence Edge Cases

extension GuidedMeditationServiceTests {
    func testSaveMeditations_EmptyArray_ClearsUserDefaults() throws {
        // Given - Start with some meditations
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let meditation = createTestMeditation(teacher: "Teacher", name: "Test")
        try sut.saveMeditations([meditation])

        // When - Save empty array
        try sut.saveMeditations([])

        // Then - Should clear everything
        let loaded = try sut.loadMeditations()
        XCTAssertTrue(loaded.isEmpty)
    }

    func testLoadMeditations_CalledMultipleTimes_ReturnsConsistentResults() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let meditation = createTestMeditation(teacher: "Teacher", name: "Test")
        try sut.saveMeditations([meditation])

        // When - Load multiple times
        let loaded1 = try sut.loadMeditations()
        let loaded2 = try sut.loadMeditations()
        let loaded3 = try sut.loadMeditations()

        // Then - Should return same data each time
        XCTAssertEqual(loaded1.count, loaded2.count)
        XCTAssertEqual(loaded2.count, loaded3.count)
        XCTAssertEqual(loaded1.first?.id, meditation.id)
        XCTAssertEqual(loaded2.first?.id, meditation.id)
        XCTAssertEqual(loaded3.first?.id, meditation.id)
    }

    func testService_WithMultipleInstances_SharesUserDefaults() throws {
        // Given - Two service instances with same UserDefaults
        guard let testUserDefaults else {
            XCTFail("Test UserDefaults not initialized")
            return
        }
        let service1 = GuidedMeditationService(userDefaults: testUserDefaults)
        let service2 = GuidedMeditationService(userDefaults: testUserDefaults)

        // When - Save with service1
        let meditation = createTestMeditation(teacher: "Teacher", name: "Test")
        try service1.saveMeditations([meditation])

        // Then - service2 should see the same data
        let loaded = try service2.loadMeditations()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, meditation.id)
    }

    func testDeleteMeditation_LastMeditation_ClearsLibrary() throws {
        // Given - Single meditation
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }
        let meditation = createTestMeditation(teacher: "Teacher", name: "Test")
        try sut.saveMeditations([meditation])

        // When - Delete the only meditation
        try sut.deleteMeditation(id: meditation.id)

        // Then - Library should be empty
        let loaded = try sut.loadMeditations()
        XCTAssertTrue(loaded.isEmpty)
    }
}

// MARK: - Helper Methods

extension GuidedMeditationServiceTests {
    func createTemporaryAudioFile(filename: String = "test_audio.mp3") -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        // Create empty file
        FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)

        return fileURL
    }

    /// Draft as the ViewModel builds it on import: file name from the URL, duration from the metadata.
    func makeImportDraft(
        for url: URL,
        teacher: String,
        name: String,
        duration: TimeInterval = 300
    ) -> GuidedMeditation {
        GuidedMeditation(
            localFilePath: "",
            fileName: url.lastPathComponent,
            duration: duration,
            teacher: teacher,
            name: name
        )
    }
}
