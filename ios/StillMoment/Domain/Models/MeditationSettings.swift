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
        intervalMode: IntervalMode = .repeating,
        intervalSoundId: String = GongSound.defaultIntervalSoundId,
        intervalGongVolume: Float = MeditationSettings.defaultIntervalGongVolume,
        backgroundSoundId: String = "silent",
        backgroundSoundVolume: Float = MeditationSettings.defaultBackgroundSoundVolume,
        durationMinutes: Int = 10,
        preparationTimeEnabled: Bool = true,
        preparationTimeSeconds: Int = 15,
        startGongSoundId: String = GongSound.defaultSoundId,
        gongVolume: Float = MeditationSettings.defaultGongVolume,
        introductionId: String? = nil
    ) {
        self.intervalGongsEnabled = intervalGongsEnabled
        self.intervalMinutes = Self.validateInterval(intervalMinutes)
        self.intervalMode = intervalMode
        self.intervalSoundId = intervalSoundId
        self.intervalGongVolume = Self.validateVolume(intervalGongVolume)
        self.backgroundSoundId = backgroundSoundId
        self.backgroundSoundVolume = Self.validateVolume(backgroundSoundVolume)
        self.durationMinutes = Self.validateDuration(durationMinutes, introductionId: introductionId)
        self.preparationTimeEnabled = preparationTimeEnabled
        self.preparationTimeSeconds = Self.validatePreparationTime(preparationTimeSeconds)
        self.startGongSoundId = startGongSoundId
        self.gongVolume = Self.validateVolume(gongVolume)
        self.introductionId = introductionId
    }

    // MARK: Internal

    // MARK: - Persistence Keys

    enum Keys {
        static let intervalGongsEnabled = "intervalGongsEnabled"
        static let intervalMinutes = "intervalMinutes"
        static let intervalMode = "intervalMode"
        static let intervalSoundId = "intervalSoundId"
        static let intervalGongVolume = "intervalGongVolume"
        static let backgroundSoundId = "backgroundSoundId"
        static let backgroundSoundVolume = "backgroundSoundVolume"
        static let durationMinutes = "durationMinutes"
        static let preparationTimeEnabled = "preparationTimeEnabled"
        static let preparationTimeSeconds = "preparationTimeSeconds"
        static let startGongSoundId = "startGongSoundId"
        static let gongVolume = "gongVolume"
        static let introductionId = "introductionId"
        /// Legacy key for migration
        static let legacyBackgroundAudioMode = "backgroundAudioMode"
    }

    /// Whether interval gongs are enabled during meditation
    var intervalGongsEnabled: Bool

    /// Interval in minutes between gongs (1-60)
    var intervalMinutes: Int

    /// Interval gong mode (repeating, afterStart, beforeEnd)
    var intervalMode: IntervalMode

    /// Sound ID for interval gongs (independent from start/end gong)
    var intervalSoundId: String

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

    /// Introduction ID (nil = no introduction, references Introduction.id)
    var introductionId: String?

    // MARK: - Validation

    /// Validates and clamps interval to valid range (1-60 minutes)
    static func validateInterval(_ minutes: Int) -> Int {
        min(max(minutes, 1), 60)
    }

    /// Returns the minimum meditation duration in minutes for a given introduction.
    /// When an introduction is selected, the minimum ensures at least 1 minute of silent meditation.
    /// Formula: ceil(introductionDurationSeconds / 60) + 1
    static func minimumDuration(for introductionId: String?) -> Int {
        guard let introId = introductionId,
              let intro = Introduction.find(byId: introId) else {
            return 1
        }
        return Int(ceil(Double(intro.durationSeconds) / 60.0)) + 1
    }

    /// Minimum meditation duration in minutes based on current introduction setting
    var minimumDurationMinutes: Int {
        Self.minimumDuration(for: self.introductionId)
    }

    /// Validates and clamps duration to valid range (minimum-60 minutes).
    /// Minimum is 1 without introduction, or ceil(introDuration/60)+1 with introduction.
    static func validateDuration(_ minutes: Int, introductionId: String? = nil) -> Int {
        let minimum = Self.minimumDuration(for: introductionId)
        return min(max(minutes, minimum), 60)
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
        intervalMode: .repeating,
        intervalSoundId: GongSound.defaultIntervalSoundId,
        intervalGongVolume: defaultIntervalGongVolume,
        backgroundSoundId: "silent",
        backgroundSoundVolume: defaultBackgroundSoundVolume,
        durationMinutes: 10,
        preparationTimeEnabled: true,
        preparationTimeSeconds: 15,
        startGongSoundId: GongSound.defaultSoundId,
        gongVolume: defaultGongVolume,
        introductionId: nil
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
