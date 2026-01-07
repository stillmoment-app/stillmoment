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
        backgroundSoundId: String = "silent",
        durationMinutes: Int = 10,
        preparationTimeEnabled: Bool = true,
        preparationTimeSeconds: Int = 15
    ) {
        self.intervalGongsEnabled = intervalGongsEnabled
        self.intervalMinutes = Self.validateInterval(intervalMinutes)
        self.backgroundSoundId = backgroundSoundId
        self.durationMinutes = Self.validateDuration(durationMinutes)
        self.preparationTimeEnabled = preparationTimeEnabled
        self.preparationTimeSeconds = Self.validatePreparationTime(preparationTimeSeconds)
    }

    // MARK: Internal

    // MARK: - Persistence Keys

    enum Keys {
        static let intervalGongsEnabled = "intervalGongsEnabled"
        static let intervalMinutes = "intervalMinutes"
        static let backgroundSoundId = "backgroundSoundId"
        static let durationMinutes = "durationMinutes"
        static let preparationTimeEnabled = "preparationTimeEnabled"
        static let preparationTimeSeconds = "preparationTimeSeconds"
        // Legacy key for migration
        static let legacyBackgroundAudioMode = "backgroundAudioMode"
    }

    /// Whether interval gongs are enabled during meditation
    var intervalGongsEnabled: Bool

    /// Interval in minutes between gongs (3, 5, or 10)
    var intervalMinutes: Int

    /// Background sound ID (references BackgroundSound.id)
    var backgroundSoundId: String

    /// Duration of meditation in minutes (1-60)
    var durationMinutes: Int

    /// Whether preparation time is enabled before meditation starts
    var preparationTimeEnabled: Bool

    /// Duration of preparation phase in seconds (5, 10, 15, 20, 30, 45)
    var preparationTimeSeconds: Int

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

    /// Validates and clamps duration to valid range (1-60 minutes)
    static func validateDuration(_ minutes: Int) -> Int {
        min(max(minutes, 1), 60)
    }

    /// Valid preparation time options in seconds
    static let validPreparationTimes = [5, 10, 15, 20, 30, 45]

    /// Validates and clamps preparation time to valid values (5, 10, 15, 20, 30, 45 seconds)
    static func validatePreparationTime(_ seconds: Int) -> Int {
        // Find the closest valid value
        self.validPreparationTimes.min { abs($0 - seconds) < abs($1 - seconds) } ?? 15
    }
}

// MARK: - Default Settings

extension MeditationSettings {
    /// Default settings with interval gongs disabled and silent background audio
    static let `default` = MeditationSettings(
        intervalGongsEnabled: false,
        intervalMinutes: 5,
        backgroundSoundId: "silent",
        durationMinutes: 10,
        preparationTimeEnabled: true,
        preparationTimeSeconds: 15
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
