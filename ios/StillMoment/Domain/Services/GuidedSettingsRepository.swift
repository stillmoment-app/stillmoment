//
//  GuidedSettingsRepository.swift
//  Still Moment
//
//  Domain Service Protocol - Guided Meditation Settings Repository
//

import Foundation

/// Protocol for persisting guided meditation settings
///
/// Implementations handle the storage mechanism (UserDefaults, etc.)
/// while keeping the domain model free of infrastructure dependencies.
protocol GuidedSettingsRepository {
    /// Loads settings from persistent storage
    /// - Returns: The stored settings, or default settings if none exist
    func load() -> GuidedMeditationSettings

    /// Saves settings to persistent storage
    /// - Parameter settings: The settings to persist
    func save(_ settings: GuidedMeditationSettings)
}
