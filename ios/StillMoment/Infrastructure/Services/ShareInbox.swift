//
//  ShareInbox.swift
//  Still Moment
//
//  Infrastructure - Places shared items in the Share Extension inbox.
//  Member of the app target (testable) and the Share Extension target (writer).
//

import Foundation

/// Writes shared audio files and links into the inbox directory (App Group `ShareInbox/`).
///
/// Every entry is written completely first and then atomically renamed into place.
/// The main app never reads a half-written entry and never finds the inbox without it.
/// A shared audio file replaces a waiting one with the same name; every shared link gets
/// an entry of its own (shared-138).
///
/// No logging here: the Share Extension has no `Logger`.
enum ShareInbox {
    /// Copies a shared audio file into the inbox under its own file name.
    ///
    /// The copy is prepared as a hidden temporary file and gets `date` as modification date
    /// before it is put in place: the original file may be older than the 24-hour stale
    /// threshold of `InboxHandler`, and "newest entry wins" relies on it. If the date cannot
    /// be set, storing fails — otherwise the app would silently discard the entry while the
    /// Share Extension reported success.
    ///
    /// - Returns: The inbox entry
    @discardableResult
    static func storeAudioFile(
        from sourceURL: URL,
        in inboxDirectory: URL,
        fileManager: FileManager = .default,
        date: Date = Date()
    ) throws -> URL {
        let destinationURL = inboxDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        let tempURL = inboxDirectory.appendingPathComponent(".\(UUID().uuidString).tmp")

        do {
            try fileManager.copyItem(at: sourceURL, to: tempURL)
            try fileManager.setAttributes([.modificationDate: date], ofItemAtPath: tempURL.path)
            try self.replaceAtomically(destinationURL, with: tempURL)
        } catch {
            try? fileManager.removeItem(at: tempURL)
            throw error
        }
        return destinationURL
    }

    /// Writes a reference to a shared link (`URLReference` from Domain, as JSON) into the inbox.
    ///
    /// Every link gets an entry of its own, `<UUID>.json` (shared-138). Links with the same
    /// ending (`…/25401/download`, `…/25402/download`) never replace each other: the app may
    /// be importing one while the other waits. "The last shared wins" (shared-132) is decided
    /// by the app via the entries' modification dates; it removes the older ones.
    ///
    /// The reference carries the link's last path component as filename for the download.
    /// A link without path (`https://www.example.com/`, also with `?id=1`) has no usable
    /// component — `lastPathComponent` is `"/"` or empty (ios-061) — so the filename stays
    /// empty and the download names the file itself (server name or `audio.mp3`/`audio.m4a`).
    ///
    /// - Returns: The inbox entry
    @discardableResult
    static func storeLink(
        _ url: URL,
        in inboxDirectory: URL,
        date: Date = Date()
    ) throws -> URL {
        let lastComponent = url.lastPathComponent
        let filename = lastComponent == "/" ? "" : lastComponent
        let destinationURL = inboxDirectory.appendingPathComponent("\(UUID().uuidString).json")
        let reference = URLReference(
            url: url.absoluteString,
            filename: filename,
            timestamp: ISO8601DateFormatter().string(from: date)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(reference)

        // `.atomic` writes to a temporary file and renames it into place.
        try data.write(to: destinationURL, options: .atomic)
        return destinationURL
    }

    // MARK: Private

    /// Puts the completely written (hidden) temporary file in place of `destinationURL`.
    ///
    /// A waiting entry with the same name is replaced (shared-132): the same file shared
    /// twice — the last shared entry wins. POSIX `rename(2)` replaces an existing target
    /// atomically ("guarantees that an instance of new will always exist"), so the app never
    /// finds the inbox without the entry, and a failure leaves the waiting entry untouched.
    /// A missing target is the normal case. Unlike `FileManager.replaceItemAt`, which keeps
    /// the original's metadata by default, `rename` keeps the new file's modification date.
    private static func replaceAtomically(_ destinationURL: URL, with tempURL: URL) throws {
        guard rename(tempURL.path, destinationURL.path) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
    }
}
