//
//  ShareInbox.swift
//  Still Moment
//
//  Infrastructure - Places shared items in the Share Extension inbox.
//  Member of the app target (testable) and the Share Extension target (writer).
//

import Foundation

// MARK: - URLReference

/// JSON format of a shared link in the inbox.
/// Written by the Share Extension via `ShareInbox.storeLink`, read by `InboxHandler`.
struct URLReference: Codable {
    let url: String
    let filename: String
    let timestamp: String
}

// MARK: - ShareInbox

/// Writes shared audio files and links into the inbox directory (App Group `ShareInbox/`).
///
/// Every entry is written to a hidden temporary file first and then moved into place,
/// so the main app never reads a half-written entry.
///
/// No logging here: the Share Extension has no `Logger`.
enum ShareInbox {
    /// Copies a shared audio file into the inbox under its own file name.
    ///
    /// The modification date is set to `date`: the original file may be older than the
    /// 24-hour stale threshold of `InboxHandler`, and "newest entry wins" relies on it.
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
        let tempURL = self.temporaryURL(in: inboxDirectory)

        do {
            try fileManager.copyItem(at: sourceURL, to: tempURL)
            try self.moveIntoPlace(tempURL, at: destinationURL, fileManager: fileManager)
        } catch {
            try? fileManager.removeItem(at: tempURL)
            throw error
        }

        try? fileManager.setAttributes([.modificationDate: date], ofItemAtPath: destinationURL.path)
        return destinationURL
    }

    /// Writes a reference to a shared link (`URLReference` as JSON) into the inbox.
    ///
    /// The entry is named after the link's last path component plus `.json`.
    ///
    /// - Returns: The inbox entry
    @discardableResult
    static func storeLink(
        _ url: URL,
        in inboxDirectory: URL,
        fileManager: FileManager = .default,
        date: Date = Date()
    ) throws -> URL {
        let filename = url.lastPathComponent
        let destinationURL = inboxDirectory.appendingPathComponent("\(filename).json")
        let reference = URLReference(
            url: url.absoluteString,
            filename: filename,
            timestamp: ISO8601DateFormatter().string(from: date)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(reference)

        let tempURL = self.temporaryURL(in: inboxDirectory)
        do {
            try data.write(to: tempURL, options: .atomic)
            try self.moveIntoPlace(tempURL, at: destinationURL, fileManager: fileManager)
        } catch {
            try? fileManager.removeItem(at: tempURL)
            throw error
        }
        return destinationURL
    }

    // MARK: Private

    /// Hidden name — `InboxHandler` skips hidden files, so a half-written entry is never picked up
    private static func temporaryURL(in inboxDirectory: URL) -> URL {
        inboxDirectory.appendingPathComponent(".\(UUID().uuidString).tmp")
    }

    /// Moves the completely written temporary file to its final name.
    private static func moveIntoPlace(_ tempURL: URL, at destinationURL: URL, fileManager: FileManager) throws {
        try fileManager.moveItem(at: tempURL, to: destinationURL)
    }
}
