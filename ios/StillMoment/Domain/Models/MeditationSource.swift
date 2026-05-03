//
//  MeditationSource.swift
//  Still Moment
//
//  Domain - Curated source for guided meditations (Content Guide).
//

import Foundation

/// A curated, free source for guided meditations shown in the Content Guide.
///
/// Source content is loaded from `meditation_sources.json` per locale at runtime.
/// The Domain layer holds the resolved strings — no localization-key lookup in views.
struct MeditationSource: Identifiable, Equatable {
    /// Stable identifier (e.g. `tara-brach`). Useful for tests and accessibility ids.
    let id: String

    /// Display name (e.g. `Tara Brach`).
    let name: String

    /// Optional author/teacher attribution (e.g. `Gil Fronsdal`).
    let author: String?

    /// One-sentence description.
    let description: String

    /// Display string for the source's host (e.g. `tarabrach.com`).
    let host: String

    /// HTTPS URL opened in the system browser.
    let url: URL
}
