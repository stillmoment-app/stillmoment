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
            return config.sounds.map { self.mapToBackgroundSound($0) }
        } catch let error as DecodingError {
            Logger.audio.error("Failed to decode sounds.json", error: error)
            throw BackgroundSoundRepositoryError.decodingFailed(error)
        } catch {
            Logger.audio.error("Failed to load sounds.json", error: error)
            throw BackgroundSoundRepositoryError.invalidJSON
        }
    }

    /// Maps a JSON DTO to the domain model, resolving localized strings for the current device language
    private static func mapToBackgroundSound(_ dto: BackgroundSoundDTO) -> BackgroundSound {
        BackgroundSound(
            id: dto.id,
            filename: dto.filename,
            name: self.resolveLocale(dto.name),
            description: self.resolveLocale(dto.description),
            iconName: dto.iconName,
            volume: dto.volume
        )
    }

    /// Resolves a localized string from the JSON DTO to the current device language
    private static func resolveLocale(_ localizedString: BackgroundSoundDTO.LocalizedString) -> String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        switch languageCode {
        case "de":
            return localizedString.de
        default:
            return localizedString.en
        }
    }
}

// MARK: - JSON DTOs

/// DTO matching the sounds.json format with inline translations.
/// File-private: only used by BackgroundSoundRepository for JSON parsing.
struct BackgroundSoundDTO: Codable {
    struct LocalizedString: Codable {
        let en: String
        let de: String
    }

    let id: String
    let filename: String
    let name: LocalizedString
    let description: LocalizedString
    let iconName: String
    let volume: Float
}

/// Internal model for decoding sounds.json
private struct SoundsConfiguration: Codable {
    let sounds: [BackgroundSoundDTO]
}
