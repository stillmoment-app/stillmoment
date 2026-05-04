//
//  FileOpenHandler.swift
//  Still Moment
//
//  Application Layer - Handles "Open with" file association for audio import
//

import Foundation
import OSLog

/// The result type when importing an audio file with a specific type.
///
/// Since guided meditations and custom audio files are stored differently,
/// the success case returns different types depending on the import type.
enum ImportResult: Equatable {
    /// Successfully imported as a guided meditation
    case guidedMeditation(GuidedMeditation)
    /// Successfully imported as custom audio (soundscape)
    case customAudio(CustomAudioFile)
}

/// State for a custom audio file that was imported and is pending review/navigation
struct CustomAudioImportState: Equatable {
    let file: CustomAudioFile
}

/// Errors that can occur during file open handling
enum FileOpenError: Error, Equatable, LocalizedError {
    /// The file format is not supported (only MP3 and M4A)
    case unsupportedFormat

    /// The file could not be imported (corrupt, unreadable, or service error)
    case importFailed

    /// A file with the same name and size is already in the library
    case alreadyImported(name: String?, teacher: String?)

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            NSLocalizedString("error.unsupportedFormat", comment: "Unsupported audio format")
        case .importFailed:
            NSLocalizedString("error.fileOpenImportFailed", comment: "File could not be imported")
        case let .alreadyImported(name, teacher):
            if let name, let teacher {
                String(
                    format: NSLocalizedString(
                        "error.alreadyImported.withInfo",
                        comment: "Duplicate with title and teacher — %1$@ is teacher, %2$@ is title"
                    ),
                    teacher,
                    name
                )
            } else {
                NSLocalizedString("error.alreadyImported", comment: "Meditation already in library")
            }
        }
    }
}

/// Handles importing audio files received via "Open with" file association
///
/// This handler is triggered when the user opens an MP3 or M4A file
/// from the Files app (or other sources) and chooses Still Moment.
///
/// Supports two import flows:
/// 1. Automatic import (legacy): handleFileOpen(...) — imports as guided meditation
/// 2. Type-based import (shared-073): importFile(from:as:) — user selects import type
///
/// Flow (type-based):
/// 1. Validate file format (MP3/M4A only) — validateFileForImport(...)
/// 2. User selects import type
/// 3. Check for duplicates within that type
/// 4. Extract metadata via AudioMetadataService
/// 5. Route to GuidedMeditationService (for meditations) or CustomAudioRepository (for custom audio)
@MainActor
final class FileOpenHandler: ObservableObject {
    // MARK: Lifecycle

    init(
        meditationService: GuidedMeditationServiceProtocol = GuidedMeditationService(),
        metadataService: AudioMetadataServiceProtocol = AudioMetadataService(),
        customAudioRepository: CustomAudioRepositoryProtocol = CustomAudioRepository()
    ) {
        self.meditationService = meditationService
        self.metadataService = metadataService
        self.customAudioRepository = customAudioRepository
    }

    // MARK: Internal

    /// Whether a file import is currently being processed
    @Published private(set) var isProcessing = false

    /// Most recently imported meditation via file open, consumed by the list view to show edit sheet
    @Published var importedMeditation: GuidedMeditation?

    /// Whether the import type selection sheet should be shown
    @Published var showImportTypeSelection = false

    /// The URL of the file being imported (set by prepareImport, consumed by importFile)
    @Published var pendingImportURL: URL?

    /// Whether a running meditation should be stopped when importing
    @Published var shouldStopMeditation = false

    /// Custom audio file that was imported and needs navigation/confirmation
    @Published var pendingCustomAudioImport: CustomAudioImportState?

    /// Supported audio file extensions for import
    static let supportedExtensions: Set<String> = ["mp3", "m4a"]

    /// Checks whether the given URL points to a supported audio file
    ///
    /// - Parameter url: File URL to check
    /// - Returns: true if the file extension is MP3 or M4A
    func canHandle(url: URL) -> Bool {
        Self.supportedExtensions.contains(url.pathExtension.lowercased())
    }

    /// Validates that a file can be imported (format check only)
    ///
    /// Used in the type-based import flow to validate the file before
    /// the user selects an import type. Does not check for duplicates.
    ///
    /// - Parameter url: URL to the audio file
    /// - Returns: Result with the validated URL or a FileOpenError
    func validateFileForImport(url: URL) -> Result<URL, FileOpenError> {
        guard self.canHandle(url: url) else {
            Logger.guidedMeditation.warning(
                "Rejected file with unsupported format",
                metadata: ["extension": url.pathExtension]
            )
            return .failure(.unsupportedFormat)
        }
        return .success(url)
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

        if let duplicate = self.findDuplicateFromLegacyCheck(url: url) {
            return .failure(.alreadyImported(name: duplicate.effectiveName, teacher: duplicate.effectiveTeacher))
        }

        self.isProcessing = true
        defer { self.isProcessing = false }

        return await self.performImport(from: url)
    }

    /// Imports a file as the specified type (shared-073: type-based import)
    ///
    /// Validates the format, checks for duplicates specific to the type,
    /// extracts metadata, and routes to the appropriate service.
    ///
    /// - Parameters:
    ///   - url: URL to the audio file
    ///   - importType: The type to import as (guided meditation or soundscape)
    /// - Returns: Result with the ImportResult or a FileOpenError
    func importFile(from url: URL, as importType: ImportAudioType) async -> Result<ImportResult, FileOpenError> {
        guard self.canHandle(url: url) else {
            Logger.guidedMeditation.warning(
                "Rejected file with unsupported format in type-based import",
                metadata: ["extension": url.pathExtension, "importType": "\(importType)"]
            )
            return .failure(.unsupportedFormat)
        }

        self.isProcessing = true
        defer { self.isProcessing = false }

        let result = await self.performTypeBasedImport(from: url, as: importType)

        // Update pending import state based on result
        switch result {
        case let .success(.guidedMeditation(meditation)):
            self.importedMeditation = meditation
            self.pendingCustomAudioImport = nil
        case let .success(.customAudio(audioFile)):
            self.pendingCustomAudioImport = CustomAudioImportState(file: audioFile)
        case .failure:
            break
        }

        return result
    }

    /// Prepares the handler for importing a file by validating it and showing the type selection sheet
    ///
    /// This method is called when a file open request is received. It validates the format,
    /// sets up the pending import URL, and signals to show the import type selection sheet.
    /// The actual import happens when the user selects a type via `importFile(from:as:)`.
    ///
    /// - Parameter url: URL to the audio file
    func prepareImport(url: URL) {
        guard self.canHandle(url: url) else {
            Logger.guidedMeditation.warning(
                "Rejected file with unsupported format in prepareImport",
                metadata: ["extension": url.pathExtension]
            )
            return
        }

        self.pendingImportURL = url
        self.showImportTypeSelection = true
        self.shouldStopMeditation = true
    }

    /// Cancels a pending import and clears all related state
    ///
    /// Called when the user dismisses the import type selection sheet without selecting a type.
    func cancelPendingImport() {
        self.pendingImportURL = nil
        self.showImportTypeSelection = false
        self.shouldStopMeditation = false
    }

    // MARK: Private

    private let meditationService: GuidedMeditationServiceProtocol
    private let metadataService: AudioMetadataServiceProtocol
    private let customAudioRepository: CustomAudioRepositoryProtocol

    /// Returns the matching meditation if the file is already in the library (legacy: meditation-only)
    ///
    /// Uses both filename and file size to avoid false positives when different files
    /// share the same name (e.g. multiple "meditation.mp3" from different sources).
    private func findDuplicateFromLegacyCheck(url: URL) -> GuidedMeditation? {
        do {
            let existing = try self.meditationService.loadMeditations()
            let fileName = url.lastPathComponent
            let incomingFileSize = self.fileSize(of: url)

            let found = existing.first { meditation in
                guard meditation.fileName == fileName else {
                    return false
                }
                guard let incomingSize = incomingFileSize else {
                    return true
                }
                guard let existingURL = self.meditationService.fileURL(for: meditation) else {
                    return true
                }
                let existingSize = self.fileSize(of: existingURL)
                return existingSize == incomingSize
            }

            if found != nil {
                Logger.guidedMeditation.info("Duplicate file detected", metadata: ["fileName": fileName])
            }
            return found
        } catch {
            Logger.guidedMeditation.error("Failed to load meditations for duplicate check", error: error)
            return nil
        }
    }

    /// Returns the first matching meditation if a duplicate exists, nil otherwise
    private func findDuplicateMeditation(fileName: String, incomingSize: UInt64?) -> GuidedMeditation? {
        do {
            let existing = try self.meditationService.loadMeditations()
            return existing
                .first { self.matchesFile(meditation: $0, fileName: fileName, incomingSize: incomingSize) }
        } catch {
            Logger.guidedMeditation.error("Failed to check for meditation duplicates", error: error)
            return nil
        }
    }

    /// Checks if a meditation matches the given filename and size
    private func matchesFile(meditation: GuidedMeditation, fileName: String, incomingSize: UInt64?) -> Bool {
        guard meditation.fileName == fileName
        else {
            return false
        }
        guard let incomingSize
        else {
            return true
        }
        guard let existingURL = self.meditationService.fileURL(for: meditation)
        else {
            return true
        }
        let existingSize = self.fileSize(of: existingURL)
        return existingSize == incomingSize
    }

    /// Checks if a file is a duplicate custom soundscape
    private func isCustomAudioDuplicate(fileName: String, incomingSize: UInt64?) -> Bool {
        let existing = self.customAudioRepository.loadAll()
        return existing.contains { self.matchesFile(audioFile: $0, fileName: fileName, incomingSize: incomingSize) }
    }

    /// Checks if custom audio file matches the given filename and size
    private func matchesFile(audioFile: CustomAudioFile, fileName: String, incomingSize: UInt64?) -> Bool {
        guard audioFile.filename == fileName
        else {
            return false
        }
        guard let incomingSize
        else {
            return true
        }
        guard let existingURL = self.customAudioRepository.fileURL(for: audioFile)
        else {
            return true
        }
        let existingSize = self.fileSize(of: existingURL)
        return existingSize == incomingSize
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

    /// Performs type-based file import with duplicate detection for the specific type
    private func performTypeBasedImport(
        from url: URL,
        as importType: ImportAudioType
    ) async -> Result<ImportResult, FileOpenError> {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        if let duplicateError = self.checkDuplicate(for: url, importType: importType) {
            return .failure(duplicateError)
        }

        let metadata: AudioMetadata
        do {
            metadata = try await self.metadataService.extractMetadata(from: url)
        } catch {
            Logger.guidedMeditation.error("Failed to extract metadata for type-based import", error: error)
            return .failure(.importFailed)
        }

        switch importType {
        case .guidedMeditation:
            return await self.performGuidedMeditationImport(from: url, metadata: metadata)
        case .soundscape:
            return self.performCustomAudioImport(from: url, metadata: metadata)
        }
    }

    /// Checks for duplicates and returns the appropriate error, or nil if no duplicate found
    private func checkDuplicate(for url: URL, importType: ImportAudioType) -> FileOpenError? {
        let fileName = url.lastPathComponent
        let incomingSize = self.fileSize(of: url)

        switch importType {
        case .guidedMeditation:
            guard let duplicate = self.findDuplicateMeditation(fileName: fileName, incomingSize: incomingSize)
            else { return nil }
            Logger.guidedMeditation.info(
                "Duplicate file detected in type-based import",
                metadata: ["fileName": fileName, "importType": "\(importType)"]
            )
            return .alreadyImported(name: duplicate.effectiveName, teacher: duplicate.effectiveTeacher)
        case .soundscape:
            guard self.isCustomAudioDuplicate(fileName: fileName, incomingSize: incomingSize)
            else { return nil }
            Logger.guidedMeditation.info(
                "Duplicate file detected in type-based import",
                metadata: ["fileName": fileName, "importType": "\(importType)"]
            )
            return .alreadyImported(name: nil, teacher: nil)
        }
    }

    /// Performs guided meditation import for type-based flow
    private func performGuidedMeditationImport(
        from url: URL,
        metadata: AudioMetadata
    ) async -> Result<ImportResult, FileOpenError> {
        do {
            let meditation = try self.meditationService.addMeditation(from: url, metadata: metadata)
            Logger.guidedMeditation.info(
                "Successfully imported meditation via type-based import",
                metadata: ["id": meditation.id.uuidString, "fileName": url.lastPathComponent]
            )
            return .success(.guidedMeditation(meditation))
        } catch {
            Logger.guidedMeditation.error("Failed to import meditation via type-based import", error: error)
            return .failure(.importFailed)
        }
    }

    /// Performs custom soundscape import for type-based flow
    private func performCustomAudioImport(
        from url: URL,
        metadata: AudioMetadata
    ) -> Result<ImportResult, FileOpenError> {
        do {
            let audioFile = try self.customAudioRepository.importFile(from: url)
            Logger.guidedMeditation.info(
                "Successfully imported custom soundscape via type-based import",
                metadata: [
                    "id": audioFile.id.uuidString,
                    "fileName": audioFile.filename
                ]
            )
            return .success(.customAudio(audioFile))
        } catch {
            Logger.guidedMeditation.error("Failed to import custom soundscape", error: error)
            return .failure(.importFailed)
        }
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
