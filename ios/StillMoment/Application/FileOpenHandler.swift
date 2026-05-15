//
//  FileOpenHandler.swift
//  Still Moment
//
//  Application Layer - Handles share / "Open with" imports of audio files.
//

import Foundation
import OSLog

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

/// Signal-Wert: ein ausstehender Import liegt bereit, das Edit-Sheet kann oeffnen.
///
/// FileOpenHandler persistiert selbst nichts mehr — er publiziert nur den
/// extrahierten Zustand, das ViewModel uebernimmt Prefill, Edit-Sheet und Save.
struct IncomingFileImport: Equatable {
    let url: URL
    let metadata: AudioMetadata
    let didStartAccessing: Bool
}

/// Handles importing audio files received via share / "Open with".
///
/// Audio files shared with the app (Share Extension, file association, or
/// direct "open in") are always imported as a guided meditation. Soundscapes
/// are imported through the Settings flow (separate code path).
///
/// Flow (ios-043):
/// 1. Validate the file format (MP3 / M4A).
/// 2. Signal a running meditation to stop (so the Edit-Sheet can open cleanly).
/// 3. Detect duplicates by filename + size.
/// 4. Extract metadata.
/// 5. Publish `pendingImportSignal` — the Library reacts by opening the Edit-Sheet
///    with a prefilled draft. Persistence happens only after Save in the sheet.
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

    /// Signal fuer einen ausstehenden Import — wird von der Library beobachtet,
    /// um das Edit-Sheet mit einem Prefill-Draft zu oeffnen. Nach dem Konsum
    /// vom Beobachter auf `nil` zurueckzusetzen.
    @Published var pendingImportSignal: IncomingFileImport?

    /// Signals that a running timer/player should be stopped because an import
    /// is about to take over the foreground (Edit-Sheet).
    @Published var shouldStopMeditation = false

    /// Supported audio file extensions for import
    static let supportedExtensions: Set<String> = ["mp3", "m4a"]

    /// Checks whether the given URL points to a supported audio file
    func canHandle(url: URL) -> Bool {
        Self.supportedExtensions.contains(url.pathExtension.lowercased())
    }

    /// Validates that a file can be imported (format check only).
    ///
    /// Used by the InboxHandler as a defense-in-depth check before handing
    /// a downloaded file over for import. Does not check for duplicates.
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

    /// Validates the shared audio file and publishes a pending-import signal.
    ///
    /// Validates the file, signals any running session to stop, checks for duplicates,
    /// extracts metadata, and publishes `pendingImportSignal`. The Library list view
    /// observes the signal, opens the Edit-Sheet with a prefilled draft, and persists
    /// only after the user taps Save.
    ///
    /// The Security-Scoped Resource stays open across the Edit-Sheet lifecycle —
    /// the ViewModel takes ownership via `didStartAccessing` and releases it on
    /// Save or Cancel.
    func importFile(from url: URL) async -> Result<IncomingFileImport, FileOpenError> {
        guard self.canHandle(url: url) else {
            Logger.guidedMeditation.warning(
                "Rejected file with unsupported format",
                metadata: ["extension": url.pathExtension]
            )
            return .failure(.unsupportedFormat)
        }

        self.shouldStopMeditation = true
        self.isProcessing = true
        defer { self.isProcessing = false }

        let didStartAccessing = url.startAccessingSecurityScopedResource()

        if let duplicate = self.findDuplicateMeditation(for: url) {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
            return .failure(.alreadyImported(
                name: duplicate.effectiveName,
                teacher: duplicate.effectiveTeacher
            ))
        }

        do {
            let metadata = try await self.metadataService.extractMetadata(from: url)
            let signal = IncomingFileImport(
                url: url,
                metadata: metadata,
                didStartAccessing: didStartAccessing
            )
            Logger.guidedMeditation.info(
                "Pending import published",
                metadata: ["fileName": url.lastPathComponent]
            )
            self.pendingImportSignal = signal
            return .success(signal)
        } catch {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
            Logger.guidedMeditation.error("Failed to extract metadata for import", error: error)
            return .failure(.importFailed)
        }
    }

    // MARK: Private

    private let meditationService: GuidedMeditationServiceProtocol
    private let metadataService: AudioMetadataServiceProtocol

    /// Returns the first meditation in the library that matches the given URL
    /// by filename and (when both files are resolvable) size.
    private func findDuplicateMeditation(for url: URL) -> GuidedMeditation? {
        do {
            let existing = try self.meditationService.loadMeditations()
            let fileName = url.lastPathComponent
            let incomingSize = self.fileSize(of: url)

            let found = existing.first { meditation in
                self.matchesFile(meditation: meditation, fileName: fileName, incomingSize: incomingSize)
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

    private func matchesFile(meditation: GuidedMeditation, fileName: String, incomingSize: UInt64?) -> Bool {
        guard meditation.fileName == fileName
        else { return false }
        guard let incomingSize
        else { return true }
        guard let existingURL = self.meditationService.fileURL(for: meditation)
        else { return true }
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
}
