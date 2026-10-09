//
//  PodcastEpisodeResolveError.swift
//  Still Moment
//
//  Domain Model - Errors while resolving a podcast episode (shared-128)
//

import Foundation

/// Why a podcast episode could not be resolved.
enum PodcastEpisodeResolveError: Error, Equatable {
    /// No connection, timeout, or the directory is overloaded (rate limit) — a retry can help
    case notReachable
    /// Episode not found, video, no audio file, or an unexpected answer — a retry does not help
    case unavailable
    /// The user cancelled
    case cancelled
}
