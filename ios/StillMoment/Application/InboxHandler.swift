//
//  InboxHandler.swift
//  Still Moment
//
//  Application Layer - Processes Share Extension inbox entries
//

import Foundation
import OSLog

// MARK: - InboxResult

/// Result of processing the Share Extension inbox
enum InboxResult: Equatable {
    /// Inbox was empty or only contained stale/unrecognized entries
    case empty
    /// An audio file was found and handed off for import
    case audioFile(URL)
    /// A download was started for a URL reference
    case downloadStarted
    /// A download completed successfully
    case downloadCompleted(URL)
    /// An error occurred during processing
    case error(InboxError)
}

// MARK: - InboxError

/// Errors that can occur during inbox processing
enum InboxError: Error, Equatable, LocalizedError {
    /// The download of a shared URL failed
    case downloadFailed
    /// The app group container is not available
    case containerNotAvailable

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            NSLocalizedString(
                "inbox_error_download_failed",
                value: "The download failed. Please try again.",
                comment: "Error when downloading a shared audio file fails"
            )
        case .containerNotAvailable:
            NSLocalizedString(
                "inbox_error_container_not_available",
                value: "Unable to access shared data.",
                comment: "Error when the app group container is not available"
            )
        }
    }
}

// MARK: - URLReference

/// JSON format written by the Share Extension for shared URLs
struct URLReference: Codable {
    let url: String
    let filename: String
    let timestamp: String
}

// MARK: - InboxHandler

/// Processes entries placed in the Share Extension inbox directory
///
/// The Share Extension writes audio files or URL references (JSON) into a shared
/// inbox directory. This handler picks up those entries, processes the newest one,
/// and cleans up the rest.
///
/// Flow:
/// 1. Check inbox directory exists
/// 2. Remove stale entries (>24h old)
/// 3. Filter to supported types (.mp3, .m4a, .json)
/// 4. Remove unrecognized files
/// 5. Process the newest entry (audio file or URL reference)
/// 6. Clean up all entries
@MainActor
final class InboxHandler: ObservableObject {
    // MARK: Lifecycle

    init(
        fileOpenHandler: FileOpenHandler,
        downloadService: AudioDownloadServiceProtocol,
        fileManager: FileManager = .default,
        inboxDirectoryURL: URL
    ) {
        self.fileOpenHandler = fileOpenHandler
        self.downloadService = downloadService
        self.fileManager = fileManager
        self.inboxDirectoryURL = inboxDirectoryURL
    }

    // MARK: Internal

    /// Whether a download is currently in progress
    @Published var isDownloading = false

    /// The most recent download error, if any
    @Published var downloadError: InboxError?

    /// Processes all entries in the inbox directory
    ///
    /// - Returns: The result of processing the inbox
    func processInbox() async -> InboxResult {
        guard self.fileManager.fileExists(atPath: self.inboxDirectoryURL.path) else {
            // Directory doesn't exist yet — no one has shared anything. That's normal.
            return .empty
        }

        guard let allFiles = try? self.fileManager.contentsOfDirectory(
            at: self.inboxDirectoryURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            Logger.infrastructure.error("Failed to list inbox directory contents")
            return .error(.containerNotAvailable)
        }

        // Remove stale entries (older than 24 hours)
        let freshFiles = self.removeStaleEntries(from: allFiles)

        // Filter to supported types and clean up unrecognized files
        let supportedFiles = self.filterSupportedFiles(from: freshFiles)

        guard let newestFile = self.newestFile(from: supportedFiles) else {
            return .empty
        }

        // Delete all entries except the newest
        let otherFiles = supportedFiles.filter { $0 != newestFile }
        self.deleteFiles(otherFiles)

        // Process the newest entry
        let result = await self.processEntry(at: newestFile)

        // JSON references can be deleted immediately — the downloaded file lives elsewhere.
        // Audio files must NOT be deleted here: prepareImport() only stores the URL for
        // deferred import. The file is needed when the user selects an import type.
        // Cleanup happens via the main app after import completes or is cancelled.
        if newestFile.pathExtension.lowercased() == "json" {
            self.deleteFiles([newestFile])
        }

        return result
    }

    /// Cancels any in-progress download
    func cancelDownload() {
        self.downloadService.cancelDownload()
    }

    // MARK: Private

    private static let supportedAudioExtensions: Set<String> = ["mp3", "m4a"]
    private static let supportedExtensions: Set<String> = ["mp3", "m4a", "json"]
    private static let staleThreshold: TimeInterval = 24 * 3600

    private let fileOpenHandler: FileOpenHandler
    private let downloadService: AudioDownloadServiceProtocol
    private let fileManager: FileManager
    private let inboxDirectoryURL: URL

    /// Removes entries older than 24 hours and returns the remaining files
    private func removeStaleEntries(from files: [URL]) -> [URL] {
        let cutoff = Date().addingTimeInterval(-Self.staleThreshold)
        var freshFiles: [URL] = []

        for file in files {
            if let modDate = self.modificationDate(of: file), modDate < cutoff {
                Logger.infrastructure.info("Removing stale inbox entry: \(file.lastPathComponent)")
                try? self.fileManager.removeItem(at: file)
            } else {
                freshFiles.append(file)
            }
        }

        return freshFiles
    }

    /// Filters files to supported types and deletes unrecognized files
    private func filterSupportedFiles(from files: [URL]) -> [URL] {
        var supported: [URL] = []

        for file in files {
            let ext = file.pathExtension.lowercased()
            if Self.supportedExtensions.contains(ext) {
                supported.append(file)
            } else {
                Logger.infrastructure.info("Removing unrecognized inbox file: \(file.lastPathComponent)")
                try? self.fileManager.removeItem(at: file)
            }
        }

        return supported
    }

    /// Returns the newest file by modification date
    private func newestFile(from files: [URL]) -> URL? {
        files.max { lhs, rhs in
            let lhsDate = self.modificationDate(of: lhs) ?? .distantPast
            let rhsDate = self.modificationDate(of: rhs) ?? .distantPast
            return lhsDate < rhsDate
        }
    }

    /// Processes a single inbox entry
    private func processEntry(at url: URL) async -> InboxResult {
        let ext = url.pathExtension.lowercased()

        if Self.supportedAudioExtensions.contains(ext) {
            return self.processAudioFile(at: url)
        } else if ext == "json" {
            return await self.processURLReference(at: url)
        }

        return .empty
    }

    /// Processes an audio file entry
    private func processAudioFile(at url: URL) -> InboxResult {
        Logger.infrastructure.info("Processing audio inbox entry: \(url.lastPathComponent)")
        self.fileOpenHandler.prepareImport(url: url)
        return .audioFile(url)
    }

    /// Processes a URL reference (JSON) entry
    private func processURLReference(at url: URL) async -> InboxResult {
        guard let data = try? Data(contentsOf: url),
              let urlRef = try? JSONDecoder().decode(URLReference.self, from: data),
              let downloadURL = URL(string: urlRef.url)
        else {
            Logger.infrastructure.error("Failed to parse URL reference: \(url.lastPathComponent)")
            return .error(.downloadFailed)
        }

        self.isDownloading = true
        defer { self.isDownloading = false }

        do {
            let downloadedURL = try await self.downloadService.download(
                from: downloadURL,
                filename: urlRef.filename
            )
            Logger.infrastructure.info("Download completed: \(urlRef.filename)")
            self.fileOpenHandler.prepareImport(url: downloadedURL)
            return .downloadCompleted(downloadedURL)
        } catch is CancellationError {
            Logger.infrastructure.info("Download cancelled for \(urlRef.url)")
            return .empty
        } catch let error as AudioDownloadError where error == .downloadCancelled {
            Logger.infrastructure.info("Download cancelled for \(urlRef.url)")
            return .empty
        } catch {
            Logger.infrastructure.error("Download failed for \(urlRef.url)")
            self.downloadError = .downloadFailed
            return .error(.downloadFailed)
        }
    }

    /// Returns the modification date of a file
    private func modificationDate(of url: URL) -> Date? {
        guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]) else {
            return nil
        }
        return values.contentModificationDate
    }

    /// Deletes a list of files
    private func deleteFiles(_ files: [URL]) {
        for file in files {
            try? self.fileManager.removeItem(at: file)
        }
    }
}
