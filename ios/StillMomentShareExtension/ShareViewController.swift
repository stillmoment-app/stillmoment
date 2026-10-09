//
//  ShareViewController.swift
//  Still Moment
//
//  Share Extension - receives audio files/URLs from Share Sheet,
//  copies them to the App Group inbox and shows a calm confirmation
//  (or a message) in the app's style (ios-059).
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Handles shared items from the system Share Sheet
///
/// Supports two attachment types:
/// - `public.audio`: Audio files shared directly (e.g. from Files, Mail)
/// - `public.url`: HTTP/HTTPS URLs shared from Safari/browsers — auch ohne Datei-Endung
///   (z. B. `https://www.audiodharma.org/talks/25401/download`). Die finale Audio-Pruefung
///   erfolgt anhand des Server-Content-Types beim Download in der Haupt-App.
///
/// Flow:
/// 1. Extract attachment from NSExtensionContext
/// 2. `ShareOutcome.evaluate` decides: confirmation or which message (format check happens
///    before anything is copied)
/// 3. On confirmation: audio file → copy to inbox; URL → write JSON reference.
///    Writing fails → "unreadable" message
/// 4. Show `ShareConfirmationView`; "Done" completes the extension request.
///    The main app picks up the inbox entry on next `scenePhase == .active`
///    (iOS does not allow Share Extensions to open the containing app).
final class ShareViewController: UIViewController {
    // MARK: - Constants

    private static let appGroupIdentifier = "group.com.stillmoment"
    private static let inboxDirectoryName = "ShareInbox"

    // MARK: - State

    private lazy var hostingController = UIHostingController(rootView: self.makeRootView(outcome: nil))
    private var hasStartedProcessing = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Always dark (ios-059) — also the sheet chrome provided by the system
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = UIColor(ThemeColors.dark.backgroundPrimary)
        self.embedHostingController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !self.hasStartedProcessing else {
            return
        }
        self.hasStartedProcessing = true
        self.processSharedItems()
    }

    // MARK: - UI

    private func embedHostingController() {
        let hostingView = self.hostingController.view
        guard let hostingView else {
            return
        }
        addChild(self.hostingController)
        hostingView.backgroundColor = .clear
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        self.hostingController.didMove(toParent: self)
    }

    private func makeRootView(outcome: ShareOutcome?) -> ShareConfirmationView {
        ShareConfirmationView(outcome: outcome) { [weak self] in
            self?.completeRequest()
        }
    }

    /// Shows the confirmation or message. Must be called on the main thread.
    private func show(_ outcome: ShareOutcome) {
        self.hostingController.rootView = self.makeRootView(outcome: outcome)
        // Move VoiceOver focus to the newly shown content
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }

    private func showOnMain(_ outcome: ShareOutcome) {
        DispatchQueue.main.async { [weak self] in
            self?.show(outcome)
        }
    }

    // MARK: - Processing

    private func processSharedItems() {
        guard let extensionItems = self.extensionContext?.inputItems as? [NSExtensionItem],
              let item = extensionItems.first,
              let attachments = item.attachments,
              let attachment = attachments.first
        else {
            self.show(ShareOutcome.evaluate(.nothing))
            return
        }

        if attachment.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
            self.handleAudioAttachment(attachment)
        } else if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            self.handleURLAttachment(attachment)
        } else {
            self.show(ShareOutcome.evaluate(.nothing))
        }
    }

    // MARK: - Audio File Handling

    private func handleAudioAttachment(_ attachment: NSItemProvider) {
        attachment.loadFileRepresentation(forTypeIdentifier: UTType.audio.identifier) { [weak self] url, error in
            guard let self
            else { return }

            guard let url, error == nil
            else {
                self.showOnMain(ShareOutcome.evaluate(.nothing))
                return
            }

            // The URL is only valid during this callback — check and copy immediately
            self.showOnMain(self.acceptAudioFile(at: url))
        }
    }

    /// Checks the format first, so an unsupported file never lands in the inbox.
    private func acceptAudioFile(at url: URL) -> ShareOutcome {
        let outcome = ShareOutcome.evaluate(.audioFile(url))
        guard outcome == .confirmation else {
            return outcome
        }
        return self.copyFileToInbox(from: url) == nil ? .unreadable : .confirmation
    }

    // MARK: - URL Handling

    private func handleURLAttachment(_ attachment: NSItemProvider) {
        attachment.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] data, error in
            guard let self
            else { return }

            guard let url = data as? URL, error == nil
            else {
                self.showOnMain(ShareOutcome.evaluate(.nothing))
                return
            }

            self.showOnMain(self.acceptLink(url))
        }
    }

    /// Only web addresses are accepted — whether audio lives there is decided later
    /// in the main app (Content-Type on download).
    private func acceptLink(_ url: URL) -> ShareOutcome {
        let outcome = ShareOutcome.evaluate(.link(url))
        guard outcome == .confirmation else {
            return outcome
        }
        return self.writeURLReferenceToInbox(url: url) ? .confirmation : .unreadable
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

        let filename = sourceURL.lastPathComponent
        let destinationURL = inboxDir.appendingPathComponent(filename)

        // Atomic write: copy to temp file, then rename
        let tempURL = inboxDir.appendingPathComponent(".\(UUID().uuidString).tmp")

        do {
            try FileManager.default.copyItem(at: sourceURL, to: tempURL)
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)
            // Reset modification date — original file may be older than the stale threshold
            try? FileManager.default.setAttributes(
                [.modificationDate: Date()],
                ofItemAtPath: destinationURL.path
            )
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

        let originalFilename = url.lastPathComponent
        let jsonFilename = "\(originalFilename).json"
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
            let tempURL = inboxDir.appendingPathComponent(".\(UUID().uuidString).tmp")
            try data.write(to: tempURL, options: .atomic)
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Completion

    private func completeRequest() {
        self.extensionContext?.completeRequest(returningItems: nil)
    }
}
