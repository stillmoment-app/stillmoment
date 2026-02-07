//
//  TimerSettingsRepository.swift
//  Still Moment
//
//  Domain Service Protocol - Timer Settings Repository
//

import Foundation

/// Protocol for persisting timer meditation settings
///
/// Implementations handle the storage mechanism (UserDefaults, etc.)
/// while keeping the domain model free of infrastructure dependencies.
/// Legacy migration logic (e.g. backgroundAudioMode) belongs here, not in ViewModels.
protocol TimerSettingsRepository {
    /// Loads settings from persistent storage
    /// - Returns: The stored settings, or default settings if none exist
    func load() -> MeditationSettings

    /// Saves settings to persistent storage
    /// - Parameter settings: The settings to persist
    func save(_ settings: MeditationSettings)
}
