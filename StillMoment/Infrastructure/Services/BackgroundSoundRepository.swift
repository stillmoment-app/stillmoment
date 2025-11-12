//
//  BackgroundSoundRepository.swift
//  Still Moment
//
//  Infrastructure - Background Sound Repository Implementation
//

import Foundation
import OSLog

/// Concrete implementation of background sound repository
final class BackgroundSoundRepository: BackgroundSoundRepositoryProtocol {
    // MARK: Lifecycle

    // MARK: - Initialization

    init() {
        // Load sounds from sounds.json - this must succeed
        do {
            self.sounds = try Self.loadSoundsFromBundle()
            Logger.audio.info("Loaded \(self.sounds.count) background sounds from sounds.json")
        } catch {
            Logger.audio.error("CRITICAL: Failed to load background sounds from sounds.json", error: error)
            // sounds.json is always part of the bundle - if it's missing, something is seriously wrong
            fatalError("""
                sounds.json must be present in bundle.
                Check Build Phases > Copy Bundle Resources.
                Error: \(error)
                """
            )
        }
    }

    // MARK: Internal

    /// Loaded sounds from sounds.json
    /// Thread-safe: Immutable after init, safe for concurrent reads
    private(set) var sounds: [BackgroundSound]

    /// All available background sounds (cached after init)
    var availableSounds: [BackgroundSound] {
        self.sounds
    }

    // MARK: - Public Methods

    func loadSounds() throws -> [BackgroundSound] {
        self.sounds
    }

    func getSound(byId id: String) -> BackgroundSound? {
        self.sounds.first { $0.id == id }
    }

    // MARK: Private

    // MARK: - Private Methods

    /// Loads sounds from sounds.json in the bundle
    ///
    /// Expected JSON format:
    /// ```json
    /// {
    ///   "sounds": [
    ///     {
    ///       "id": "example-sound",
    ///       "filename": "example-sound.mp3",
    ///       "name": { "en": "Example Sound", "de": "Beispiel-Sound" },
    ///       "description": { "en": "Description", "de": "Beschreibung" },
    ///       "iconName": "speaker.wave.2",
    ///       "volume": 0.15
    ///     }
    ///   ]
    /// }
    /// ```
    private static func loadSoundsFromBundle() throws -> [BackgroundSound] {
        // Locate sounds.json in BackgroundAudio folder
        guard let url = Bundle.main.url(
            forResource: "sounds",
            withExtension: "json",
            subdirectory: "BackgroundAudio"
        ) else {
            Logger.audio.error("sounds.json not found in BackgroundAudio folder")
            throw BackgroundSoundRepositoryError.configFileNotFound
        }

        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(SoundsConfiguration.self, from: data)
            return config.sounds
        } catch let error as DecodingError {
            Logger.audio.error("Failed to decode sounds.json", error: error)
            throw BackgroundSoundRepositoryError.decodingFailed(error)
        } catch {
            Logger.audio.error("Failed to load sounds.json", error: error)
            throw BackgroundSoundRepositoryError.invalidJSON
        }
    }
}

// MARK: - Configuration Model

/// Internal model for decoding sounds.json
private struct SoundsConfiguration: Codable {
    let sounds: [BackgroundSound]
}
