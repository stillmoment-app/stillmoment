//
//  AudioDownloadServiceContentTypeTests.swift
//  Still Moment
//
//  shared-131: Link- und Podcast-Import nehmen dieselben Dateitypen an wie Android und lehnen
//  andere ab, bevor die Datei vollstaendig geladen ist — ohne Abbrechen und lange Folgen zu brechen.
//

import XCTest
@testable import StillMoment

final class AudioDownloadServiceContentTypeTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        self.sut = AudioDownloadService(session: URLSession(configuration: configuration))
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.bodyDelayNanoseconds = 0
        MockURLProtocol.redirects = [:]
        MockURLProtocol.onResponseDelivered = nil
        self.sut = nil
        super.tearDown()
    }

    // MARK: - Ablehnen

    func testOtherAudioFormatIsRejectedWithoutWaitingForTheFile() async throws {
        // Given — Kopfzeilen kommen sofort, der Inhalt erst nach 5 s
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://anbieter.example/folge.ogg"))
        MockURLProtocol.bodyDelayNanoseconds = Self.slowBody
        MockURLProtocol.requestHandler = { request in
            try Self.answer(request, contentType: "audio/ogg", body: Data(count: 50000))
        }
        let start = Date()

        // When
        let error = await Self.downloadError(sut, from: remoteURL)

        // Then
        XCTAssertEqual(error, .unsupportedContentType)
        XCTAssertLessThan(Date().timeIntervalSince(start), 2, "Abgelehnt, bevor die Datei geladen ist")
    }

    func testPlaylistIsRejectedAndLeavesNoFileBehind() async throws {
        // Given — Wiedergabeliste, deren Typ nur mit "audio/mpeg" beginnt
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://anbieter.example/liste.m3u"))
        MockURLProtocol.requestHandler = { request in
            try Self.answer(request, contentType: "audio/x-mpegurl", body: Data("#EXTM3U".utf8))
        }
        let foldersBefore = Self.downloadFolders()
        let dataFilesBefore = Self.sessionFilesWithData()

        // When
        let error = await Self.downloadError(sut, from: remoteURL)

        // Then — no file for the import and no downloaded data stays behind
        XCTAssertEqual(error, .unsupportedContentType)
        XCTAssertEqual(Self.downloadFolders(), foldersBefore)
        XCTAssertEqual(Self.sessionFilesWithData(), dataFilesBefore)
    }

    func testSmallFileWithOtherAudioFormatIsRejected() async throws {
        // Given — kleiner Inhalt, der schon vollstaendig da sein kann, bevor geprueft wird
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://anbieter.example/kurz.ogg"))
        MockURLProtocol.requestHandler = { request in
            try Self.answer(request, contentType: "audio/ogg", body: Data("OggS".utf8))
        }

        // When
        let error = await Self.downloadError(sut, from: remoteURL)

        // Then
        XCTAssertEqual(error, .unsupportedContentType)
    }

    func testEmptyReportedTypeIsRejected() async throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://anbieter.example/folge"))
        MockURLProtocol.requestHandler = { request in
            try Self.answer(request, contentType: "", body: Data("audio".utf8))
        }

        // When
        let error = await Self.downloadError(sut, from: remoteURL)

        // Then
        XCTAssertEqual(error, .unsupportedContentType)
    }

    func testServerErrorPageStaysAServerError() async throws {
        // Given — 404 mit HTML ist ein Serverfehler, kein falscher Dateityp
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://anbieter.example/weg.mp3"))
        MockURLProtocol.bodyDelayNanoseconds = Self.shortDelay
        MockURLProtocol.requestHandler = { request in
            try Self.answer(request, status: 404, contentType: "text/html", body: Data("<html/>".utf8))
        }

        // When
        let error = await Self.downloadError(sut, from: remoteURL)

        // Then
        XCTAssertEqual(error, .invalidResponse)
    }

    // MARK: - Annehmen

    func testNonStandardMp3TypesAreLoadedAsMp3() async throws {
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://anbieter.example/talks/1/download"))
        for contentType in ["audio/x-mpeg", "audio/mpeg3", "Audio/MPEG; charset=UTF-8"] {
            // Given
            MockURLProtocol.requestHandler = { request in
                try Self.answer(request, contentType: contentType, body: Data("audio".utf8))
            }

            // When
            let localURL = try await sut.download(from: remoteURL, filename: "download")
            defer { try? FileManager.default.removeItem(at: localURL.deletingLastPathComponent()) }

            // Then
            XCTAssertEqual(localURL.pathExtension, "mp3", contentType)
        }
    }

    func testSlowAcceptedFileIsLoadedCompletely() async throws {
        // Given — Typ passt, Inhalt kommt verzoegert (lange Folge)
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://anbieter.example/lang.mp3"))
        let content = Data((0..<300_000).map { UInt8($0 % 251) })
        MockURLProtocol.bodyDelayNanoseconds = Self.shortDelay
        MockURLProtocol.requestHandler = { request in
            try Self.answer(request, contentType: "audio/mpeg", body: content)
        }

        // When
        let localURL = try await sut.download(from: remoteURL, filename: "lang.mp3")
        defer { try? FileManager.default.removeItem(at: localURL.deletingLastPathComponent()) }

        // Then
        XCTAssertEqual(try Data(contentsOf: localURL), content)
    }

    func testFileWithoutReportedTypeIsLoaded() async throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://anbieter.example/folge.mp3"))
        MockURLProtocol.bodyDelayNanoseconds = Self.shortDelay
        MockURLProtocol.requestHandler = { request in
            try Self.answer(request, contentType: nil, body: Data("audio".utf8))
        }

        // When
        let localURL = try await sut.download(from: remoteURL, filename: "folge.mp3")
        defer { try? FileManager.default.removeItem(at: localURL.deletingLastPathComponent()) }

        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: localURL.path))
    }

    // MARK: - Weiterleitung (audiodharma: /talks/<id>/download → 302 → Datei beim Speicheranbieter)

    func testRedirectedMp3IsLoadedCompletely() async throws {
        // Given — die Weiterleitung selbst meldet text/html, das Ziel audio/mp3
        let sut = try XCTUnwrap(self.sut)
        let sharedURL = try XCTUnwrap(URL(string: "https://www.audiodharma.org/talks/25407/download"))
        let fileURL = try XCTUnwrap(URL(string: "https://speicher.example/talk-25407.mp3"))
        let content = Data((0..<100_000).map { UInt8($0 % 251) })
        MockURLProtocol.redirects = [sharedURL: fileURL]
        MockURLProtocol.bodyDelayNanoseconds = Self.shortDelay
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, fileURL)
            return try Self.answer(request, contentType: "audio/mp3", body: content)
        }

        // When
        let localURL = try await sut.download(from: sharedURL, filename: "download")
        defer { try? FileManager.default.removeItem(at: localURL.deletingLastPathComponent()) }

        // Then
        XCTAssertEqual(localURL.pathExtension, "mp3")
        XCTAssertEqual(try Data(contentsOf: localURL), content)
    }

    func testRedirectedOtherAudioFormatIsRejectedWithoutWaitingForTheFile() async throws {
        // Given — Weiterleitung auf eine Ogg-Datei, deren Inhalt erst nach 5 s kommt
        let sut = try XCTUnwrap(self.sut)
        let sharedURL = try XCTUnwrap(URL(string: "https://www.audiodharma.org/talks/1/download"))
        let fileURL = try XCTUnwrap(URL(string: "https://speicher.example/talk-1.ogg"))
        MockURLProtocol.redirects = [sharedURL: fileURL]
        MockURLProtocol.bodyDelayNanoseconds = Self.slowBody
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, fileURL)
            return try Self.answer(request, contentType: "audio/ogg", body: Data(count: 50000))
        }
        let start = Date()

        // When
        let error = await Self.downloadError(sut, from: sharedURL)

        // Then
        XCTAssertEqual(error, .unsupportedContentType)
        XCTAssertLessThan(Date().timeIntervalSince(start), 2, "Abgelehnt, bevor die Datei geladen ist")
    }

    // MARK: - Abbrechen

    func testCancellingAnAcceptedRunningDownloadIsStillACancel() async throws {
        // Given — Kopfzeilen sind da und passen, der Inhalt laeuft noch
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://anbieter.example/lang.mp3"))
        MockURLProtocol.bodyDelayNanoseconds = Self.slowBody
        MockURLProtocol.requestHandler = { request in
            try Self.answer(request, contentType: "audio/mpeg", body: Data(count: 50000))
        }
        let responseArrived = self.expectation(description: "Antwort beim Client")
        MockURLProtocol.onResponseDelivered = { responseArrived.fulfill() }
        let start = Date()
        let download = Task { await Self.downloadError(sut, from: remoteURL) }

        // When — erst abbrechen, wenn die passenden Kopfzeilen angekommen sind
        await self.fulfillment(of: [responseArrived], timeout: 5)
        sut.cancelDownload()

        // Then
        let error = await download.value
        XCTAssertEqual(error, .downloadCancelled)
        XCTAssertLessThan(Date().timeIntervalSince(start), 2, "Abbrechen wirkt sofort")
    }

    // MARK: Private

    private static let slowBody: UInt64 = 5_000_000_000
    private static let shortDelay: UInt64 = 200_000_000

    private var sut: AudioDownloadService?

    private static func answer(
        _ request: URLRequest,
        status: Int = 200,
        contentType: String?,
        body: Data
    ) throws -> (HTTPURLResponse, Data) {
        let headers = contentType.map { ["Content-Type": $0] }
        let response = try XCTUnwrap(HTTPURLResponse(
            url: XCTUnwrap(request.url),
            statusCode: status,
            httpVersion: nil,
            headerFields: headers
        ))
        return (response, body)
    }

    /// The download error, or `nil` if the download unexpectedly succeeded.
    private static func downloadError(_ sut: AudioDownloadService, from url: URL) async -> AudioDownloadError? {
        do {
            let localURL = try await sut.download(from: url, filename: url.lastPathComponent)
            try? FileManager.default.removeItem(at: localURL.deletingLastPathComponent())
            return nil
        } catch {
            return error as? AudioDownloadError
        }
    }

    /// Per-download folders (`dl_<UUID>`) the service creates in the temp directory.
    private static func downloadFolders() -> Set<String> {
        self.tempEntries().filter { $0.hasPrefix("dl_") }
    }

    /// URLSession's download files in the temp directory that contain data.
    ///
    /// A *cancelled* download task — user cancel as well as rejection — leaves an empty
    /// `CFNetworkDownload_*.tmp` placeholder; the async API never reveals its path. Only
    /// files with content would cost storage.
    private static func sessionFilesWithData() -> Set<String> {
        self.tempEntries().filter { name in
            guard name.hasPrefix("CFNetworkDownload") else {
                return false
            }
            let path = (NSTemporaryDirectory() as NSString).appendingPathComponent(name)
            let size = (try? FileManager.default.attributesOfItem(atPath: path))?[.size] as? Int
            return (size ?? 0) > 0
        }
    }

    private static func tempEntries() -> Set<String> {
        Set((try? FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())) ?? [])
    }
}
