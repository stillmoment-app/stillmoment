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
        attunementId: String? = nil,
        attunementEnabled: Bool = false,
        customAttunementDurationSeconds: Int? = nil
    ) {
        self.intervalGongsEnabled = intervalGongsEnabled
        self.intervalMinutes = Self.validateInterval(intervalMinutes)
        self.intervalMode = intervalMode
        self.intervalSoundId = intervalSoundId
        self.intervalGongVolume = Self.validateVolume(intervalGongVolume)
        self.backgroundSoundId = backgroundSoundId
        self.backgroundSoundVolume = Self.validateVolume(backgroundSoundVolume)
        self.customAttunementDurationSeconds = customAttunementDurationSeconds
        self.durationMinutes = Self.validateDuration(
            durationMinutes,
            attunementId: attunementId,
            attunementEnabled: attunementEnabled,
            attunementDurationSeconds: customAttunementDurationSeconds
        )
        self.preparationTimeEnabled = preparationTimeEnabled
        self.preparationTimeSeconds = Self.validatePreparationTime(preparationTimeSeconds)
        self.startGongSoundId = startGongSoundId
        self.gongVolume = Self.validateVolume(gongVolume)
        self.attunementId = attunementId
        self.attunementEnabled = attunementEnabled
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
        static let attunementId = "introductionId"
        static let attunementEnabled = "introductionEnabled"
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

    /// Attunement ID (nil = no attunement, references Attunement.id)
    var attunementId: String?

    /// Whether the attunement is enabled (separate from attunementId to preserve user's selection)
    var attunementEnabled: Bool

    /// Custom attunement duration in seconds, resolved by ViewModel. Nil for built-in attunements.
    /// Transient — not persisted to UserDefaults.
    var customAttunementDurationSeconds: Int?

    /// The effective attunement ID. `nil` when disabled or no attunement is selected.
    /// Use this instead of checking `attunementEnabled` + `attunementId` manually.
    var activeAttunementId: String? {
        guard self.attunementEnabled else {
            return nil
        }
        return self.attunementId
    }

    // MARK: - Validation

    /// Validates and clamps interval to valid range (1-60 minutes)
    static func validateInterval(_ minutes: Int) -> Int {
        min(max(minutes, 1), 60)
    }

    /// Returns the minimum meditation duration in minutes for a given active attunement ID.
    /// `activeAttunementId` is `nil` when disabled or unset — callers use `settings.activeAttunementId`.
    /// `attunementDurationSeconds` is provided by the caller (resolved via AttunementResolver).
    /// Falls back to `Attunement.find()` for built-in attunements when `attunementDurationSeconds` is nil.
    /// Formula: ceil(attunementDurationSeconds / 60)
    static func minimumDuration(activeAttunementId: String?, attunementDurationSeconds: Int? = nil) -> Int {
        guard activeAttunementId != nil else {
            return 1
        }
        let durationSeconds: Int
        if let provided = attunementDurationSeconds {
            durationSeconds = provided
        } else if let attunementId = activeAttunementId,
                  let attunement = Attunement.find(byId: attunementId) {
            durationSeconds = attunement.durationSeconds
        } else {
            return 1
        }
        guard durationSeconds > 0 else {
            return 1
        }
        return Int(ceil(Double(durationSeconds) / 60.0))
    }

    /// Backward-compatible overload used during init/validation where enabled+id are separate.
    static func minimumDuration(
        for attunementId: String?,
        attunementEnabled: Bool = false,
        attunementDurationSeconds: Int? = nil
    ) -> Int {
        let activeId = attunementEnabled ? attunementId : nil
        return Self.minimumDuration(
            activeAttunementId: activeId,
            attunementDurationSeconds: attunementDurationSeconds
        )
    }

    /// Minimum meditation duration in minutes based on current attunement setting.
    /// Uses `customAttunementDurationSeconds` when set (resolved via AttunementResolver).
    var minimumDurationMinutes: Int {
        Self.minimumDuration(
            activeAttunementId: self.activeAttunementId,
            attunementDurationSeconds: self.customAttunementDurationSeconds
        )
    }

    /// Validates and clamps duration to valid range (minimum-60 minutes).
    /// Minimum is 1 without attunement, or ceil(attunementDuration/60) with enabled attunement.
    static func validateDuration(
        _ minutes: Int,
        attunementId: String? = nil,
        attunementEnabled: Bool = false,
        attunementDurationSeconds: Int? = nil
    ) -> Int {
        let minimum = Self.minimumDuration(
            for: attunementId,
            attunementEnabled: attunementEnabled,
            attunementDurationSeconds: attunementDurationSeconds
        )
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
        attunementId: nil,
        attunementEnabled: false
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
