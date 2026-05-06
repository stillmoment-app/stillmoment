//
//  MockAudioDownloadService.swift
//  Still Moment
//

import Foundation
@testable import StillMoment

final class MockAudioDownloadService: AudioDownloadServiceProtocol {
    var downloadedURL: URL?
    var downloadShouldFail = false
    /// Wenn gesetzt, wirft `download(...)` diesen Fehler — hat Vorrang vor `downloadShouldFail`.
    var errorToThrow: AudioDownloadError?
    var downloadCancelCalled = false
    var downloadedFileURL: URL?

    func download(from url: URL, filename: String) async throws -> URL {
        self.downloadedURL = url
        if let errorToThrow {
            throw errorToThrow
        }
        if self.downloadShouldFail {
            throw AudioDownloadError.downloadFailed
        }
        guard let downloadedFileURL else {
            // Return a default temp path if none configured
            let tempDir = FileManager.default.temporaryDirectory
            return tempDir.appendingPathComponent(filename)
        }
        return downloadedFileURL
    }

    func cancelDownload() {
        self.downloadCancelCalled = true
    }
}
