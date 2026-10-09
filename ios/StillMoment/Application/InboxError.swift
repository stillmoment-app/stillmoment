//
//  InboxError.swift
//  Still Moment
//
//  Application Layer - Errors shown to the user while processing a share
//

import Foundation

/// Errors that can occur during inbox processing — each case is one message for the user.
///
/// Podcast import (shared-128) uses exactly three messages: `.podcastWithoutEpisode`,
/// `.notReachable` and `.episodeUnavailable`. The link import additionally keeps
/// `.downloadFailed` and `.notAnAudioUrl`.
enum InboxError: Error, Equatable, LocalizedError {
    /// The download of a shared URL failed (server, write error — retry sinnvoll)
    case downloadFailed
    /// Der geteilte Link liefert keine Audio-Datei (z. B. text/html). Retry hilft nicht.
    case notAnAudioUrl
    /// The app group container is not available
    case containerNotAvailable
    /// No connection, timeout or the podcast directory is overloaded — "try again later"
    case notReachable
    /// The shared link leads to a whole podcast, not a single episode
    case podcastWithoutEpisode
    /// The episode cannot be taken over (not found, video, paid, file gone, unexpected answer)
    case episodeUnavailable

    // MARK: Internal

    /// Whether "Retry" is offered — only when another attempt can change the outcome.
    var isRetryable: Bool {
        switch self {
        case .notReachable,
             .downloadFailed:
            true
        case .notAnAudioUrl,
             .containerNotAvailable,
             .podcastWithoutEpisode,
             .episodeUnavailable:
            false
        }
    }

    /// Localization key of the alert title
    var alertTitleKey: String {
        switch self {
        case .notReachable:
            "share.download.error.not_reachable.title"
        case .podcastWithoutEpisode:
            "share.download.error.podcast_without_episode.title"
        case .episodeUnavailable:
            "share.download.error.episode_unavailable.title"
        case .notAnAudioUrl:
            "share.download.error.not_audio.title"
        case .downloadFailed,
             .containerNotAvailable:
            "share.download.error.title"
        }
    }

    /// Localization key of the alert message
    var alertMessageKey: String {
        switch self {
        case .notReachable:
            "share.download.error.not_reachable.message"
        case .podcastWithoutEpisode:
            "share.download.error.podcast_without_episode.message"
        case .episodeUnavailable:
            "share.download.error.episode_unavailable.message"
        case .notAnAudioUrl:
            "share.download.error.not_audio.message"
        case .downloadFailed,
             .containerNotAvailable:
            "share.download.error.message"
        }
    }

    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            NSLocalizedString(
                "inbox_error_download_failed",
                value: "The download failed. Please try again.",
                comment: "Error when downloading a shared audio file fails"
            )
        case .notAnAudioUrl,
             .notReachable,
             .podcastWithoutEpisode,
             .episodeUnavailable:
            NSLocalizedString(self.alertMessageKey, comment: "")
        case .containerNotAvailable:
            NSLocalizedString(
                "inbox_error_container_not_available",
                value: "Unable to access shared data.",
                comment: "Error when the app group container is not available"
            )
        }
    }

    // MARK: - Mapping

    /// Message for a failed download in the regular link import. `nil` = cancelled, no message.
    static func forLinkImport(_ error: AudioDownloadError) -> InboxError? {
        switch error {
        case .downloadCancelled:
            nil
        case .networkError:
            .notReachable
        case .unsupportedContentType:
            .notAnAudioUrl
        case .invalidResponse,
             .downloadFailed:
            .downloadFailed
        }
    }

    /// Message for a failed episode lookup in the podcast import. `nil` = cancelled, no message.
    static func forPodcastImport(_ error: PodcastEpisodeResolveError) -> InboxError? {
        switch error {
        case .cancelled:
            nil
        case .notReachable:
            .notReachable
        case .unavailable:
            .episodeUnavailable
        }
    }

    /// Message for a failed episode download in the podcast import. `nil` = cancelled, no message.
    static func forPodcastImport(_ error: AudioDownloadError) -> InboxError? {
        switch error {
        case .downloadCancelled:
            nil
        case .networkError:
            .notReachable
        case .invalidResponse,
             .unsupportedContentType,
             .downloadFailed:
            .episodeUnavailable
        }
    }
}
