//
//  BackgroundSound.swift
//  Still Moment
//
//  Domain - Background Sound Model
//

import Foundation

/// Represents a background audio option for meditation sessions
///
/// This model defines a configurable background sound that can be played during meditation.
/// Sounds are loaded from `sounds.json` in the BackgroundAudio bundle and include:
/// - Unique identifier for persistence
/// - Audio file reference
/// - Localized name and description (German + English)
/// - SF Symbol icon for UI display
/// - Volume level (0.0 = silent, 1.0 = max)
///
/// Example usage:
/// ```swift
/// let sound = BackgroundSound(
///     id: "forest",
///     filename: "forest-ambience.mp3",
///     name: LocalizedString(en: "Forest", de: "Wald"),
///     description: LocalizedString(en: "Natural sounds", de: "Natürliche Geräusche"),
///     iconName: "leaf.fill",
///     volume: 0.15
/// )
/// ```
struct BackgroundSound: Codable, Identifiable, Equatable {
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

    /// Filename in the BackgroundAudio bundle (e.g., "silence.m4a")
    let filename: String

    /// Localized display name
    let name: LocalizedString

    /// Localized description
    let description: LocalizedString

    /// SF Symbol icon name (e.g., "speaker.wave.1")
    let iconName: String

    /// Volume level for playback (0.0 = silent, 1.0 = full volume)
    /// Default: 0.15 if not specified
    let volume: Float
}
