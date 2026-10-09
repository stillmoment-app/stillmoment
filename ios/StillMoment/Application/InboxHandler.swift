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
    /// An audio file was successfully imported as a meditation
    case audioFile(URL)
    /// An audio file was recognized but the import itself failed
    /// (duplicate, metadata failure, persistence failure)
    case audioImportFailed(FileOpenError)
    /// A download was started for a URL reference
    case downloadStarted
    /// A download completed and the resulting file was imported successfully
    case downloadCompleted(URL)
    /// An error occurred during processing
    case error(InboxError)
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
        episodeResolver: PodcastEpisodeResolverProtocol,
        fileManager: FileManager = .default,
        inboxDirectoryURL: URL
    ) {
        self.fileOpenHandler = fileOpenHandler
        self.downloadService = downloadService
        self.episodeResolver = episodeResolver
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
        guard !self.isProcessing else {
            Logger.infrastructure.info("processInbox() — already in progress, skipping")
            return .empty
        }
        self.isProcessing = true
        defer { self.isProcessing = false }

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
            self.downloadError = .containerNotAvailable
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

        // Audio files are imported synchronously by processAudioFile — the
        // copy lives in the library, so we can delete the inbox entry here.
        // JSON references describe a download; the downloaded file is stored
        // elsewhere, so deleting the JSON reference is safe too.
        self.deleteFiles([newestFile])

        return result
    }

    /// Processes the last shared link again after a retryable error ("Retry" in the alert).
    ///
    /// The inbox entry is already cleaned up after the first attempt, so the link is
    /// remembered here. Returns `.empty` if there is nothing to retry.
    func retry() async -> InboxResult {
        guard !self.isProcessing, let link = self.retryableSharedLink else {
            return .empty
        }
        self.isProcessing = true
        defer { self.isProcessing = false }
        return await self.processSharedLink(link)
    }

    /// Cancels the running episode lookup and download (loading window "Cancel").
    /// No message and no entry result from a cancelled share.
    func cancelDownload() {
        self.cancelRequested = true
        self.episodeResolver.cancel()
        self.downloadService.cancelDownload()
    }

    // MARK: Private

    /// A link shared via the Share Extension
    private struct SharedLink {
        let url: URL
        let filename: String
    }

    /// What differs between link import and podcast import once the audio address is known
    private struct DownloadPlan {
        let url: URL
        let filename: String
        let mapError: (AudioDownloadError) -> InboxError?
        let rejectedFileError: InboxError
        var preferredTitle: String?
        var preferredArtist: String?
    }

    private var isProcessing = false
    private var cancelRequested = false
    private var retryableSharedLink: SharedLink?

    private static let supportedAudioExtensions: Set<String> = ["mp3", "m4a"]
    private static let supportedExtensions: Set<String> = ["mp3", "m4a", "json"]
    private static let staleThreshold: TimeInterval = 24 * 3600
    private static let downloadFolderPrefix = "dl_"

    private let fileOpenHandler: FileOpenHandler
    private let downloadService: AudioDownloadServiceProtocol
    private let episodeResolver: PodcastEpisodeResolverProtocol
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
            return await self.processAudioFile(at: url)
        } else if ext == "json" {
            return await self.processURLReference(at: url)
        }

        return .empty
    }

    /// Validates a freshly downloaded file and imports it as a meditation.
    ///
    /// Defense-in-Depth: Der AudioDownloadService akzeptiert ggf. neue
    /// Content-Types, die FileOpenHandler.canHandle (noch) nicht kennt.
    /// Ohne diesen Check waere die Ablehnung fuer den User unsichtbar.
    private func importDownloadedFile(at url: URL, plan: DownloadPlan) async -> InboxResult {
        guard case .success = self.fileOpenHandler.validateFileForImport(url: url) else {
            Logger.infrastructure.error("Downloaded file rejected by importer: \(url.lastPathComponent)")
            self.discardDownload(at: url)
            return self.fail(plan.rejectedFileError)
        }
        let result = await self.fileOpenHandler.importFile(
            from: url,
            preferredTitle: plan.preferredTitle,
            preferredArtist: plan.preferredArtist
        )
        switch result {
        case .success:
            return .downloadCompleted(url)
        case let .failure(error):
            self.discardDownload(at: url)
            return .audioImportFailed(error)
        }
    }

    /// Removes a download that will not be imported, including its per-download folder
    /// `tmp/dl_<UUID>/` (created by AudioDownloadService). Other folders are never removed.
    private func discardDownload(at url: URL) {
        let folder = url.deletingLastPathComponent()
        let target = folder.lastPathComponent.hasPrefix(Self.downloadFolderPrefix) ? folder : url
        try? self.fileManager.removeItem(at: target)
    }

    /// Processes an audio file entry — imports directly as a meditation.
    ///
    /// Surfaces import errors (duplicate, metadata failure, persistence failure)
    /// via `.audioImportFailed` so the caller can present an alert. Without this,
    /// "bereits importiert"-Hinweise verschwinden im Share-Extension-Pfad.
    private func processAudioFile(at url: URL) async -> InboxResult {
        Logger.infrastructure.info("Processing audio inbox entry: \(url.lastPathComponent)")
        switch await self.fileOpenHandler.importFile(from: url) {
        case .success:
            return .audioFile(url)
        case let .failure(error):
            return .audioImportFailed(error)
        }
    }

    /// Processes a URL reference (JSON) entry
    private func processURLReference(at url: URL) async -> InboxResult {
        guard let data = try? Data(contentsOf: url),
              let urlRef = try? JSONDecoder().decode(URLReference.self, from: data),
              let sharedURL = URL(string: urlRef.url)
        else {
            Logger.infrastructure.error("Failed to parse URL reference: \(url.lastPathComponent)")
            return self.fail(.downloadFailed)
        }
        return await self.processSharedLink(SharedLink(url: sharedURL, filename: urlRef.filename))
    }

    /// Processes a shared link: an Apple Podcasts episode is resolved to its audio file first
    /// (shared-128), every other link is downloaded directly (link import).
    /// Remembers the link when the error can be retried.
    private func processSharedLink(_ link: SharedLink) async -> InboxResult {
        self.cancelRequested = false
        self.retryableSharedLink = nil

        let result: InboxResult
        switch ApplePodcastsLink.parse(link.url) {
        case .podcast:
            // Decided without network — no loading window.
            Logger.infrastructure.info("Shared link is a whole podcast, not a single episode")
            result = self.fail(.podcastWithoutEpisode)
        case let .episode(country, podcastId, episodeId):
            result = await self.processPodcastEpisode(country: country, podcastId: podcastId, episodeId: episodeId)
        case nil:
            result = await self.downloadAndImport(DownloadPlan(
                url: link.url,
                filename: link.filename,
                mapError: InboxError.forLinkImport,
                rejectedFileError: .notAnAudioUrl
            ))
        }

        if case let .error(error) = result, error.isRetryable {
            self.retryableSharedLink = link
        }
        return result
    }

    /// Looks up the episode in the podcast directory, then loads its audio file directly
    /// from the podcast's provider. Title and teacher suggestions win over the file's tags.
    private func processPodcastEpisode(country: String?, podcastId: Int64, episodeId: Int64) async -> InboxResult {
        self.isDownloading = true
        defer { self.isDownloading = false }

        let episode: PodcastEpisode
        do {
            episode = try await self.episodeResolver.resolveEpisode(
                country: country,
                podcastId: podcastId,
                episodeId: episodeId
            )
        } catch {
            let resolveError = (error as? PodcastEpisodeResolveError)
                ?? (error is CancellationError ? .cancelled : .unavailable)
            Logger.infrastructure.info("Podcast episode not resolved: \(String(describing: resolveError))")
            return self.failUnlessCancelled(InboxError.forPodcastImport(resolveError))
        }

        guard !self.cancelRequested else {
            Logger.infrastructure.info("Podcast import cancelled after lookup")
            return .empty
        }

        return await self.downloadAndImport(DownloadPlan(
            url: episode.audioURL,
            filename: episode.audioURL.lastPathComponent,
            mapError: InboxError.forPodcastImport,
            rejectedFileError: .episodeUnavailable,
            preferredTitle: episode.title,
            preferredArtist: episode.teacherSuggestion
        ))
    }

    /// Downloads the audio file (loading window visible) and hands it to the importer.
    private func downloadAndImport(_ plan: DownloadPlan) async -> InboxResult {
        self.isDownloading = true
        defer { self.isDownloading = false }

        let downloadedURL: URL
        do {
            downloadedURL = try await self.downloadService.download(from: plan.url, filename: plan.filename)
        } catch is CancellationError {
            Logger.infrastructure.info("Download cancelled for \(plan.url.absoluteString)")
            return .empty
        } catch {
            let downloadError = (error as? AudioDownloadError) ?? .downloadFailed
            Logger.infrastructure.info("Download ended without file: \(String(describing: downloadError))")
            return self.failUnlessCancelled(plan.mapError(downloadError))
        }

        guard !self.cancelRequested else {
            Logger.infrastructure.info("Import cancelled after download")
            self.discardDownload(at: downloadedURL)
            return .empty
        }

        Logger.infrastructure.info("Download completed: \(downloadedURL.lastPathComponent)")
        return await self.importDownloadedFile(at: downloadedURL, plan: plan)
    }

    /// Publishes the error for the alert and returns it as result.
    /// After the user cancelled, no message appears anymore — every error becomes `.empty`.
    private func fail(_ error: InboxError) -> InboxResult {
        guard !self.cancelRequested else {
            Logger.infrastructure.info("Error after cancel suppressed: \(String(describing: error))")
            return .empty
        }
        self.downloadError = error
        return .error(error)
    }

    /// `nil` means the user cancelled — no message, no entry.
    private func failUnlessCancelled(_ error: InboxError?) -> InboxResult {
        guard let error else {
            return .empty
        }
        return self.fail(error)
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
