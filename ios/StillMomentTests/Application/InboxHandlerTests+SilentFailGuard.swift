//
//  InboxHandlerTests+SilentFailGuard.swift
//  Still Moment
//
//  shared-091: Garantie "kein Silent Fail" — jeder Fehlerpfad muss
//  via downloadError sichtbar sein, sonst sieht der User nichts.
//

import XCTest
@testable import StillMoment

extension InboxHandlerTests {
    func testInvalidJSONInInboxReferenceSetsDownloadError() async {
        // Given — JSON file in inbox that can't be parsed as URLReference
        // (theoretisch: ShareExtension hat korruptes JSON geschrieben)
        let filename = "\(UUID().uuidString)_invalid.json"
        let fileURL = self.inboxDirectory.appendingPathComponent(filename)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data("not valid json".utf8))

        // When
        let result = await self.sut.processInbox()

        // Then — Fehler wird sowohl als Result als auch via downloadError publiziert.
        // Ohne downloadError waere der Fehler fuer den User unsichtbar (silent fail).
        if case let .error(error) = result {
            XCTAssertEqual(error, .downloadFailed)
        } else {
            XCTFail("Expected .error(.downloadFailed), got \(result)")
        }
        XCTAssertEqual(
            self.sut.downloadError,
            .downloadFailed,
            "Inbox-Fehler muessen via downloadError sichtbar werden — sonst silent fail"
        )
    }
}
