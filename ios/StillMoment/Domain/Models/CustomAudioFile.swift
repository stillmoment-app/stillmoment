//
//  CustomAudioFile.swift
//  Still Moment
//
//  Domain - Custom Audio File Model (user-imported soundscapes and attunements)
//

import Foundation

/// Type of custom audio file
enum CustomAudioType: String, Codable, Equatable {
    /// Background sound that loops during meditation
    case soundscape
    /// Introduction audio that plays once after the start gong
    case attunement
}

/// A user-imported audio file stored in local app storage.
///
/// Custom audio files are copied to Application Support and can be used
/// as soundscapes (background loops) or attunements (one-shot introductions)
/// within a Praxis configuration.
///
/// CustomAudioFile is an immutable value object — all state changes produce new instances.
struct CustomAudioFile: Identifiable, Codable, Equatable {
    // MARK: - Properties

    /// Unique identifier
    let id: UUID

    /// Display name (derived from filename without extension on import)
    let name: String

    /// Actual filename in local storage (UUID-based, e.g. "3A9F...mp3")
    let filename: String

    /// Audio duration in seconds (nil if detection failed)
    let duration: TimeInterval?

    /// Whether this is a soundscape or attunement
    let type: CustomAudioType

    /// When the file was imported
    let dateAdded: Date

    // MARK: - Computed

    /// Human-readable duration string (e.g. "3:45") or localized "Unknown"
    var formattedDuration: String {
        guard let duration else {
            return NSLocalizedString("custom.audio.duration.unknown", comment: "")
        }
        let total = Int(duration)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
