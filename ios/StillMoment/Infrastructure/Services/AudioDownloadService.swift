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

        // Check for cancellation after receiving response
        try Task.checkCancellation()

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AudioDownloadError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AudioDownloadError.invalidResponse
        }

        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
            let lowered = contentType.lowercased()
            guard lowered.hasPrefix("audio/") || lowered.hasPrefix("application/octet-stream") else {
                throw AudioDownloadError.unsupportedContentType
            }
        }

        let fileExtension = (filename as NSString).pathExtension
        let tempFileName = UUID().uuidString + (fileExtension.isEmpty ? "" : ".\(fileExtension)")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(tempFileName)

        do {
            try data.write(to: tempURL)
        } catch {
            Logger.infrastructure.error("Failed to write downloaded file: \(error.localizedDescription)")
            throw AudioDownloadError.downloadFailed
        }

        Logger.infrastructure.info("Downloaded audio file: \(filename)")
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
}
