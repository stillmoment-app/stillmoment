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

    /// Default volume for background sounds (15%)
    static let defaultBackgroundSoundVolume: Float = 0.15

    /// Default volume for gong sounds (100%)
    static let defaultGongVolume: Float = 1.0

    /// Default volume for interval gong (75%)
    static let defaultIntervalGongVolume: Float = 0.75

    init(
        intervalGongsEnabled: Bool = false,
        intervalMinutes: Int = 5,
        intervalGongVolume: Float = MeditationSettings.defaultIntervalGongVolume,
        backgroundSoundId: String = "silent",
        backgroundSoundVolume: Float = MeditationSettings.defaultBackgroundSoundVolume,
        durationMinutes: Int = 10,
        preparationTimeEnabled: Bool = true,
        preparationTimeSeconds: Int = 15,
        startGongSoundId: String = GongSound.defaultSoundId,
        gongVolume: Float = MeditationSettings.defaultGongVolume
    ) {
        self.intervalGongsEnabled = intervalGongsEnabled
        self.intervalMinutes = Self.validateInterval(intervalMinutes)
        self.intervalGongVolume = Self.validateVolume(intervalGongVolume)
        self.backgroundSoundId = backgroundSoundId
        self.backgroundSoundVolume = Self.validateVolume(backgroundSoundVolume)
        self.durationMinutes = Self.validateDuration(durationMinutes)
        self.preparationTimeEnabled = preparationTimeEnabled
        self.preparationTimeSeconds = Self.validatePreparationTime(preparationTimeSeconds)
        self.startGongSoundId = startGongSoundId
        self.gongVolume = Self.validateVolume(gongVolume)
    }

    // MARK: Internal

    // MARK: - Persistence Keys

    enum Keys {
        static let intervalGongsEnabled = "intervalGongsEnabled"
        static let intervalMinutes = "intervalMinutes"
        static let intervalGongVolume = "intervalGongVolume"
        static let backgroundSoundId = "backgroundSoundId"
        static let backgroundSoundVolume = "backgroundSoundVolume"
        static let durationMinutes = "durationMinutes"
        static let preparationTimeEnabled = "preparationTimeEnabled"
        static let preparationTimeSeconds = "preparationTimeSeconds"
        static let startGongSoundId = "startGongSoundId"
        static let gongVolume = "gongVolume"
        /// Legacy key for migration
        static let legacyBackgroundAudioMode = "backgroundAudioMode"
    }

    /// Whether interval gongs are enabled during meditation
    var intervalGongsEnabled: Bool

    /// Interval in minutes between gongs (3, 5, or 10)
    var intervalMinutes: Int

    /// Interval gong volume (0.0 to 1.0)
    var intervalGongVolume: Float

    /// Background sound ID (references BackgroundSound.id)
    var backgroundSoundId: String

    /// Background sound volume (0.0 to 1.0)
    var backgroundSoundVolume: Float

    /// Duration of meditation in minutes (1-60)
    var durationMinutes: Int

    /// Whether preparation time is enabled before meditation starts
    var preparationTimeEnabled: Bool

    /// Duration of preparation phase in seconds (5, 10, 15, 20, 30, 45)
    var preparationTimeSeconds: Int

    /// Gong sound ID for start/end gong (references GongSound.id)
    var startGongSoundId: String

    /// Gong volume (0.0 to 1.0) - applies to start and end gong
    var gongVolume: Float

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

    /// Validates and clamps volume to valid range (0.0-1.0)
    static func validateVolume(_ volume: Float) -> Float {
        min(max(volume, 0.0), 1.0)
    }
}

// MARK: - Default Settings

extension MeditationSettings {
    /// Default settings with interval gongs disabled and silent background audio
    static let `default` = MeditationSettings(
        intervalGongsEnabled: false,
        intervalMinutes: 5,
        intervalGongVolume: defaultIntervalGongVolume,
        backgroundSoundId: "silent",
        backgroundSoundVolume: defaultBackgroundSoundVolume,
        durationMinutes: 10,
        preparationTimeEnabled: true,
        preparationTimeSeconds: 15,
        startGongSoundId: GongSound.defaultSoundId,
        gongVolume: defaultGongVolume
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
