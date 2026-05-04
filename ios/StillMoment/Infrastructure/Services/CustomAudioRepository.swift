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

    func loadAll(type: CustomAudioType) -> [CustomAudioFile] {
        let key = self.storageKey(for: type)
        guard let data = userDefaults.data(forKey: key) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            let files = try decoder.decode([CustomAudioFile].self, from: data)
            return files.sorted { $0.dateAdded > $1.dateAdded }
        } catch {
            Logger.infrastructure.error(
                "Failed to decode custom audio files",
                error: error,
                metadata: ["type": type.rawValue]
            )
            return []
        }
    }

    func importFile(from url: URL, type: CustomAudioType) throws -> CustomAudioFile {
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
        let destinationURL = try copyFileToDirectory(from: url, filename: filename, type: type)

        // Detect duration
        let duration = self.detectDuration(at: destinationURL)

        // Create model
        let file = CustomAudioFile(
            id: fileId,
            name: url.deletingPathExtension().lastPathComponent,
            filename: filename,
            duration: duration,
            type: type,
            dateAdded: Date()
        )

        // Persist metadata
        try self.persistFile(file, type: type)

        Logger.infrastructure.info("Imported custom audio: \(file.name)", metadata: ["type": type.rawValue])

        return file
    }

    func delete(id: UUID) throws {
        let type = CustomAudioType.soundscape
        var files = self.loadAll(type: type)
        guard let index = files.firstIndex(where: { $0.id == id }) else {
            throw CustomAudioError.fileNotFound(id)
        }

        let file = files[index]

        // Remove file from disk
        let directory = self.getDirectory(for: type)
        let fileURL = directory.appendingPathComponent(file.filename)
        if self.fileManager.fileExists(atPath: fileURL.path) {
            try? self.fileManager.removeItem(at: fileURL)
            Logger.infrastructure.debug("Deleted custom audio file: \(fileURL.path)")
        }

        // Remove from metadata and persist
        files.remove(at: index)
        try self.saveFiles(files, type: type)

        Logger.infrastructure.info("Deleted custom audio: \(file.name)", metadata: ["type": type.rawValue])
    }

    func fileURL(for audioFile: CustomAudioFile) -> URL? {
        let directory = self.getDirectory(for: audioFile.type)
        let url = directory.appendingPathComponent(audioFile.filename)
        guard self.fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        return url
    }

    func findFile(byId id: UUID) -> CustomAudioFile? {
        let allSoundscapes = self.loadAll(type: .soundscape)
        return allSoundscapes.first { $0.id == id }
    }

    func update(_ file: CustomAudioFile) throws {
        var files = self.loadAll(type: file.type)
        guard let index = files.firstIndex(where: { $0.id == file.id }) else {
            throw CustomAudioError.fileNotFound(file.id)
        }
        files[index] = file
        try self.saveFiles(files, type: file.type)
        Logger.infrastructure.info("Updated custom audio: \(file.name)")
    }

    // MARK: Private

    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    private let supportedFormats: Set<String> = ["mp3", "m4a", "wav"]

    // MARK: - Storage Keys

    private func storageKey(for type: CustomAudioType) -> String {
        switch type {
        case .soundscape:
            "customAudioFiles_soundscape"
        }
    }

    // MARK: - Directory Management

    private func getDirectory(for type: CustomAudioType) -> URL {
        // Application Support directory is guaranteed to exist on iOS
        // swiftlint:disable:next force_unwrapping
        let appSupport = self.fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        switch type {
        case .soundscape:
            return appSupport.appendingPathComponent("CustomAudio/soundscapes")
        }
    }

    // MARK: - File Operations

    @discardableResult
    private func copyFileToDirectory(from sourceURL: URL, filename: String, type: CustomAudioType) throws -> URL {
        let directory = self.getDirectory(for: type)

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

    private func persistFile(_ file: CustomAudioFile, type: CustomAudioType) throws {
        var files = self.loadAll(type: type)
        files.append(file)
        try self.saveFiles(files, type: type)
    }

    private func saveFiles(_ files: [CustomAudioFile], type: CustomAudioType) throws {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(files)
            self.userDefaults.set(data, forKey: self.storageKey(for: type))
        } catch {
            throw CustomAudioError.persistenceFailed(error.localizedDescription)
        }
    }
}
