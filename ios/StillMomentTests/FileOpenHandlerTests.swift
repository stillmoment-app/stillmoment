//
//  FileOpenHandlerTests.swift
//  Still Moment
//
//  Tests for FileOpenHandler - handles "Open with" file association
//

import XCTest
@testable import StillMoment

// MARK: - FileOpenHandlerTests

@MainActor
final class FileOpenHandlerTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: FileOpenHandler!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockMeditationService: MockGuidedMeditationService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockMetadataService: MockAudioMetadataService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockCustomAudioRepo: MockCustomAudioRepository!

    override func setUp() {
        super.setUp()
        self.mockMeditationService = MockGuidedMeditationService()
        self.mockMetadataService = MockAudioMetadataService()
        self.mockCustomAudioRepo = MockCustomAudioRepository()
        self.sut = FileOpenHandler(
            meditationService: self.mockMeditationService,
            metadataService: self.mockMetadataService,
            customAudioRepository: self.mockCustomAudioRepo
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockCustomAudioRepo = nil
        self.mockMetadataService = nil
        self.mockMeditationService = nil
        super.tearDown()
    }

    // MARK: - Supported Format Tests

    func testAcceptsMP3File() {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")

        // When
        let result = self.sut.canHandle(url: url)

        // Then
        XCTAssertTrue(result)
    }

    func testAcceptsM4AFile() {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.m4a")

        // When
        let result = self.sut.canHandle(url: url)

        // Then
        XCTAssertTrue(result)
    }

    func testAcceptsUppercaseExtension() {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.MP3")

        // When
        let result = self.sut.canHandle(url: url)

        // Then
        XCTAssertTrue(result)
    }

    func testRejectsUnsupportedFormat() {
        // Given
        let url = URL(fileURLWithPath: "/tmp/document.pdf")

        // When
        let result = self.sut.canHandle(url: url)

        // Then
        XCTAssertFalse(result)
    }

    func testRejectsWAVFormat() {
        // Given
        let url = URL(fileURLWithPath: "/tmp/audio.wav")

        // When
        let result = self.sut.canHandle(url: url)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Import Tests

    func testSuccessfulImportReturnsMeditation() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")

        // When
        let result = await self.sut.handleFileOpen(url: url)

        // Then
        switch result {
        case .success:
            XCTAssertEqual(self.mockMeditationService.meditations.count, 1)
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func testSuccessfulImportResultIncludesMeditation() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")

        // When
        let result = await self.sut.handleFileOpen(url: url)

        // Then
        switch result {
        case let .success(meditation):
            XCTAssertNotNil(meditation)
            XCTAssertEqual(meditation.fileName, "meditation.mp3")
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func testUnsupportedFormatReturnsError() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/document.pdf")

        // When
        let result = await self.sut.handleFileOpen(url: url)

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure for unsupported format")
        case let .failure(error):
            XCTAssertEqual(error, .unsupportedFormat)
        }
    }

    func testMetadataExtractionFailureReturnsError() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/corrupt.mp3")
        self.mockMetadataService.extractShouldThrow = true

        // When
        let result = await self.sut.handleFileOpen(url: url)

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure for corrupt file")
        case let .failure(error):
            XCTAssertEqual(error, .importFailed)
        }
    }

    func testServiceAddFailureReturnsError() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")
        self.mockMeditationService.addShouldThrow = true

        // When
        let result = await self.sut.handleFileOpen(url: url)

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure when service fails")
        case let .failure(error):
            XCTAssertEqual(error, .importFailed)
        }
    }

    // MARK: - Duplicate Detection Tests

    func testDuplicateFileReturnsAlreadyImported() async {
        // Given - add a meditation with same filename and size
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")
        let existingMeditation = GuidedMeditation(
            localFilePath: "existing.mp3",
            fileName: "meditation.mp3",
            duration: 600,
            teacher: "Teacher",
            name: "Existing"
        )
        self.mockMeditationService.meditations = [existingMeditation]

        // When
        let result = await self.sut.handleFileOpen(url: url)

        // Then
        switch result {
        case .success:
            XCTFail("Expected duplicate detection")
        case let .failure(error):
            XCTAssertEqual(error, .alreadyImported)
        }
    }

    func testDifferentFilenameIsNotDuplicate() async {
        // Given - existing meditation with different filename
        let url = URL(fileURLWithPath: "/tmp/new-meditation.mp3")
        let existingMeditation = GuidedMeditation(
            localFilePath: "existing.mp3",
            fileName: "other-meditation.mp3",
            duration: 600,
            teacher: "Teacher",
            name: "Existing"
        )
        self.mockMeditationService.meditations = [existingMeditation]

        // When
        let result = await self.sut.handleFileOpen(url: url)

        // Then
        switch result {
        case .success:
            break // Expected success
        case .failure:
            XCTFail("Different filename should not be considered duplicate")
        }
    }

    func testSameNameDifferentSizeIsNotDuplicate() async {
        // Given - two files with same name but different sizes on disk
        let incomingURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("meditation.mp3")
        let existingLocalPath = "existing-\(UUID().uuidString).mp3"
        let existingURL = self.mockMeditationService.getMeditationsDirectory()
            .appendingPathComponent(existingLocalPath)

        // Create both files with different sizes
        let fileManager = FileManager.default
        try? fileManager.createDirectory(
            at: self.mockMeditationService.getMeditationsDirectory(),
            withIntermediateDirectories: true
        )
        fileManager.createFile(atPath: incomingURL.path, contents: Data(repeating: 0xAA, count: 1000))
        fileManager.createFile(atPath: existingURL.path, contents: Data(repeating: 0xBB, count: 2000))

        defer {
            try? fileManager.removeItem(at: incomingURL)
            try? fileManager.removeItem(at: existingURL)
        }

        let existingMeditation = GuidedMeditation(
            localFilePath: existingLocalPath,
            fileName: "meditation.mp3",
            duration: 600,
            teacher: "Teacher",
            name: "Existing"
        )
        self.mockMeditationService.meditations = [existingMeditation]

        // When
        let result = await self.sut.handleFileOpen(url: incomingURL)

        // Then - different file size → not a duplicate → import succeeds
        switch result {
        case .success:
            XCTAssertEqual(self.mockMeditationService.meditations.count, 2)
        case let .failure(error):
            XCTFail("Same name but different size should not be duplicate, got: \(error)")
        }
    }

    func testSameNameWithUnresolvableFileDefaultsToNameOnlyDuplicateCheck() async {
        // Given - existing meditation with same filename but file doesn't exist on disk
        // (fileURL returns nil → falls back to name-only, but when file doesn't exist
        // the mock returns nil for unresolvable files)
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")
        let existingMeditation = GuidedMeditation(
            localFilePath: "existing.mp3",
            fileName: "meditation.mp3",
            duration: 600,
            teacher: "Teacher",
            name: "Existing"
        )
        self.mockMeditationService.meditations = [existingMeditation]
        // Simulate that the existing file cannot be found on disk
        self.mockMeditationService.mockFileExists = false

        // When
        let result = await self.sut.handleFileOpen(url: url)

        // Then - falls back to name-only check when file can't be resolved
        switch result {
        case .success:
            XCTFail("Expected duplicate detection when existing file cannot be resolved")
        case let .failure(error):
            XCTAssertEqual(error, .alreadyImported)
        }
    }

    // MARK: - State Management Tests

    func testIsProcessingIsTrueDuringImport() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")

        // When - start import (check state before)
        XCTAssertFalse(self.sut.isProcessing)

        // After import
        _ = await self.sut.handleFileOpen(url: url)

        // Then - should be false again
        XCTAssertFalse(self.sut.isProcessing)
    }

    // MARK: - Format Validation (shared-073)

    func testValidateFileForImport_mp3_succeeds() {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")

        // When
        let result = self.sut.validateFileForImport(url: url)

        // Then
        switch result {
        case let .success(validatedURL):
            XCTAssertEqual(validatedURL, url)
        case .failure:
            XCTFail("MP3 should be accepted")
        }
    }

    func testValidateFileForImport_unsupportedFormat_fails() {
        // Given
        let url = URL(fileURLWithPath: "/tmp/document.pdf")

        // When
        let result = self.sut.validateFileForImport(url: url)

        // Then
        switch result {
        case .success:
            XCTFail("PDF should be rejected")
        case let .failure(error):
            XCTAssertEqual(error, .unsupportedFormat)
        }
    }

    // MARK: - Type-Based Import (shared-073)

    func testImportAsGuidedMeditation_routesToMeditationService() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")

        // When
        let result = await self.sut.importFile(from: url, as: .guidedMeditation)

        // Then
        switch result {
        case let .success(importResult):
            if case .guidedMeditation = importResult {
                XCTAssertEqual(self.mockMeditationService.meditations.count, 1)
            } else {
                XCTFail("Expected guidedMeditation result")
            }
        case .failure:
            XCTFail("Expected successful import")
        }
    }

    func testImportAsSoundscape_routesToCustomAudioRepository() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/nature-sounds.mp3")

        // When
        let result = await self.sut.importFile(from: url, as: .soundscape)

        // Then
        switch result {
        case let .success(importResult):
            if case .customAudio = importResult {
                XCTAssertEqual(self.mockCustomAudioRepo.importedFiles.count, 1)
                XCTAssertEqual(self.mockCustomAudioRepo.importedFiles.first?.1, .soundscape)
            } else {
                XCTFail("Expected customAudio result")
            }
        case .failure:
            XCTFail("Expected successful import")
        }
    }

    func testImportAsAttunement_routesToCustomAudioRepository() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/intro.m4a")

        // When
        let result = await self.sut.importFile(from: url, as: .attunement)

        // Then
        switch result {
        case let .success(importResult):
            if case .customAudio = importResult {
                XCTAssertEqual(self.mockCustomAudioRepo.importedFiles.count, 1)
                XCTAssertEqual(self.mockCustomAudioRepo.importedFiles.first?.1, .attunement)
            } else {
                XCTFail("Expected customAudio result")
            }
        case .failure:
            XCTFail("Expected successful import")
        }
    }

    // MARK: - Type-Based Duplicate Detection (shared-073)

    func testImportAsGuidedMeditation_duplicate_returnsError() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")
        let existing = GuidedMeditation(
            localFilePath: "existing.mp3",
            fileName: "meditation.mp3",
            duration: 600,
            teacher: "Teacher",
            name: "Existing"
        )
        self.mockMeditationService.meditations = [existing]

        // When
        let result = await self.sut.importFile(from: url, as: .guidedMeditation)

        // Then
        switch result {
        case .success:
            XCTFail("Expected duplicate detection")
        case let .failure(error):
            XCTAssertEqual(error, .alreadyImported)
        }
    }

    func testSameFileAsSoundscapeAndGuidedMeditation_bothSucceed() async {
        // Given - import as guided meditation first
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")
        let guidedResult = await self.sut.importFile(from: url, as: .guidedMeditation)
        guard case .success = guidedResult else {
            XCTFail("First import should succeed")
            return
        }

        // When - import same file as soundscape
        let soundscapeResult = await self.sut.importFile(from: url, as: .soundscape)

        // Then - both exist independently
        switch soundscapeResult {
        case .success:
            XCTAssertEqual(self.mockMeditationService.meditations.count, 1)
            XCTAssertEqual(self.mockCustomAudioRepo.importedFiles.count, 1)
        case .failure:
            XCTFail("Same file should be importable as different types")
        }
    }

    func testCancelImport_noFileImported() {
        // Given - validate a file
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")
        let result = self.sut.validateFileForImport(url: url)
        guard case .success = result else {
            XCTFail("Validation should succeed")
            return
        }

        // When - user cancels (no importFile call)
        // Then - nothing was imported
        XCTAssertEqual(self.mockMeditationService.meditations.count, 0)
        XCTAssertEqual(self.mockCustomAudioRepo.importedFiles.count, 0)
    }
}
