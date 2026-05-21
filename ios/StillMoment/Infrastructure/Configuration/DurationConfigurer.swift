//
//  DurationConfigurer.swift
//  Still Moment
//
//  Infrastructure - Duration Configuration
//
//  Configures the active Praxis duration for UI tests and screenshot automation.
//

import Foundation
import OSLog

/// Configures the active Praxis duration via the PraxisRepository.
///
/// Used by UI tests via `-DurationMinutes <n>` launch argument to set the
/// session duration before the timer is started — necessary because a 10-minute
/// default leaves the moon-phase visualisation at near-new-moon for the entire
/// snapshot window (ios-047).
enum DurationConfigurer {
    /// Updates the persisted Praxis to use the given duration in minutes.
    ///
    /// Call this when the app receives `-DurationMinutes <n>` launch argument.
    /// The new duration is clamped to the valid range by `Praxis.validateDuration`.
    static func setDuration(_ minutes: Int) {
        let repository = UserDefaultsPraxisRepository()
        let updated = repository.load().withDurationMinutes(minutes)
        repository.save(updated)
        Logger.infrastructure.info(
            "Duration set via launch argument",
            metadata: ["minutes": updated.durationMinutes]
        )
    }
}
