//
//  AudioDownloadService.swift
//  Still Moment
//
//  Infrastructure - Audio File Download Service
//

import Foundation
import OSLog

/// Concrete implementation of AudioDownloadServiceProtocol
///
/// Downloads audio files using URLSession, validates HTTP responses
/// and content types, and saves files to a temporary directory.
final class AudioDownloadService: AudioDownloadServiceProtocol {
    // MARK: - Properties

    private let session: URLSession

    // MARK: - Initialization

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: Internal

    func download(from url: URL, filename: String) async throws -> URL {
        let (data, httpResponse) = try await self.fetch(url: url)
        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")
        try Self.validateContentType(contentType)

        let resolvedName = self.resolveFilename(
            parameterFilename: filename,
            contentDisposition: httpResponse.value(forHTTPHeaderField: "Content-Disposition"),
            contentType: contentType
        )

        // Per-Download-Subdir, damit die Datei ihren Original-Namen behaelt
        // (sichtbar in Import-Sheet / Library) und mehrfache Downloads nicht kollidieren.
        let downloadDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("dl_\(UUID().uuidString)")
        let tempURL = downloadDir.appendingPathComponent(resolvedName)

        do {
            try FileManager.default.createDirectory(at: downloadDir, withIntermediateDirectories: true)
            try data.write(to: tempURL)
        } catch {
            Logger.infrastructure.error("Failed to write downloaded file: \(error.localizedDescription)")
            throw AudioDownloadError.downloadFailed
        }

        Logger.infrastructure.info("Downloaded audio file: \(resolvedName)")
        return tempURL
    }

    /// Note: Cancels all tasks on the session. Safe as long as this service
    /// uses .shared and only one download runs at a time (enforced by InboxHandler).
    /// If multiple concurrent downloads are needed later, track individual tasks instead.
    func cancelDownload() {
        self.session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }

    // MARK: Private

    private static let supportedExtensions: Set<String> = ["mp3", "m4a"]

    /// Fetches the response and maps URLSession errors to AudioDownloadError cases.
    private func fetch(url: URL) async throws -> (Data, HTTPURLResponse) {
        let request = URLRequest(url: url)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await self.session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw AudioDownloadError.downloadCancelled
        } catch {
            throw AudioDownloadError.networkError
        }
        try Task.checkCancellation()

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AudioDownloadError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AudioDownloadError.invalidResponse
        }
        return (data, httpResponse)
    }

    /// Validates that the Content-Type (if present) is an audio type or generic octet-stream.
    /// A missing Content-Type is accepted — many servers omit it.
    private static func validateContentType(_ contentType: String?) throws {
        guard let contentType else {
            return
        }
        let lowered = contentType.lowercased()
        guard lowered.hasPrefix("audio/") || lowered.hasPrefix("application/octet-stream") else {
            throw AudioDownloadError.unsupportedContentType
        }
    }

    /// Resolves the final filename for the downloaded file in this priority:
    /// 1. `Content-Disposition: filename=...` (echter Server-Filename — User-relevant)
    /// 2. `parameterFilename` falls Audio-Endung vorhanden
    /// 3. Fallback `audio.mp3` / `audio.m4a` aus Content-Type
    private func resolveFilename(
        parameterFilename: String,
        contentDisposition: String?,
        contentType: String?
    ) -> String {
        if let dispositionName = self.parseContentDispositionFilename(contentDisposition),
           Self.hasSupportedExtension(dispositionName) {
            return dispositionName
        }
        if Self.hasSupportedExtension(parameterFilename) {
            return parameterFilename
        }
        return Self.fallbackFilename(for: contentType)
    }

    private static func hasSupportedExtension(_ name: String) -> Bool {
        self.supportedExtensions.contains((name as NSString).pathExtension.lowercased())
    }

    /// Default-Filename basierend auf Content-Type. `audio/mp4` und `audio/x-m4a` → m4a,
    /// alles andere (audio/mpeg, application/octet-stream, fehlend) → mp3.
    private static func fallbackFilename(for contentType: String?) -> String {
        let lowered = contentType?.lowercased() ?? ""
        if lowered.hasPrefix("audio/mp4") || lowered.hasPrefix("audio/x-m4a") || lowered.hasPrefix("audio/m4a") {
            return "audio.m4a"
        }
        return "audio.mp3"
    }

    /// Parst `Content-Disposition: attachment; filename="foo.mp3"` (RFC 6266).
    /// Beruecksichtigt sowohl `filename="..."` als auch `filename*=UTF-8''...`.
    /// Strippt Pfad-Separatoren als Sicherheitsmassnahme (kein Directory-Traversal).
    private func parseContentDispositionFilename(_ header: String?) -> String? {
        guard let header, !header.isEmpty else {
            return nil
        }

        if let starName = Self.extractFilenameStar(from: header) {
            return Self.sanitizeFilename(starName)
        }
        if let plainName = Self.extractFilenameQuoted(from: header) {
            return Self.sanitizeFilename(plainName)
        }
        return nil
    }

    /// `filename*=UTF-8''percent-encoded-name`
    private static func extractFilenameStar(from header: String) -> String? {
        let pattern = #"filename\*=([^']*)'[^']*'([^;]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: header, range: NSRange(header.startIndex..., in: header)),
              match.numberOfRanges >= 3,
              let valueRange = Range(match.range(at: 2), in: header)
        else {
            return nil
        }
        let raw = String(header[valueRange]).trimmingCharacters(in: .whitespaces)
        return raw.removingPercentEncoding ?? raw
    }

    /// `filename="..."` oder `filename=...` (ungequotet bis zum naechsten `;`)
    private static func extractFilenameQuoted(from header: String) -> String? {
        let pattern = #"filename=(?:"([^"]+)"|([^;]+))"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: header, range: NSRange(header.startIndex..., in: header))
        else {
            return nil
        }
        for index in 1..<match.numberOfRanges {
            if let range = Range(match.range(at: index), in: header) {
                return String(header[range]).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    /// Entfernt Pfad-Separatoren — der Header kommt vom Server und darf
    /// keinen Pfad ins Dateisystem schreiben koennen.
    private static func sanitizeFilename(_ name: String) -> String {
        (name as NSString).lastPathComponent
    }
}
