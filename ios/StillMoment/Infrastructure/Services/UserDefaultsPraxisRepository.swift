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
/// Stores all Praxes as a JSON-encoded array. Handles:
/// - Fresh install: creates a "Standard" Praxis with default values
/// - Migration: converts existing MeditationSettings to a "Standard" Praxis
/// - Active Praxis ID persistence
final class UserDefaultsPraxisRepository: PraxisRepository {
    // MARK: Lifecycle

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.settingsRepository = UserDefaultsTimerSettingsRepository(userDefaults: userDefaults)
    }

    // MARK: Internal

    func loadAll() -> [Praxis] {
        if let data = userDefaults.data(forKey: Keys.praxes),
           let praxes = try? JSONDecoder().decode([Praxis].self, from: data),
           !praxes.isEmpty {
            Logger.infrastructure.info("Loaded \(praxes.count) praxes")
            return praxes
        }

        // No praxes stored — first launch (fresh install or migration)
        let praxis = self.createInitialPraxis()
        self.persist([praxis])
        Logger.infrastructure.info("Initialized with first praxis", metadata: ["name": praxis.name])
        return [praxis]
    }

    func load(byId id: UUID) -> Praxis? {
        self.loadAll().first { $0.id == id }
    }

    func save(_ praxis: Praxis) {
        var praxes = self.loadAll()
        if let index = praxes.firstIndex(where: { $0.id == praxis.id }) {
            praxes[index] = praxis
        } else {
            praxes.append(praxis)
        }
        self.persist(praxes)
        Logger.infrastructure.info("Saved praxis", metadata: [
            "id": praxis.id.uuidString,
            "name": praxis.name
        ])
    }

    func delete(id: UUID) throws {
        var praxes = self.loadAll()
        guard praxes.contains(where: { $0.id == id }) else {
            throw PraxisRepositoryError.praxisNotFound(id)
        }
        guard praxes.count > 1 else {
            throw PraxisRepositoryError.cannotDeleteLastPraxis
        }
        praxes.removeAll { $0.id == id }
        self.persist(praxes)
        Logger.infrastructure.info("Deleted praxis", metadata: ["id": id.uuidString])
    }

    var activePraxisId: UUID? {
        guard let string = userDefaults.string(forKey: Keys.activePraxisId) else {
            return nil
        }
        return UUID(uuidString: string)
    }

    func setActivePraxisId(_ id: UUID) {
        self.userDefaults.set(id.uuidString, forKey: Keys.activePraxisId)
        Logger.infrastructure.info("Set active praxis ID", metadata: ["id": id.uuidString])
    }

    // MARK: Private

    private enum Keys {
        static let praxes = "praxes"
        static let activePraxisId = "activePraxisId"
    }

    private let userDefaults: UserDefaults
    private let settingsRepository: UserDefaultsTimerSettingsRepository

    private func createInitialPraxis() -> Praxis {
        // Migration: existing MeditationSettings found
        if self.hasMeditationSettings() {
            let settings = self.settingsRepository.load()
            let praxis = Praxis(migratingFrom: settings)
            Logger.infrastructure.info("Migrated existing MeditationSettings to Praxis")
            return praxis
        }
        // Fresh install: use defaults
        Logger.infrastructure.info("Creating default Praxis for fresh install")
        return Praxis.default
    }

    private func hasMeditationSettings() -> Bool {
        self.userDefaults.object(forKey: MeditationSettings.Keys.backgroundSoundId) != nil ||
            self.userDefaults.object(forKey: MeditationSettings.Keys.intervalGongsEnabled) != nil
    }

    private func persist(_ praxes: [Praxis]) {
        guard let data = try? JSONEncoder().encode(praxes) else {
            Logger.infrastructure.error("Failed to encode praxes for persistence")
            return
        }
        self.userDefaults.set(data, forKey: Keys.praxes)
    }
}
