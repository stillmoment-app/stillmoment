//
//  PraxisRepository.swift
//  Still Moment
//
//  Domain Service Protocol - Praxis Repository
//

import Foundation

/// Errors thrown by PraxisRepository operations
enum PraxisRepositoryError: Error, LocalizedError {
    /// Thrown when attempting to delete the last remaining Praxis
    case cannotDeleteLastPraxis
    /// Thrown when a Praxis with the given ID is not found
    case praxisNotFound(UUID)

    var errorDescription: String? {
        switch self {
        case .cannotDeleteLastPraxis:
            "At least one Praxis must always exist."
        case let .praxisNotFound(id):
            "Praxis with ID \(id) not found."
        }
    }
}

/// Protocol for managing Praxis persistence
///
/// Implementations handle storage (UserDefaults, file system, etc.)
/// while keeping the domain model free of infrastructure dependencies.
/// At least one Praxis always exists — deletion of the last Praxis is prevented.
protocol PraxisRepository {
    /// Returns all stored Praxes. Creates a default Praxis on first call (fresh install or migration).
    func loadAll() -> [Praxis]

    /// Returns the Praxis with the given ID, or nil if not found.
    func load(byId id: UUID) -> Praxis?

    /// Saves (creates or updates) the given Praxis.
    func save(_ praxis: Praxis)

    /// Deletes the Praxis with the given ID.
    /// - Throws: `PraxisRepositoryError.cannotDeleteLastPraxis` if this is the only Praxis.
    /// - Throws: `PraxisRepositoryError.praxisNotFound` if no Praxis with the given ID exists.
    func delete(id: UUID) throws

    /// The currently active Praxis ID (nil if none explicitly set).
    var activePraxisId: UUID? { get }

    /// Persists the active Praxis ID.
    func setActivePraxisId(_ id: UUID)
}
