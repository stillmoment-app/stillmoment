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
/// Sounds are loaded from `sounds.json` in the BackgroundAudio bundle. The repository
/// resolves localized names and descriptions for the current device language at load time.
///
/// Example usage:
/// ```swift
/// let sound = BackgroundSound(
///     id: "forest",
///     filename: "forest-ambience.mp3",
///     name: "Forest Ambience",
///     description: "Natural forest sounds",
///     iconName: "leaf.fill",
///     volume: 0.15
/// )
/// ```
struct BackgroundSound: Identifiable, Equatable {
    /// ID des "Stille"-Sounds. Sonderfall: kein abspielbares Audio,
    /// sondern das Datensignal "kein Soundscape ausgewaehlt". Wird vom
    /// `SoundscapeResolver` zu `nil` aufgeloest und steuert UI-Zustaende
    /// wie die gedaempfte Idle-Listenzeile (shared-089).
    static let silentId: String = "silent"

    /// Unique identifier for the sound
    let id: String

    /// Filename in the BackgroundAudio bundle (e.g., "silence.mp3")
    let filename: String

    /// Localized display name (resolved at load time)
    let name: String

    /// Localized description (resolved at load time)
    let description: String

    /// SF Symbol icon name (e.g., "speaker.wave.1")
    let iconName: String

    /// Volume level for playback (0.0 = silent, 1.0 = full volume)
    /// Default: 0.15 if not specified
    let volume: Float
}
