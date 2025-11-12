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
            #if DEBUG
            assertionFailure("sounds.json must be present in bundle. Check Build Phases > Copy Bundle Resources.")
            #endif
            // Provide minimal fallback to prevent crash in production
            self.sounds = Self.defaultFallbackSounds
            Logger.audio.warning("Using fallback sounds due to loading failure")
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

    /// Default fallback sounds if sounds.json cannot be loaded
    /// Used only in error scenarios to prevent app crashes
    private static var defaultFallbackSounds: [BackgroundSound] {
        [
            BackgroundSound(
                id: "silent",
                filename: "silence.m4a",
                name: BackgroundSound.LocalizedString(en: "Silent", de: "Still"),
                description: BackgroundSound.LocalizedString(
                    en: "Almost silent (keeps app active)",
                    de: "Fast still (hält App aktiv)"
                ),
                iconName: "speaker.wave.1",
                volume: 0.01
            )
        ]
    }

    /// Loads sounds from sounds.json in the bundle
    ///
    /// Expected JSON format:
    /// ```json
    /// {
    ///   "sounds": [
    ///     {
    ///       "id": "silent",
    ///       "filename": "silence.m4a",
    ///       "name": { "en": "Silent", "de": "Still" },
    ///       "description": { "en": "...", "de": "..." },
    ///       "iconName": "speaker.wave.1",
    ///       "volume": 0.01
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
