//
//  UserDefaultsPraxisRepository.swift
//  Still Moment
//
//  Infrastructure - Praxis Repository (UserDefaults + JSON)
//

import Foundation
import OSLog

/// UserDefaults-based implementation of PraxisRepository.
///
/// Stores a single Praxis as JSON. Handles:
/// - Fresh install: creates a default Praxis with factory defaults
/// - Migration from old multi-preset format ("praxes" key): loads active or first preset
/// - Migration from MeditationSettings: converts existing settings to a Praxis
final class UserDefaultsPraxisRepository: PraxisRepository {
    // MARK: Lifecycle

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.settingsRepository = UserDefaultsTimerSettingsRepository(userDefaults: userDefaults)
    }

    // MARK: Internal

    func load() -> Praxis {
        // 1. Try new single-praxis key
        if let data = userDefaults.data(forKey: Keys.currentPraxis),
           let praxis = try? JSONDecoder().decode(Praxis.self, from: data) {
            Logger.infrastructure.info("Loaded current praxis")
            return praxis
        }

        // 2. Migrate from old multi-praxis array (name field is ignored by Codable)
        if let data = userDefaults.data(forKey: Keys.praxes),
           let praxes = try? JSONDecoder().decode([Praxis].self, from: data),
           !praxes.isEmpty {
            let praxis = self.resolveActiveFromLegacy(praxes)
            self.save(praxis)
            Logger.infrastructure.info("Migrated from legacy multi-praxis format")
            return praxis
        }

        // 3. Migrate from MeditationSettings
        if self.hasMeditationSettings() {
            let settings = self.settingsRepository.load()
            let praxis = Praxis(migratingFrom: settings)
            self.save(praxis)
            Logger.infrastructure.info("Migrated existing MeditationSettings to Praxis")
            return praxis
        }

        // 4. Fresh install: use defaults
        let praxis = Praxis.default
        self.save(praxis)
        Logger.infrastructure.info("Creating default Praxis for fresh install")
        return praxis
    }

    func save(_ praxis: Praxis) {
        guard let data = try? JSONEncoder().encode(praxis) else {
            Logger.infrastructure.error("Failed to encode praxis for persistence")
            return
        }
        self.userDefaults.set(data, forKey: Keys.currentPraxis)
        Logger.infrastructure.info("Saved praxis", metadata: ["id": praxis.id.uuidString])
    }

    // MARK: Private

    private enum Keys {
        static let currentPraxis = "currentPraxis"
        static let praxes = "praxes" // legacy multi-preset key
        static let activePraxisId = "activePraxisId" // legacy active-preset key
    }

    private let userDefaults: UserDefaults
    private let settingsRepository: UserDefaultsTimerSettingsRepository

    private func resolveActiveFromLegacy(_ praxes: [Praxis]) -> Praxis {
        if let activeIdString = userDefaults.string(forKey: Keys.activePraxisId),
           let activeId = UUID(uuidString: activeIdString),
           let active = praxes.first(where: { $0.id == activeId }) {
            return active
        }
        return praxes[0]
    }

    private func hasMeditationSettings() -> Bool {
        self.userDefaults.object(forKey: MeditationSettings.Keys.backgroundSoundId) != nil ||
            self.userDefaults.object(forKey: MeditationSettings.Keys.intervalGongsEnabled) != nil
    }
}
