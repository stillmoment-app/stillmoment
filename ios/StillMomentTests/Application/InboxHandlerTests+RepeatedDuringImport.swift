//
//  InboxHandlerTests+RepeatedDuringImport.swift
//  Still Moment
//
//  shared-138: Derselbe Eintrag, erneut geteilt, solange er laedt, sein Blatt offen ist oder
//  seine Meldung steht, aendert nichts — kein zweiter Import, kein nachgeschobenes "Schon da".
//  Erst danach erneut geteilt, erscheint wie bisher "Schon da".
//

import XCTest
@testable import StillMoment

extension InboxHandlerTests {
    /// Die Meditation, die nach "Speichern" eines Downloads in der Bibliothek steht
    func libraryEntry(for file: URL) -> GuidedMeditation {
        GuidedMeditation(
            localFilePath: "saved.mp3",
            fileName: file.lastPathComponent,
            duration: 600,
            teacher: "Gil",
            name: "Talk"
        )
    }

    func testSameLinkSharedAgainWhileLoadingIsIgnored() async throws {
        // Given — 25401 laedt und wird waehrenddessen erneut geteilt
        let talk25401 = try self.talk25401
        try self.prepareDownload(talk25401)
        try self.shareLink(talk25401)
        self.mockDownloadService.whileDownloading = { [weak self] in
            try? self?.shareLink(talk25401)
            _ = await self?.appBecomesActive()
        }
        _ = await self.sut.processInbox()
        self.openEditor()

        // When
        let result = await self.closeEditor()

        // Then — kein zweiter Download, kein "Schon da", nichts wartet
        XCTAssertEqual(result, .empty)
        XCTAssertEqual(self.mockDownloadService.requestedURLs, [talk25401])
        XCTAssertNil(self.sut.importError)
        XCTAssertEqual(try self.waitingEntries(), [])
    }

    func testRepeatOfRunningLinkLeavesOtherWaitingEntryWaiting() async throws {
        // Given — 25401 laedt, eine Audiodatei wartet, dann wird 25401 erneut geteilt
        let talk25401 = try self.talk25401
        try self.prepareDownload(talk25401)
        try self.shareLink(talk25401)
        self.mockDownloadService.whileDownloading = { [weak self] in
            try? self?.shareAudioFile(named: "Vortrag.mp3")
            try? self?.shareLink(talk25401)
            _ = await self?.appBecomesActive()
        }
        _ = await self.sut.processInbox()
        self.openEditor()

        // When
        let result = await self.closeEditor()

        // Then — der neueste *andere* Eintrag startet
        guard case let .audioFile(file) = result else {
            return XCTFail("Expected .audioFile, got \(result)")
        }
        XCTAssertEqual(file.lastPathComponent, "Vortrag.mp3")
        XCTAssertEqual(self.mockDownloadService.requestedURLs, [talk25401])
    }

    func testSameAudioFileSharedAgainWhileEditorOpenIsIgnored() async throws {
        // Given — Blatt fuer Vortrag.mp3 offen, Vortrag.mp3 wird erneut geteilt
        try self.shareAudioFile(named: "Vortrag.mp3")
        _ = await self.sut.processInbox()
        self.openEditor()
        try self.shareAudioFile(named: "Vortrag.mp3")
        _ = await self.appBecomesActive()

        // When
        let result = await self.closeEditor()

        // Then
        XCTAssertEqual(result, .empty)
        XCTAssertNil(self.mockFileOpenHandler.pendingImportSignal)
        XCTAssertEqual(try self.waitingEntries(), [])
    }

    func testLinkSharedAgainAfterImportFinishedSaysAlreadyThere() async throws {
        // Given — 25401 ist importiert und gespeichert, das Blatt ist zu
        let talk25401 = try self.talk25401
        let file = try self.prepareDownload(talk25401)
        self.mockMeditationService.mockFileExists = false
        try self.shareLink(talk25401)
        _ = await self.sut.processInbox()
        self.openEditor()
        self.mockMeditationService.meditations = [self.libraryEntry(for: file)]
        _ = await self.closeEditor()

        // When — erst jetzt wird 25401 erneut geteilt
        try self.shareLink(talk25401)
        let result = await self.appBecomesActive()

        // Then — wie bisher "Schon da"
        XCTAssertEqual(result, .audioImportFailed(.alreadyImported(name: "Talk", teacher: "Gil")))
    }

    func testLinkSharedAgainWhileEditingAnotherMeditationIsNotIgnored() async throws {
        // Given — 25401 ist importiert und gespeichert; spaeter ist das Blatt einer
        // vorhandenen Meditation offen, und 25401 wird erneut geteilt
        let talk25401 = try self.talk25401
        let file = try self.prepareDownload(talk25401)
        self.mockMeditationService.mockFileExists = false
        try self.shareLink(talk25401)
        _ = await self.sut.processInbox()
        self.openEditor()
        self.mockMeditationService.meditations = [self.libraryEntry(for: file)]
        _ = await self.closeEditor()
        self.isEditorOpen = true
        try self.shareLink(talk25401)
        _ = await self.appBecomesActive()

        // When
        let result = await self.closeEditor()

        // Then — der beendete Import zaehlt nicht mehr als laufend: "Schon da"
        XCTAssertEqual(result, .audioImportFailed(.alreadyImported(name: "Talk", teacher: "Gil")))
    }
}
