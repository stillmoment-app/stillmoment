//
//  UserDefaultsTimerSettingsRepository.swift
//  Still Moment
//
//  Infrastructure - Timer Settings Repository Implementation
//

import Foundation
import OSLog

/// UserDefaults-based implementation of timer settings persistence
///
/// Handles loading, saving, and legacy migration of `MeditationSettings`.
/// Legacy migration logic (backgroundAudioMode → backgroundSoundId) lives here
/// to keep the ViewModel free of infrastructure concerns.
/// Legacy repository — only used internally by `UserDefaultsPraxisRepository` for migration
/// from old UserDefaults keys to Praxis format. Not used for active read/write operations.
final class UserDefaultsTimerSettingsRepository {
    // MARK: Lifecycle

    /// Creates a repository with the specified UserDefaults instance
    /// - Parameter userDefaults: The UserDefaults to use (defaults to .standard)
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: Internal

    func load() -> MeditationSettings {
        let settings = MeditationSettings(
            intervalGongsEnabled: self.userDefaults.bool(forKey: MeditationSettings.Keys.intervalGongsEnabled),
            intervalMinutes: self.loadIntervalMinutes(),
            intervalMode: self.loadIntervalMode(),
            intervalSoundId: self.userDefaults.string(forKey: MeditationSettings.Keys.intervalSoundId)
                ?? GongSound.defaultIntervalSoundId,
            intervalGongVolume: self.loadFloat(
                MeditationSettings.Keys.intervalGongVolume,
                default: MeditationSettings.defaultIntervalGongVolume
            ),
            backgroundSoundId: self.loadBackgroundSoundId(),
            backgroundSoundVolume: self.loadFloat(
                MeditationSettings.Keys.backgroundSoundVolume,
                default: MeditationSettings.defaultBackgroundSoundVolume
            ),
            durationMinutes: self.loadInteger(MeditationSettings.Keys.durationMinutes, default: 10),
            preparationTimeEnabled: self.loadBool(MeditationSettings.Keys.preparationTimeEnabled, default: true),
            preparationTimeSeconds: self.loadInteger(MeditationSettings.Keys.preparationTimeSeconds, default: 15),
            startGongSoundId: self.userDefaults.string(forKey: MeditationSettings.Keys.startGongSoundId) ?? GongSound
                .defaultSoundId,
            gongVolume: self.loadFloat(
                MeditationSettings.Keys.gongVolume,
                default: MeditationSettings.defaultGongVolume
            ),
            introductionId: self.userDefaults.string(forKey: MeditationSettings.Keys.introductionId),
            introductionEnabled: self.loadIntroductionEnabled()
        )

        self.logSettings(settings, action: "Loaded")
        return settings
    }

    func save(_ settings: MeditationSettings) {
        self.userDefaults.set(settings.intervalGongsEnabled, forKey: MeditationSettings.Keys.intervalGongsEnabled)
        self.userDefaults.set(settings.intervalMinutes, forKey: MeditationSettings.Keys.intervalMinutes)
        self.userDefaults.set(settings.intervalMode.rawValue, forKey: MeditationSettings.Keys.intervalMode)
        self.userDefaults.set(settings.intervalSoundId, forKey: MeditationSettings.Keys.intervalSoundId)
        self.userDefaults.set(settings.intervalGongVolume, forKey: MeditationSettings.Keys.intervalGongVolume)
        self.userDefaults.set(settings.backgroundSoundId, forKey: MeditationSettings.Keys.backgroundSoundId)
        self.userDefaults.set(settings.backgroundSoundVolume, forKey: MeditationSettings.Keys.backgroundSoundVolume)
        self.userDefaults.set(settings.durationMinutes, forKey: MeditationSettings.Keys.durationMinutes)
        self.userDefaults.set(settings.preparationTimeEnabled, forKey: MeditationSettings.Keys.preparationTimeEnabled)
        self.userDefaults.set(settings.preparationTimeSeconds, forKey: MeditationSettings.Keys.preparationTimeSeconds)
        self.userDefaults.set(settings.startGongSoundId, forKey: MeditationSettings.Keys.startGongSoundId)
        self.userDefaults.set(settings.gongVolume, forKey: MeditationSettings.Keys.gongVolume)
        self.userDefaults.set(settings.introductionId, forKey: MeditationSettings.Keys.introductionId)
        self.userDefaults.set(settings.introductionEnabled, forKey: MeditationSettings.Keys.introductionEnabled)

        self.logSettings(settings, action: "Saved")
    }

    // MARK: Private

    private let userDefaults: UserDefaults

    // MARK: - Typed Value Loaders

    private func loadFloat(_ key: String, default defaultValue: Float) -> Float {
        self.userDefaults.object(forKey: key) != nil
            ? self.userDefaults.float(forKey: key)
            : defaultValue
    }

    private func loadInteger(_ key: String, default defaultValue: Int) -> Int {
        self.userDefaults.object(forKey: key) != nil
            ? self.userDefaults.integer(forKey: key)
            : defaultValue
    }

    private func loadBool(_ key: String, default defaultValue: Bool) -> Bool {
        self.userDefaults.object(forKey: key) != nil
            ? self.userDefaults.bool(forKey: key)
            : defaultValue
    }

    private func loadIntervalMinutes() -> Int {
        let stored = self.userDefaults.integer(forKey: MeditationSettings.Keys.intervalMinutes)
        return stored == 0 ? 5 : stored
    }

    /// Loads interval mode with fallback to default (repeating)
    private func loadIntervalMode() -> IntervalMode {
        guard let rawValue = self.userDefaults.string(forKey: MeditationSettings.Keys.intervalMode) else {
            return .repeating
        }
        return IntervalMode(rawValue: rawValue) ?? .repeating
    }

    /// Loads introductionEnabled with migration support.
    /// If the key doesn't exist yet (legacy data), defaults to `true` when introductionId is set.
    private func loadIntroductionEnabled() -> Bool {
        if self.userDefaults.object(forKey: MeditationSettings.Keys.introductionEnabled) != nil {
            return self.userDefaults.bool(forKey: MeditationSettings.Keys.introductionEnabled)
        }
        // Legacy migration: if introductionId is set, the user had introduction enabled
        return self.userDefaults.string(forKey: MeditationSettings.Keys.introductionId) != nil
    }

    // MARK: - Legacy Migration

    /// Loads background sound ID with legacy migration support
    private func loadBackgroundSoundId() -> String {
        if let soundId = self.userDefaults.string(forKey: MeditationSettings.Keys.backgroundSoundId),
           !soundId.isEmpty {
            return soundId
        }
        if let legacyMode = self.userDefaults.string(forKey: MeditationSettings.Keys.legacyBackgroundAudioMode) {
            let migratedId = MeditationSettings.migrateLegacyMode(legacyMode)
            self.userDefaults.set(migratedId, forKey: MeditationSettings.Keys.backgroundSoundId)
            Logger.infrastructure.info("Migrated legacy timer settings", metadata: [
                "legacyMode": legacyMode,
                "newSoundId": migratedId
            ])
            return migratedId
        }
        return "silent"
    }

    // MARK: - Logging

    private func logSettings(_ settings: MeditationSettings, action: String) {
        Logger.infrastructure.info("\(action) timer settings", metadata: [
            "intervalEnabled": settings.intervalGongsEnabled,
            "intervalMinutes": settings.intervalMinutes,
            "intervalMode": settings.intervalMode.rawValue,
            "intervalSoundId": settings.intervalSoundId,
            "backgroundSoundId": settings.backgroundSoundId,
            "durationMinutes": settings.durationMinutes,
            "preparationEnabled": settings.preparationTimeEnabled,
            "preparationSeconds": settings.preparationTimeSeconds
        ])
    }
}
