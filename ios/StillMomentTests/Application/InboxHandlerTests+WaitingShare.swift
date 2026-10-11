//
//  InboxHandlerTests+WaitingShare.swift
//  Still Moment
//
//  shared-138: Was die App begonnen hat (Laden, Bearbeiten-Blatt, Meldung), fuehrt sie zu Ende.
//  Ein waehrenddessen geteilter Eintrag wartet in der Inbox und startet danach von selbst.
//  Abgelegt wird wie in der Share-Extension ueber `ShareInbox`.
//

import XCTest
@testable import StillMoment

extension InboxHandlerTests {
    // MARK: - Helfer

    var talk25401: URL {
        get throws {
            try XCTUnwrap(URL(string: ShareInboxTests.talk25401))
        }
    }

    var talk25402: URL {
        get throws {
            try XCTUnwrap(URL(string: ShareInboxTests.talk25402))
        }
    }

    /// Teilt einen Link so, wie die Share-Extension es tut
    func shareLink(_ link: URL) throws {
        try ShareInbox.storeLink(link, in: self.inboxDirectory)
    }

    /// Teilt eine Audiodatei so, wie die Share-Extension es tut
    func shareAudioFile(named name: String) throws {
        try ShareInbox.storeAudioFile(from: self.makeSharedAudioFile(named: name), in: self.inboxDirectory)
    }

    /// Teilt einen Link, waehrend der laufende Download noch unterwegs ist
    func shareLinkWhileDownloading(_ link: URL) {
        self.mockDownloadService.whileDownloading = { [weak self] in
            try? self?.shareLink(link)
        }
    }

    /// Die Adresse liefert eine eigene "geladene" Datei, wie der AudioDownloadService
    @discardableResult
    func prepareDownload(_ link: URL) throws -> URL {
        let talkNumber = link.deletingLastPathComponent().lastPathComponent
        let file = try self.makeDownloadedFile(named: "talk-\(talkNumber).mp3")
        self.mockDownloadService.downloadedFiles[link] = file
        addTeardownBlock {
            try? FileManager.default.removeItem(at: file.deletingLastPathComponent())
        }
        return file
    }

    @discardableResult
    func prepareDownloads(_ first: URL, _ second: URL) throws -> (URL, URL) {
        try (self.prepareDownload(first), self.prepareDownload(second))
    }

    /// Die Bibliothek uebernimmt den Import und zeigt das Bearbeiten-Blatt
    func openEditor() {
        _ = self.mockFileOpenHandler.takePendingImport()
        self.isEditorOpen = true
    }

    /// Das Bearbeiten-Blatt wird gespeichert oder verworfen — die App schaut danach in die Inbox
    func closeEditor() async -> InboxResult {
        self.isEditorOpen = false
        return await self.sut.processInbox()
    }

    /// Die App wird aktiv, nachdem geteilt wurde
    func appBecomesActive() async -> InboxResult {
        await self.sut.processInbox()
    }

    /// Die Adressen der Links, die in der Inbox warten
    func waitingLinks() throws -> [String] {
        try self.waitingEntries()
            .filter { $0.pathExtension == "json" }
            .map { try JSONDecoder().decode(URLReference.self, from: Data(contentsOf: $0)).url }
    }

    /// Alle Eintraege, die in der Inbox warten
    func waitingEntries() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: self.inboxDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
    }

    // MARK: - AK-1: Link geteilt, waehrend ein Link laedt

    func testLinkSharedWhileLinkLoadsWaitsForRunningImport() async throws {
        // Given — 25401 laedt, waehrenddessen wird 25402 geteilt und die App wird aktiv
        let (talk25401, talk25402) = try (self.talk25401, self.talk25402)
        let (file25401, _) = try self.prepareDownloads(talk25401, talk25402)
        try self.shareLink(talk25401)
        self.mockDownloadService.whileDownloading = { [weak self] in
            try? self?.shareLink(talk25402)
            let resultWhileLoading = await self?.appBecomesActive()
            XCTAssertEqual(resultWhileLoading, .empty)
        }

        // When
        let result = await self.sut.processInbox()

        // Then — 25401 laedt zu Ende und oeffnet sein Blatt, 25402 wartet
        XCTAssertEqual(result, .downloadCompleted(file25401))
        XCTAssertEqual(self.mockDownloadService.requestedURLs, [talk25401])
        XCTAssertEqual(try self.waitingLinks(), [ShareInboxTests.talk25402])
    }

    func testWaitingLinkStartsWhenEditorOfRunningImportCloses() async throws {
        // Given — Blatt fuer 25401 offen, 25402 wartet
        let (talk25401, talk25402) = try (self.talk25401, self.talk25402)
        let (_, file25402) = try self.prepareDownloads(talk25401, talk25402)
        try self.shareLink(talk25401)
        _ = await self.sut.processInbox()
        self.openEditor()
        try self.shareLink(talk25402)
        let resultWhileEditing = await self.appBecomesActive()
        XCTAssertEqual(resultWhileEditing, .empty)

        // When — Speichern oder Verwerfen schliessen das Blatt gleichermassen
        let result = await self.closeEditor()

        // Then — 25402 wird geladen, sein Blatt folgt
        XCTAssertEqual(result, .downloadCompleted(file25402))
        XCTAssertEqual(self.mockDownloadService.requestedURLs, [talk25401, talk25402])
        XCTAssertEqual(self.mockFileOpenHandler.pendingImportSignal?.url, file25402)
    }

    // MARK: - AK-3: Offenes Bearbeiten-Blatt

    func testShareWhileEditingExistingMeditationWaitsUntilEditorCloses() async throws {
        // Given — ein Blatt fuer eine vorhandene Meditation ist offen
        let talk25402 = try self.talk25402
        let file25402 = try self.prepareDownload(talk25402)
        self.isEditorOpen = true
        try self.shareLink(talk25402)

        // When
        let resultWhileEditing = await self.appBecomesActive()

        // Then — nichts geladen, das offene Blatt bleibt
        XCTAssertEqual(resultWhileEditing, .empty)
        XCTAssertTrue(self.mockDownloadService.requestedURLs.isEmpty)
        XCTAssertNil(self.mockFileOpenHandler.pendingImportSignal)

        // When — das Blatt wird geschlossen
        let result = await self.closeEditor()

        // Then
        XCTAssertEqual(result, .downloadCompleted(file25402))
    }

    func testShareBeforeLibraryTookOverImportWaits() async throws {
        // Given — eine Audiodatei ist uebernommen, die Bibliothek hat ihr Blatt noch nicht geoeffnet
        try self.shareAudioFile(named: "Vortrag.mp3")
        _ = await self.sut.processInbox()
        let pending = self.mockFileOpenHandler.pendingImportSignal
        try self.shareLink(self.talk25402)

        // When
        let result = await self.appBecomesActive()

        // Then — kein neuer Import ersetzt den begonnenen
        XCTAssertEqual(result, .empty)
        XCTAssertTrue(self.mockDownloadService.requestedURLs.isEmpty)
        XCTAssertEqual(self.mockFileOpenHandler.pendingImportSignal, pending)
    }

    // MARK: - AK-5: Abbrechen im Ladefenster

    func testCancelWhileLoadingStartsWaitingLinkWithoutMessage() async throws {
        // Given — 25401 laedt, 25402 wird geteilt, dann tippt jemand "Abbrechen"
        let (talk25401, talk25402) = try (self.talk25401, self.talk25402)
        let (_, file25402) = try self.prepareDownloads(talk25401, talk25402)
        try self.shareLink(talk25401)
        self.mockDownloadService.whileDownloadingFrom[talk25401] = { [weak self] in
            try? self?.shareLink(talk25402)
            self?.sut.cancelDownload()
        }

        // When
        let result = await self.sut.processInbox()

        // Then — keine Meldung fuer 25401, 25402 wird geladen und nicht als abgebrochen behandelt
        XCTAssertEqual(result, .downloadCompleted(file25402))
        XCTAssertEqual(self.mockDownloadService.requestedURLs, [talk25401, talk25402])
        XCTAssertNil(self.sut.downloadError)
        XCTAssertNotNil(self.mockFileOpenHandler.pendingImportSignal)
    }

    func testCancelDuringRetryStartsWaitingLink() async throws {
        // Given — 25401 war nicht erreichbar, 25402 wartet
        let (talk25401, talk25402) = try (self.talk25401, self.talk25402)
        let (_, file25402) = try self.prepareDownloads(talk25401, talk25402)
        self.mockDownloadService.errorToThrow = .networkError
        try self.shareLink(talk25401)
        _ = await self.sut.processInbox()
        try self.shareLink(talk25402)
        self.mockDownloadService.errorToThrow = nil
        self.mockDownloadService.whileDownloadingFrom[talk25401] = { [weak self] in
            self?.sut.cancelDownload()
        }

        // When — "Erneut versuchen", dann "Abbrechen" im Ladefenster
        let result = await self.sut.retry()

        // Then
        XCTAssertEqual(result, .downloadCompleted(file25402))
        XCTAssertEqual(self.mockDownloadService.requestedURLs, [talk25401, talk25401, talk25402])
        XCTAssertNil(self.sut.downloadError)
    }

    // MARK: - AK-6: Mehrfach geteilt

    func testOfSeveralEntriesSharedDuringImportOnlyTheLastStarts() async throws {
        // Given — 25401 laedt; erst 25402, dann eine Audiodatei geteilt
        let (talk25401, talk25402) = try (self.talk25401, self.talk25402)
        try self.prepareDownloads(talk25401, talk25402)
        try self.shareLink(talk25401)
        self.mockDownloadService.whileDownloading = { [weak self] in
            try? self?.shareLink(talk25402)
            try? self?.shareAudioFile(named: "Vortrag.mp3")
        }
        _ = await self.sut.processInbox()
        self.openEditor()

        // When
        let result = await self.closeEditor()

        // Then — nur die Audiodatei, 25402 wird nie angefragt, danach wartet nichts mehr
        guard case let .audioFile(file) = result else {
            return XCTFail("Expected .audioFile, got \(result)")
        }
        XCTAssertEqual(file.lastPathComponent, "Vortrag.mp3")
        XCTAssertEqual(self.mockDownloadService.requestedURLs, [talk25401])
        XCTAssertEqual(try self.waitingEntries(), [])
    }

    func testLinkSharedTwiceDuringImportIsLoadedOnce() async throws {
        // Given — 25401 laedt, 25402 wird zweimal geteilt
        let (talk25401, talk25402) = try (self.talk25401, self.talk25402)
        try self.prepareDownloads(talk25401, talk25402)
        try self.shareLink(talk25401)
        self.mockDownloadService.whileDownloadingFrom[talk25401] = { [weak self] in
            try? self?.shareLink(talk25402)
            try? self?.shareLink(talk25402)
        }
        _ = await self.sut.processInbox()
        self.openEditor()

        // When
        _ = await self.closeEditor()
        self.openEditor()
        let afterSecondEditor = await self.closeEditor()

        // Then
        XCTAssertEqual(self.mockDownloadService.requestedURLs, [talk25401, talk25402])
        XCTAssertEqual(afterSecondEditor, .empty)
    }

    // MARK: - AK-7: Kein stiller Verlust bei gleichem Namen

    func testLinkWithSameNameSharedWhileLoadingKeepsWaiting() async throws {
        // Given — 25401 laedt, waehrenddessen wird 25402 geteilt (beide heissen download.json)
        let file = try self.makeDownloadedFile(named: "download.mp3")
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        self.mockDownloadService.downloadedFileURL = file
        try self.shareLink(self.talk25401)
        try self.shareLinkWhileDownloading(self.talk25402)

        // When
        let result = await self.sut.processInbox()

        // Then — 25401 ist fertig geladen, 25402 wartet weiter
        XCTAssertEqual(result, .downloadCompleted(file))
        XCTAssertEqual(try self.waitingLinks(), [ShareInboxTests.talk25402])
    }
}
