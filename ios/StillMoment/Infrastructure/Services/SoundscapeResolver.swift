//
//  SoundscapeResolver.swift
//  Still Moment
//
//  Infrastructure - Unified soundscape resolution (built-in + custom)
//

import Foundation
import OSLog

/// Resolves soundscape IDs by checking built-in background sounds and custom audio repository.
///
/// The special "silent" ID always returns nil (silence is not a soundscape to resolve).
final class SoundscapeResolver: SoundscapeResolverProtocol {
    private let soundRepository: BackgroundSoundRepositoryProtocol
    private let customAudioRepository: CustomAudioRepositoryProtocol

    init(
        soundRepository: BackgroundSoundRepositoryProtocol,
        customAudioRepository: CustomAudioRepositoryProtocol
    ) {
        self.soundRepository = soundRepository
        self.customAudioRepository = customAudioRepository
    }

    func resolve(id: String) -> ResolvedSoundscape? {
        guard id != "silent" else {
            return nil
        }

        // Try built-in sound
        if let sound = self.soundRepository.getSound(byId: id) {
            return ResolvedSoundscape(id: sound.id, displayName: sound.name)
        }

        // Try custom soundscape (UUID-based ID)
        if let uuid = UUID(uuidString: id),
           let customFile = self.customAudioRepository.findFile(byId: uuid),
           customFile.type == .soundscape {
            return ResolvedSoundscape(id: id, displayName: customFile.name)
        }

        return nil
    }

    func resolveAudioURL(id: String) throws -> URL {
        // Try built-in sound first
        if let sound = self.soundRepository.getSound(byId: id) {
            let components = sound.filename.split(separator: ".", maxSplits: 1)
            let name = String(components.first ?? "")
            let ext = components.count > 1 ? String(components.last ?? "") : ""

            guard let url = Bundle.main.url(
                forResource: name,
                withExtension: ext,
                subdirectory: "BackgroundAudio"
            ) else {
                Logger.audio.error(
                    "Background audio file not found in bundle",
                    metadata: ["filename": sound.filename]
                )
                throw AudioServiceError.soundFileNotFound
            }
            return url
        }

        // Try custom soundscape (UUID-based)
        if let uuid = UUID(uuidString: id),
           let customFile = self.customAudioRepository.findFile(byId: uuid),
           let url = self.customAudioRepository.fileURL(for: customFile) {
            return url
        }

        Logger.audio.error("Soundscape not found", metadata: ["id": id])
        throw AudioServiceError.soundFileNotFound
    }

    func allAvailable() -> [ResolvedSoundscape] {
        // Built-in sounds
        var result = self.soundRepository.availableSounds.map { sound in
            ResolvedSoundscape(id: sound.id, displayName: sound.name)
        }

        // Custom soundscapes
        let customFiles = self.customAudioRepository.loadAll(type: .soundscape)
        result += customFiles.map { file in
            ResolvedSoundscape(id: file.id.uuidString, displayName: file.name)
        }

        return result
    }
}
