//
//  MeditationSourceRepository.swift
//  Still Moment
//
//  Infrastructure - Loads curated meditation sources from `meditation_sources.json`.
//

import Foundation
import OSLog

/// Loads curated meditation sources from `meditation_sources.json`.
///
/// The file ships in the app bundle under `MeditationSources/`. Each top-level
/// key is a language code (`"de"`, `"en"`) mapped to an array of sources.
/// Which language is shown first is decided by `MeditationSourceCatalog`.
final class MeditationSourceRepository: MeditationSourceRepositoryProtocol {
    // MARK: Lifecycle

    init(bundle: Bundle = .main) {
        do {
            self.loadedCatalog = try Self.loadCatalog(from: bundle)
            let total = self.loadedCatalog.sourcesByLanguage.values.reduce(0) { $0 + $1.count }
            Logger.infrastructure.info("Loaded meditation sources catalog (\(total) entries)")
        } catch {
            Logger.infrastructure.error("Failed to load meditation_sources.json", error: error)
            self.loadedCatalog = MeditationSourceCatalog(sourcesByLanguage: [:])
        }
    }

    // MARK: Internal

    func catalog() -> MeditationSourceCatalog {
        self.loadedCatalog
    }

    // MARK: Private

    private let loadedCatalog: MeditationSourceCatalog

    private static func loadCatalog(from bundle: Bundle) throws -> MeditationSourceCatalog {
        // Synchronized file-system groups in Xcode typically flatten resources into the
        // bundle root, so try the flat lookup first and fall back to the folder.
        let url = bundle.url(forResource: "meditation_sources", withExtension: "json")
            ?? bundle.url(
                forResource: "meditation_sources",
                withExtension: "json",
                subdirectory: "MeditationSources"
            )
        guard let url else {
            throw MeditationSourceRepositoryError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try Self.decodeCatalog(from: data)
    }

    /// Exposed for unit testing without a Bundle.
    static func decodeCatalog(from data: Data) throws -> MeditationSourceCatalog {
        let decoded = try JSONDecoder().decode([String: [MeditationSourceDTO]].self, from: data)
        return MeditationSourceCatalog(
            sourcesByLanguage: decoded.mapValues { dtos in dtos.compactMap(Self.mapToSource) }
        )
    }

    private static func mapToSource(_ dto: MeditationSourceDTO) -> MeditationSource? {
        guard let url = URL(string: dto.url), url.scheme?.hasPrefix("http") == true else {
            Logger.infrastructure.error("Invalid URL for source \(dto.id): \(dto.url)")
            return nil
        }
        return MeditationSource(
            id: dto.id,
            name: dto.name,
            offer: dto.offer?.nonBlankTrimmed,
            description: dto.description,
            host: dto.host,
            url: url
        )
    }
}

// MARK: - JSON DTO

private struct MeditationSourceDTO: Codable {
    let id: String
    let name: String
    let offer: String?
    let description: String
    let host: String
    let url: String
}

// MARK: - Errors

enum MeditationSourceRepositoryError: Error, LocalizedError {
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            "meditation_sources.json not found in app bundle"
        }
    }
}
