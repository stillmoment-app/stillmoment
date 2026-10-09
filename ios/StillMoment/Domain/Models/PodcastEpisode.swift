//
//  PodcastEpisode.swift
//  Still Moment
//
//  Domain Model - A podcast episode resolved from a shared link (shared-128)
//

import Foundation

/// A single podcast episode as found in the podcast directory.
///
/// Carries the address of the audio file at the podcast's provider and the raw values
/// used as suggestions in the edit dialog.
struct PodcastEpisode: Equatable {
    /// Audio file at the podcast's provider
    let audioURL: URL

    /// Episode title (used as the meditation name suggestion, unchanged)
    let title: String?

    /// Author of the podcast
    let podcastAuthor: String?

    /// Name of the podcast
    let podcastName: String?

    /// Teacher suggestion: the podcast's author, otherwise the podcast's name.
    /// Empty values count as missing.
    var teacherSuggestion: String? {
        self.podcastAuthor?.nonBlankTrimmed ?? self.podcastName?.nonBlankTrimmed
    }
}
