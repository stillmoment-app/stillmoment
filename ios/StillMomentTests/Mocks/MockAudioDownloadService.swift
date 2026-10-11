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
    /// Ob irgendwann Abbrechen weitergereicht wurde
    var downloadCancelCalled = false
    /// Geladene Datei fuer jede Adresse, die hier nicht steht
    var downloadedFileURL: URL?
    /// Geladene Datei pro Adresse (shared-138: mehrere Links nacheinander)
    var downloadedFiles: [URL: URL] = [:]
    /// Laeuft, waehrend der Download "unterwegs" ist — z.B. um dort Abbrechen zu tippen.
    /// Wurde dabei abgebrochen, wirft der Download wie der echte Dienst `.downloadCancelled`.
    var whileDownloading: (@MainActor () async -> Void)?
    /// Wie `whileDownloading`, aber nur fuer den Download dieser Adresse; hat Vorrang.
    var whileDownloadingFrom: [URL: @MainActor () async -> Void] = [:]
    /// Laeuft, nachdem der Download fertig ist (die Datei liegt schon da).
    var afterDownloaded: (@MainActor () -> Void)?
    /// Alle angefragten Adressen in Reihenfolge
    private(set) var requestedURLs: [URL] = []

    func download(from url: URL, filename: String) async throws -> URL {
        self.downloadedURL = url
        self.requestedURLs.append(url)
        // Abbrechen trifft wie beim echten Dienst nur den laufenden Download
        self.isCurrentDownloadCancelled = false
        if let whileDownloading = self.whileDownloadingFrom[url] ?? self.whileDownloading {
            await whileDownloading()
        }
        // Ein konfigurierter Fehler kommt auch nach Abbrechen noch an (z.B. Netzfehler im selben Moment).
        if let errorToThrow {
            throw errorToThrow
        }
        if self.isCurrentDownloadCancelled {
            throw AudioDownloadError.downloadCancelled
        }
        if self.downloadShouldFail {
            throw AudioDownloadError.downloadFailed
        }
        // Return a default temp path if none configured
        let result = self.downloadedFiles[url]
            ?? self.downloadedFileURL
            ?? FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        if let afterDownloaded {
            await afterDownloaded()
        }
        return result
    }

    func cancelDownload() {
        self.downloadCancelCalled = true
        self.isCurrentDownloadCancelled = true
    }

    // MARK: Private

    private var isCurrentDownloadCancelled = false
}
