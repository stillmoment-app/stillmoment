//
//  MeditationSourceRepositoryProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Curated meditation sources for the Content Guide.
//

import Foundation

/// Loads curated meditation sources for the current locale (Content Guide).
///
/// The catalog is static and ships with the app — no network calls, no per-user state.
/// Sources are read from `meditation_sources.json` once and cached.
protocol MeditationSourceRepositoryProtocol {
    /// Sources for the requested language code (`"de"`, `"en"`, ...).
    /// Falls back to English when the language code has no curated list.
    func sources(for languageCode: String) -> [MeditationSource]
}
