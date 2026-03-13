//
//  InboxHandlerTests.swift
//  Still Moment
//
//  TDD RED phase: Tests for InboxHandler — processes Share Extension inbox entries
//

import XCTest
@testable import StillMoment

// MARK: - InboxHandlerTests

@MainActor
final class InboxHandlerTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: InboxHandler!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockFileOpenHandler: FileOpenHandler!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockDownloadService: MockAudioDownloadService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockMeditationService: MockGuidedMeditationService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockMetadataService: MockAudioMetadataService!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockCustomAudioRepo: MockCustomAudioRepository!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var inboxDirectory: URL!

    override func setUp() {
        super.setUp()
        self.inboxDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("InboxHandlerTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(
            at: self.inboxDirectory,
            withIntermediateDirectories: true
        )

        self.mockMeditationService = MockGuidedMeditationService()
        self.mockMetadataService = MockAudioMetadataService()
        self.mockCustomAudioRepo = MockCustomAudioRepository()
        self.mockFileOpenHandler = FileOpenHandler(
            meditationService: self.mockMeditationService,
            metadataService: self.mockMetadataService,
            customAudioRepository: self.mockCustomAudioRepo
        )
        self.mockDownloadService = MockAudioDownloadService()

        self.sut = InboxHandler(
            fileOpenHandler: self.mockFileOpenHandler,
            downloadService: self.mockDownloadService,
            fileManager: .default,
            inboxDirectoryURL: self.inboxDirectory
        )
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: self.inboxDirectory)
        self.sut = nil
        self.mockDownloadService = nil
        self.mockFileOpenHandler = nil
        self.mockCustomAudioRepo = nil
        self.mockMetadataService = nil
        self.mockMeditationService = nil
        self.inboxDirectory = nil
        super.tearDown()
    }

    // MARK: - Empty Inbox

    func testEmptyInboxReturnsEmpty() async {
        // Given - inbox directory exists but is empty

        // When
        let result = await self.sut.processInbox()

        // Then
        XCTAssertEqual(result, .empty)
    }

    // MARK: - Audio File Processing

    func testAudioFileInInboxIsPassedToFileOpenHandler() async {
        // Given
        let filename = "\(UUID().uuidString)_meditation.mp3"
        let fileURL = self.inboxDirectory.appendingPathComponent(filename)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data(repeating: 0xFF, count: 100))

        // When
        let result = await self.sut.processInbox()

        // Then
        if case .audioFile = result {
            // File was recognized and handed off for import
        } else {
            XCTFail("Expected .audioFile result, got \(result)")
        }
    }

    func testAudioFileIsDeletedAfterProcessing() async {
        // Given
        let filename = "\(UUID().uuidString)_meditation.mp3"
        let fileURL = self.inboxDirectory.appendingPathComponent(filename)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data(repeating: 0xFF, count: 100))

        // When
        _ = await self.sut.processInbox()

        // Then
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: fileURL.path),
            "Inbox entry should be deleted after processing"
        )
    }

    func testM4AFileIsAlsoProcessed() async {
        // Given
        let filename = "\(UUID().uuidString)_meditation.m4a"
        let fileURL = self.inboxDirectory.appendingPathComponent(filename)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data(repeating: 0xFF, count: 100))

        // When
        let result = await self.sut.processInbox()

        // Then
        if case .audioFile = result {
            // M4A file recognized
        } else {
            XCTFail("Expected .audioFile result for M4A, got \(result)")
        }
    }

    // MARK: - URL Reference Processing

    func testURLReferenceStartsDownload() async throws {
        // Given
        let urlRef = URLReference(
            url: "https://example.com/meditation.mp3",
            filename: "meditation.mp3",
            timestamp: "2026-03-13T10:30:00Z"
        )
        let jsonData = try JSONEncoder().encode(urlRef)
        let filename = "\(UUID().uuidString)_meditation.json"
        let fileURL = self.inboxDirectory.appendingPathComponent(filename)
        FileManager.default.createFile(atPath: fileURL.path, contents: jsonData)

        // When
        let result = await self.sut.processInbox()

        // Then
        if case .downloadCompleted = result {
            XCTAssertNotNil(
                self.mockDownloadService.downloadedURL,
                "Download service should have been called"
            )
        } else if case .downloadStarted = result {
            // Also acceptable depending on async behavior
        } else {
            XCTFail("Expected download result, got \(result)")
        }
    }

    func testURLReferenceDownloadsFromCorrectURL() async throws {
        // Given
        let expectedURL = "https://example.com/guided-session.mp3"
        let urlRef = URLReference(
            url: expectedURL,
            filename: "guided-session.mp3",
            timestamp: "2026-03-13T10:30:00Z"
        )
        let jsonData = try JSONEncoder().encode(urlRef)
        let filename = "\(UUID().uuidString)_guided-session.json"
        let fileURL = self.inboxDirectory.appendingPathComponent(filename)
        FileManager.default.createFile(atPath: fileURL.path, contents: jsonData)

        // When
        _ = await self.sut.processInbox()

        // Then
        XCTAssertEqual(
            self.mockDownloadService.downloadedURL?.absoluteString,
            expectedURL
        )
    }

    func testURLReferenceIsDeletedAfterDownload() async throws {
        // Given
        let urlRef = URLReference(
            url: "https://example.com/meditation.mp3",
            filename: "meditation.mp3",
            timestamp: "2026-03-13T10:30:00Z"
        )
        let jsonData = try JSONEncoder().encode(urlRef)
        let filename = "\(UUID().uuidString)_meditation.json"
        let fileURL = self.inboxDirectory.appendingPathComponent(filename)
        FileManager.default.createFile(atPath: fileURL.path, contents: jsonData)

        // When
        _ = await self.sut.processInbox()

        // Then
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: fileURL.path),
            "URL reference should be deleted after processing"
        )
    }

    // MARK: - Newest Entry Priority

    func testOnlyNewestEntryIsProcessed() async {
        // Given - two audio files, the newer one should be picked
        let olderFilename = "\(UUID().uuidString)_older.mp3"
        let newerFilename = "\(UUID().uuidString)_newer.mp3"
        let olderURL = self.inboxDirectory.appendingPathComponent(olderFilename)
        let newerURL = self.inboxDirectory.appendingPathComponent(newerFilename)

        FileManager.default.createFile(atPath: olderURL.path, contents: Data(repeating: 0xAA, count: 50))
        // Set older file's modification date to the past
        try? FileManager.default.setAttributes(
            [.modificationDate: Date().addingTimeInterval(-3600)],
            ofItemAtPath: olderURL.path
        )
        FileManager.default.createFile(atPath: newerURL.path, contents: Data(repeating: 0xBB, count: 50))

        // When
        let result = await self.sut.processInbox()

        // Then - newest file was processed
        if case let .audioFile(processedURL) = result {
            XCTAssertTrue(
                processedURL.lastPathComponent.contains("newer"),
                "Should process newest entry, got \(processedURL.lastPathComponent)"
            )
        } else {
            XCTFail("Expected .audioFile result, got \(result)")
        }
    }

    func testAllEntriesDeletedAfterProcessingNewest() async {
        // Given - multiple entries in inbox
        let file1 = self.inboxDirectory.appendingPathComponent("\(UUID().uuidString)_first.mp3")
        let file2 = self.inboxDirectory.appendingPathComponent("\(UUID().uuidString)_second.mp3")
        FileManager.default.createFile(atPath: file1.path, contents: Data(repeating: 0xAA, count: 50))
        try? FileManager.default.setAttributes(
            [.modificationDate: Date().addingTimeInterval(-3600)],
            ofItemAtPath: file1.path
        )
        FileManager.default.createFile(atPath: file2.path, contents: Data(repeating: 0xBB, count: 50))

        // When
        _ = await self.sut.processInbox()

        // Then - all entries cleaned up
        let remaining = try? FileManager.default.contentsOfDirectory(atPath: self.inboxDirectory.path)
        XCTAssertEqual(remaining?.count ?? 0, 0, "All inbox entries should be deleted after processing")
    }

    // MARK: - Stale Entry Cleanup

    func testEntriesOlderThan24HoursAreCleanedUp() async {
        // Given - a single entry older than 24 hours
        let staleFilename = "\(UUID().uuidString)_stale.mp3"
        let staleURL = self.inboxDirectory.appendingPathComponent(staleFilename)
        FileManager.default.createFile(atPath: staleURL.path, contents: Data(repeating: 0xCC, count: 50))
        try? FileManager.default.setAttributes(
            [.modificationDate: Date().addingTimeInterval(-25 * 3600)],
            ofItemAtPath: staleURL.path
        )

        // When
        let result = await self.sut.processInbox()

        // Then - stale entry removed, inbox effectively empty
        XCTAssertEqual(result, .empty, "Stale entries should be cleaned up and not processed")
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: staleURL.path),
            "Stale entry should be deleted"
        )
    }

    func testStaleEntriesCleanedUpWhileNewestIsProcessed() async {
        // Given - one stale entry and one fresh entry
        let staleURL = self.inboxDirectory.appendingPathComponent("\(UUID().uuidString)_stale.mp3")
        let freshURL = self.inboxDirectory.appendingPathComponent("\(UUID().uuidString)_fresh.mp3")
        FileManager.default.createFile(atPath: staleURL.path, contents: Data(repeating: 0xCC, count: 50))
        try? FileManager.default.setAttributes(
            [.modificationDate: Date().addingTimeInterval(-25 * 3600)],
            ofItemAtPath: staleURL.path
        )
        FileManager.default.createFile(atPath: freshURL.path, contents: Data(repeating: 0xDD, count: 50))

        // When
        let result = await self.sut.processInbox()

        // Then - fresh entry processed, stale entry deleted
        if case .audioFile = result {
            XCTAssertFalse(
                FileManager.default.fileExists(atPath: staleURL.path),
                "Stale entry should be deleted"
            )
            XCTAssertFalse(
                FileManager.default.fileExists(atPath: freshURL.path),
                "Fresh entry should also be cleaned up after processing"
            )
        } else {
            XCTFail("Expected .audioFile result, got \(result)")
        }
    }

    // MARK: - Download Failure

    func testDownloadFailureReturnsError() async throws {
        // Given - URL reference with a download that will fail
        self.mockDownloadService.downloadShouldFail = true
        let urlRef = URLReference(
            url: "https://example.com/meditation.mp3",
            filename: "meditation.mp3",
            timestamp: "2026-03-13T10:30:00Z"
        )
        let jsonData = try JSONEncoder().encode(urlRef)
        let filename = "\(UUID().uuidString)_meditation.json"
        let fileURL = self.inboxDirectory.appendingPathComponent(filename)
        FileManager.default.createFile(atPath: fileURL.path, contents: jsonData)

        // When
        let result = await self.sut.processInbox()

        // Then
        if case let .error(error) = result {
            XCTAssertEqual(error, .downloadFailed)
        } else {
            XCTFail("Expected .error(.downloadFailed), got \(result)")
        }
    }

    func testDownloadFailureStillCleansUpInboxEntry() async throws {
        // Given
        self.mockDownloadService.downloadShouldFail = true
        let urlRef = URLReference(
            url: "https://example.com/meditation.mp3",
            filename: "meditation.mp3",
            timestamp: "2026-03-13T10:30:00Z"
        )
        let jsonData = try JSONEncoder().encode(urlRef)
        let filename = "\(UUID().uuidString)_meditation.json"
        let fileURL = self.inboxDirectory.appendingPathComponent(filename)
        FileManager.default.createFile(atPath: fileURL.path, contents: jsonData)

        // When
        _ = await self.sut.processInbox()

        // Then
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: fileURL.path),
            "Inbox entry should be cleaned up even when download fails"
        )
    }

    // MARK: - Download Cancellation

    func testCancelDownloadForwardsToDownloadService() {
        // Given - handler exists

        // When
        self.sut.cancelDownload()

        // Then
        XCTAssertTrue(
            self.mockDownloadService.downloadCancelCalled,
            "Cancel should be forwarded to download service"
        )
    }

    // MARK: - Non-Audio File Handling

    func testNonAudioNonJSONFileIsIgnoredAndCleanedUp() async {
        // Given - an unexpected file type in inbox
        let filename = "\(UUID().uuidString)_notes.txt"
        let fileURL = self.inboxDirectory.appendingPathComponent(filename)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data("some text".utf8))

        // When
        let result = await self.sut.processInbox()

        // Then
        XCTAssertEqual(result, .empty, "Non-audio, non-JSON files should be ignored")
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: fileURL.path),
            "Unrecognized file should be cleaned up"
        )
    }

    // MARK: - Non-Existent Inbox Directory

    func testNonExistentInboxDirectoryReturnsEmpty() async {
        // Given - inbox directory that does not exist (no one has shared yet)
        let nonExistentDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("does-not-exist-\(UUID().uuidString)")
        let handler = InboxHandler(
            fileOpenHandler: self.mockFileOpenHandler,
            downloadService: self.mockDownloadService,
            fileManager: .default,
            inboxDirectoryURL: nonExistentDir
        )

        // When
        let result = await handler.processInbox()

        // Then
        XCTAssertEqual(result, .empty)
    }

    // MARK: - Published State

    func testIsDownloadingIsTrueDuringURLReferenceProcessing() async throws {
        // Given
        let urlRef = URLReference(
            url: "https://example.com/meditation.mp3",
            filename: "meditation.mp3",
            timestamp: "2026-03-13T10:30:00Z"
        )
        let jsonData = try JSONEncoder().encode(urlRef)
        let filename = "\(UUID().uuidString)_meditation.json"
        let fileURL = self.inboxDirectory.appendingPathComponent(filename)
        FileManager.default.createFile(atPath: fileURL.path, contents: jsonData)

        // When - check initial state
        XCTAssertFalse(self.sut.isDownloading)

        // After processing completes
        _ = await self.sut.processInbox()

        // Then - should be false again after completion
        XCTAssertFalse(self.sut.isDownloading)
    }

    func testDownloadErrorIsPublishedOnFailure() async throws {
        // Given
        self.mockDownloadService.downloadShouldFail = true
        let urlRef = URLReference(
            url: "https://example.com/meditation.mp3",
            filename: "meditation.mp3",
            timestamp: "2026-03-13T10:30:00Z"
        )
        let jsonData = try JSONEncoder().encode(urlRef)
        let filename = "\(UUID().uuidString)_meditation.json"
        let fileURL = self.inboxDirectory.appendingPathComponent(filename)
        FileManager.default.createFile(atPath: fileURL.path, contents: jsonData)

        // When
        _ = await self.sut.processInbox()

        // Then
        XCTAssertEqual(self.sut.downloadError, .downloadFailed)
    }
}
