//
//  AudioDownloadServiceTests.swift
//  Still Moment
//
//  TDD RED phase — tests for AudioDownloadService (implementation does not exist yet)
//

import XCTest
@testable import StillMoment

final class AudioDownloadServiceTests: XCTestCase {
    // MARK: - Properties

    private var sut: AudioDownloadService?
    private var mockSession: URLSession?

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        self.mockSession = session
        self.sut = AudioDownloadService(session: session)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        self.sut = nil
        self.mockSession = nil
        super.tearDown()
    }

    // MARK: - Successful Download

    func testDownloadSucceeds_returnsLocalFileURL() async throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://example.com/meditation.mp3"))
        let responseData = Data("fake audio content".utf8)

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "audio/mpeg"]
            ))
            return (response, responseData)
        }

        // When
        let localURL = try await sut.download(from: remoteURL, filename: "meditation.mp3")

        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: localURL.path))
    }

    func testDownloadedFilePreservesMp3Extension() async throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://example.com/session.mp3"))

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "audio/mpeg"]
            ))
            return (response, Data("audio".utf8))
        }

        // When
        let localURL = try await sut.download(from: remoteURL, filename: "session.mp3")

        // Then
        XCTAssertEqual(localURL.pathExtension, "mp3")
    }

    func testDownloadedFilePreservesM4aExtension() async throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://example.com/calm.m4a"))

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "audio/mp4"]
            ))
            return (response, Data("audio".utf8))
        }

        // When
        let localURL = try await sut.download(from: remoteURL, filename: "calm.m4a")

        // Then
        XCTAssertEqual(localURL.pathExtension, "m4a")
    }

    // MARK: - URL ohne Datei-Endung (audiodharma-Style)

    func testDownloadFromURLWithoutFileExtension_audioMpegContentType_savesAsMp3() async throws {
        // Given — URL ohne .mp3/.m4a-Endung (z. B. https://www.audiodharma.org/talks/25401/download)
        // Server liefert audio/mpeg, kein Content-Disposition
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://www.audiodharma.org/talks/25401/download"))

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "audio/mpeg"]
            ))
            return (response, Data("audio".utf8))
        }

        // When
        let localURL = try await sut.download(from: remoteURL, filename: "talk-25401")

        // Then — Endung aus Content-Type abgeleitet, FileOpenHandler.canHandle akzeptiert sie
        XCTAssertTrue(FileManager.default.fileExists(atPath: localURL.path))
        XCTAssertEqual(localURL.pathExtension, "mp3")
    }

    func testDownloadFromURLWithoutExtension_contentDispositionFilename_usesServerFilename() async throws {
        // Given — URL ohne Endung, aber Server liefert Content-Disposition mit echtem Filename
        // (audiodharma S3-Antwort liefert genau das)
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://www.audiodharma.org/talks/25401/download"))

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [
                    "Content-Type": "audio/mpeg",
                    "Content-Disposition": "attachment; filename=\"20260504-David_Lorey-IMC-guided.mp3\""
                ]
            ))
            return (response, Data("audio".utf8))
        }

        // When
        let localURL = try await sut.download(from: remoteURL, filename: "talk-25401")

        // Then — Filename aus Content-Disposition gewinnt vor Parameter
        XCTAssertEqual(localURL.lastPathComponent, "20260504-David_Lorey-IMC-guided.mp3")
        XCTAssertEqual(localURL.pathExtension, "mp3")
    }

    func testDownloadFromURLWithoutExtension_audioMp4ContentType_savesAsM4a() async throws {
        // Given — URL ohne Endung, Server liefert audio/mp4
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://example.com/episode/42"))

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "audio/mp4"]
            ))
            return (response, Data("audio".utf8))
        }

        // When
        let localURL = try await sut.download(from: remoteURL, filename: "42")

        // Then
        XCTAssertEqual(localURL.pathExtension, "m4a")
    }

    func testDownloadFromURLWithoutExtension_octetStream_fallsBackToMp3() async throws {
        // Given — URL ohne Endung, Server liefert generischen Content-Type
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://example.com/audio/feed"))

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/octet-stream"]
            ))
            return (response, Data("audio".utf8))
        }

        // When
        let localURL = try await sut.download(from: remoteURL, filename: "feed")

        // Then — Fallback auf .mp3 (FileOpenHandler.canHandle akzeptiert)
        XCTAssertEqual(localURL.pathExtension, "mp3")
    }

    func testDownloadFromURLWithoutExtension_audioXM4aContentType_savesAsM4a() async throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://example.com/podcast"))

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "audio/x-m4a"]
            ))
            return (response, Data("audio".utf8))
        }

        // When
        let localURL = try await sut.download(from: remoteURL, filename: "podcast")

        // Then
        XCTAssertEqual(localURL.pathExtension, "m4a")
    }

    func testDownloadFromURLWithoutExtension_htmlContentType_throwsUnsupportedContentType() async throws {
        // Given — URL ohne Endung, Server antwortet mit text/html (typisch fuer Linksammlungen)
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://www.example.com/"))

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "text/html"]
            ))
            return (response, Data("<html></html>".utf8))
        }

        // When / Then
        do {
            _ = try await sut.download(from: remoteURL, filename: "page")
            XCTFail("Expected unsupportedContentType for non-audio URL without extension")
        } catch {
            guard let downloadError = error as? AudioDownloadError else {
                return XCTFail("Expected AudioDownloadError, got \(error)")
            }
            XCTAssertEqual(downloadError, .unsupportedContentType)
        }
    }

    // MARK: - Network Error

    func testDownloadWithNetworkError_throwsNetworkError() async throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://example.com/unreachable.mp3"))

        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        // When / Then
        do {
            _ = try await sut.download(from: remoteURL, filename: "unreachable.mp3")
            XCTFail("Expected networkError to be thrown")
        } catch {
            guard let downloadError = error as? AudioDownloadError else {
                return XCTFail("Expected AudioDownloadError, got \(error)")
            }
            XCTAssertEqual(downloadError, .networkError)
        }
    }

    // MARK: - Invalid Response (non-2xx)

    func testDownloadWith404Response_throwsInvalidResponse() async throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://example.com/missing.mp3"))

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: url,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            ))
            return (response, Data())
        }

        // When / Then
        do {
            _ = try await sut.download(from: remoteURL, filename: "missing.mp3")
            XCTFail("Expected invalidResponse to be thrown")
        } catch {
            guard let downloadError = error as? AudioDownloadError else {
                return XCTFail("Expected AudioDownloadError, got \(error)")
            }
            XCTAssertEqual(downloadError, .invalidResponse)
        }
    }

    func testDownloadWith500Response_throwsInvalidResponse() async throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://example.com/error.mp3"))

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: url,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            ))
            return (response, Data())
        }

        // When / Then
        do {
            _ = try await sut.download(from: remoteURL, filename: "error.mp3")
            XCTFail("Expected invalidResponse to be thrown")
        } catch {
            guard let downloadError = error as? AudioDownloadError else {
                return XCTFail("Expected AudioDownloadError, got \(error)")
            }
            XCTAssertEqual(downloadError, .invalidResponse)
        }
    }

    // MARK: - Unsupported Content Type

    func testDownloadWithHtmlContentType_throwsUnsupportedContentType() async throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://example.com/page.mp3"))

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "text/html"]
            ))
            return (response, Data("<html>Not audio</html>".utf8))
        }

        // When / Then
        do {
            _ = try await sut.download(from: remoteURL, filename: "page.mp3")
            XCTFail("Expected unsupportedContentType to be thrown")
        } catch {
            guard let downloadError = error as? AudioDownloadError else {
                return XCTFail("Expected AudioDownloadError, got \(error)")
            }
            XCTAssertEqual(downloadError, .unsupportedContentType)
        }
    }

    // MARK: - Cancellation

    func testCancelDownload_throwsDownloadCancelled() async throws {
        // Given
        let sut = try XCTUnwrap(self.sut)
        let remoteURL = try XCTUnwrap(URL(string: "https://example.com/long.mp3"))

        MockURLProtocol.requestHandler = { _ in
            // Simulate a slow response so cancellation can take effect
            try await Task.sleep(nanoseconds: 5_000_000_000)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: remoteURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "audio/mpeg"]
            ))
            return (response, Data("audio".utf8))
        }

        // When
        let task = Task {
            try await sut.download(from: remoteURL, filename: "long.mp3")
        }

        // Give the download a moment to start, then cancel
        try? await Task.sleep(nanoseconds: 50_000_000)
        sut.cancelDownload()

        // Then
        do {
            _ = try await task.value
            XCTFail("Expected downloadCancelled to be thrown")
        } catch {
            guard let downloadError = error as? AudioDownloadError else {
                return XCTFail("Expected AudioDownloadError, got \(error)")
            }
            XCTAssertEqual(downloadError, .downloadCancelled)
        }
    }

    // MARK: - Error Descriptions

    func testAudioDownloadErrorNetworkError_hasLocalizedDescription() {
        let error = AudioDownloadError.networkError
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func testAudioDownloadErrorInvalidResponse_hasLocalizedDescription() {
        let error = AudioDownloadError.invalidResponse
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func testAudioDownloadErrorUnsupportedContentType_hasLocalizedDescription() {
        let error = AudioDownloadError.unsupportedContentType
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }

    func testAudioDownloadErrorDownloadCancelled_hasLocalizedDescription() {
        let error = AudioDownloadError.downloadCancelled
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
    }
}

// MARK: - MockURLProtocol

/// URLProtocol subclass that intercepts network requests for testing.
/// Supports both sync and async request handlers.
final class MockURLProtocol: URLProtocol {
    /// Handler that receives the request and returns a response + data, or throws.
    static var requestHandler: ((URLRequest) async throws -> (HTTPURLResponse, Data))?

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        let request = self.request
        Task {
            do {
                let (response, data) = try await handler(request)
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                self.client?.urlProtocol(self, didLoad: data)
                self.client?.urlProtocolDidFinishLoading(self)
            } catch {
                self.client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {
        // No-op for mock
    }
}
