//
//  FileOpenHandlerTests.swift
//  Still Moment
//
//  Tests for FileOpenHandler - handles share/"open with" imports.
//

import XCTest
@testable import StillMoment

@MainActor
final class FileOpenHandlerTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: FileOpenHandler!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockMeditationService: MockGuidedMeditationService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockMetadataService: MockAudioMetadataService!

    override func setUp() {
        super.setUp()
        self.mockMeditationService = MockGuidedMeditationService()
        self.mockMetadataService = MockAudioMetadataService()
        self.sut = FileOpenHandler(
            meditationService: self.mockMeditationService,
            metadataService: self.mockMetadataService
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockMetadataService = nil
        self.mockMeditationService = nil
        super.tearDown()
    }

    // MARK: - Supported Formats

    func testAcceptsMP3File() {
        XCTAssertTrue(self.sut.canHandle(url: URL(fileURLWithPath: "/tmp/meditation.mp3")))
    }

    func testAcceptsM4AFile() {
        XCTAssertTrue(self.sut.canHandle(url: URL(fileURLWithPath: "/tmp/meditation.m4a")))
    }

    func testAcceptsUppercaseExtension() {
        XCTAssertTrue(self.sut.canHandle(url: URL(fileURLWithPath: "/tmp/meditation.MP3")))
    }

    func testRejectsUnsupportedFormat() {
        XCTAssertFalse(self.sut.canHandle(url: URL(fileURLWithPath: "/tmp/document.pdf")))
    }

    func testRejectsWAVFormat() {
        XCTAssertFalse(self.sut.canHandle(url: URL(fileURLWithPath: "/tmp/audio.wav")))
    }

    // MARK: - Duplicate Detection

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
        let result = await self.sut.importFile(from: url)

        // Then
        guard case .success = result else {
            XCTFail("Different filename should import successfully, got \(result)")
            return
        }
    }

    func testSameNameDifferentSizeIsNotDuplicate() async {
        // Given - two files with same name but different sizes on disk
        let incomingURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("meditation.mp3")
        let existingLocalPath = "existing-\(UUID().uuidString).mp3"
        let existingURL = self.mockMeditationService.getMeditationsDirectory()
            .appendingPathComponent(existingLocalPath)

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
        let result = await self.sut.importFile(from: incomingURL)

        // Then
        guard case .success = result else {
            XCTFail("Same name but different size should import, got \(result)")
            return
        }
        XCTAssertEqual(self.mockMeditationService.meditations.count, 2)
    }

    func testSameNameWithUnresolvableFileDefaultsToNameOnlyDuplicateCheck() async {
        // Given - existing meditation with same filename but file doesn't exist on disk
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")
        let existingMeditation = GuidedMeditation(
            localFilePath: "existing.mp3",
            fileName: "meditation.mp3",
            duration: 600,
            teacher: "Teacher",
            name: "Existing"
        )
        self.mockMeditationService.meditations = [existingMeditation]
        self.mockMeditationService.mockFileExists = false

        // When
        let result = await self.sut.importFile(from: url)

        // Then - falls back to name-only check when file can't be resolved
        guard case let .failure(error) = result else {
            XCTFail("Expected duplicate detection when existing file cannot be resolved")
            return
        }
        guard case .alreadyImported = error else {
            XCTFail("Expected alreadyImported, got \(error)")
            return
        }
    }

    // MARK: - Service Failures

    func testServiceAddFailureReturnsError() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")
        self.mockMeditationService.addShouldThrow = true

        // When
        let result = await self.sut.importFile(from: url)

        // Then
        guard case let .failure(error) = result else {
            XCTFail("Expected failure, got \(result)")
            return
        }
        XCTAssertEqual(error, .importFailed)
    }

    // MARK: - State Management

    func testIsProcessingIsResetAfterImport() async {
        // Given
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")
        XCTAssertFalse(self.sut.isProcessing)

        // When
        _ = await self.sut.importFile(from: url)

        // Then
        XCTAssertFalse(self.sut.isProcessing)
    }

    // MARK: - Format Validation (used by InboxHandler defense-in-depth)

    func testValidateFileForImport_mp3_succeeds() {
        let url = URL(fileURLWithPath: "/tmp/meditation.mp3")
        guard case let .success(validatedURL) = self.sut.validateFileForImport(url: url) else {
            XCTFail("MP3 should be accepted")
            return
        }
        XCTAssertEqual(validatedURL, url)
    }

    func testValidateFileForImport_unsupportedFormat_fails() {
        let url = URL(fileURLWithPath: "/tmp/document.pdf")
        guard case let .failure(error) = self.sut.validateFileForImport(url: url) else {
            XCTFail("PDF should be rejected")
            return
        }
        XCTAssertEqual(error, .unsupportedFormat)
    }
}
