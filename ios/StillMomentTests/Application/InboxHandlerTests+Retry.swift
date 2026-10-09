//
//  InboxHandlerTests+Retry.swift
//  Still Moment
//
//  shared-128: "Erneut versuchen" laedt den geteilten Link tatsaechlich erneut —
//  der Inbox-Eintrag ist nach dem ersten Versuch schon aufgeraeumt.
//

import XCTest
@testable import StillMoment

extension InboxHandlerTests {
    func testLinkImportWithoutConnectionShowsTryLaterMessage() async throws {
        // Given — direkter MP3-Link, kein Internet
        self.mockDownloadService.errorToThrow = .networkError
        try self.share("https://example.com/meditation.mp3")

        // When
        let result = await self.sut.processInbox()

        // Then — dieselbe Meldung wie beim Podcast-Import, statt "Download fehlgeschlagen"
        XCTAssertEqual(result, .error(.notReachable))
        XCTAssertEqual(self.sut.downloadError, .notReachable)
    }

    func testRetryLoadsSameLinkAgain() async throws {
        // Given
        self.mockDownloadService.errorToThrow = .networkError
        try self.share("https://example.com/meditation.mp3")
        _ = await self.sut.processInbox()

        // When — Netz ist wieder da
        self.mockDownloadService.errorToThrow = nil
        self.sut.downloadError = nil
        let result = await self.sut.retry()

        // Then
        guard case .downloadCompleted = result else {
            return XCTFail("Expected .downloadCompleted, got \(result)")
        }
        XCTAssertEqual(
            self.mockDownloadService.requestedURLs.map(\.absoluteString),
            ["https://example.com/meditation.mp3", "https://example.com/meditation.mp3"]
        )
        XCTAssertNotNil(self.mockFileOpenHandler.pendingImportSignal)
    }

    func testRetryResolvesSameEpisodeAgain() async throws {
        // Given
        self.mockEpisodeResolver.errorToThrow = .notReachable
        try self.share(Self.episodeLink)
        _ = await self.sut.processInbox()

        // When
        self.mockEpisodeResolver.errorToThrow = nil
        self.sut.downloadError = nil
        let result = await self.sut.retry()

        // Then
        guard case .downloadCompleted = result else {
            return XCTFail("Expected .downloadCompleted, got \(result)")
        }
        XCTAssertEqual(self.mockEpisodeResolver.requests.count, 2)
        XCTAssertEqual(self.mockEpisodeResolver.requests.last?.episodeId, 1_000_792_422_344)
    }

    func testRetryShowsMessageAgainIfStillNotReachable() async throws {
        // Given
        self.mockDownloadService.errorToThrow = .networkError
        try self.share("https://example.com/meditation.mp3")
        _ = await self.sut.processInbox()
        self.sut.downloadError = nil

        // When
        let result = await self.sut.retry()

        // Then — nie stilles Scheitern
        XCTAssertEqual(result, .error(.notReachable))
        XCTAssertEqual(self.sut.downloadError, .notReachable)
    }

    func testNoRetryAfterSuccessfulImport() async throws {
        // Given
        try self.share("https://example.com/meditation.mp3")
        _ = await self.sut.processInbox()

        // When
        let result = await self.sut.retry()

        // Then
        XCTAssertEqual(result, .empty)
        XCTAssertEqual(self.mockDownloadService.requestedURLs.count, 1)
    }
}
