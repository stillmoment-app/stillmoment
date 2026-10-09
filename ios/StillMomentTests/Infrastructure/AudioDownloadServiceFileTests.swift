//
//  AudioDownloadServiceFileTests.swift
//  Still Moment
//
//  shared-128: Der Download landet direkt in einer Datei (Folgen > 2 h ohne Arbeitsspeicher-Spitze),
//  keine Reste bei Fehlern, keine Cookies.
//

import XCTest
@testable import StillMoment

final class AudioDownloadServiceFileTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        self.sut = AudioDownloadService(session: URLSession(configuration: configuration))
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        self.sut = nil
        super.tearDown()
    }

    func testDownloadedFileHasIdenticalContentInOwnDownloadFolder() async throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://anbieter.example/folge.mp3"))
        let content = Data((0..<200_000).map { UInt8($0 % 251) })
        MockURLProtocol.requestHandler = { request in
            try Self.answer(request, status: 200, contentType: "audio/mpeg", body: content)
        }
        let leftoversBefore = Self.sessionTempFiles()

        // When
        let localURL = try await sut.download(from: remoteURL, filename: "folge.mp3")
        defer { try? FileManager.default.removeItem(at: localURL.deletingLastPathComponent()) }

        // Then
        XCTAssertEqual(try Data(contentsOf: localURL), content)
        XCTAssertEqual(localURL.lastPathComponent, "folge.mp3")
        XCTAssertTrue(localURL.deletingLastPathComponent().lastPathComponent.hasPrefix("dl_"))
        XCTAssertEqual(Self.sessionTempFiles(), leftoversBefore, "Temporaere Datei wird verschoben, nicht kopiert")
    }

    func testFailedDownloadLeavesNoFileBehind() async throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://anbieter.example/weg.mp3"))
        let leftoversBefore = Self.sessionTempFiles()

        for (status, contentType) in [(404, "audio/mpeg"), (200, "text/html")] {
            MockURLProtocol.requestHandler = { request in
                try Self.answer(request, status: status, contentType: contentType, body: Data(count: 50000))
            }

            // When
            _ = try? await sut.download(from: remoteURL, filename: "weg.mp3")
        }

        // Then
        XCTAssertEqual(Self.sessionTempFiles(), leftoversBefore)
    }

    func testDownloadSendsNoCookies() async throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://anbieter.example/folge.mp3"))
        var handlesCookies: Bool?
        MockURLProtocol.requestHandler = { request in
            handlesCookies = request.httpShouldHandleCookies
            return try Self.answer(request, status: 200, contentType: "audio/mpeg", body: Data("audio".utf8))
        }

        // When
        let localURL = try await sut.download(from: remoteURL, filename: "folge.mp3")
        try? FileManager.default.removeItem(at: localURL.deletingLastPathComponent())

        // Then
        XCTAssertEqual(handlesCookies, false)
    }

    // MARK: Private

    private var sut: AudioDownloadService?

    private static func answer(
        _ request: URLRequest,
        status: Int,
        contentType: String,
        body: Data
    ) throws -> (HTTPURLResponse, Data) {
        let response = try XCTUnwrap(HTTPURLResponse(
            url: XCTUnwrap(request.url),
            statusCode: status,
            httpVersion: nil,
            headerFields: ["Content-Type": contentType]
        ))
        return (response, body)
    }

    /// Files URLSession writes for download tasks (`CFNetworkDownload_*.tmp`) in the temp directory.
    private static func sessionTempFiles() -> Set<String> {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())) ?? []
        return Set(names.filter { $0.hasPrefix("CFNetworkDownload") })
    }
}
