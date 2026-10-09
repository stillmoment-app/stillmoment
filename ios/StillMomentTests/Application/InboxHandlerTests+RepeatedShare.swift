//
//  InboxHandlerTests+RepeatedShare.swift
//  Still Moment
//
//  shared-132: Mehrfach geteilt, bevor die App uebernommen hat — kein Fehler,
//  der zuletzt geteilte Eintrag wird importiert, und zwar genau einmal.
//  Abgelegt wird wie in der Share-Extension ueber `ShareInbox`.
//

import XCTest
@testable import StillMoment

extension InboxHandlerTests {
    /// Eine geteilte Audiodatei, wie sie die Dateien-App der Share-Extension uebergibt
    func makeSharedAudioFile(named name: String) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("shared_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent(name)
        try Data(repeating: 0xAB, count: 100).write(to: file)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: folder)
        }
        return file
    }

    // MARK: - Link

    func testSameLinkSharedTwiceIsDownloadedAndImportedOnce() async throws {
        // Given
        let file = try self.makeDownloadedFile(named: "download.mp3")
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        self.mockDownloadService.downloadedFileURL = file
        let link = try XCTUnwrap(URL(string: ShareInboxTests.talk25401))
        try ShareInbox.storeLink(link, in: self.inboxDirectory)
        try ShareInbox.storeLink(link, in: self.inboxDirectory)

        // When
        let result = await self.sut.processInbox()

        // Then
        XCTAssertEqual(result, .downloadCompleted(file))
        XCTAssertEqual(self.mockDownloadService.requestedURLs, [link])
        XCTAssertNil(self.sut.downloadError)
        XCTAssertNotNil(self.mockFileOpenHandler.pendingImportSignal)
    }

    func testOfTwoLinksWithSameEndingTheLaterOneIsImported() async throws {
        // Given
        let file = try self.makeDownloadedFile(named: "download.mp3")
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        self.mockDownloadService.downloadedFileURL = file
        let later = try XCTUnwrap(URL(string: ShareInboxTests.talk25402))
        try ShareInbox.storeLink(XCTUnwrap(URL(string: ShareInboxTests.talk25401)), in: self.inboxDirectory)
        try ShareInbox.storeLink(later, in: self.inboxDirectory)

        // When
        let result = await self.sut.processInbox()

        // Then — nur 25402 wird geladen
        XCTAssertEqual(result, .downloadCompleted(file))
        XCTAssertEqual(self.mockDownloadService.requestedURLs, [later])
    }

    // MARK: - Audiodatei

    func testSameAudioFileSharedTwiceIsImportedOnce() async throws {
        // Given
        let source = try self.makeSharedAudioFile(named: "Vortrag.mp3")
        try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory)
        try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory)

        // When
        let result = await self.sut.processInbox()

        // Then — ein Import, danach wartet nichts mehr
        XCTAssertEqual(result, .audioFile(self.inboxDirectory.appendingPathComponent("Vortrag.mp3")))
        XCTAssertNotNil(self.mockFileOpenHandler.pendingImportSignal)
        let secondPass = await self.sut.processInbox()
        XCTAssertEqual(secondPass, .empty)
    }

    func testAudioFileAlreadyInLibrarySharedTwiceStillSaysAlreadyThere() async throws {
        // Given — Vortrag.mp3 steht schon in der Bibliothek
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
        let source = try self.makeSharedAudioFile(named: "Vortrag.mp3")
        try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory)
        try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory)

        // When
        let result = await self.sut.processInbox()

        // Then — der Hinweis "Schon da", keine zweite Meditation
        XCTAssertEqual(result, .audioImportFailed(.alreadyImported(name: "Vortrag", teacher: "Lehrerin")))
        XCTAssertNil(self.mockFileOpenHandler.pendingImportSignal)
    }
}
