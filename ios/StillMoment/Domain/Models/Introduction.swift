//
//  Introduction.swift
//  Still Moment
//
//  Domain Model - Introduction for Meditation Timer
//

import Foundation

/// Represents an optional introduction audio that plays at the beginning of a meditation session
///
/// Introductions are bundled audio files (e.g., guided breathing exercises) that play
/// after the start gong and before the silent meditation phase. They are language-specific
/// and can be configured in the timer settings.
///
/// Example usage:
/// ```swift
/// let intro = Introduction.breath
/// let filename = intro.audioFilename(for: "de") // "intro-breath-de.mp3"
/// ```
struct Introduction: Identifiable, Equatable {
    /// Unique, language-independent identifier (e.g., "breath")
    let id: String

    /// Localized display name (resolved via NSLocalizedString at creation time)
    let name: String

    /// Duration of the introduction audio in seconds, per language
    let durationByLanguage: [String: Int]

    /// Languages for which audio files are available
    let availableLanguages: [String]

    /// Filename pattern with `{lang}` placeholder (e.g., "intro-breath-{lang}.mp3")
    let filenamePattern: String

    /// Returns the audio filename for a specific language
    /// - Parameter language: Language code (e.g., "de", "en")
    /// - Returns: Resolved filename or nil if language not available
    func audioFilename(for language: String) -> String? {
        guard self.availableLanguages.contains(language) else {
            return nil
        }
        return self.filenamePattern.replacingOccurrences(of: "{lang}", with: language)
    }

    /// Maximum duration across all languages (used for minimum timer calculation)
    var durationSeconds: Int {
        self.durationByLanguage.values.max() ?? 0
    }

    /// Duration for a specific language, or max if language not found
    func durationSeconds(for language: String) -> Int {
        self.durationByLanguage[language] ?? self.durationSeconds
    }

    /// Formatted duration string (e.g., "1:35") — uses max duration across languages
    var formattedDuration: String {
        let minutes = self.durationSeconds / 60
        let seconds = self.durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Static Introduction Definitions

extension Introduction {
    /// Breathing exercise introduction (first available introduction)
    static let breath = Introduction(
        id: "breath",
        name: NSLocalizedString("introduction.breath.name", comment: ""),
        durationByLanguage: ["de": 95, "en": 93],
        availableLanguages: ["de", "en"],
        filenamePattern: "intro-breath-{lang}.mp3"
    )

    /// All registered introductions
    static let allIntroductions: [Introduction] = [
        breath
    ]
}

// MARK: - Registry Methods

extension Introduction {
    /// Override for testing — set to a language code to bypass `Locale.current`.
    /// Must be reset to `nil` in test tearDown.
    static var languageOverride: String?

    /// Returns the current device language code (or test override)
    static var currentLanguage: String {
        self.languageOverride ?? Locale.current.language.languageCode?.identifier ?? "en"
    }

    /// Returns introductions available for the current device language
    static func availableForCurrentLanguage() -> [Introduction] {
        let lang = self.currentLanguage
        return self.allIntroductions.filter { $0.availableLanguages.contains(lang) }
    }

    /// Checks if any introductions are available for the current device language
    static var hasAvailableIntroductions: Bool {
        !self.availableForCurrentLanguage().isEmpty
    }

    /// Finds an introduction by ID
    /// - Parameter id: The introduction ID to search for
    /// - Returns: The matching Introduction or nil
    static func find(byId id: String) -> Introduction? {
        self.allIntroductions.first { $0.id == id }
    }

    /// Checks if an introduction is available for the current device language
    /// - Parameter id: The introduction ID to check
    /// - Returns: true if the introduction exists and has audio for the current language
    static func isAvailableForCurrentLanguage(_ id: String) -> Bool {
        guard let intro = find(byId: id) else {
            return false
        }
        return intro.availableLanguages.contains(self.currentLanguage)
    }

    /// Returns the audio filename for an introduction in the current device language
    /// - Parameter id: The introduction ID
    /// - Returns: Resolved filename or nil if not available
    static func audioFilenameForCurrentLanguage(_ id: String) -> String? {
        guard let intro = find(byId: id) else {
            return nil
        }
        return intro.audioFilename(for: self.currentLanguage)
    }
}
