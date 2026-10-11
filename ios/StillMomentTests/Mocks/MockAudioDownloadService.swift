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
    /// Laeuft, waehrend der Download "unterwegs" ist — z.B. um dort Abbrechen zu tippen.
    /// Wurde dabei abgebrochen, wirft der Download wie der echte Dienst `.downloadCancelled`.
    var whileDownloading: (@MainActor () -> Void)?
    /// Laeuft, nachdem der Download fertig ist (die Datei liegt schon da).
    var afterDownloaded: (@MainActor () -> Void)?
    /// Alle angefragten Adressen in Reihenfolge
    private(set) var requestedURLs: [URL] = []

    func download(from url: URL, filename: String) async throws -> URL {
        self.downloadedURL = url
        self.requestedURLs.append(url)
        if let whileDownloading {
            await whileDownloading()
        }
        // Ein konfigurierter Fehler kommt auch nach Abbrechen noch an (z.B. Netzfehler im selben Moment).
        if let errorToThrow {
            throw errorToThrow
        }
        if self.whileDownloading != nil, self.downloadCancelCalled {
            throw AudioDownloadError.downloadCancelled
        }
        if self.downloadShouldFail {
            throw AudioDownloadError.downloadFailed
        }
        // Return a default temp path if none configured
        let result = self.downloadedFileURL ?? FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        if let afterDownloaded {
            await afterDownloaded()
        }
        return result
    }

    func cancelDownload() {
        self.downloadCancelCalled = true
    }
}
