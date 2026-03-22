//
//  Praxis.swift
//  Still Moment
//
//  Domain - Praxis Model (saveable timer configuration)
//

import Foundation

/// A saveable timer configuration.
///
/// "Praxis" (practice) represents a complete set of meditation timer settings
/// that can be stored and recalled. There is exactly one active Praxis at a time.
///
/// Praxis is an immutable value object — all state changes produce new instances.
struct Praxis: Codable, Equatable, Identifiable {
    // MARK: - Properties

    let id: UUID

    // Timer configuration (1:1 with MeditationSettings fields)
    let durationMinutes: Int
    let preparationTimeEnabled: Bool
    let preparationTimeSeconds: Int
    let startGongSoundId: String
    let gongVolume: Float
    let attunementId: String?
    let attunementEnabled: Bool
    let intervalGongsEnabled: Bool
    let intervalMinutes: Int
    let intervalMode: IntervalMode
    let intervalSoundId: String
    let intervalGongVolume: Float
    let backgroundSoundId: String
    let backgroundSoundVolume: Float

    // MARK: - Initialization

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case durationMinutes
        case preparationTimeEnabled
        case preparationTimeSeconds
        case startGongSoundId
        case gongVolume
        case attunementId = "introductionId"
        case attunementEnabled = "introductionEnabled"
        case intervalGongsEnabled
        case intervalMinutes
        case intervalMode
        case intervalSoundId
        case intervalGongVolume
        case backgroundSoundId
        case backgroundSoundVolume
    }

    init(
        id: UUID = UUID(),
        durationMinutes: Int = 10,
        preparationTimeEnabled: Bool = true,
        preparationTimeSeconds: Int = 15,
        startGongSoundId: String = GongSound.defaultSoundId,
        gongVolume: Float = 1.0,
        attunementId: String? = nil,
        attunementEnabled: Bool = false,
        intervalGongsEnabled: Bool = false,
        intervalMinutes: Int = 5,
        intervalMode: IntervalMode = .repeating,
        intervalSoundId: String = GongSound.defaultIntervalSoundId,
        intervalGongVolume: Float = 0.75,
        backgroundSoundId: String = "silent",
        backgroundSoundVolume: Float = 0.15
    ) {
        self.id = id
        self.durationMinutes = Self.validateDuration(durationMinutes)
        self.preparationTimeEnabled = preparationTimeEnabled
        self.preparationTimeSeconds = Self.validatePreparationTime(preparationTimeSeconds)
        self.startGongSoundId = startGongSoundId
        self.gongVolume = Self.validateVolume(gongVolume)
        self.attunementId = attunementId
        self.attunementEnabled = attunementEnabled
        self.intervalGongsEnabled = intervalGongsEnabled
        self.intervalMinutes = Self.validateInterval(intervalMinutes)
        self.intervalMode = intervalMode
        self.intervalSoundId = intervalSoundId
        self.intervalGongVolume = Self.validateVolume(intervalGongVolume)
        self.backgroundSoundId = backgroundSoundId
        self.backgroundSoundVolume = Self.validateVolume(backgroundSoundVolume)
    }

    // MARK: - Codable Migration

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.durationMinutes = try Self.validateDuration(container.decode(Int.self, forKey: .durationMinutes))
        self.preparationTimeEnabled = try container.decode(Bool.self, forKey: .preparationTimeEnabled)
        self.preparationTimeSeconds = try Self.validatePreparationTime(
            container.decode(Int.self, forKey: .preparationTimeSeconds)
        )
        self.startGongSoundId = try container.decode(String.self, forKey: .startGongSoundId)
        self.gongVolume = try Self.validateVolume(container.decode(Float.self, forKey: .gongVolume))
        self.attunementId = try container.decodeIfPresent(String.self, forKey: .attunementId)
        self.attunementEnabled = try container.decodeIfPresent(Bool.self, forKey: .attunementEnabled)
            ?? (self.attunementId != nil)
        self.intervalGongsEnabled = try container.decode(Bool.self, forKey: .intervalGongsEnabled)
        self.intervalMinutes = try Self.validateInterval(container.decode(Int.self, forKey: .intervalMinutes))
        self.intervalMode = try container.decode(IntervalMode.self, forKey: .intervalMode)
        self.intervalSoundId = try container.decode(String.self, forKey: .intervalSoundId)
        self.intervalGongVolume = try Self.validateVolume(container.decode(Float.self, forKey: .intervalGongVolume))
        self.backgroundSoundId = try container.decode(String.self, forKey: .backgroundSoundId)
        self.backgroundSoundVolume = try Self.validateVolume(
            container.decode(Float.self, forKey: .backgroundSoundVolume)
        )
    }

    // MARK: - Validation

    static func validateDuration(_ minutes: Int) -> Int {
        min(max(minutes, 1), 60)
    }

    static func validateInterval(_ minutes: Int) -> Int {
        min(max(minutes, 1), 60)
    }

    static let validPreparationTimes = [5, 10, 15, 20, 30, 45]

    static func validatePreparationTime(_ seconds: Int) -> Int {
        self.validPreparationTimes.min { abs($0 - seconds) < abs($1 - seconds) } ?? 15
    }

    static func validateVolume(_ volume: Float) -> Float {
        min(max(volume, 0.0), 1.0)
    }
}

// MARK: - Default Praxis

extension Praxis {
    /// Default Praxis with factory defaults.
    static let `default` = Praxis(
        id: UUID(),
        durationMinutes: 10,
        preparationTimeEnabled: true,
        preparationTimeSeconds: 15,
        startGongSoundId: GongSound.defaultSoundId,
        gongVolume: 1.0,
        attunementId: nil,
        attunementEnabled: false,
        intervalGongsEnabled: false,
        intervalMinutes: 5,
        intervalMode: .repeating,
        intervalSoundId: GongSound.defaultIntervalSoundId,
        intervalGongVolume: 0.75,
        backgroundSoundId: "silent",
        backgroundSoundVolume: 0.15
    )
}

// MARK: - Builder Methods

extension Praxis {
    /// Returns a new Praxis with the background sound replaced.
    func withBackgroundSoundId(_ newId: String) -> Praxis {
        Praxis(
            id: self.id,
            durationMinutes: self.durationMinutes,
            preparationTimeEnabled: self.preparationTimeEnabled,
            preparationTimeSeconds: self.preparationTimeSeconds,
            startGongSoundId: self.startGongSoundId,
            gongVolume: self.gongVolume,
            attunementId: self.attunementId,
            attunementEnabled: self.attunementEnabled,
            intervalGongsEnabled: self.intervalGongsEnabled,
            intervalMinutes: self.intervalMinutes,
            intervalMode: self.intervalMode,
            intervalSoundId: self.intervalSoundId,
            intervalGongVolume: self.intervalGongVolume,
            backgroundSoundId: newId,
            backgroundSoundVolume: self.backgroundSoundVolume
        )
    }

    /// Returns a new Praxis with the duration replaced.
    func withDurationMinutes(_ minutes: Int) -> Praxis {
        Praxis(
            id: self.id,
            durationMinutes: minutes,
            preparationTimeEnabled: self.preparationTimeEnabled,
            preparationTimeSeconds: self.preparationTimeSeconds,
            startGongSoundId: self.startGongSoundId,
            gongVolume: self.gongVolume,
            attunementId: self.attunementId,
            attunementEnabled: self.attunementEnabled,
            intervalGongsEnabled: self.intervalGongsEnabled,
            intervalMinutes: self.intervalMinutes,
            intervalMode: self.intervalMode,
            intervalSoundId: self.intervalSoundId,
            intervalGongVolume: self.intervalGongVolume,
            backgroundSoundId: self.backgroundSoundId,
            backgroundSoundVolume: self.backgroundSoundVolume
        )
    }

    /// Returns a new Praxis with the attunement replaced.
    func withAttunementId(_ newId: String?) -> Praxis {
        Praxis(
            id: self.id,
            durationMinutes: self.durationMinutes,
            preparationTimeEnabled: self.preparationTimeEnabled,
            preparationTimeSeconds: self.preparationTimeSeconds,
            startGongSoundId: self.startGongSoundId,
            gongVolume: self.gongVolume,
            attunementId: newId,
            attunementEnabled: self.attunementEnabled,
            intervalGongsEnabled: self.intervalGongsEnabled,
            intervalMinutes: self.intervalMinutes,
            intervalMode: self.intervalMode,
            intervalSoundId: self.intervalSoundId,
            intervalGongVolume: self.intervalGongVolume,
            backgroundSoundId: self.backgroundSoundId,
            backgroundSoundVolume: self.backgroundSoundVolume
        )
    }

    /// Returns a new Praxis with the attunement enabled/disabled.
    func withAttunementEnabled(_ enabled: Bool) -> Praxis {
        Praxis(
            id: self.id,
            durationMinutes: self.durationMinutes,
            preparationTimeEnabled: self.preparationTimeEnabled,
            preparationTimeSeconds: self.preparationTimeSeconds,
            startGongSoundId: self.startGongSoundId,
            gongVolume: self.gongVolume,
            attunementId: self.attunementId,
            attunementEnabled: enabled,
            intervalGongsEnabled: self.intervalGongsEnabled,
            intervalMinutes: self.intervalMinutes,
            intervalMode: self.intervalMode,
            intervalSoundId: self.intervalSoundId,
            intervalGongVolume: self.intervalGongVolume,
            backgroundSoundId: self.backgroundSoundId,
            backgroundSoundVolume: self.backgroundSoundVolume
        )
    }
}

// MARK: - Migration from MeditationSettings

extension Praxis {
    /// Creates a Praxis from existing MeditationSettings (for migration).
    init(migratingFrom settings: MeditationSettings, id: UUID = UUID()) {
        self.init(
            id: id,
            durationMinutes: settings.durationMinutes,
            preparationTimeEnabled: settings.preparationTimeEnabled,
            preparationTimeSeconds: settings.preparationTimeSeconds,
            startGongSoundId: settings.startGongSoundId,
            gongVolume: settings.gongVolume,
            attunementId: settings.attunementId,
            attunementEnabled: settings.attunementEnabled,
            intervalGongsEnabled: settings.intervalGongsEnabled,
            intervalMinutes: settings.intervalMinutes,
            intervalMode: settings.intervalMode,
            intervalSoundId: settings.intervalSoundId,
            intervalGongVolume: settings.intervalGongVolume,
            backgroundSoundId: settings.backgroundSoundId,
            backgroundSoundVolume: settings.backgroundSoundVolume
        )
    }
}

// MARK: - Conversion to MeditationSettings

extension Praxis {
    /// Converts this Praxis to a MeditationSettings instance.
    /// Used when a Praxis is selected and its configuration is applied to the timer.
    func toMeditationSettings(customAttunementDurationSeconds: Int? = nil) -> MeditationSettings {
        MeditationSettings(
            intervalGongsEnabled: self.intervalGongsEnabled,
            intervalMinutes: self.intervalMinutes,
            intervalMode: self.intervalMode,
            intervalSoundId: self.intervalSoundId,
            intervalGongVolume: self.intervalGongVolume,
            backgroundSoundId: self.backgroundSoundId,
            backgroundSoundVolume: self.backgroundSoundVolume,
            durationMinutes: self.durationMinutes,
            preparationTimeEnabled: self.preparationTimeEnabled,
            preparationTimeSeconds: self.preparationTimeSeconds,
            startGongSoundId: self.startGongSoundId,
            gongVolume: self.gongVolume,
            attunementId: self.attunementId,
            attunementEnabled: self.attunementEnabled,
            customAttunementDurationSeconds: customAttunementDurationSeconds
        )
    }
}
