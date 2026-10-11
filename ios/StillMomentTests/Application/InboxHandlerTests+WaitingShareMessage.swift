//
//  InboxHandlerTests+WaitingShareMessage.swift
//  Still Moment
//
//  shared-138: Endet der laufende Import mit "Schon da" oder einer Fehlermeldung, startet der
//  wartende Eintrag, sobald die Meldung geschlossen ist. Eine Audiodatei, die waehrend eines
//  Imports geteilt oder per "Oeffnen in" geoeffnet wird, wartet ebenso.
//

import XCTest
@testable import StillMoment

extension InboxHandlerTests {
    /// Vortrag.mp3 steht schon in der Bibliothek
    func libraryAlreadyContainsVortrag() {
        self.mockMeditationService.mockFileExists = false
        self.mockMeditationService.meditations = [
            GuidedMeditation(
                localFilePath: "existing.mp3",
                fileName: "Vortrag.mp3",
                duration: 600,
                teacher: "Lehrerin",
                name: "Vortrag"
            )
        ]
    }

    // MARK: - AK-4: Meldung

    func testWaitingLinkStartsWhenAlreadyThereMessageIsClosed() async throws {
        // Given — die geteilte Audiodatei ist schon da, 25402 wird geteilt, solange die Meldung steht
        let talk25402 = try self.talk25402
        let file25402 = try self.prepareDownload(talk25402)
        self.libraryAlreadyContainsVortrag()
        try self.shareAudioFile(named: "Vortrag.mp3")
        let first = await self.sut.processInbox()
        try self.shareLink(talk25402)
        let resultWhileMessage = await self.appBecomesActive()

        // When
        let result = await self.sut.closeMessage()

        // Then
        XCTAssertEqual(first, .audioImportFailed(.alreadyImported(name: "Vortrag", teacher: "Lehrerin")))
        XCTAssertEqual(resultWhileMessage, .empty)
        XCTAssertEqual(result, .downloadCompleted(file25402))
        XCTAssertNil(self.sut.importError)
    }

    func testWaitingLinkStartsWhenErrorMessageIsClosed() async throws {
        // Given — 25401 ist nicht erreichbar, 25402 wartet
        let (talk25401, talk25402) = try (self.talk25401, self.talk25402)
        let (_, file25402) = try self.prepareDownloads(talk25401, talk25402)
        self.mockDownloadService.errorToThrow = .networkError
        try self.shareLink(talk25401)
        _ = await self.sut.processInbox()
        self.mockDownloadService.errorToThrow = nil
        try self.shareLink(talk25402)
        let resultWhileMessage = await self.appBecomesActive()

        // When
        let result = await self.sut.closeMessage()

        // Then
        XCTAssertEqual(resultWhileMessage, .empty)
        XCTAssertEqual(result, .downloadCompleted(file25402))
        XCTAssertNil(self.sut.downloadError)
        XCTAssertEqual(self.mockDownloadService.requestedURLs, [talk25401, talk25402])
    }

    func testRetryLoadsRunningLinkAgainWhileSharedEntryWaits() async throws {
        // Given — 25401 ist nicht erreichbar, 25402 wartet
        let (talk25401, talk25402) = try (self.talk25401, self.talk25402)
        let (file25401, file25402) = try self.prepareDownloads(talk25401, talk25402)
        self.mockDownloadService.errorToThrow = .networkError
        try self.shareLink(talk25401)
        _ = await self.sut.processInbox()
        self.mockDownloadService.errorToThrow = nil
        try self.shareLink(talk25402)

        // When — "Erneut versuchen"
        let result = await self.sut.retry()

        // Then — derselbe Link laedt erneut, 25402 wartet bis zum Abschluss
        XCTAssertEqual(result, .downloadCompleted(file25401))
        XCTAssertNil(self.sut.downloadError)
        XCTAssertEqual(try self.waitingLinks(), [ShareInboxTests.talk25402])

        // When — das Blatt von 25401 wird geschlossen
        self.openEditor()
        let next = await self.closeEditor()

        // Then
        XCTAssertEqual(next, .downloadCompleted(file25402))
    }

    func testWaitingAudioFileStartsWhenPodcastMessageIsClosed() async throws {
        // Given — ein ganzer Podcast statt einer Folge (Meldung ohne Ladefenster), dann eine Audiodatei
        try self.share(Self.podcastLink)
        _ = await self.sut.processInbox()
        try self.shareAudioFile(named: "Vortrag.mp3")
        let resultWhileMessage = await self.appBecomesActive()

        // When
        let result = await self.sut.closeMessage()

        // Then — das Blatt der Datei
        XCTAssertEqual(resultWhileMessage, .empty)
        guard case let .audioFile(file) = result else {
            return XCTFail("Expected .audioFile, got \(result)")
        }
        XCTAssertEqual(file.lastPathComponent, "Vortrag.mp3")
        XCTAssertEqual(self.mockFileOpenHandler.pendingImportSignal?.url, file)
    }

    func testAudioFileAlreadyThereShowsMessageAndLeavesNothingWaiting() async throws {
        // Given
        self.libraryAlreadyContainsVortrag()
        try self.shareAudioFile(named: "Vortrag.mp3")

        // When
        let result = await self.sut.processInbox()

        // Then — die Meldung steht, die uebernommene Kopie ist weg, die Inbox ist leer
        let alreadyThere = FileOpenError.alreadyImported(name: "Vortrag", teacher: "Lehrerin")
        XCTAssertEqual(result, .audioImportFailed(alreadyThere))
        XCTAssertEqual(self.sut.importError, alreadyThere)
        XCTAssertEqual(try self.waitingEntries(), [])
        XCTAssertNil(self.mockFileOpenHandler.pendingImportSignal)
    }

    // MARK: - AK-2: Audiodatei waehrend ein Link laedt

    func testAudioFileSharedWhileLinkLoadsFollowsTheLinkEditor() async throws {
        // Given — 25401 laedt, waehrenddessen wird Vortrag.mp3 geteilt
        let talk25401 = try self.talk25401
        let file25401 = try self.prepareDownload(talk25401)
        try self.shareLink(talk25401)
        self.mockDownloadService.whileDownloading = { [weak self] in
            try? self?.shareAudioFile(named: "Vortrag.mp3")
            _ = await self?.appBecomesActive()
        }

        // When
        let result = await self.sut.processInbox()

        // Then — erst das Ergebnis des Links, die Datei wartet
        XCTAssertEqual(result, .downloadCompleted(file25401))
        XCTAssertEqual(try self.waitingEntries().map(\.lastPathComponent), ["Vortrag.mp3"])

        // When — das Blatt des Links wird verworfen
        self.openEditor()
        let next = await self.closeEditor()

        // Then — das Blatt der Datei; die Datei liegt ausserhalb der Inbox bereit
        guard case let .audioFile(file) = next else {
            return XCTFail("Expected .audioFile, got \(next)")
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        XCTAssertNotEqual(file.deletingLastPathComponent().standardizedFileURL, self.inboxDirectory.standardizedFileURL)
        XCTAssertEqual(try self.waitingEntries(), [])
    }

    // MARK: - "Oeffnen in" zaehlt wie Teilen

    func testFileOpenedWhileLinkLoadsWaits() async throws {
        // Given — 25401 laedt, waehrenddessen wird Vortrag.mp3 per "Oeffnen in" geoeffnet
        let talk25401 = try self.talk25401
        try self.prepareDownload(talk25401)
        let opened = try self.makeSharedAudioFile(named: "Vortrag.mp3")
        try self.shareLink(talk25401)
        self.mockDownloadService.whileDownloading = { [weak self] in
            self?.sut.acceptOpenedFile(opened)
            _ = await self?.appBecomesActive()
        }
        _ = await self.sut.processInbox()
        self.openEditor()

        // When
        let result = await self.closeEditor()

        // Then
        guard case let .audioFile(file) = result else {
            return XCTFail("Expected .audioFile, got \(result)")
        }
        XCTAssertEqual(file.lastPathComponent, "Vortrag.mp3")
    }

    func testFileOpenedWithoutRunningImportOpensEditor() async throws {
        // Given
        let opened = try self.makeSharedAudioFile(named: "Vortrag.mp3")

        // When
        self.sut.acceptOpenedFile(opened)
        let result = await self.appBecomesActive()

        // Then
        guard case let .audioFile(file) = result else {
            return XCTFail("Expected .audioFile, got \(result)")
        }
        XCTAssertEqual(self.mockFileOpenHandler.pendingImportSignal?.url, file)
    }

    func testFileOpenedAlreadyInLibrarySaysAlreadyThere() async throws {
        // Given
        self.libraryAlreadyContainsVortrag()
        let opened = try self.makeSharedAudioFile(named: "Vortrag.mp3")

        // When
        self.sut.acceptOpenedFile(opened)
        let result = await self.appBecomesActive()

        // Then
        XCTAssertEqual(result, .audioImportFailed(.alreadyImported(name: "Vortrag", teacher: "Lehrerin")))
    }

    func testFileOpenedInUnsupportedFormatIsReportedRightAwayAndNeverWaits() throws {
        // Given
        let opened = try self.makeSharedAudioFile(named: "Vortrag.wav")

        // When
        self.sut.acceptOpenedFile(opened)

        // Then
        XCTAssertEqual(self.sut.importError, .unsupportedFormat)
        XCTAssertEqual(try self.waitingEntries(), [])
    }
}
