//
//  MeditationSourceRepositoryProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Curated meditation sources for the Content Guide.
//

import Foundation

/// Loads the curated meditation sources of all languages (Content Guide).
///
/// The catalog is static and ships with the app — no network calls, no per-user state.
/// Sources are read from `meditation_sources.json` once and cached.
protocol MeditationSourceRepositoryProtocol {
    /// All curated sources, grouped by language code.
    func catalog() -> MeditationSourceCatalog
}
