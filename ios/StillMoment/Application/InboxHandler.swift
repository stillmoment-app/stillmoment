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
/// 4. Remove unrecognized files and all entries except the newest
/// 5. Take the newest entry over: move it out of the inbox into `tmp/share_<UUID>/` (shared-138)
/// 6. Process it (audio file or URL reference)
///
/// Taking the entry over before processing keeps the inbox for waiting entries only: an entry
/// shared meanwhile under the same name (`download.json` for two audiodharma talks) is never
/// mistaken for the one in progress. A shared audio file stays in `tmp` until "Save" in the
/// editor copies it into the library.
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

        return await self.processEntry(at: newestFile)
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
    /// Folders this handler may remove with their file: downloads (`dl_`) and taken-over entries
    private static let ownedFolderPrefixes = ["dl_", takenEntryFolderPrefix]
    private static let takenEntryFolderPrefix = "share_"

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

    /// Takes the inbox entry over and processes it
    private func processEntry(at inboxEntry: URL) async -> InboxResult {
        let isAudioFile = Self.supportedAudioExtensions.contains(inboxEntry.pathExtension.lowercased())
        guard let entry = self.takeOver(inboxEntry) else {
            return isAudioFile ? .audioImportFailed(.importFailed) : self.fail(.downloadFailed)
        }
        return isAudioFile ? await self.processAudioFile(at: entry) : await self.processURLReference(at: entry)
    }

    /// Moves the entry out of the inbox into a folder of its own, `tmp/share_<UUID>/<name>`.
    ///
    /// On the same volume (app group container and app `tmp` both live on the data volume)
    /// the move is a rename and atomic: either the entry is taken over, or it is still waiting.
    /// An entry that cannot be moved is removed, so it is not retried forever.
    private func takeOver(_ inboxEntry: URL) -> URL? {
        let folder = self.fileManager.temporaryDirectory
            .appendingPathComponent("\(Self.takenEntryFolderPrefix)\(UUID().uuidString)")
        let entry = folder.appendingPathComponent(inboxEntry.lastPathComponent)
        do {
            try self.fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            try self.fileManager.moveItem(at: inboxEntry, to: entry)
            return entry
        } catch {
            Logger.infrastructure.error(
                "Failed to take over inbox entry \(inboxEntry.lastPathComponent): \(error.localizedDescription)"
            )
            try? self.fileManager.removeItem(at: folder)
            try? self.fileManager.removeItem(at: inboxEntry)
            return nil
        }
    }

    /// Validates a freshly downloaded file and imports it as a meditation.
    ///
    /// Defense-in-Depth: Der AudioDownloadService akzeptiert ggf. neue
    /// Content-Types, die FileOpenHandler.canHandle (noch) nicht kennt.
    /// Ohne diesen Check waere die Ablehnung fuer den User unsichtbar.
    private func importDownloadedFile(at url: URL, plan: DownloadPlan) async -> InboxResult {
        guard case .success = self.fileOpenHandler.validateFileForImport(url: url) else {
            Logger.infrastructure.error("Downloaded file rejected by importer: \(url.lastPathComponent)")
            self.discardFile(at: url)
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
            self.discardFile(at: url)
            return .audioImportFailed(error)
        }
    }

    /// Removes a file that will not be imported, including its own folder: `tmp/dl_<UUID>/`
    /// (created by AudioDownloadService) or `tmp/share_<UUID>/` (taken-over inbox entry).
    /// Other folders are never removed.
    private func discardFile(at url: URL) {
        let folder = url.deletingLastPathComponent()
        let ownsFolder = Self.ownedFolderPrefixes.contains { folder.lastPathComponent.hasPrefix($0) }
        try? self.fileManager.removeItem(at: ownsFolder ? folder : url)
    }

    /// Processes a taken-over audio file entry: opens the editor with it (pending import).
    ///
    /// The file stays where it is until "Save" in the editor copies it into the library.
    /// Surfaces import errors (duplicate, metadata failure) via `.audioImportFailed` so the
    /// caller can present an alert. Without this, "bereits importiert"-Hinweise verschwinden
    /// im Share-Extension-Pfad.
    private func processAudioFile(at url: URL) async -> InboxResult {
        Logger.infrastructure.info("Processing audio inbox entry: \(url.lastPathComponent)")
        switch await self.fileOpenHandler.importFile(from: url) {
        case .success:
            return .audioFile(url)
        case let .failure(error):
            self.discardFile(at: url)
            return .audioImportFailed(error)
        }
    }

    /// Processes a taken-over URL reference (JSON) entry. The reference is removed once read.
    private func processURLReference(at url: URL) async -> InboxResult {
        let link = self.readSharedLink(at: url)
        self.discardFile(at: url)
        guard let link else {
            Logger.infrastructure.error("Failed to parse URL reference: \(url.lastPathComponent)")
            return self.fail(.downloadFailed)
        }
        return await self.processSharedLink(link)
    }

    private func readSharedLink(at url: URL) -> SharedLink? {
        guard let data = try? Data(contentsOf: url),
              let urlRef = try? JSONDecoder().decode(URLReference.self, from: data),
              let sharedURL = URL(string: urlRef.url)
        else {
            return nil
        }
        return SharedLink(url: sharedURL, filename: urlRef.filename)
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
            self.discardFile(at: downloadedURL)
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
