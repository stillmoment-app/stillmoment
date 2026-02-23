//
//  Praxis.swift
//  Still Moment
//
//  Domain - Praxis Model (named, saveable timer configuration)
//

import Foundation

/// A named, saveable timer configuration.
///
/// "Praxis" (practice) represents a complete set of meditation timer settings
/// that can be stored, recalled, and reused. Multiple Praxes allow users to
/// quickly switch between different meditation configurations.
///
/// Praxis is an immutable value object — all state changes produce new instances.
struct Praxis: Codable, Equatable, Identifiable {
    // MARK: - Properties

    let id: UUID
    let name: String

    // Timer configuration (1:1 with MeditationSettings fields)
    let durationMinutes: Int
    let preparationTimeEnabled: Bool
    let preparationTimeSeconds: Int
    let startGongSoundId: String
    let gongVolume: Float
    let introductionId: String?
    let intervalGongsEnabled: Bool
    let intervalMinutes: Int
    let intervalMode: IntervalMode
    let intervalSoundId: String
    let intervalGongVolume: Float
    let backgroundSoundId: String
    let backgroundSoundVolume: Float

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        durationMinutes: Int = 10,
        preparationTimeEnabled: Bool = true,
        preparationTimeSeconds: Int = 15,
        startGongSoundId: String = GongSound.defaultSoundId,
        gongVolume: Float = 1.0,
        introductionId: String? = nil,
        intervalGongsEnabled: Bool = false,
        intervalMinutes: Int = 5,
        intervalMode: IntervalMode = .repeating,
        intervalSoundId: String = GongSound.defaultIntervalSoundId,
        intervalGongVolume: Float = 0.75,
        backgroundSoundId: String = "silent",
        backgroundSoundVolume: Float = 0.15
    ) {
        self.id = id
        self.name = name
        self.durationMinutes = Self.validateDuration(durationMinutes)
        self.preparationTimeEnabled = preparationTimeEnabled
        self.preparationTimeSeconds = Self.validatePreparationTime(preparationTimeSeconds)
        self.startGongSoundId = startGongSoundId
        self.gongVolume = Self.validateVolume(gongVolume)
        self.introductionId = introductionId
        self.intervalGongsEnabled = intervalGongsEnabled
        self.intervalMinutes = Self.validateInterval(intervalMinutes)
        self.intervalMode = intervalMode
        self.intervalSoundId = intervalSoundId
        self.intervalGongVolume = Self.validateVolume(intervalGongVolume)
        self.backgroundSoundId = backgroundSoundId
        self.backgroundSoundVolume = Self.validateVolume(backgroundSoundVolume)
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

    // MARK: - Short Description

    /// A short, human-readable summary of the key configuration.
    /// Example (DE): "10 Min · Stille · Tempelglocke · 15s Vorbereitung"
    /// Example (EN): "10 min · Silence · Temple Bell · 15s preparation"
    var shortDescription: String {
        var parts: [String] = []

        // Duration
        parts.append(String(
            format: NSLocalizedString("praxis.description.duration", comment: ""),
            self.durationMinutes
        ))

        // Background sound (only show "Silence" label for silent, other sounds shown elsewhere)
        if self.backgroundSoundId == "silent" {
            parts.append(NSLocalizedString("praxis.description.silent", comment: ""))
        }

        // Start gong name
        if let gong = GongSound.find(byId: startGongSoundId) {
            parts.append(gong.name)
        }

        // Preparation time
        if self.preparationTimeEnabled {
            parts.append(String(
                format: NSLocalizedString("praxis.description.preparation", comment: ""),
                self.preparationTimeSeconds
            ))
        }

        return parts.joined(separator: " · ")
    }
}

// MARK: - Default Praxis

extension Praxis {
    /// Default "Standard" Praxis with factory defaults.
    static let `default` = Praxis(
        id: UUID(),
        name: NSLocalizedString("praxis.default.name", comment: ""),
        durationMinutes: 10,
        preparationTimeEnabled: true,
        preparationTimeSeconds: 15,
        startGongSoundId: GongSound.defaultSoundId,
        gongVolume: 1.0,
        introductionId: nil,
        intervalGongsEnabled: false,
        intervalMinutes: 5,
        intervalMode: .repeating,
        intervalSoundId: GongSound.defaultIntervalSoundId,
        intervalGongVolume: 0.75,
        backgroundSoundId: "silent",
        backgroundSoundVolume: 0.15
    )
}

// MARK: - Migration from MeditationSettings

extension Praxis {
    /// Creates a Praxis from existing MeditationSettings (for migration).
    init(migratingFrom settings: MeditationSettings, id: UUID = UUID()) {
        self.init(
            id: id,
            name: NSLocalizedString("praxis.default.name", comment: ""),
            durationMinutes: settings.durationMinutes,
            preparationTimeEnabled: settings.preparationTimeEnabled,
            preparationTimeSeconds: settings.preparationTimeSeconds,
            startGongSoundId: settings.startGongSoundId,
            gongVolume: settings.gongVolume,
            introductionId: settings.introductionId,
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
