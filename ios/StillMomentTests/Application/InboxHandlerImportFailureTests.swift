//
//  InboxHandlerImportFailureTests.swift
//  Still Moment
//
//  Tests fuer den Failure-Pfad: Import-Fehler aus dem Share-Extension- und
//  URL-Download-Pfad muessen via `.audioImportFailed` an den App-Layer
//  weitergereicht werden, damit der Alert ("bereits importiert") erscheint.
//

import XCTest
@testable import StillMoment

@MainActor
final class InboxHandlerImportFailureTests: XCTestCase {
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
    var inboxDirectory: URL!

    override func setUp() {
        super.setUp()
        self.inboxDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("InboxHandlerImportFailureTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(
            at: self.inboxDirectory,
            withIntermediateDirectories: true
        )

        self.mockMeditationService = MockGuidedMeditationService()
        // Existierende Meditationen liegen nicht real auf der Disk — Name-Only-Match
        // ist genau die Konstellation, in der die Duplikat-Erkennung greifen soll.
        self.mockMeditationService.mockFileExists = false
        self.mockMetadataService = MockAudioMetadataService()
        self.mockFileOpenHandler = FileOpenHandler(
            meditationService: self.mockMeditationService,
            metadataService: self.mockMetadataService
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
        self.mockMetadataService = nil
        self.mockMeditationService = nil
        self.inboxDirectory = nil
        super.tearDown()
    }

    // MARK: - Share-Extension: Duplicate

    func testDuplicateAudioFileReturnsAudioImportFailed() async {
        // Given — eine Meditation mit gleichem Dateinamen liegt bereits in der Library.
        // Der Share-Extension-Pfad muss den Fehler weiterreichen, damit der App-Layer
        // den "bereits importiert"-Alert zeigen kann.
        let filename = "\(UUID().uuidString)_meditation.mp3"
        let fileURL = self.inboxDirectory.appendingPathComponent(filename)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data(repeating: 0xFF, count: 100))
        self.mockMeditationService.meditations = [
            GuidedMeditation(
                localFilePath: "existing.mp3",
                fileName: filename,
                duration: 600,
                teacher: "Teacher",
                name: "Existing"
            )
        ]

        // When
        let result = await self.sut.processInbox()

        // Then
        guard case let .audioImportFailed(error) = result else {
            XCTFail("Expected .audioImportFailed for duplicate, got \(result)")
            return
        }
        guard case .alreadyImported = error else {
            XCTFail("Expected .alreadyImported, got \(error)")
            return
        }
    }

    // MARK: - URL Download: Duplicate

    func testDownloadedDuplicateFileReturnsAudioImportFailed() async throws {
        // Given — Download liefert eine Datei, die als Duplikat erkannt wird.
        let downloadedFilename = "duplicate-meditation.mp3"
        let downloadedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString)_\(downloadedFilename)")
        FileManager.default.createFile(atPath: downloadedURL.path, contents: Data(repeating: 0xEE, count: 100))
        defer { try? FileManager.default.removeItem(at: downloadedURL) }

        self.mockDownloadService.downloadedFileURL = downloadedURL
        self.mockMeditationService.meditations = [
            GuidedMeditation(
                localFilePath: "existing.mp3",
                fileName: downloadedURL.lastPathComponent,
                duration: 600,
                teacher: "Teacher",
                name: "Existing"
            )
        ]

        let urlRef = URLReference(
            url: "https://example.com/meditation.mp3",
            filename: downloadedFilename,
            timestamp: "2026-05-06T10:00:00Z"
        )
        let jsonData = try JSONEncoder().encode(urlRef)
        let jsonFilename = "\(UUID().uuidString)_meditation.json"
        let fileURL = self.inboxDirectory.appendingPathComponent(jsonFilename)
        FileManager.default.createFile(atPath: fileURL.path, contents: jsonData)

        // When
        let result = await self.sut.processInbox()

        // Then
        guard case let .audioImportFailed(error) = result else {
            XCTFail("Expected .audioImportFailed for duplicate after download, got \(result)")
            return
        }
        guard case .alreadyImported = error else {
            XCTFail("Expected .alreadyImported, got \(error)")
            return
        }
    }
}
