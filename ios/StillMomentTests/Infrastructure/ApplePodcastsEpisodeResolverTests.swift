//
//  ApplePodcastsEpisodeResolverTests.swift
//  Still Moment
//
//  shared-128: Abfrage beim Apple-Podcast-Verzeichnis — ausschliesslich ueber MockURLProtocol.
//

import XCTest
@testable import StillMoment

final class ApplePodcastsEpisodeResolverTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        self.sut = ApplePodcastsEpisodeResolver(session: URLSession(configuration: configuration))
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        self.sut = nil
        super.tearDown()
    }

    // MARK: - Anfrage

    func testLookupAsksDirectoryForPodcastEpisodesInSharedCountry() async throws {
        let sut = try XCTUnwrap(self.sut)
        var requestedURL: URL?
        MockURLProtocol.requestHandler = { request in
            requestedURL = request.url
            return try Self.answer(request, status: 200, body: Self.validBody)
        }

        _ = try await sut.resolveEpisode(country: "us", podcastId: 1_528_936_478, episodeId: Self.episodeId)

        let components = try XCTUnwrap(URLComponents(url: XCTUnwrap(requestedURL), resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "itunes.apple.com")
        XCTAssertEqual(components.path, "/lookup")
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
        XCTAssertEqual(query, [
            "id": "1528936478",
            "entity": "podcastEpisode",
            "limit": "200",
            "country": "us"
        ])
    }

    func testLookupRequestCarriesNoExtraHeadersOrIdentifiers() throws {
        let request = try XCTUnwrap(
            ApplePodcastsEpisodeResolver.lookupRequest(country: "de", podcastId: 1_528_936_478)
        )

        XCTAssertTrue((request.allHTTPHeaderFields ?? [:]).isEmpty)
        XCTAssertFalse(request.httpShouldHandleCookies)
    }

    func testFoundEpisodeIsReturned() async throws {
        let sut = try XCTUnwrap(self.sut)
        MockURLProtocol.requestHandler = { request in
            try Self.answer(request, status: 200, body: Self.validBody)
        }

        let episode = try await sut.resolveEpisode(country: "de", podcastId: 1_528_936_478, episodeId: Self.episodeId)

        XCTAssertEqual(episode.audioURL.absoluteString, "https://anbieter.example/folge.mp3")
    }

    // MARK: - Fehlerzuordnung

    func testRateLimitAnswersMeanNotReachable() async {
        for status in [403, 429] {
            MockURLProtocol.requestHandler = { request in
                try Self.answer(request, status: status, body: "")
            }

            let error = await self.resolveError()

            XCTAssertEqual(error, .notReachable, "HTTP \(status)")
        }
    }

    func testOtherServerErrorsMeanUnavailable() async {
        for status in [404, 500] {
            MockURLProtocol.requestHandler = { request in
                try Self.answer(request, status: status, body: "")
            }

            let error = await self.resolveError()

            XCTAssertEqual(error, .unavailable, "HTTP \(status)")
        }
    }

    func testNoConnectionAndTimeoutMeanNotReachable() async {
        for code in [URLError.Code.notConnectedToInternet, .timedOut] {
            MockURLProtocol.requestHandler = { _ in
                throw URLError(code)
            }

            let error = await self.resolveError()

            XCTAssertEqual(error, .notReachable, "\(code)")
        }
    }

    func testCancelStopsTheLookup() async throws {
        let sut = try XCTUnwrap(self.sut)
        MockURLProtocol.requestHandler = { request in
            try await Task.sleep(nanoseconds: 5_000_000_000)
            return try Self.answer(request, status: 200, body: Self.validBody)
        }

        let task = Task {
            try await sut.resolveEpisode(country: "de", podcastId: 1, episodeId: Self.episodeId)
        }
        try? await Task.sleep(nanoseconds: 50_000_000)
        sut.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancelled")
        } catch {
            XCTAssertEqual(error as? PodcastEpisodeResolveError, .cancelled)
        }
    }

    // MARK: Private

    private static let episodeId: Int64 = 1_000_792_422_344

    private static let validBody = """
        {"resultCount": 1, "results": [{"wrapperType": "podcastEpisode", "trackId": 1000792422344,
         "collectionName": "Achtsam", "trackName": "Body Scan", "episodeUrl": "https://anbieter.example/folge.mp3",
         "episodeContentType": "audio"}]}
        """

    private var sut: ApplePodcastsEpisodeResolver?

    private static func answer(_ request: URLRequest, status: Int, body: String) throws -> (HTTPURLResponse, Data) {
        let response = try XCTUnwrap(HTTPURLResponse(
            url: XCTUnwrap(request.url),
            statusCode: status,
            httpVersion: nil,
            headerFields: ["Content-Type": "text/javascript; charset=utf-8"]
        ))
        return (response, Data(body.utf8))
    }

    private func resolveError() async -> PodcastEpisodeResolveError? {
        guard let sut = self.sut else {
            return nil
        }
        do {
            _ = try await sut.resolveEpisode(country: "de", podcastId: 1, episodeId: Self.episodeId)
            return nil
        } catch {
            return error as? PodcastEpisodeResolveError
        }
    }
}
