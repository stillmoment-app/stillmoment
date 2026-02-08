//
//  FileOpenHandler.swift
//  Still Moment
//
//  Application Layer - Handles "Open with" file association for audio import
//

import Foundation
import OSLog

/// Errors that can occur during file open handling
enum FileOpenError: Error, Equatable, LocalizedError {
    /// The file format is not supported (only MP3 and M4A)
    case unsupportedFormat

    /// The file could not be imported (corrupt, unreadable, or service error)
    case importFailed

    /// A meditation with the same filename is already in the library
    case alreadyImported

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            NSLocalizedString("error.unsupportedFormat", comment: "Unsupported audio format")
        case .importFailed:
            NSLocalizedString("error.fileOpenImportFailed", comment: "File could not be imported")
        case .alreadyImported:
            NSLocalizedString("error.alreadyImported", comment: "Meditation already in library")
        }
    }
}

/// Handles importing audio files received via "Open with" file association
///
/// This handler is triggered when the user opens an MP3 or M4A file
/// from the Files app (or other sources) and chooses Still Moment.
///
/// Flow:
/// 1. Validate file format (MP3/M4A only)
/// 2. Check for duplicates (same filename + file size)
/// 3. Extract metadata via AudioMetadataService
/// 4. Import via GuidedMeditationService
@MainActor
final class FileOpenHandler: ObservableObject {
    // MARK: Lifecycle

    init(
        meditationService: GuidedMeditationServiceProtocol = GuidedMeditationService(),
        metadataService: AudioMetadataServiceProtocol = AudioMetadataService()
    ) {
        self.meditationService = meditationService
        self.metadataService = metadataService
    }

    // MARK: Internal

    /// Whether a file import is currently being processed
    @Published private(set) var isProcessing = false

    /// Most recently imported meditation via file open, consumed by the list view to show edit sheet
    @Published var importedMeditation: GuidedMeditation?

    /// Supported audio file extensions for import
    static let supportedExtensions: Set<String> = ["mp3", "m4a"]

    /// Checks whether the given URL points to a supported audio file
    ///
    /// - Parameter url: File URL to check
    /// - Returns: true if the file extension is MP3 or M4A
    func canHandle(url: URL) -> Bool {
        Self.supportedExtensions.contains(url.pathExtension.lowercased())
    }

    /// Handles a file open request from the system
    ///
    /// Validates the format, checks for duplicates, extracts metadata,
    /// and imports the file into the meditation library.
    ///
    /// - Parameter url: URL to the audio file
    /// - Returns: Result with the imported GuidedMeditation or a FileOpenError
    func handleFileOpen(url: URL) async -> Result<GuidedMeditation, FileOpenError> {
        guard self.canHandle(url: url) else {
            Logger.guidedMeditation.warning(
                "Rejected file with unsupported format",
                metadata: ["extension": url.pathExtension]
            )
            return .failure(.unsupportedFormat)
        }

        if self.isDuplicate(url: url) {
            return .failure(.alreadyImported)
        }

        self.isProcessing = true
        defer { self.isProcessing = false }

        return await self.performImport(from: url)
    }

    // MARK: Private

    private let meditationService: GuidedMeditationServiceProtocol
    private let metadataService: AudioMetadataServiceProtocol

    /// Checks whether a file with the same name and size is already in the library
    ///
    /// Uses both filename and file size to avoid false positives when different files
    /// share the same name (e.g. multiple "meditation.mp3" from different sources).
    private func isDuplicate(url: URL) -> Bool {
        do {
            let existing = try self.meditationService.loadMeditations()
            let fileName = url.lastPathComponent
            let incomingFileSize = self.fileSize(of: url)

            let found = existing.contains { meditation in
                guard meditation.fileName == fileName else {
                    return false
                }
                guard let incomingSize = incomingFileSize else {
                    // Cannot determine incoming file size — fall back to name-only check
                    return true
                }
                guard let existingURL = self.meditationService.fileURL(for: meditation) else {
                    // Cannot resolve existing file — fall back to name-only check
                    return true
                }
                let existingSize = self.fileSize(of: existingURL)
                return existingSize == incomingSize
            }

            if found {
                Logger.guidedMeditation.info("Duplicate file detected", metadata: ["fileName": fileName])
            }
            return found
        } catch {
            Logger.guidedMeditation.error("Failed to load meditations for duplicate check", error: error)
            return false
        }
    }

    /// Returns the file size in bytes, or nil if the file attributes cannot be read
    private func fileSize(of url: URL) -> UInt64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? UInt64
        else {
            return nil
        }
        return size
    }

    /// Performs the actual file import with security-scoped access
    private func performImport(from url: URL) async -> Result<GuidedMeditation, FileOpenError> {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let metadata: AudioMetadata
        do {
            metadata = try await self.metadataService.extractMetadata(from: url)
        } catch {
            Logger.guidedMeditation.error("Failed to extract metadata for file open", error: error)
            return .failure(.importFailed)
        }

        do {
            let meditation = try self.meditationService.addMeditation(from: url, metadata: metadata)
            Logger.guidedMeditation.info(
                "Successfully imported meditation via file open",
                metadata: ["id": meditation.id.uuidString, "fileName": url.lastPathComponent]
            )
            return .success(meditation)
        } catch {
            Logger.guidedMeditation.error("Failed to import meditation via file open", error: error)
            return .failure(.importFailed)
        }
    }
}
