//
//  Attunement.swift
//  Still Moment
//
//  Domain Model - Attunement for Meditation Timer
//

import Foundation

/// Represents an optional attunement audio that plays at the beginning of a meditation session
///
/// Attunements are bundled audio files (e.g., guided breathing exercises) that play
/// after the start gong and before the silent meditation phase. They are language-specific
/// and can be configured in the timer settings.
///
/// Example usage:
/// ```swift
/// let attunement = Attunement.breath
/// let filename = attunement.audioFilename(for: "de") // "intro-breath-de.mp3"
/// ```
struct Attunement: Identifiable, Equatable {
    /// Unique, language-independent identifier (e.g., "breath")
    let id: String

    /// Localized display name (resolved via NSLocalizedString at creation time)
    let name: String

    /// Duration of the attunement audio in seconds, per language
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

// MARK: - Static Attunement Definitions

extension Attunement {
    /// Breathing exercise attunement (first available attunement)
    static let breath = Attunement(
        id: "breath",
        name: NSLocalizedString("attunement.breath.name", comment: ""),
        durationByLanguage: ["de": 95, "en": 93],
        availableLanguages: ["de", "en"],
        filenamePattern: "intro-breath-{lang}.mp3"
    )

    /// All registered attunements
    static let allAttunements: [Attunement] = [
        breath
    ]
}

// MARK: - Registry Methods

extension Attunement {
    /// Override for testing — set to a language code to bypass `Locale.current`.
    /// Must be reset to `nil` in test tearDown.
    static var languageOverride: String?

    /// Returns the current device language code (or test override)
    static var currentLanguage: String {
        self.languageOverride ?? Locale.current.language.languageCode?.identifier ?? "en"
    }

    /// Returns attunements available for the current device language
    static func availableForCurrentLanguage() -> [Attunement] {
        let lang = self.currentLanguage
        return self.allAttunements.filter { $0.availableLanguages.contains(lang) }
    }

    /// Checks if any attunements are available for the current device language
    static var hasAvailableAttunements: Bool {
        !self.availableForCurrentLanguage().isEmpty
    }

    /// Finds an attunement by ID
    /// - Parameter id: The attunement ID to search for
    /// - Returns: The matching Attunement or nil
    static func find(byId id: String) -> Attunement? {
        self.allAttunements.first { $0.id == id }
    }

    /// Checks if an attunement is available for the current device language
    /// - Parameter id: The attunement ID to check
    /// - Returns: true if the attunement exists and has audio for the current language
    static func isAvailableForCurrentLanguage(_ id: String) -> Bool {
        guard let attunement = find(byId: id) else {
            return false
        }
        return attunement.availableLanguages.contains(self.currentLanguage)
    }

    /// Returns the audio filename for an attunement in the current device language
    /// - Parameter id: The attunement ID
    /// - Returns: Resolved filename or nil if not available
    static func audioFilenameForCurrentLanguage(_ id: String) -> String? {
        guard let attunement = find(byId: id) else {
            return nil
        }
        return attunement.audioFilename(for: self.currentLanguage)
    }
}
