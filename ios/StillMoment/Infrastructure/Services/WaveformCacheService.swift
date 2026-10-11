//
//  WaveformCacheService.swift
//  Still Moment
//
//  Infrastructure - Waveform Cache (JSON per meditation)
//

import Foundation
import OSLog

/// Concrete implementation of `WaveformCacheServiceProtocol`.
///
/// Stores one JSON file per meditation under `<baseDirectory>/Waveforms/{id}.json`
/// (in the app: Application Support).
final class WaveformCacheService: WaveformCacheServiceProtocol {
    // MARK: Lifecycle

    /// - Parameter baseDirectory: Folder that holds the `Waveforms` subfolder.
    init(baseDirectory: URL) {
        self.directory = baseDirectory.appendingPathComponent("Waveforms")
    }

    // MARK: Internal

    func load(id: UUID) -> MeditationWaveform? {
        let url = self.fileURL(for: id)
        guard self.fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(MeditationWaveform.self, from: data)
        } catch {
            Logger.infrastructure.error("Failed to load cached waveform for \(id): \(error.localizedDescription)")
            return nil
        }
    }

    func save(id: UUID, waveform: MeditationWaveform) throws {
        if !self.fileManager.fileExists(atPath: self.directory.path) {
            try self.fileManager.createDirectory(at: self.directory, withIntermediateDirectories: true)
        }

        let data = try JSONEncoder().encode(waveform)
        try data.write(to: self.fileURL(for: id), options: .atomic)
    }

    func delete(id: UUID) {
        let url = self.fileURL(for: id)
        guard self.fileManager.fileExists(atPath: url.path) else {
            return
        }
        do {
            try self.fileManager.removeItem(at: url)
        } catch {
            Logger.infrastructure.error("Failed to delete cached waveform for \(id): \(error.localizedDescription)")
        }
    }

    // MARK: Private

    private let directory: URL
    private let fileManager = FileManager.default

    private func fileURL(for id: UUID) -> URL {
        self.directory.appendingPathComponent("\(id.uuidString).json")
    }
}
