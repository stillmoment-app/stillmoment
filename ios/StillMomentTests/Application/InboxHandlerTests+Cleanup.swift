//
//  InboxHandlerTests+Cleanup.swift
//  Still Moment
//
//  shared-128: Nach Abbrechen erscheint keine Meldung mehr, und nicht uebernommene
//  Downloads (Abbruch, abgelehnte Datei, Import-Fehler) hinterlassen keinen Ordner in tmp.
//

import XCTest
@testable import StillMoment

extension InboxHandlerTests {
    /// Legt eine "geladene" Datei so ab, wie der AudioDownloadService es tut: `tmp/dl_<UUID>/<name>`.
    func makeDownloadedFile(named name: String) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("dl_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent(name)
        FileManager.default.createFile(atPath: file.path, contents: Data(repeating: 0xFF, count: 100))
        return file
    }

    // MARK: - Aufraeumen

    func testCancelAfterDownloadRemovesDownloadFolder() async throws {
        // Given — die Datei ist schon geladen, als Abbrechen getippt wird
        let file = try self.makeDownloadedFile(named: "folge.mp3")
        self.mockDownloadService.downloadedFileURL = file
        self.mockDownloadService.afterDownloaded = { [weak self] in
            self?.sut.cancelDownload()
        }
        try self.share(Self.episodeLink)

        // When
        let result = await self.sut.processInbox()

        // Then
        XCTAssertEqual(result, .empty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.deletingLastPathComponent().path))
    }

    func testRejectedFileRemovesDownloadFolder() async throws {
        // Given — Datei ohne Audio-Endung
        let file = try self.makeDownloadedFile(named: "feed")
        self.mockDownloadService.downloadedFileURL = file
        try self.share(Self.episodeLink)

        // When
        let result = await self.sut.processInbox()

        // Then
        XCTAssertEqual(result, .error(.episodeUnavailable))
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.deletingLastPathComponent().path))
    }

    func testImportFailureRemovesDownloadFolder() async throws {
        // Given — die Datei laesst sich nicht lesen
        let file = try self.makeDownloadedFile(named: "folge.mp3")
        self.mockDownloadService.downloadedFileURL = file
        self.mockMetadataService.extractShouldThrow = true
        try self.share("https://example.com/folge.mp3")

        // When
        let result = await self.sut.processInbox()

        // Then
        XCTAssertEqual(result, .audioImportFailed(.importFailed))
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.deletingLastPathComponent().path))
    }

    func testSuccessfulDownloadKeepsFileForEditDialog() async throws {
        // Given
        let file = try self.makeDownloadedFile(named: "folge.mp3")
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        self.mockDownloadService.downloadedFileURL = file
        try self.share(Self.episodeLink)

        // When
        _ = await self.sut.processInbox()

        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
    }

    // MARK: - Nach Abbrechen keine Meldung

    func testLookupErrorAfterCancelShowsNoMessage() async throws {
        // Given — die Suche scheitert im selben Moment, in dem Abbrechen getippt wird
        self.mockEpisodeResolver.errorToThrow = .notReachable
        self.mockEpisodeResolver.whileResolving = { [weak self] in
            self?.sut.cancelDownload()
        }
        try self.share(Self.episodeLink)

        // When
        let result = await self.sut.processInbox()

        // Then
        XCTAssertEqual(result, .empty)
        XCTAssertNil(self.sut.downloadError)
    }

    func testDownloadErrorAfterCancelShowsNoMessage() async throws {
        // Given
        self.mockDownloadService.errorToThrow = .networkError
        self.mockDownloadService.whileDownloading = { [weak self] in
            self?.sut.cancelDownload()
        }
        try self.share("https://example.com/folge.mp3")

        // When
        let result = await self.sut.processInbox()

        // Then
        XCTAssertEqual(result, .empty)
        XCTAssertNil(self.sut.downloadError)
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

        // Then - fresh entry processed (imported + cleaned up), stale entry deleted
        if case .audioFile = result {
            XCTAssertFalse(
                FileManager.default.fileExists(atPath: staleURL.path),
                "Stale entry should be deleted"
            )
            XCTAssertFalse(
                FileManager.default.fileExists(atPath: freshURL.path),
                "Fresh entry should be taken out of the inbox for import"
            )
            // Persistenz erfolgt erst nach Save im Edit-Sheet (ios-043).
            XCTAssertNotNil(self.mockFileOpenHandler.pendingImportSignal)
        } else {
            XCTFail("Expected .audioFile result, got \(result)")
        }
    }
}
