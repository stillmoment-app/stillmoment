//
//  ApplePodcastsLinkTests.swift
//  Still Moment
//
//  shared-128: Erkennen geteilter Apple-Podcasts-Links (Folge vs. ganzer Podcast).
//

import XCTest
@testable import StillMoment

final class ApplePodcastsLinkTests: XCTestCase {
    // MARK: - Folge

    func testEpisodeLinkIsRecognizedAsSingleEpisode() throws {
        let url = try XCTUnwrap(URL(
            string: "https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478?i=1000792422344"
        ))

        XCTAssertEqual(
            ApplePodcastsLink.parse(url),
            .episode(country: "de", podcastId: 1_528_936_478, episodeId: 1_000_792_422_344)
        )
    }

    func testEpisodeLinksFromAllCountryVariantsAreRecognized() throws {
        for country in ["de", "us", "gb"] {
            let url = try XCTUnwrap(URL(
                string: "https://podcasts.apple.com/\(country)/podcast/achtsam/id1528936478?i=1000792422344"
            ))

            XCTAssertEqual(
                ApplePodcastsLink.parse(url),
                .episode(country: country, podcastId: 1_528_936_478, episodeId: 1_000_792_422_344),
                "Land \(country) muss erkannt werden"
            )
        }
    }

    func testHostAndCountryAreCaseInsensitive() throws {
        let url = try XCTUnwrap(URL(
            string: "https://Podcasts.Apple.com/US/podcast/tara-brach/id265264012?i=1000792422344"
        ))

        XCTAssertEqual(
            ApplePodcastsLink.parse(url),
            .episode(country: "us", podcastId: 265_264_012, episodeId: 1_000_792_422_344)
        )
    }

    func testEpisodeIsRecognizedWithAdditionalQueryParameters() throws {
        let url = try XCTUnwrap(URL(
            string: "https://podcasts.apple.com/de/podcast/achtsam/id1528936478?l=en&i=1000792422344&uo=4"
        ))

        XCTAssertEqual(
            ApplePodcastsLink.parse(url),
            .episode(country: "de", podcastId: 1_528_936_478, episodeId: 1_000_792_422_344)
        )
    }

    // MARK: - Ganzer Podcast

    func testLinkWithoutEpisodeIsRecognizedAsWholePodcast() throws {
        let url = try XCTUnwrap(URL(
            string: "https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478"
        ))

        XCTAssertEqual(ApplePodcastsLink.parse(url), .podcast(country: "de", podcastId: 1_528_936_478))
    }

    func testEmptyOrNonNumericEpisodeCountsAsWholePodcast() throws {
        let empty = try XCTUnwrap(URL(string: "https://podcasts.apple.com/de/podcast/achtsam/id1528936478?i="))
        let text = try XCTUnwrap(URL(string: "https://podcasts.apple.com/de/podcast/achtsam/id1528936478?i=abc"))

        XCTAssertEqual(ApplePodcastsLink.parse(empty), .podcast(country: "de", podcastId: 1_528_936_478))
        XCTAssertEqual(ApplePodcastsLink.parse(text), .podcast(country: "de", podcastId: 1_528_936_478))
    }

    // MARK: - Kein Apple-Podcasts-Link

    func testForeignHostIsNotAnApplePodcastsLink() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/de/podcast/x/id123?i=456"))

        XCTAssertNil(ApplePodcastsLink.parse(url))
    }

    func testDirectAudioLinkIsNotAnApplePodcastsLink() throws {
        let url = try XCTUnwrap(URL(string: "https://www.audiodharma.org/talks/25401/download.mp3"))

        XCTAssertNil(ApplePodcastsLink.parse(url))
    }

    func testOtherApplePodcastsPagesAreNotRecognized() throws {
        let browse = try XCTUnwrap(URL(string: "https://podcasts.apple.com/de/browse"))
        let noId = try XCTUnwrap(URL(string: "https://podcasts.apple.com/de/podcast/achtsam?i=1000792422344"))

        XCTAssertNil(ApplePodcastsLink.parse(browse))
        XCTAssertNil(ApplePodcastsLink.parse(noId))
    }
}
