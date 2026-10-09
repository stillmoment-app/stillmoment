//
//  ApplePodcastsLookupResponseTests.swift
//  Still Moment
//
//  shared-128: Finden der Folge in der Antwort des Apple-Podcast-Verzeichnisses.
//  Antworten gekuerzt, Feldnamen wie in der echten Antwort von itunes.apple.com/lookup.
//

import XCTest
@testable import StillMoment

final class ApplePodcastsLookupResponseTests: XCTestCase {
    // MARK: Internal

    func testEpisodeIsFoundWithAudioFileTitleAndPodcastAuthor() throws {
        let data = Self.response(entries: [Self.podcastEntry, Self.episodeEntry()])

        let episode = try ApplePodcastsLookupResponse.episode(withId: Self.episodeId, from: data)

        XCTAssertEqual(episode.audioURL.absoluteString, "https://anbieter.example/folge.mp3?ref=1")
        XCTAssertEqual(episode.title, "Body Scan (20:34 Min.)")
        XCTAssertEqual(episode.podcastAuthor, "Deutschlandfunk Nova")
        XCTAssertEqual(episode.podcastName, "Achtsam")
        XCTAssertEqual(episode.teacherSuggestion, "Deutschlandfunk Nova")
    }

    func testEpisodeTitleIsTrimmedOnlyAtTheEdges() throws {
        let entry = Self.episodeEntry().replacingOccurrences(
            of: #""trackName": "Body Scan (20:34 Min.)""#,
            with: #""trackName": "  Body Scan  (20:34 Min.)\n ""#
        )
        let data = Self.response(entries: [Self.podcastEntry, entry])

        let episode = try ApplePodcastsLookupResponse.episode(withId: Self.episodeId, from: data)

        XCTAssertEqual(episode.title, "Body Scan  (20:34 Min.)")
    }

    func testPodcastEntryIsFoundRegardlessOfOrder() throws {
        let data = Self.response(entries: [Self.episodeEntry(id: 1), Self.episodeEntry(), Self.podcastEntry])

        let episode = try ApplePodcastsLookupResponse.episode(withId: Self.episodeId, from: data)

        XCTAssertEqual(episode.podcastAuthor, "Deutschlandfunk Nova")
    }

    func testWithoutPodcastEntryTheEpisodesPodcastNameIsUsed() throws {
        let data = Self.response(entries: [Self.episodeEntry()])

        let episode = try ApplePodcastsLookupResponse.episode(withId: Self.episodeId, from: data)

        XCTAssertNil(episode.podcastAuthor)
        XCTAssertEqual(episode.teacherSuggestion, "Achtsam")
    }

    func testHttpAudioAddressIsLoadedViaHttps() throws {
        let entry = Self.episodeEntry(episodeUrl: "http://anbieter.example/pfad/folge.mp3?x=1&y=2")
        let data = Self.response(entries: [Self.podcastEntry, entry])

        let episode = try ApplePodcastsLookupResponse.episode(withId: Self.episodeId, from: data)

        XCTAssertEqual(episode.audioURL.absoluteString, "https://anbieter.example/pfad/folge.mp3?x=1&y=2")
    }

    // MARK: - Nicht uebernehmbar

    func testOlderEpisodeNotInAnswerIsUnavailable() {
        let data = Self.response(entries: [Self.podcastEntry, Self.episodeEntry(id: 42)])

        self.assertUnavailable(data)
    }

    func testEmptyAnswerIsUnavailable() {
        self.assertUnavailable(Data(#"{"resultCount": 0, "results": []}"#.utf8))
    }

    func testVideoEpisodeIsUnavailable() {
        let data = Self.response(entries: [Self.podcastEntry, Self.episodeEntry(contentType: "video")])

        self.assertUnavailable(data)
    }

    func testEpisodeWithoutAudioAddressIsUnavailable() {
        let data = Self.response(entries: [Self.podcastEntry, Self.episodeEntry(episodeUrl: nil)])

        self.assertUnavailable(data)
    }

    func testEpisodeWithNonWebAudioAddressIsUnavailable() {
        let data = Self.response(entries: [Self.episodeEntry(episodeUrl: "ftp://anbieter.example/folge.mp3")])

        self.assertUnavailable(data)
    }

    func testUnexpectedAnswerIsUnavailable() {
        self.assertUnavailable(Data("<html>Fehler</html>".utf8))
        self.assertUnavailable(Data(#"{"errorMessage": "Invalid value(s) for key(s): [id]"}"#.utf8))
    }

    // MARK: Private

    private static let episodeId: Int64 = 1_000_792_422_344

    private static let podcastEntry = """
        {"wrapperType": "track", "kind": "podcast", "collectionId": 1528936478, "trackId": 1528936478,
         "artistName": "Deutschlandfunk Nova", "collectionName": "Achtsam", "trackName": "Achtsam"}
        """

    private static func episodeEntry(
        id: Int64 = episodeId,
        episodeUrl: String? = "https://anbieter.example/folge.mp3?ref=1",
        contentType: String = "audio"
    ) -> String {
        let urlField = episodeUrl.map { #""episodeUrl": "\#($0)","# } ?? ""
        return """
            {"wrapperType": "podcastEpisode", "kind": "podcast-episode", "trackId": \(id),
             "collectionId": 1528936478, "collectionName": "Achtsam", "trackName": "Body Scan (20:34 Min.)",
             \(urlField) "episodeContentType": "\(contentType)", "episodeFileExtension": "mp3"}
            """
    }

    private static func response(entries: [String]) -> Data {
        Data(#"{"resultCount": \#(entries.count), "results": [\#(entries.joined(separator: ","))]}"#.utf8)
    }

    private func assertUnavailable(_ data: Data, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(
            try ApplePodcastsLookupResponse.episode(withId: Self.episodeId, from: data),
            file: file,
            line: line
        ) { error in
            XCTAssertEqual(error as? PodcastEpisodeResolveError, .unavailable, file: file, line: line)
        }
    }
}
