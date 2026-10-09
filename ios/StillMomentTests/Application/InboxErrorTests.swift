//
//  InboxErrorTests.swift
//  Still Moment
//
//  shared-128: Jeder Fehlerfall fuehrt zu genau einer Meldung; "Erneut versuchen" nur, wenn es etwas aendern kann.
//

import XCTest
@testable import StillMoment

final class InboxErrorTests: XCTestCase {
    // MARK: - Podcast-Import → drei Meldungen

    func testPodcastLookupProblemsMapToThreeMessages() {
        XCTAssertEqual(InboxError.forPodcastImport(PodcastEpisodeResolveError.notReachable), .notReachable)
        XCTAssertEqual(InboxError.forPodcastImport(PodcastEpisodeResolveError.unavailable), .episodeUnavailable)
        XCTAssertNil(InboxError.forPodcastImport(PodcastEpisodeResolveError.cancelled), "Abbrechen zeigt keine Meldung")
    }

    func testPodcastDownloadProblemsMapToThreeMessages() {
        XCTAssertEqual(InboxError.forPodcastImport(AudioDownloadError.networkError), .notReachable)
        XCTAssertEqual(InboxError.forPodcastImport(AudioDownloadError.invalidResponse), .episodeUnavailable)
        XCTAssertEqual(InboxError.forPodcastImport(AudioDownloadError.unsupportedContentType), .episodeUnavailable)
        XCTAssertEqual(InboxError.forPodcastImport(AudioDownloadError.downloadFailed), .episodeUnavailable)
        XCTAssertNil(InboxError.forPodcastImport(AudioDownloadError.downloadCancelled))
    }

    // MARK: - Bestehender Link-Import

    func testLinkImportShowsNotReachableOnlyForConnectionProblems() {
        XCTAssertEqual(InboxError.forLinkImport(.networkError), .notReachable)
        XCTAssertEqual(InboxError.forLinkImport(.invalidResponse), .downloadFailed)
        XCTAssertEqual(InboxError.forLinkImport(.downloadFailed), .downloadFailed)
        XCTAssertEqual(InboxError.forLinkImport(.unsupportedContentType), .notAnAudioUrl)
        XCTAssertNil(InboxError.forLinkImport(.downloadCancelled))
    }

    // MARK: - Erneut versuchen

    func testRetryIsOfferedOnlyWhenItCanHelp() {
        XCTAssertTrue(InboxError.notReachable.isRetryable)
        XCTAssertTrue(InboxError.downloadFailed.isRetryable)
        XCTAssertFalse(InboxError.podcastWithoutEpisode.isRetryable)
        XCTAssertFalse(InboxError.episodeUnavailable.isRetryable)
        XCTAssertFalse(InboxError.notAnAudioUrl.isRetryable)
        XCTAssertFalse(InboxError.containerNotAvailable.isRetryable)
    }

    // MARK: - Texte

    func testEachNewMessageHasItsOwnLocalizedText() {
        XCTAssertEqual(InboxError.notReachable.alertTitleKey, "share.download.error.not_reachable.title")
        XCTAssertEqual(InboxError.notReachable.alertMessageKey, "share.download.error.not_reachable.message")
        XCTAssertEqual(
            InboxError.podcastWithoutEpisode.alertTitleKey,
            "share.download.error.podcast_without_episode.title"
        )
        XCTAssertEqual(
            InboxError.podcastWithoutEpisode.alertMessageKey,
            "share.download.error.podcast_without_episode.message"
        )
        XCTAssertEqual(InboxError.episodeUnavailable.alertTitleKey, "share.download.error.episode_unavailable.title")
        XCTAssertEqual(
            InboxError.episodeUnavailable.alertMessageKey,
            "share.download.error.episode_unavailable.message"
        )
    }

    func testExistingMessagesAreUnchanged() {
        XCTAssertEqual(InboxError.notAnAudioUrl.alertTitleKey, "share.download.error.not_audio.title")
        XCTAssertEqual(InboxError.notAnAudioUrl.alertMessageKey, "share.download.error.not_audio.message")
        XCTAssertEqual(InboxError.downloadFailed.alertTitleKey, "share.download.error.title")
        XCTAssertEqual(InboxError.downloadFailed.alertMessageKey, "share.download.error.message")
    }

    func testNewMessagesAreTranslatedInGermanAndEnglish() throws {
        let keys = [InboxError.notReachable, .podcastWithoutEpisode, .episodeUnavailable]
            .flatMap { [$0.alertTitleKey, $0.alertMessageKey] }
        for language in ["de", "en"] {
            let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try XCTUnwrap(Bundle(path: path))
            for key in keys {
                let text = bundle.localizedString(forKey: key, value: nil, table: nil)
                XCTAssertNotEqual(text, key, "\(key) fehlt in \(language)")
                for term in ["Download", "HTTP", "Server", "Lookup", "URL"] {
                    XCTAssertFalse(text.contains(term), "\(key) (\(language)) enthaelt Fachbegriff \(term)")
                }
            }
        }
    }
}
