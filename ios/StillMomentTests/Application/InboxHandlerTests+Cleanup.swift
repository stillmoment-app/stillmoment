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
}
