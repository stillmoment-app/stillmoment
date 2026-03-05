//
//  AttunementResolver.swift
//  Still Moment
//
//  Infrastructure - Unified attunement resolution (built-in + custom)
//

import Foundation
import OSLog

/// Resolves attunement IDs by checking built-in introductions and custom audio repository.
///
/// Built-in introductions are language-filtered (only available for the device language).
/// Custom attunements are always available regardless of language.
final class AttunementResolver: AttunementResolverProtocol {
    private let customAudioRepository: CustomAudioRepositoryProtocol

    init(customAudioRepository: CustomAudioRepositoryProtocol) {
        self.customAudioRepository = customAudioRepository
    }

    func resolve(id: String) -> ResolvedAttunement? {
        // Try built-in introduction first
        if let intro = Introduction.find(byId: id),
           intro.availableLanguages.contains(Introduction.currentLanguage) {
            return ResolvedAttunement(
                id: intro.id,
                displayName: intro.name,
                durationSeconds: intro.durationSeconds(for: Introduction.currentLanguage)
            )
        }

        // Try custom attunement (UUID-based ID)
        if let uuid = UUID(uuidString: id),
           let customFile = self.customAudioRepository.findFile(byId: uuid),
           customFile.type == .attunement {
            return ResolvedAttunement(
                id: id,
                displayName: customFile.name,
                durationSeconds: customFile.duration.map { Int($0) } ?? 0
            )
        }

        return nil
    }

    func resolveAudioURL(id: String) throws -> URL {
        // Try custom attunement first (UUID-based)
        if let uuid = UUID(uuidString: id),
           let customFile = self.customAudioRepository.findFile(byId: uuid),
           let url = self.customAudioRepository.fileURL(for: customFile) {
            return url
        }

        // Try built-in introduction
        guard let filename = Introduction.audioFilenameForCurrentLanguage(id) else {
            Logger.audio.error(
                "Attunement not found or not available",
                metadata: ["id": id]
            )
            throw AudioServiceError.soundFileNotFound
        }

        let components = filename.split(separator: ".", maxSplits: 1)
        let name = String(components.first ?? "")
        let ext = components.count > 1 ? String(components.last ?? "") : ""

        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: ext,
            subdirectory: "IntroductionAudio"
        ) else {
            Logger.audio.error(
                "Attunement audio file not found in bundle",
                metadata: ["filename": filename]
            )
            throw AudioServiceError.soundFileNotFound
        }
        return url
    }

    func allAvailable() -> [ResolvedAttunement] {
        // Built-in introductions for current language
        var result = Introduction.availableForCurrentLanguage().map { intro in
            ResolvedAttunement(
                id: intro.id,
                displayName: intro.name,
                durationSeconds: intro.durationSeconds(for: Introduction.currentLanguage)
            )
        }

        // Custom attunements
        let customFiles = self.customAudioRepository.loadAll(type: .attunement)
        result += customFiles.map { file in
            ResolvedAttunement(
                id: file.id.uuidString,
                displayName: file.name,
                durationSeconds: file.duration.map { Int($0) } ?? 0
            )
        }

        return result
    }
}
