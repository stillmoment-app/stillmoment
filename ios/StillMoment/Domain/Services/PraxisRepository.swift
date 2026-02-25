//
//  PraxisRepository.swift
//  Still Moment
//
//  Domain Service Protocol - Praxis Repository
//

import Foundation

/// Protocol for managing Praxis persistence.
///
/// Implementations handle storage (UserDefaults, file system, etc.)
/// while keeping the domain model free of infrastructure dependencies.
/// There is exactly one Praxis configuration — no multi-preset CRUD.
protocol PraxisRepository {
    /// Returns the stored Praxis. Creates a default Praxis on first call (fresh install or migration).
    func load() -> Praxis

    /// Saves the given Praxis, replacing the existing configuration.
    func save(_ praxis: Praxis)
}
