//
//  MeditationSourceCatalog.swift
//  Still Moment
//
//  Domain - All curated meditation sources, grouped by language (shared-137).
//

import Foundation

/// The sources of one language, as shown together in the Content Guide.
struct MeditationSourceGroup: Equatable {
    /// Language code of the sources (`"de"`, `"en"`, …).
    let languageCode: String

    /// Sources in their curated order.
    let sources: [MeditationSource]
}

/// All curated meditation sources, keyed by language code.
///
/// Decides which language the user sees first and in which order the other
/// languages follow. Immutable value object.
struct MeditationSourceCatalog: Equatable {
    /// Language shown first when the user's own language has no sources.
    static let fallbackLanguageCode = "en"

    /// Sources per language code, each list in its curated order.
    let sourcesByLanguage: [String: [MeditationSource]]

    /// The sources grouped by language, in display order.
    ///
    /// 1. The user's own language — or English if there are no sources in it.
    /// 2. English, unless it already came first.
    /// 3. All other languages, alphabetically by their displayed name.
    ///
    /// Languages without sources are left out. Within a language the curated order stays.
    ///
    /// - Parameters:
    ///   - ownLanguageCode: The app's language (`"de"`, `"en"`, `"fr"`, …).
    ///   - displayName: The name shown for a language code; only used for sorting.
    func groups(
        ownLanguageCode: String,
        displayName: (String) -> String
    ) -> [MeditationSourceGroup] {
        let available = self.sourcesByLanguage.filter { !$0.value.isEmpty }
        let own = self.resolvedLanguageCode(for: ownLanguageCode)

        var leading = [own]
        if own != Self.fallbackLanguageCode {
            leading.append(Self.fallbackLanguageCode)
        }
        let leadingCodes = leading.filter { available[$0] != nil }
        let otherCodes = available.keys
            .filter { !leading.contains($0) }
            .sorted { displayName($0).localizedCompare(displayName($1)) == .orderedAscending }

        return (leadingCodes + otherCodes).compactMap { code in
            available[code].map { MeditationSourceGroup(languageCode: code, sources: $0) }
        }
    }

    /// The language shown first for a user with the given language:
    /// that language if it has sources, otherwise English.
    func resolvedLanguageCode(for languageCode: String) -> String {
        let hasSources = !(self.sourcesByLanguage[languageCode] ?? []).isEmpty
        return hasSources ? languageCode : Self.fallbackLanguageCode
    }
}
