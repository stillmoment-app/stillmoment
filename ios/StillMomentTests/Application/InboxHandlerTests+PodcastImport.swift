//
//  InboxHandlerTests+PodcastImport.swift
//  Still Moment
//
//  shared-128: Ein geteilter Apple-Podcasts-Folgenlink wird zur Audiodatei aufgeloest
//  und laeuft danach durch den bekannten Link-Import.
//

import XCTest
@testable import StillMoment

extension InboxHandlerTests {
    static let episodeLink =
        "https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478?i=1000792422344"
    static let podcastLink = "https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478"

    /// Legt einen geteilten Link so in die Inbox, wie die Share-Extension es tut.
    func share(_ link: String) throws {
        let filename = try XCTUnwrap(URL(string: link)).lastPathComponent
        let reference = URLReference(url: link, filename: filename, timestamp: "2026-10-09T10:00:00Z")
        let fileURL = self.inboxDirectory.appendingPathComponent("\(UUID().uuidString)_shared.json")
        try FileManager.default.createFile(atPath: fileURL.path, contents: JSONEncoder().encode(reference))
    }

    func episode(audio: String = "https://anbieter.example/folge.mp3") throws -> PodcastEpisode {
        try PodcastEpisode(
            audioURL: XCTUnwrap(URL(string: audio)),
            title: "Body Scan (20:34 Min.)",
            podcastAuthor: "Deutschlandfunk Nova",
            podcastName: "Achtsam"
        )
    }

    // MARK: - Folge wird geladen

    func testSharedEpisodeIsLookedUpOnceAndLoadedFromProvider() async throws {
        // Given
        self.mockEpisodeResolver.episodeToReturn = try self.episode()
        try self.share(Self.episodeLink)

        // When
        let result = await self.sut.processInbox()

        // Then — Bearbeiten-Dialog fuer die geladene Datei, Audiodatei direkt beim Anbieter
        guard case .downloadCompleted = result else {
            return XCTFail("Expected .downloadCompleted, got \(result)")
        }
        XCTAssertEqual(
            self.mockEpisodeResolver.requests,
            [.init(country: "de", podcastId: 1_528_936_478, episodeId: 1_000_792_422_344)]
        )
        XCTAssertEqual(
            self.mockDownloadService.requestedURLs.map(\.absoluteString),
            ["https://anbieter.example/folge.mp3"]
        )
        XCTAssertNotNil(self.mockFileOpenHandler.pendingImportSignal)
        XCTAssertNil(self.sut.downloadError)
    }

    func testEditDialogSuggestsEpisodeTitleAndPodcastAuthor() async throws {
        // Given — die Datei selbst hat nichtssagende Tags
        self.mockMetadataService.fixedMetadata = AudioMetadata(artist: "DLF", title: "ep_123", duration: 1234)
        self.mockEpisodeResolver.episodeToReturn = try self.episode()
        try self.share(Self.episodeLink)

        // When
        _ = await self.sut.processInbox()

        // Then
        let metadata = self.mockFileOpenHandler.pendingImportSignal?.metadata
        XCTAssertEqual(metadata?.title, "Body Scan (20:34 Min.)")
        XCTAssertEqual(metadata?.artist, "Deutschlandfunk Nova")
    }

    func testEditDialogSuggestsPodcastNameWithoutAuthor() async throws {
        // Given
        self.mockEpisodeResolver.episodeToReturn = try PodcastEpisode(
            audioURL: XCTUnwrap(URL(string: "https://anbieter.example/folge.mp3")),
            title: "Body Scan",
            podcastAuthor: nil,
            podcastName: "Achtsam"
        )
        try self.share(Self.episodeLink)

        // When
        _ = await self.sut.processInbox()

        // Then
        XCTAssertEqual(self.mockFileOpenHandler.pendingImportSignal?.metadata.artist, "Achtsam")
    }

    func testLoadingWindowIsShownDuringLookup() async throws {
        // Given
        var visibleDuringLookup: Bool?
        self.mockEpisodeResolver.whileResolving = { [weak self] in
            visibleDuringLookup = self?.sut.isDownloading
        }
        try self.share(Self.episodeLink)

        // When
        _ = await self.sut.processInbox()

        // Then
        XCTAssertEqual(visibleDuringLookup, true)
        XCTAssertFalse(self.sut.isDownloading)
    }

    // MARK: - Ganzer Podcast

    func testWholePodcastAsksForSingleEpisodeWithoutNetwork() async throws {
        // Given
        try self.share(Self.podcastLink)

        // When
        let result = await self.sut.processInbox()

        // Then
        XCTAssertEqual(result, .error(.podcastWithoutEpisode))
        XCTAssertEqual(self.sut.downloadError, .podcastWithoutEpisode)
        XCTAssertTrue(self.mockEpisodeResolver.requests.isEmpty)
        XCTAssertTrue(self.mockDownloadService.requestedURLs.isEmpty)
    }

    // MARK: - Fehler

    func testLookupNotReachableShowsTryLaterMessage() async throws {
        self.mockEpisodeResolver.errorToThrow = .notReachable
        try self.share(Self.episodeLink)

        let result = await self.sut.processInbox()

        XCTAssertEqual(result, .error(.notReachable))
        XCTAssertEqual(self.sut.downloadError, .notReachable)
        XCTAssertTrue(self.mockDownloadService.requestedURLs.isEmpty)
    }

    func testEpisodeNotFoundShowsCannotBeImported() async throws {
        self.mockEpisodeResolver.errorToThrow = .unavailable
        try self.share(Self.episodeLink)

        let result = await self.sut.processInbox()

        XCTAssertEqual(result, .error(.episodeUnavailable))
        XCTAssertEqual(self.sut.downloadError, .episodeUnavailable)
    }

    func testEpisodeDownloadProblemsShowOneOfTheThreeMessages() async throws {
        let cases: [(AudioDownloadError, InboxError)] = [
            (.networkError, .notReachable),
            (.invalidResponse, .episodeUnavailable),
            (.unsupportedContentType, .episodeUnavailable)
        ]
        for (downloadError, expected) in cases {
            self.mockDownloadService.errorToThrow = downloadError
            self.sut.downloadError = nil
            try self.share(Self.episodeLink)

            let result = await self.sut.processInbox()

            XCTAssertEqual(result, .error(expected), "\(downloadError)")
            XCTAssertEqual(self.sut.downloadError, expected, "\(downloadError)")
        }
    }

    func testEpisodeFileRejectedByImporterShowsCannotBeImported() async throws {
        // Given — Anbieter liefert eine Datei ohne Audio-Endung
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)_feed")
        FileManager.default.createFile(atPath: file.path, contents: Data("x".utf8))
        defer { try? FileManager.default.removeItem(at: file) }
        self.mockDownloadService.downloadedFileURL = file
        try self.share(Self.episodeLink)

        // When
        let result = await self.sut.processInbox()

        // Then
        XCTAssertEqual(result, .error(.episodeUnavailable))
        XCTAssertNil(self.mockFileOpenHandler.pendingImportSignal)
    }

    // MARK: - Abbrechen

    func testCancelDuringLookupStopsLookupWithoutMessageOrDownload() async throws {
        // Given
        self.mockEpisodeResolver.whileResolving = { [weak self] in
            self?.sut.cancelDownload()
        }
        try self.share(Self.episodeLink)

        // When
        let result = await self.sut.processInbox()

        // Then
        XCTAssertEqual(result, .empty)
        XCTAssertTrue(self.mockEpisodeResolver.cancelCalled)
        XCTAssertTrue(self.mockDownloadService.requestedURLs.isEmpty)
        XCTAssertNil(self.sut.downloadError)
        XCTAssertNil(self.mockFileOpenHandler.pendingImportSignal)
        XCTAssertFalse(self.sut.isDownloading)
    }

    func testCancelBetweenLookupAndDownloadStartsNoDownload() async throws {
        // Given — die Suche ist schon fertig, als Abbrechen getippt wird
        self.mockEpisodeResolver.afterResolved = { [weak self] in
            self?.sut.cancelDownload()
        }
        try self.share(Self.episodeLink)

        // When
        let result = await self.sut.processInbox()

        // Then
        XCTAssertEqual(result, .empty)
        XCTAssertTrue(self.mockDownloadService.requestedURLs.isEmpty)
        XCTAssertNil(self.sut.downloadError)
    }

    func testCancelDuringEpisodeDownloadCreatesNoEntry() async throws {
        // Given
        self.mockDownloadService.whileDownloading = { [weak self] in
            self?.sut.cancelDownload()
        }
        try self.share(Self.episodeLink)

        // When
        let result = await self.sut.processInbox()

        // Then
        XCTAssertEqual(result, .empty)
        XCTAssertNil(self.sut.downloadError)
        XCTAssertNil(self.mockFileOpenHandler.pendingImportSignal)
    }

    // MARK: - Kein Netz ohne Teilen

    func testNoLookupWithoutSharedLink() async {
        _ = await self.sut.processInbox()

        XCTAssertTrue(self.mockEpisodeResolver.requests.isEmpty)
        XCTAssertTrue(self.mockDownloadService.requestedURLs.isEmpty)
    }

    func testRegularLinkIsLoadedWithoutLookup() async throws {
        try self.share("https://www.audiodharma.org/talks/25401/download")

        _ = await self.sut.processInbox()

        XCTAssertTrue(self.mockEpisodeResolver.requests.isEmpty)
        XCTAssertEqual(self.mockDownloadService.requestedURLs.count, 1)
    }
}
