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
            guard let inbox = self?.inboxDirectory else {
                return
            }
            try? ShareInbox.storeLink(link, in: inbox)
        }
    }

    /// Die Adressen der Links, die in der Inbox warten
    func waitingLinks() throws -> [String] {
        try self.waitingEntries()
            .filter { $0.pathExtension == "json" }
            .map { try JSONDecoder().decode(URLReference.self, from: Data(contentsOf: $0)).url }
    }

    /// Die Namen aller Eintraege, die in der Inbox warten
    func waitingEntries() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: self.inboxDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
    }

    // MARK: - Kein stiller Verlust bei gleichem Namen (AK-7)

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
