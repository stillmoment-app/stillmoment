//
//  MeditationSettings.swift
//  Still Moment
//
//  Domain - Meditation Settings Model
//

import Foundation

/// Settings for meditation sessions
struct MeditationSettings: Codable, Equatable {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(
        intervalGongsEnabled: Bool = false,
        intervalMinutes: Int = 5,
        backgroundSoundId: String = "silent"
    ) {
        self.intervalGongsEnabled = intervalGongsEnabled
        self.intervalMinutes = Self.validateInterval(intervalMinutes)
        self.backgroundSoundId = backgroundSoundId
    }

    // MARK: Internal

    // MARK: - Persistence Keys

    enum Keys {
        static let intervalGongsEnabled = "intervalGongsEnabled"
        static let intervalMinutes = "intervalMinutes"
        static let backgroundSoundId = "backgroundSoundId"
        // Legacy key for migration
        static let legacyBackgroundAudioMode = "backgroundAudioMode"
    }

    /// Whether interval gongs are enabled during meditation
    var intervalGongsEnabled: Bool

    /// Interval in minutes between gongs (3, 5, or 10)
    var intervalMinutes: Int

    /// Background sound ID (references BackgroundSound.id)
    var backgroundSoundId: String

    // MARK: - Validation

    /// Validates and clamps interval to valid values (3, 5, or 10)
    static func validateInterval(_ minutes: Int) -> Int {
        switch minutes {
        case ...3:
            3
        case 4...7:
            5
        default:
            10
        }
    }
}

// MARK: - Default Settings

extension MeditationSettings {
    /// Default settings with interval gongs disabled and silent background audio
    static let `default` = MeditationSettings(
        intervalGongsEnabled: false,
        intervalMinutes: 5,
        backgroundSoundId: "silent"
    )
}

// MARK: - Legacy Migration

extension MeditationSettings {
    /// Migrates legacy BackgroundAudioMode enum to sound ID
    /// - Parameter mode: Legacy enum value
    /// - Returns: Corresponding sound ID
    static func migrateLegacyMode(_ mode: String) -> String {
        switch mode {
        case "Silent":
            "silent"
        case "White Noise":
            "silent" // WhiteNoise removed, fallback to silent
        default:
            "silent"
        }
    }
}
