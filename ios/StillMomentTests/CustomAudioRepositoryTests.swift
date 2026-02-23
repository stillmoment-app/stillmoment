//
//  CustomAudioRepositoryTests.swift
//  Still Moment
//
//  Tests for CustomAudioRepository infrastructure service
//

import XCTest
@testable import StillMoment

final class CustomAudioRepositoryTests: XCTestCase {
    // MARK: - Properties

    private static let suiteName = "CustomAudioRepositoryTests"

    private var sut: CustomAudioRepository?
    private var tempDir: URL?
    private var testDefaults: UserDefaults?

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )
        self.tempDir = dir

        self.testDefaults = UserDefaults(suiteName: Self.suiteName)
        self.testDefaults?.removePersistentDomain(forName: Self.suiteName)

        if let defaults = testDefaults {
            self.sut = CustomAudioRepository(
                userDefaults: defaults,
                fileManager: .default
            )
        }
    }

    override func tearDown() {
        if let dir = tempDir {
            try? FileManager.default.removeItem(at: dir)
        }
        self.testDefaults?.removePersistentDomain(forName: Self.suiteName)
        self.testDefaults = nil
        self.sut = nil
        super.tearDown()
    }

    // MARK: - loadAll

    func testLoadAll_emptyRepository_returnsEmptyArray() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // When
        let result = sut.loadAll(type: .soundscape)

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testLoadAll_attunementType_returnsEmptyWhenOnlySoundscapesExist() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        let url = try createTempAudioFile(name: "sound.mp3")
        _ = try sut.importFile(from: url, type: .soundscape)

        // When
        let attunements = sut.loadAll(type: .attunement)

        // Then
        XCTAssertTrue(attunements.isEmpty)
    }

    func testLoadAll_returnsOnlyMatchingType() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        let soundscapeURL = try createTempAudioFile(name: "bg-sound.mp3")
        let attunementURL = try createTempAudioFile(name: "intro.mp3")
        _ = try sut.importFile(from: soundscapeURL, type: .soundscape)
        _ = try sut.importFile(from: attunementURL, type: .attunement)

        // When
        let soundscapes = sut.loadAll(type: .soundscape)
        let attunements = sut.loadAll(type: .attunement)

        // Then
        XCTAssertEqual(soundscapes.count, 1)
        XCTAssertEqual(attunements.count, 1)
        XCTAssertEqual(soundscapes.first?.name, "bg-sound")
        XCTAssertEqual(attunements.first?.name, "intro")
    }

    func testLoadAll_sortedByDateAddedDescending() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given - import two files sequentially
        let url1 = try createTempAudioFile(name: "first.mp3")
        _ = try sut.importFile(from: url1, type: .soundscape)

        // Small delay to ensure different timestamps
        Thread.sleep(forTimeInterval: 0.01)
        let url2 = try createTempAudioFile(name: "second.mp3")
        _ = try sut.importFile(from: url2, type: .soundscape)

        // When
        let loaded = sut.loadAll(type: .soundscape)

        // Then - most recently added first
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded.first?.name, "second")
        XCTAssertEqual(loaded.last?.name, "first")
    }

    // MARK: - importFile

    func testImportFile_mp3_succeeds() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        let url = try createTempAudioFile(name: "my-sound.mp3")

        // When
        let result = try sut.importFile(from: url, type: .soundscape)

        // Then
        XCTAssertEqual(result.name, "my-sound")
        XCTAssertEqual(result.type, .soundscape)
        XCTAssertFalse(result.filename.isEmpty)
        XCTAssertTrue(result.filename.hasSuffix(".mp3"))
    }

    func testImportFile_m4a_succeeds() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        let url = try createTempAudioFile(name: "sound.m4a")

        // When
        let result = try sut.importFile(from: url, type: .attunement)

        // Then
        XCTAssertEqual(result.type, .attunement)
        XCTAssertTrue(result.filename.hasSuffix(".m4a"))
    }

    func testImportFile_wav_succeeds() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        let url = try createTempAudioFile(name: "sound.wav")

        // When
        let result = try sut.importFile(from: url, type: .soundscape)

        // Then
        XCTAssertEqual(result.name, "sound")
        XCTAssertTrue(result.filename.hasSuffix(".wav"))
    }

    func testImportFile_unsupportedFormat_throwsError() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        let url = try createTempAudioFile(name: "sound.ogg")

        // When / Then
        XCTAssertThrowsError(try sut.importFile(from: url, type: .soundscape)) { error in
            guard case CustomAudioError.unsupportedFormat = error else {
                return XCTFail("Expected unsupportedFormat error, got \(error)")
            }
        }
    }

    func testImportFile_caseInsensitiveExtension_mp3Uppercase_succeeds() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given - the file extension is uppercase but should still be recognized
        let url = try createTempAudioFile(name: "sound.MP3")

        // When / Then - the repo lowercases the extension before checking
        let result = try sut.importFile(from: url, type: .soundscape)
        XCTAssertEqual(result.name, "sound")
    }

    func testImportFile_persistsAcrossRepositoryInstances() throws {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given
        let url = try createTempAudioFile(name: "persisted.mp3")
        _ = try sut.importFile(from: url, type: .soundscape)

        // When - create a fresh repository with the same UserDefaults
        let repo2 = CustomAudioRepository(
            userDefaults: testDefaults,
            fileManager: .default
        )
        let loaded = repo2.loadAll(type: .soundscape)

        // Then
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.name, "persisted")
    }

    func testImportFile_sameFileTwice_createsTwoEntries() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        let url1 = try createTempAudioFile(name: "sound.mp3")
        let url2 = try createTempAudioFile(name: "sound.mp3")

        // When
        let first = try sut.importFile(from: url1, type: .soundscape)
        let second = try sut.importFile(from: url2, type: .soundscape)

        // Then - both have the same name but different IDs (duplicate import allowed)
        XCTAssertEqual(first.name, second.name)
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(sut.loadAll(type: .soundscape).count, 2)
    }

    func testImportFile_dummyData_durationIsNil() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given - our temp files contain text, not real audio
        let url = try createTempAudioFile(name: "not-real-audio.mp3")

        // When
        let result = try sut.importFile(from: url, type: .soundscape)

        // Then - duration detection fails gracefully for non-audio data
        XCTAssertNil(result.duration)
    }

    // MARK: - delete

    func testDelete_existingFile_removesFromList() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        let url = try createTempAudioFile(name: "deletable.mp3")
        let imported = try sut.importFile(from: url, type: .soundscape)

        // When
        try sut.delete(id: imported.id)

        // Then
        XCTAssertTrue(sut.loadAll(type: .soundscape).isEmpty)
    }

    func testDelete_nonExistentId_throwsFileNotFound() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // When / Then
        XCTAssertThrowsError(try sut.delete(id: UUID())) { error in
            guard case CustomAudioError.fileNotFound = error else {
                return XCTFail("Expected fileNotFound error, got \(error)")
            }
        }
    }

    func testDelete_onlyRemovesTargetFile_leavesOthers() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        let url1 = try createTempAudioFile(name: "keep.mp3")
        let url2 = try createTempAudioFile(name: "delete.mp3")
        _ = try sut.importFile(from: url1, type: .soundscape)
        let toDelete = try sut.importFile(from: url2, type: .soundscape)

        // When
        try sut.delete(id: toDelete.id)

        // Then
        let remaining = sut.loadAll(type: .soundscape)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.name, "keep")
    }

    func testDelete_persistsAcrossRepositoryInstances() throws {
        guard let sut, let testDefaults else {
            return XCTFail("sut not initialized")
        }

        // Given
        let url = try createTempAudioFile(name: "temp.mp3")
        let imported = try sut.importFile(from: url, type: .attunement)
        try sut.delete(id: imported.id)

        // When - create fresh repository
        let repo2 = CustomAudioRepository(
            userDefaults: testDefaults,
            fileManager: .default
        )

        // Then
        XCTAssertTrue(repo2.loadAll(type: .attunement).isEmpty)
    }

    // MARK: - findFile

    func testFindFile_existingId_returnsFile() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        let url = try createTempAudioFile(name: "findme.mp3")
        let imported = try sut.importFile(from: url, type: .soundscape)

        // When
        let found = sut.findFile(byId: imported.id)

        // Then
        XCTAssertEqual(found?.id, imported.id)
        XCTAssertEqual(found?.name, "findme")
    }

    func testFindFile_nonExistentId_returnsNil() {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // When / Then
        XCTAssertNil(sut.findFile(byId: UUID()))
    }

    func testFindFile_searchesAcrossTypes() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given - file stored as attunement
        let url = try createTempAudioFile(name: "cross-type.mp3")
        let imported = try sut.importFile(from: url, type: .attunement)

        // When - search without specifying type
        let found = sut.findFile(byId: imported.id)

        // Then
        XCTAssertEqual(found?.type, .attunement)
    }

    // MARK: - fileURL

    func testFileURL_existingFile_returnsAccessibleURL() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        let url = try createTempAudioFile(name: "accessible.mp3")
        let imported = try sut.importFile(from: url, type: .soundscape)

        // When
        let fileURL = sut.fileURL(for: imported)

        // Then
        let unwrappedURL = try XCTUnwrap(fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: unwrappedURL.path))
    }

    func testFileURL_deletedFile_returnsNil() throws {
        guard let sut else {
            return XCTFail("sut not initialized")
        }

        // Given
        let url = try createTempAudioFile(name: "will-delete.mp3")
        let imported = try sut.importFile(from: url, type: .soundscape)
        try sut.delete(id: imported.id)

        // When
        let fileURL = sut.fileURL(for: imported)

        // Then
        XCTAssertNil(fileURL)
    }

    // MARK: - CustomAudioError

    func testUnsupportedFormatError_hasLocalizedDescription() {
        // Given
        let error = CustomAudioError.unsupportedFormat("ogg")

        // When / Then
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func testFileNotFoundError_hasLocalizedDescription() {
        // Given
        let error = CustomAudioError.fileNotFound(UUID())

        // When / Then
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    // MARK: - Helpers

    private func createTempAudioFile(name: String) throws -> URL {
        let dir = try XCTUnwrap(self.tempDir)
        let url = dir.appendingPathComponent(name)
        try "dummy audio data".write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
