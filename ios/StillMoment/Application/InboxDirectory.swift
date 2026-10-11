//
//  InboxDirectory.swift
//  Still Moment
//
//  Application Layer - The Share Extension inbox on disk
//

import Foundation
import OSLog

/// The Share Extension inbox on disk: the entries waiting there and how one is taken over.
///
/// Every entry in the inbox is a *waiting* entry (shared-138). The entry in progress has been
/// moved out (`takeOver`), so an audio file shared meanwhile under the same name can never be
/// mistaken for it. Links get an entry name of their own anyway (`ShareInbox.storeLink`).
struct InboxDirectory {
    // MARK: Internal

    /// Prefix of the folder in `tmp` that holds a taken-over entry
    static let takenEntryFolderPrefix = "share_"

    let url: URL
    let fileManager: FileManager

    /// Fresh entries of a supported type. Stale (>24 h) and unrecognized files are removed on the way.
    ///
    /// - Returns: No entries when the inbox does not exist yet (nobody has shared anything)
    /// - Throws: When the inbox exists but cannot be read
    func waitingEntries() throws -> [URL] {
        guard self.fileManager.fileExists(atPath: self.url.path) else {
            return []
        }
        let allFiles = try self.fileManager.contentsOfDirectory(
            at: self.url,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        return self.filterSupportedFiles(from: self.removeStaleEntries(from: allFiles))
    }

    /// The newest waiting entry; all older ones are removed ("the last shared wins", shared-132).
    func newestEntryRemovingOthers() throws -> URL? {
        let entries = try self.waitingEntries()
        guard let newest = self.newestFile(from: entries) else {
            return nil
        }
        self.remove(entries.filter { $0 != newest })
        return newest
    }

    /// Moves the entry out of the inbox into a folder of its own, `tmp/share_<UUID>/<name>`.
    ///
    /// On the same volume (app group container and app `tmp` both live on the data volume)
    /// the move is a rename and atomic: either the entry is taken over, or it is still waiting.
    /// An entry that cannot be moved is removed, so it is not retried forever.
    func takeOver(_ entry: URL) -> URL? {
        let folder = self.fileManager.temporaryDirectory
            .appendingPathComponent("\(Self.takenEntryFolderPrefix)\(UUID().uuidString)")
        let takenEntry = folder.appendingPathComponent(entry.lastPathComponent)
        do {
            try self.fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            try self.fileManager.moveItem(at: entry, to: takenEntry)
            return takenEntry
        } catch {
            Logger.infrastructure.error(
                "Failed to take over inbox entry \(entry.lastPathComponent): \(error.localizedDescription)"
            )
            try? self.fileManager.removeItem(at: folder)
            try? self.fileManager.removeItem(at: entry)
            return nil
        }
    }

    /// Puts an audio file opened with the app ("Open in") into the inbox, like the Share Extension does.
    func storeOpenedFile(_ file: URL) throws {
        try self.fileManager.createDirectory(at: self.url, withIntermediateDirectories: true)
        try ShareInbox.storeAudioFile(from: file, in: self.url, fileManager: self.fileManager)
    }

    func remove(_ entries: [URL]) {
        for entry in entries {
            try? self.fileManager.removeItem(at: entry)
        }
    }

    // MARK: Private

    private static let supportedExtensions: Set<String> = ["mp3", "m4a", "json"]
    private static let staleThreshold: TimeInterval = 24 * 3600

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
            if Self.supportedExtensions.contains(file.pathExtension.lowercased()) {
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

    private func modificationDate(of url: URL) -> Date? {
        guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]) else {
            return nil
        }
        return values.contentModificationDate
    }
}
