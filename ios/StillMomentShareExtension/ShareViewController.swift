//
//  ShareViewController.swift
//  Still Moment
//
//  Share Extension - receives audio files/URLs from Share Sheet,
//  copies them to the App Group inbox, then opens the main app.
//

import UIKit
import UniformTypeIdentifiers

/// Handles shared items from the system Share Sheet
///
/// Supports two attachment types:
/// - `public.audio`: Audio files shared directly (e.g. from Files, Mail)
/// - `public.url`: URLs shared from Safari/browsers (filtered to .mp3/.m4a)
///
/// Flow:
/// 1. Extract attachment from NSExtensionContext
/// 2. Audio file → copy to inbox; URL → validate extension, write JSON reference
/// 3. Open main app via `stillmoment://import` URL scheme
/// 4. Complete extension request
final class ShareViewController: UIViewController {
    // MARK: - Constants

    private static let appGroupIdentifier = "group.com.stillmoment"
    private static let inboxDirectoryName = "ShareInbox"
    private static let supportedExtensions: Set<String> = ["mp3", "m4a"]
    private static let urlScheme = "stillmoment://import"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Transparent background — no UI in the extension
        view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.processSharedItems()
    }

    // MARK: - Processing

    private func processSharedItems() {
        guard let extensionItems = self.extensionContext?.inputItems as? [NSExtensionItem],
              let item = extensionItems.first,
              let attachments = item.attachments,
              let attachment = attachments.first
        else {
            self.completeRequest()
            return
        }

        if attachment.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
            self.handleAudioAttachment(attachment)
        } else if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            self.handleURLAttachment(attachment)
        } else {
            // Not an audio file or URL — close silently
            self.completeRequest()
        }
    }

    // MARK: - Audio File Handling

    private func handleAudioAttachment(_ attachment: NSItemProvider) {
        attachment.loadFileRepresentation(forTypeIdentifier: UTType.audio.identifier) { [weak self] url, error in
            guard let self
            else { return }

            guard let url, error == nil
            else {
                DispatchQueue.main.async {
                    self.showError()
                }
                return
            }

            // The URL is only valid during this callback — copy immediately
            guard let inboxURL = self.copyFileToInbox(from: url) else {
                DispatchQueue.main.async {
                    self.showError()
                }
                return
            }

            // Verify it's a supported format
            guard Self.supportedExtensions.contains(inboxURL.pathExtension.lowercased()) else {
                try? FileManager.default.removeItem(at: inboxURL)
                DispatchQueue.main.async {
                    self.completeRequest()
                }
                return
            }

            DispatchQueue.main.async {
                self.openMainAppAndComplete()
            }
        }
    }

    // MARK: - URL Handling

    private func handleURLAttachment(_ attachment: NSItemProvider) {
        attachment.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] data, error in
            guard let self
            else { return }

            guard let url = data as? URL, error == nil
            else {
                DispatchQueue.main.async {
                    self.completeRequest()
                }
                return
            }

            // Check if the URL points to an audio file
            let pathExtension = url.pathExtension.lowercased()
            guard Self.supportedExtensions.contains(pathExtension) else {
                // Not an audio URL — close silently (no error for non-audio URLs)
                DispatchQueue.main.async {
                    self.completeRequest()
                }
                return
            }

            // Write URL reference to inbox as JSON
            guard self.writeURLReferenceToInbox(url: url) else {
                DispatchQueue.main.async {
                    self.showError()
                }
                return
            }

            DispatchQueue.main.async {
                self.openMainAppAndComplete()
            }
        }
    }

    // MARK: - Inbox Operations

    /// Returns the inbox directory URL inside the App Group container, creating it if needed
    private func inboxDirectoryURL() -> URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        ) else {
            return nil
        }

        let inboxURL = containerURL.appendingPathComponent(Self.inboxDirectoryName)
        try? FileManager.default.createDirectory(at: inboxURL, withIntermediateDirectories: true)
        return inboxURL
    }

    /// Copies an audio file to the inbox with a UUID prefix for uniqueness
    ///
    /// Uses atomic write: writes to a temporary file first, then renames.
    /// This prevents the main app from reading a half-written file.
    private func copyFileToInbox(from sourceURL: URL) -> URL? {
        guard let inboxDir = self.inboxDirectoryURL()
        else { return nil }

        let uuid = UUID().uuidString
        let filename = "\(uuid)_\(sourceURL.lastPathComponent)"
        let destinationURL = inboxDir.appendingPathComponent(filename)

        // Atomic write: copy to temp file, then rename
        let tempURL = inboxDir.appendingPathComponent(".\(uuid).tmp")

        do {
            try FileManager.default.copyItem(at: sourceURL, to: tempURL)
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)
            return destinationURL
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            return nil
        }
    }

    /// Writes a URL reference as JSON to the inbox
    ///
    /// Schema: { "url": "...", "filename": "...", "timestamp": "..." }
    private func writeURLReferenceToInbox(url: URL) -> Bool {
        guard let inboxDir = self.inboxDirectoryURL()
        else { return false }

        let uuid = UUID().uuidString
        let originalFilename = url.lastPathComponent
        let jsonFilename = "\(uuid)_\(originalFilename).json"
        let destinationURL = inboxDir.appendingPathComponent(jsonFilename)

        let formatter = ISO8601DateFormatter()
        let reference: [String: String] = [
            "url": url.absoluteString,
            "filename": originalFilename,
            "timestamp": formatter.string(from: Date())
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: reference, options: [.sortedKeys])

            // Atomic write: write to temp file, then rename
            let tempURL = inboxDir.appendingPathComponent(".\(uuid).tmp")
            try data.write(to: tempURL, options: .atomic)
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)
            return true
        } catch {
            return false
        }
    }

    // MARK: - App Opening

    /// Shows a brief success message, then completes the extension request.
    ///
    /// iOS does not allow Share Extensions to open the containing app reliably.
    /// The main app picks up the inbox entry on next `scenePhase == .active`.
    private func openMainAppAndComplete() {
        let title = NSLocalizedString(
            "share.success.title",
            tableName: nil,
            bundle: Bundle(for: ShareViewController.self),
            value: "Saved to Still Moment",
            comment: "Share extension success message"
        )
        let message = NSLocalizedString(
            "share.success.message",
            tableName: nil,
            bundle: Bundle(for: ShareViewController.self),
            value: "Open Still Moment to continue the import.",
            comment: "Share extension success instruction"
        )
        let okTitle = NSLocalizedString(
            "common.ok",
            tableName: nil,
            bundle: Bundle(for: ShareViewController.self),
            value: "OK",
            comment: "OK button"
        )

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okTitle, style: .default) { [weak self] _ in
            self?.completeRequest()
        })
        self.present(alert, animated: true)
    }

    // MARK: - Error Handling

    /// Shows a localized error alert, then completes
    private func showError() {
        let title = NSLocalizedString(
            "share.error.title",
            tableName: nil,
            bundle: Bundle(for: ShareViewController.self),
            value: "Import Failed",
            comment: "Share extension error alert title"
        )
        let message = NSLocalizedString(
            "share.error.message",
            tableName: nil,
            bundle: Bundle(for: ShareViewController.self),
            value: "The file could not be prepared for import.",
            comment: "Share extension error alert message"
        )
        let okTitle = NSLocalizedString(
            "common.ok",
            tableName: nil,
            bundle: Bundle(for: ShareViewController.self),
            value: "OK",
            comment: "OK button"
        )

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okTitle, style: .default) { [weak self] _ in
            self?.completeRequest()
        })
        self.present(alert, animated: true)
    }

    // MARK: - Completion

    private func completeRequest() {
        self.extensionContext?.completeRequest(returningItems: nil)
    }
}
