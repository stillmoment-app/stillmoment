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
/// - Localized name (resolved via NSLocalizedString)
///
/// Example usage:
/// ```swift
/// let sound = GongSound.defaultSound
/// print(sound.name) // "Temple Bell" (en) / "Tempelglocke" (de)
/// ```
struct GongSound: Identifiable, Equatable {
    /// Unique identifier for the sound
    let id: String

    /// Filename in the GongSounds bundle (e.g., "singing-bowl-hit-3-33366-5s.mp3")
    let filename: String

    /// Localized display name (resolved at creation time)
    let name: String
}

// MARK: - Static Sound Definitions

extension GongSound {
    /// All available gong sounds (for start/end gong)
    static let allSounds: [GongSound] = [
        GongSound(
            id: "temple-bell",
            filename: "tibetan-singing-bowl-55786-10s.mp3",
            name: NSLocalizedString("gong.temple-bell", comment: "")
        ),
        GongSound(
            id: "classic-bowl",
            filename: "singing-bowl-hit-3-33366-10s.mp3",
            name: NSLocalizedString("gong.classic-bowl", comment: "")
        ),
        GongSound(
            id: "deep-resonance",
            filename: "singing-bowl-male-frequency-29714-10s.mp3",
            name: NSLocalizedString("gong.deep-resonance", comment: "")
        ),
        GongSound(
            id: "clear-strike",
            filename: "singing-bowl-strike-sound-84682-10s.mp3",
            name: NSLocalizedString("gong.clear-strike", comment: "")
        )
    ]

    /// Soft interval tone (5th sound option, only for interval gongs)
    static let softIntervalTone = GongSound(
        id: "soft-interval",
        filename: "interval.mp3",
        name: NSLocalizedString("gong.soft-interval", comment: "")
    )

    /// All available interval gong sounds (4 standard + soft interval tone)
    static let allIntervalSounds: [GongSound] = allSounds + [softIntervalTone]

    /// Default gong sound (Temple Bell)
    static let defaultSound: GongSound = allSounds.first { $0.id == defaultSoundId } ?? allSounds[0]

    /// Default sound ID for settings
    static let defaultSoundId: String = "temple-bell"

    /// Default interval sound ID (soft interval tone)
    static let defaultIntervalSoundId: String = "soft-interval"

    /// Find a gong sound by ID (searches all sounds including interval sounds)
    /// - Parameter id: The sound ID to search for
    /// - Returns: The matching GongSound or nil if not found
    static func find(byId id: String) -> GongSound? {
        self.allIntervalSounds.first { $0.id == id }
    }

    /// Find a gong sound by ID, returning default if not found
    /// - Parameter id: The sound ID to search for
    /// - Returns: The matching GongSound or defaultSound if not found
    static func findOrDefault(byId id: String) -> GongSound {
        self.find(byId: id) ?? self.defaultSound
    }
}
