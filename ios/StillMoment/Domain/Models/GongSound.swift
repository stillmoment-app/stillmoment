//
//  GongSound.swift
//  Still Moment
//
//  Domain - Gong Sound Model
//

import Foundation

/// Represents a configurable gong sound for meditation timer
///
/// This model defines a gong sound that can be selected for start/end gong
/// or interval gong. Sounds include:
/// - Unique identifier for persistence
/// - Audio file reference
/// - Localized name (German + English)
///
/// Example usage:
/// ```swift
/// let sound = GongSound(
///     id: "classic-bowl",
///     filename: "singing-bowl-hit-3-33366-5s.mp3",
///     name: LocalizedString(en: "Classic Bowl", de: "Klassisch")
/// )
/// ```
struct GongSound: Codable, Identifiable, Equatable {
    /// Localized string supporting German and English
    struct LocalizedString: Codable, Equatable {
        let en: String
        let de: String

        /// Returns localized string based on current locale
        var localized: String {
            let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
            switch languageCode {
            case "de":
                return self.de
            default:
                return self.en
            }
        }
    }

    /// Unique identifier for the sound
    let id: String

    /// Filename in the GongSounds bundle (e.g., "singing-bowl-hit-3-33366-5s.mp3")
    let filename: String

    /// Localized display name
    let name: LocalizedString
}

// MARK: - Static Sound Definitions

extension GongSound {
    /// All available gong sounds
    static let allSounds: [GongSound] = [
        GongSound(
            id: "temple-bell",
            filename: "tibetan-singing-bowl-55786-10s.mp3",
            name: LocalizedString(en: "Temple Bell", de: "Tempelglocke")
        ),
        GongSound(
            id: "classic-bowl",
            filename: "singing-bowl-hit-3-33366-10s.mp3",
            name: LocalizedString(en: "Classic Bowl", de: "Klassisch")
        ),
        GongSound(
            id: "deep-resonance",
            filename: "singing-bowl-male-frequency-29714-10s.mp3",
            name: LocalizedString(en: "Deep Resonance", de: "Tiefe Resonanz")
        ),
        GongSound(
            id: "clear-strike",
            filename: "singing-bowl-strike-sound-84682-10s.mp3",
            name: LocalizedString(en: "Clear Strike", de: "Klarer Anschlag")
        )
    ]

    /// Default gong sound (Temple Bell)
    static let defaultSound: GongSound = allSounds.first { $0.id == defaultSoundId } ?? allSounds[0]

    /// Default sound ID for settings
    static let defaultSoundId: String = "temple-bell"

    /// Find a gong sound by ID
    /// - Parameter id: The sound ID to search for
    /// - Returns: The matching GongSound or nil if not found
    static func find(byId id: String) -> GongSound? {
        self.allSounds.first { $0.id == id }
    }

    /// Find a gong sound by ID, returning default if not found
    /// - Parameter id: The sound ID to search for
    /// - Returns: The matching GongSound or defaultSound if not found
    static func findOrDefault(byId id: String) -> GongSound {
        self.find(byId: id) ?? self.defaultSound
    }
}
