//
//  PodcastEpisodeTests.swift
//  Still Moment
//
//  shared-128: Vorschlag fuer Lehrer:in — Autor des Podcasts, sonst Name des Podcasts.
//

import XCTest
@testable import StillMoment

final class PodcastEpisodeTests: XCTestCase {
    private func episode(author: String?, podcastName: String?) throws -> PodcastEpisode {
        try PodcastEpisode(
            audioURL: XCTUnwrap(URL(string: "https://anbieter.example/folge.mp3")),
            title: "Body Scan",
            podcastAuthor: author,
            podcastName: podcastName
        )
    }

    func testTeacherSuggestionIsPodcastAuthor() throws {
        let episode = try self.episode(author: "Deutschlandfunk Nova", podcastName: "Achtsam")

        XCTAssertEqual(episode.teacherSuggestion, "Deutschlandfunk Nova")
    }

    func testTeacherSuggestionFallsBackToPodcastNameWithoutAuthor() throws {
        let episode = try self.episode(author: nil, podcastName: "Achtsam")

        XCTAssertEqual(episode.teacherSuggestion, "Achtsam")
    }

    func testEmptyAuthorCountsAsMissing() throws {
        let episode = try self.episode(author: "   ", podcastName: "Achtsam")

        XCTAssertEqual(episode.teacherSuggestion, "Achtsam")
    }

    func testNoTeacherSuggestionWithoutAuthorAndPodcastName() throws {
        let episode = try self.episode(author: nil, podcastName: "")

        XCTAssertNil(episode.teacherSuggestion)
    }
}
