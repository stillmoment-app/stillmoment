//
//  UserDefaultsSearchHistoryStore.swift
//  Still Moment
//
//  Infrastructure - UserDefaults-basierter Store fuer die Bibliotheks-Suchhistorie.
//

import Foundation

/// Konkrete `SearchHistoryStore`-Implementierung gegen `UserDefaults`.
///
/// Privacy: Die Daten bleiben auf dem Geraet, keine Cloud-Synchronisation.
final class UserDefaultsSearchHistoryStore: SearchHistoryStore {
    // MARK: Lifecycle

    init(userDefaults: UserDefaults = .standard, key: String = UserDefaultsSearchHistoryStore.defaultKey) {
        self.userDefaults = userDefaults
        self.key = key
    }

    // MARK: Internal

    static let defaultKey = "library.searchHistory"

    func load() -> [String] {
        (self.userDefaults.array(forKey: self.key) as? [String]) ?? []
    }

    func save(_ history: [String]) {
        self.userDefaults.set(history, forKey: self.key)
    }

    // MARK: Private

    private let userDefaults: UserDefaults
    private let key: String
}
