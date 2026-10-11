//
//  InboxHandlerTests+PathlessLink.swift
//  Still Moment
//
//  ios-061: Ein geteilter Link ohne Pfad (`https://www.example.com/`, auch mit `?id=1`)
//  wird beim Oeffnen der App geladen wie jeder andere Link — wie auf Android.
//  Abgelegt wird wie in der Share-Extension ueber `ShareInbox`.
//

import XCTest
@testable import StillMoment

extension InboxHandlerTests {
    static let pathlessLinks = [
        "https://www.example.com/",
        "https://www.example.com",
        "https://www.example.com/?id=1"
    ]

    // MARK: - Webseite

    func testSharedLinkWithoutPathShowsLoadingWindowThenNoRecordingFound() async throws {
        for address in Self.pathlessLinks {
            // Given — unter der Adresse liegt eine Webseite
            let link = try XCTUnwrap(URL(string: address))
            self.mockDownloadService.errorToThrow = .unsupportedContentType
            var loadingWindowShown = false
            self.mockDownloadService.whileDownloading = { [weak self] in
                loadingWindowShown = self?.sut.isDownloading ?? false
            }
            try ShareInbox.storeLink(link, in: self.inboxDirectory)

            // When
            let result = await self.sut.processInbox()

            // Then — Ladefenster, danach "Keine Aufnahme gefunden"
            XCTAssertTrue(loadingWindowShown, "Ladefenster fuer \(address)")
            XCTAssertEqual(result, .error(.notAnAudioUrl), address)
            XCTAssertEqual(self.mockDownloadService.requestedURLs.last, link, address)
        }
    }

    // MARK: - Aufnahme

    func testSharedLinkWithoutPathServingRecordingIsImported() async throws {
        // Given — die Adresse liefert direkt eine MP3
        let file = try self.makeDownloadedFile(named: "audio.mp3")
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        self.mockDownloadService.downloadedFileURL = file
        try ShareInbox.storeLink(XCTUnwrap(URL(string: "https://www.example.com/?id=1")), in: self.inboxDirectory)

        // When
        let result = await self.sut.processInbox()

        // Then — das Bearbeiten-Blatt erscheint
        XCTAssertEqual(result, .downloadCompleted(file))
        XCTAssertNotNil(self.mockFileOpenHandler.pendingImportSignal)
    }

    func testSharedLinkWithoutPathIsLoadedWithoutSlashAsFilename() async throws {
        // Given
        try ShareInbox.storeLink(XCTUnwrap(URL(string: "https://www.example.com/")), in: self.inboxDirectory)

        // When
        _ = await self.sut.processInbox()

        // Then — der Download bestimmt den Namen selbst (Server oder audio.mp3/audio.m4a)
        let filename = try XCTUnwrap(self.mockDownloadService.requestedFilenames.first)
        XCTAssertFalse(filename.contains("/"), "Dateiname: \(filename)")
    }

    // MARK: - Mehrfach geteilt (shared-132)

    func testOfTwoLinksWithoutPathTheLaterOneIsLoaded() async throws {
        // Given
        let later = try XCTUnwrap(URL(string: "https://www.example.com/?id=2"))
        try ShareInbox.storeLink(XCTUnwrap(URL(string: "https://www.example.com/?id=1")), in: self.inboxDirectory)
        try ShareInbox.storeLink(later, in: self.inboxDirectory)

        // When
        _ = await self.sut.processInbox()

        // Then — der zuletzt geteilte gewinnt
        XCTAssertEqual(self.mockDownloadService.requestedURLs, [later])
    }

    // MARK: - Aufraeumen

    func testUnclaimedLinkWithoutPathIsRemovedAfter24Hours() async throws {
        // Given — der Eintrag wartet seit 25 Stunden
        let entry = try ShareInbox.storeLink(
            XCTUnwrap(URL(string: "https://www.example.com/")),
            in: self.inboxDirectory,
            date: Date().addingTimeInterval(-25 * 3600)
        )
        try FileManager.default.setAttributes(
            [.modificationDate: Date().addingTimeInterval(-25 * 3600)],
            ofItemAtPath: entry.path
        )

        // When
        let result = await self.sut.processInbox()

        // Then — nichts geladen, nichts bleibt liegen
        XCTAssertEqual(result, .empty)
        XCTAssertEqual(self.mockDownloadService.requestedURLs, [])
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: self.inboxDirectory.path), [])
    }
}
