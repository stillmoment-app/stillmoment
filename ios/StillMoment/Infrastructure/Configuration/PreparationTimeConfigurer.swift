//
//  PreparationTimeConfigurer.swift
//  Still Moment
//
//  Infrastructure - Preparation Time Configuration
//
//  Configures preparation time settings for UI tests and screenshot automation.
//

import Foundation
import OSLog

/// Configures preparation time settings via UserDefaults
///
/// Used by UI tests via `-DisablePreparation` launch argument to skip
/// the preparation countdown phase for faster, more reliable tests.
enum PreparationTimeConfigurer {
    /// Disables preparation time in UserDefaults
    ///
    /// Call this when the app receives `-DisablePreparation` launch argument.
    /// The timer will start immediately without the preparation countdown.
    static func disable() {
        UserDefaults.standard.set(false, forKey: MeditationSettings.Keys.preparationTimeEnabled)
        Logger.infrastructure.info("Preparation time disabled via launch argument")
    }
}
