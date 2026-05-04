//
//  UserDefaultsTimerSettingsRepository.swift
//  Still Moment
//
//  Infrastructure - Timer Settings Repository Implementation
//

import Foundation
import OSLog

/// Legacy repository — read-only, used internally by `UserDefaultsPraxisRepository` for migration
/// from old UserDefaults keys to Praxis format.
///
/// Handles loading and legacy migration of `MeditationSettings` from UserDefaults.
/// Legacy migration logic (backgroundAudioMode → backgroundSoundId) lives here
/// to keep the ViewModel free of infrastructure concerns.
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
            )
        )

        self.logSettings(settings, action: "Loaded")
        return settings
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
        return BackgroundSound.silentId
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
