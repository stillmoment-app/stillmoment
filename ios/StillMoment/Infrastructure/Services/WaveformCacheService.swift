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
/// Stores one JSON file per meditation under `Application Support/Waveforms/{id}.json`.
/// The directory and `FileManager` are injectable so tests can use a temporary directory.
final class WaveformCacheService: WaveformCacheServiceProtocol {
    // MARK: Lifecycle

    /// - Parameters:
    ///   - fileManager: FileManager instance (defaults to `.default`).
    ///   - directory: Override for the storage directory. When `nil`, resolves to
    ///     `Application Support/Waveforms`.
    init(fileManager: FileManager = .default, directory: URL? = nil) {
        self.fileManager = fileManager
        self.overrideDirectory = directory
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
        let directory = self.waveformsDirectory()
        if !self.fileManager.fileExists(atPath: directory.path) {
            try self.fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
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

    private let fileManager: FileManager
    private let overrideDirectory: URL?

    private func waveformsDirectory() -> URL {
        if let overrideDirectory {
            return overrideDirectory
        }
        // Application Support directory is guaranteed to exist on iOS.
        // swiftlint:disable:next force_unwrapping
        let appSupport = self.fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Waveforms")
    }

    private func fileURL(for id: UUID) -> URL {
        self.waveformsDirectory().appendingPathComponent("\(id.uuidString).json")
    }
}
