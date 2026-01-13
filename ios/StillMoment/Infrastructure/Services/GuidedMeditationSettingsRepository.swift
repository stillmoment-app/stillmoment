//
//  GuidedMeditationSettingsRepository.swift
//  Still Moment
//
//  Infrastructure - Guided Meditation Settings Repository Implementation
//

import Foundation

/// UserDefaults-based implementation of guided meditation settings persistence
final class GuidedMeditationSettingsRepository: GuidedSettingsRepository {
    // MARK: Lifecycle

    /// Creates a repository with the specified UserDefaults instance
    /// - Parameter userDefaults: The UserDefaults to use (defaults to .standard)
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: Internal

    func load() -> GuidedMeditationSettings {
        if self.userDefaults.object(forKey: Self.preparationTimeKey) != nil {
            let seconds = self.userDefaults.integer(forKey: Self.preparationTimeKey)
            return GuidedMeditationSettings(preparationTimeSeconds: seconds == 0 ? nil : seconds)
        }
        return .default
    }

    func save(_ settings: GuidedMeditationSettings) {
        // Store 0 for disabled (nil) - simpler than removing the key
        self.userDefaults.set(settings.preparationTimeSeconds ?? 0, forKey: Self.preparationTimeKey)
    }

    // MARK: Private

    private static let preparationTimeKey = "guidedMeditation.preparationTimeSeconds"
    private let userDefaults: UserDefaults
}
