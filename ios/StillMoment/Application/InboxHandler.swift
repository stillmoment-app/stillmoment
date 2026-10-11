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
    /// Nothing was started: the inbox was empty, the entry waits, or the import was cancelled
    case empty
    /// A shared audio file was handed to the editor (pending import, persisted on "Save")
    case audioFile(URL)
    /// An audio file was recognized but cannot be imported (duplicate, unreadable);
    /// the message is published via `importError`
    case audioImportFailed(FileOpenError)
    /// A download was started for a URL reference
    case downloadStarted
    /// A download completed and the resulting file was handed to the editor
    case downloadCompleted(URL)
    /// An error occurred during processing; the message is published via `downloadError`
    case error(InboxError)
}

// MARK: - InboxHandler

/// Processes entries placed in the Share Extension inbox directory
///
/// The Share Extension writes audio files or URL references (JSON) into a shared
/// inbox directory; "Open in" puts audio files there too. This handler takes the newest
/// entry over, processes it, and removes the older ones ("the last shared wins", shared-132).
///
/// **What the app has begun, it finishes (shared-138).** While an import is open — it loads,
/// its editor is shown, or its message stands (`hasOpenImport`) — entries shared meanwhile
/// wait in the inbox. When the import ends, the app calls back (`processInbox()` after the
/// editor closed, `closeMessage()`, or "Cancel" in the loading window) and the newest waiting
/// entry starts by itself. The entry in progress is moved out of the inbox when it starts,
/// so the inbox holds waiting entries only (see `InboxDirectory`).
@MainActor
final class InboxHandler: ObservableObject {
    // MARK: Lifecycle

    /// - Parameter isEditorOpen: Whether the library shows an editor — for a share, a file
    ///   from the document picker, or a meditation already in the library. Every editor counts.
    init(
        fileOpenHandler: FileOpenHandler,
        downloadService: AudioDownloadServiceProtocol,
        episodeResolver: PodcastEpisodeResolverProtocol,
        fileManager: FileManager = .default,
        inboxDirectoryURL: URL,
        isEditorOpen: @escaping @MainActor () -> Bool
    ) {
        self.fileOpenHandler = fileOpenHandler
        self.downloadService = downloadService
        self.episodeResolver = episodeResolver
        self.fileManager = fileManager
        self.inbox = InboxDirectory(url: inboxDirectoryURL, fileManager: fileManager)
        self.isEditorOpen = isEditorOpen
    }

    // MARK: Internal

    /// Whether a download is currently in progress
    @Published var isDownloading = false

    /// Message for a shared link that could not be imported, if any (download alert)
    @Published var downloadError: InboxError?

    /// Message for a shared or opened audio file that is not imported, if any
    /// ("already there", unreadable, unsupported format)
    @Published var importError: FileOpenError?

    /// Takes the newest waiting entry over and processes it.
    ///
    /// While an import is open, nothing starts: the entry keeps waiting, and only entries
    /// that repeat the running one are dropped (no second import, no late "already there").
    func processInbox() async -> InboxResult {
        guard !self.hasOpenImport else {
            Logger.infrastructure.info("processInbox() — an import is still open, shared entries wait")
            self.discardRepeatsOfRunningEntry()
            return .empty
        }
        self.runningEntry = nil
        self.isProcessing = true
        defer { self.isProcessing = false }
        return await self.processWaitingEntries()
    }

    /// Processes the running shared link again after a retryable error ("Retry" in the alert).
    ///
    /// The import continues; a waiting entry keeps waiting. Without a link to load again
    /// (the entry itself was unreadable), "Retry" ends the import like closing the message.
    func retry() async -> InboxResult {
        guard let link = self.retryableSharedLink else {
            return await self.closeMessage()
        }
        guard !self.isProcessing else {
            return .empty
        }
        self.downloadError = nil
        self.isProcessing = true
        defer { self.isProcessing = false }
        self.cancelRequested = false
        let result = await self.processSharedLink(link)
        return await self.continueAfterSilentEnd(result)
    }

    /// The message of the running import was closed (not "Retry"): the import is finished,
    /// the waiting entry starts.
    func closeMessage() async -> InboxResult {
        self.downloadError = nil
        self.importError = nil
        self.retryableSharedLink = nil
        return await self.processInbox()
    }

    /// Cancels the running episode lookup and download (loading window "Cancel").
    /// No message and no entry result from a cancelled share; the waiting entry starts.
    func cancelDownload() {
        self.cancelRequested = true
        self.episodeResolver.cancel()
        self.downloadService.cancelDownload()
    }

    /// Accepts an audio file opened with the app ("Open in"). It is put into the inbox like a
    /// shared one, so the same rules apply; `processInbox()` starts it. An unsupported format
    /// is reported right away and never waits.
    func acceptOpenedFile(_ url: URL) {
        guard self.fileOpenHandler.canHandle(url: url) else {
            Logger.infrastructure.info("Opened file has an unsupported format: \(url.lastPathComponent)")
            self.reportUnlessMessageStands(.unsupportedFormat)
            return
        }
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try self.inbox.storeOpenedFile(url)
        } catch {
            Logger.infrastructure.error("Failed to accept opened file: \(error.localizedDescription)")
            self.reportUnlessMessageStands(.importFailed)
        }
    }

    // MARK: Private

    /// A link shared via the Share Extension
    private struct SharedLink {
        let url: URL
        let filename: String
    }

    /// What makes two shared entries the same: a link by its address, an audio file by
    /// name and size (like the "already there" check).
    private enum EntryIdentity: Equatable {
        case link(URL)
        case audioFile(name: String, size: UInt64?)
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

    private static let supportedAudioExtensions: Set<String> = ["mp3", "m4a"]
    /// Folders this handler may remove with their file: downloads and taken-over entries
    private static let ownedFolderPrefixes = ["dl_", InboxDirectory.takenEntryFolderPrefix]

    /// An entry is being taken over, looked up, downloaded or read
    private var isProcessing = false
    private var cancelRequested = false
    private var retryableSharedLink: SharedLink?
    /// The entry of the import that is open — repeats of it are dropped while it is
    private var runningEntry: EntryIdentity?

    private let fileOpenHandler: FileOpenHandler
    private let downloadService: AudioDownloadServiceProtocol
    private let episodeResolver: PodcastEpisodeResolverProtocol
    private let fileManager: FileManager
    private let inbox: InboxDirectory
    private let isEditorOpen: @MainActor () -> Bool

    /// Whether an import the app has begun is still open: it loads, its editor is about to
    /// open or shown, or its message stands. Derived from the actual state, nothing to reset.
    private var hasOpenImport: Bool {
        self.isProcessing
            || self.downloadError != nil
            || self.importError != nil
            || self.fileOpenHandler.pendingImportSignal != nil
            || self.isEditorOpen()
    }

    /// Takes over and processes the newest waiting entry; an import that ends silently
    /// hands over to the next one.
    private func processWaitingEntries() async -> InboxResult {
        while true {
            let next: URL?
            do {
                next = try self.inbox.newestEntryRemovingOthers()
            } catch {
                Logger.infrastructure.error("Failed to list inbox directory contents")
                self.downloadError = .containerNotAvailable
                return .error(.containerNotAvailable)
            }
            guard let next else {
                self.runningEntry = nil
                return .empty
            }
            let result = await self.processEntry(at: next)
            guard result == .empty else {
                return result
            }
        }
    }

    /// "Cancel" in the loading window ends an import silently (`.empty`). The waiting entry
    /// starts right away — the app cannot tell a cancelled import from an empty inbox.
    private func continueAfterSilentEnd(_ result: InboxResult) async -> InboxResult {
        guard result == .empty else {
            return result
        }
        return await self.processWaitingEntries()
    }

    /// Drops waiting entries that repeat the running one; other waiting entries stay.
    private func discardRepeatsOfRunningEntry() {
        guard let runningEntry, let entries = try? self.inbox.waitingEntries() else {
            return
        }
        let repeats = entries.filter { self.identity(of: $0) == runningEntry }
        for entry in repeats {
            Logger.infrastructure.info("Dropping repeat of the running import: \(entry.lastPathComponent)")
        }
        self.inbox.remove(repeats)
    }

    private func identity(of entry: URL) -> EntryIdentity? {
        if Self.supportedAudioExtensions.contains(entry.pathExtension.lowercased()) {
            let size = (try? self.fileManager.attributesOfItem(atPath: entry.path))?[.size] as? UInt64
            return .audioFile(name: entry.lastPathComponent, size: size)
        }
        return self.readSharedLink(at: entry).map { .link($0.url) }
    }

    /// "Open in" outside the rule: a message that already stands stays, the new one is only logged.
    private func reportUnlessMessageStands(_ error: FileOpenError) {
        guard self.downloadError == nil, self.importError == nil else {
            Logger.infrastructure.info("Message already shown, not replaced: \(String(describing: error))")
            return
        }
        self.importError = error
    }

    /// Takes the inbox entry over and processes it
    private func processEntry(at inboxEntry: URL) async -> InboxResult {
        self.cancelRequested = false
        self.retryableSharedLink = nil
        let isAudioFile = Self.supportedAudioExtensions.contains(inboxEntry.pathExtension.lowercased())
        guard let entry = self.inbox.takeOver(inboxEntry) else {
            return isAudioFile ? self.failImport(.importFailed) : self.fail(.downloadFailed)
        }
        self.runningEntry = self.identity(of: entry)
        return isAudioFile ? await self.processAudioFile(at: entry) : await self.processURLReference(at: entry)
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
            return self.failImport(error)
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
    /// Import errors (duplicate, metadata failure) become a message — without it,
    /// "bereits importiert"-Hinweise verschwinden im Share-Extension-Pfad.
    private func processAudioFile(at url: URL) async -> InboxResult {
        Logger.infrastructure.info("Processing audio inbox entry: \(url.lastPathComponent)")
        switch await self.fileOpenHandler.importFile(from: url) {
        case .success:
            return .audioFile(url)
        case let .failure(error):
            self.discardFile(at: url)
            return self.failImport(error)
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

    /// Publishes the error for the download alert and returns it as result.
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

    /// Publishes the error for the import alert and returns it as result.
    private func failImport(_ error: FileOpenError) -> InboxResult {
        self.importError = error
        return .audioImportFailed(error)
    }
}
