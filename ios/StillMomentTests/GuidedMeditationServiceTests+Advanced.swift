//
//  GuidedMeditationServiceTests+Advanced.swift
//  Still Moment
//
//  Advanced tests for GuidedMeditationService (security-scoped resources, bookmarks, persistence)
//  Note: File I/O and bookmark operations are tested with temporary files

import XCTest
@testable import StillMoment

// MARK: - Security-Scoped Resource Tests

extension GuidedMeditationServiceTests {
    func testStartAccessingSecurityScopedResource_ReturnsResult() {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        // Create a temporary file URL for testing
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test.mp3")

        // When
        let result = sut.startAccessingSecurityScopedResource(tempURL)

        // Then - Should return a Bool (true or false depending on URL)
        // On iOS simulator, this typically returns false for non-security-scoped URLs
        XCTAssertNotNil(result)

        // Clean up - safe to call even if not started
        sut.stopAccessingSecurityScopedResource(tempURL)
    }

    func testStopAccessingSecurityScopedResource_DoesNotCrash() {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test.mp3")

        // When - Call stop without corresponding start (should be safe)
        sut.stopAccessingSecurityScopedResource(tempURL)

        // Then - Should not crash (test passes if we reach here)
        XCTAssertTrue(true)
    }

    func testSecurityScopedResource_StartAndStop_Balanced() {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test.mp3")

        // When - Start and stop in balanced pairs
        _ = sut.startAccessingSecurityScopedResource(tempURL)
        sut.stopAccessingSecurityScopedResource(tempURL)

        _ = sut.startAccessingSecurityScopedResource(tempURL)
        sut.stopAccessingSecurityScopedResource(tempURL)

        // Then - Should not crash
        XCTAssertTrue(true)
    }
}

// MARK: - Add Meditation Tests

extension GuidedMeditationServiceTests {
    func testAddMeditation_WithValidMetadata_CreatesMeditation() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        // Create a temporary file for testing
        let tempURL = createTemporaryAudioFile()
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        let metadata = AudioMetadata(
            artist: "Test Teacher",
            title: "Test Meditation",
            duration: 600
        )

        // When
        let meditation = try sut.addMeditation(from: tempURL, metadata: metadata)

        // Then
        XCTAssertEqual(meditation.name, "Test Meditation")
        XCTAssertEqual(meditation.teacher, "Test Teacher")
        XCTAssertEqual(meditation.duration, 600)
        XCTAssertEqual(meditation.fileName, tempURL.lastPathComponent)
        XCTAssertFalse(meditation.fileBookmark.isEmpty)

        // Verify it was saved
        let loaded = try sut.loadMeditations()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, meditation.id)
    }

    func testAddMeditation_WithMissingTitle_UsesFilename() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        let tempURL = createTemporaryAudioFile(filename: "Awesome_Meditation.mp3")
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        let metadata = AudioMetadata(
            artist: "Teacher",
            title: nil, // No title
            duration: 300
        )

        // When
        let meditation = try sut.addMeditation(from: tempURL, metadata: metadata)

        // Then - Should use filename without extension
        XCTAssertEqual(meditation.name, "Awesome_Meditation")
        XCTAssertEqual(meditation.teacher, "Teacher")
    }

    func testAddMeditation_WithMissingArtist_UsesUnknownArtist() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        let tempURL = createTemporaryAudioFile()
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        let metadata = AudioMetadata(
            artist: nil, // No artist
            title: "Meditation",
            duration: 300
        )

        // When
        let meditation = try sut.addMeditation(from: tempURL, metadata: metadata)

        // Then - Should use "Unknown Artist"
        XCTAssertEqual(meditation.teacher, "Unknown Artist")
        XCTAssertEqual(meditation.name, "Meditation")
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
        }

        let metadata1 = AudioMetadata(artist: "Teacher", title: "First", duration: 300)
        let metadata2 = AudioMetadata(artist: "Teacher", title: "Second", duration: 600)

        // When
        let med1 = try sut.addMeditation(from: url1, metadata: metadata1)
        let med2 = try sut.addMeditation(from: url2, metadata: metadata2)

        // Then
        let loaded = try sut.loadMeditations()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertTrue(loaded.contains { $0.id == med1.id })
        XCTAssertTrue(loaded.contains { $0.id == med2.id })
    }
}

// MARK: - Resolve Bookmark Tests

extension GuidedMeditationServiceTests {
    func testResolveBookmark_WithValidBookmark_ReturnsURL() throws {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        // Create a temporary file and bookmark
        let tempURL = createTemporaryAudioFile()
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        let bookmarkData = try tempURL.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        // When
        let resolvedURL = try sut.resolveBookmark(bookmarkData)

        // Then
        XCTAssertEqual(resolvedURL.lastPathComponent, tempURL.lastPathComponent)
    }

    func testResolveBookmark_WithInvalidBookmark_ThrowsError() {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        // Create invalid bookmark data
        let invalidBookmark = Data("invalid bookmark data".utf8)

        // When/Then
        XCTAssertThrowsError(try sut.resolveBookmark(invalidBookmark)) { error in
            guard case GuidedMeditationError.bookmarkResolutionFailed = error else {
                XCTFail("Expected bookmarkResolutionFailed error")
                return
            }
        }
    }

    func testResolveBookmark_WithEmptyData_ThrowsError() {
        // Given
        guard let sut else {
            XCTFail("SUT not initialized")
            return
        }

        let emptyBookmark = Data()

        // When/Then
        XCTAssertThrowsError(try sut.resolveBookmark(emptyBookmark)) { error in
            guard case GuidedMeditationError.bookmarkResolutionFailed = error else {
                XCTFail("Expected bookmarkResolutionFailed error")
                return
            }
        }
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
}
