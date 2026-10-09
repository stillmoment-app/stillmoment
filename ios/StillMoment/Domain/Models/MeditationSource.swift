//
//  MeditationSource.swift
//  Still Moment
//
//  Domain - Curated source for guided meditations (Content Guide).
//

import Foundation

/// A curated, free source for guided meditations shown in the Content Guide.
///
/// Source content is loaded from `meditation_sources.json` per language at runtime.
/// The Domain layer holds the resolved strings — no localization-key lookup in views.
struct MeditationSource: Identifiable, Equatable {
    /// Stable identifier (e.g. `tara-brach`). Useful for tests and accessibility ids.
    let id: String

    /// Who stands behind the source — usually the teacher (e.g. `Melissa Gein`).
    let name: String

    /// The offer's own name, if it has one (e.g. `Podcast „Einfach meditieren“`).
    /// `nil` when the source is simply the teacher's own site.
    let offer: String?

    /// One-sentence description, in the source's language.
    let description: String

    /// Display string for the source's host (e.g. `tarabrach.com`).
    let host: String

    /// HTTPS URL opened outside the app.
    let url: URL
}
