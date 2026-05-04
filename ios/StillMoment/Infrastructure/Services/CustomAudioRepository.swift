//
//  CustomAudioRepository.swift
//  Still Moment
//
//  Infrastructure - Custom Audio File Import and Persistence
//

import AVFoundation
import Foundation
import OSLog

/// Concrete implementation of CustomAudioRepositoryProtocol
///
/// Manages user-imported audio files (soundscapes) with UserDefaults persistence.
/// Audio files are copied to Application Support/CustomAudio/soundscapes/.
final class CustomAudioRepository: CustomAudioRepositoryProtocol {
    // MARK: Lifecycle

    /// Initializes the repository with optional custom UserDefaults and FileManager
    ///
    /// - Parameters:
    ///   - userDefaults: UserDefaults instance (defaults to .standard)
    ///   - fileManager: FileManager instance (defaults to .default)
    init(userDefaults: UserDefaults = .standard, fileManager: FileManager = .default) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
    }

    // MARK: Internal

    func loadAll() -> [CustomAudioFile] {
        guard let data = userDefaults.data(forKey: Self.storageKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            let files = try decoder.decode([CustomAudioFile].self, from: data)
            return files.sorted { $0.dateAdded > $1.dateAdded }
        } catch {
            Logger.infrastructure.error(
                "Failed to decode custom audio files",
                error: error
            )
            return []
        }
    }

    func importFile(from url: URL) throws -> CustomAudioFile {
        // Validate format
        let ext = url.pathExtension.lowercased()
        guard self.supportedFormats.contains(ext) else {
            throw CustomAudioError.unsupportedFormat(ext)
        }

        // Access security-scoped resource
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Generate unique ID and filename
        let fileId = UUID()
        let filename = "\(fileId.uuidString).\(ext)"

        // Copy file to local storage
        let destinationURL = try copyFileToDirectory(from: url, filename: filename)

        // Detect duration
        let duration = self.detectDuration(at: destinationURL)

        // Create model
        let file = CustomAudioFile(
            id: fileId,
            name: url.deletingPathExtension().lastPathComponent,
            filename: filename,
            duration: duration,
            dateAdded: Date()
        )

        // Persist metadata
        try self.persistFile(file)

        Logger.infrastructure.info("Imported custom audio: \(file.name)")

        return file
    }

    func delete(id: UUID) throws {
        var files = self.loadAll()
        guard let index = files.firstIndex(where: { $0.id == id }) else {
            throw CustomAudioError.fileNotFound(id)
        }

        let file = files[index]

        // Remove file from disk
        let fileURL = Self.directory(fileManager: self.fileManager).appendingPathComponent(file.filename)
        if self.fileManager.fileExists(atPath: fileURL.path) {
            try? self.fileManager.removeItem(at: fileURL)
            Logger.infrastructure.debug("Deleted custom audio file: \(fileURL.path)")
        }

        // Remove from metadata and persist
        files.remove(at: index)
        try self.saveFiles(files)

        Logger.infrastructure.info("Deleted custom audio: \(file.name)")
    }

    func fileURL(for audioFile: CustomAudioFile) -> URL? {
        let url = Self.directory(fileManager: self.fileManager).appendingPathComponent(audioFile.filename)
        guard self.fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        return url
    }

    func findFile(byId id: UUID) -> CustomAudioFile? {
        self.loadAll().first { $0.id == id }
    }

    func update(_ file: CustomAudioFile) throws {
        var files = self.loadAll()
        guard let index = files.firstIndex(where: { $0.id == file.id }) else {
            throw CustomAudioError.fileNotFound(file.id)
        }
        files[index] = file
        try self.saveFiles(files)
        Logger.infrastructure.info("Updated custom audio: \(file.name)")
    }

    // MARK: Private

    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    private let supportedFormats: Set<String> = ["mp3", "m4a", "wav"]

    /// UserDefaults key for the soundscape file metadata array.
    /// Suffix `_soundscape` retained for backward compatibility with existing
    /// pre-shared-088 storage; renaming would require a data migration.
    private static let storageKey = "customAudioFiles_soundscape"

    private static func directory(fileManager: FileManager) -> URL {
        // Application Support directory is guaranteed to exist on iOS
        // swiftlint:disable:next force_unwrapping
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("CustomAudio/soundscapes")
    }

    // MARK: - File Operations

    @discardableResult
    private func copyFileToDirectory(from sourceURL: URL, filename: String) throws -> URL {
        let directory = Self.directory(fileManager: self.fileManager)

        // Create directory if needed
        if !self.fileManager.fileExists(atPath: directory.path) {
            do {
                try self.fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                throw CustomAudioError.fileCopyFailed(error.localizedDescription)
            }
        }

        let destinationURL = directory.appendingPathComponent(filename)

        // Remove existing file if present
        if self.fileManager.fileExists(atPath: destinationURL.path) {
            try? self.fileManager.removeItem(at: destinationURL)
        }

        // Copy file
        do {
            try self.fileManager.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw CustomAudioError.fileCopyFailed(error.localizedDescription)
        }

        return destinationURL
    }

    // MARK: - Duration Detection

    private func detectDuration(at url: URL) -> TimeInterval? {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            let duration = player.duration
            guard duration.isFinite, duration > 0 else {
                Logger.infrastructure.debug("Duration detection returned invalid value for: \(url.lastPathComponent)")
                return nil
            }
            return duration
        } catch {
            Logger.infrastructure.debug("Duration detection failed for: \(url.lastPathComponent)")
            return nil
        }
    }

    // MARK: - Persistence

    private func persistFile(_ file: CustomAudioFile) throws {
        var files = self.loadAll()
        files.append(file)
        try self.saveFiles(files)
    }

    private func saveFiles(_ files: [CustomAudioFile]) throws {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(files)
            self.userDefaults.set(data, forKey: Self.storageKey)
        } catch {
            throw CustomAudioError.persistenceFailed(error.localizedDescription)
        }
    }
}
