//
//  BackgroundSoundRepositoryProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Background Sound Repository
//

import Foundation

/// Protocol for loading and accessing background sounds
///
/// The repository manages background sounds loaded from `sounds.json` configuration.
/// Sounds are loaded once during initialization and cached for the app lifecycle.
///
/// Thread Safety: All methods are safe for concurrent access after initialization.
protocol BackgroundSoundRepositoryProtocol {
    /// All available sounds (cached after first load)
    var availableSounds: [BackgroundSound] { get }

    /// Loads all available background sounds from configuration
    /// - Returns: Array of background sounds
    /// - Throws: BackgroundSoundRepositoryError if loading fails
    func loadSounds() throws -> [BackgroundSound]

    /// Retrieves a specific sound by its ID
    /// - Parameter id: The unique identifier of the sound
    /// - Returns: The background sound if found, nil otherwise
    func getSound(byId id: String) -> BackgroundSound?
}

/// Errors that can occur during background sound repository operations
enum BackgroundSoundRepositoryError: Error, LocalizedError {
    case configFileNotFound
    case invalidJSON
    case decodingFailed(Error)

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .configFileNotFound:
            "Background sounds configuration file not found"
        case .invalidJSON:
            "Invalid JSON in sounds configuration"
        case let .decodingFailed(error):
            "Failed to decode sounds configuration: \(error.localizedDescription)"
        }
    }
}
