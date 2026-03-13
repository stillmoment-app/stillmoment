//
//  AudioDownloadServiceProtocol.swift
//  Still Moment
//
//  Domain Service Protocol - Audio File Download
//

import Foundation

/// Service for downloading audio files from remote URLs
///
/// Downloads audio files to a local temporary directory, validating
/// the server response and content type before saving.
protocol AudioDownloadServiceProtocol {
    /// Downloads an audio file from a remote URL
    ///
    /// - Parameters:
    ///   - url: The remote URL to download from
    ///   - filename: The original filename (used to preserve file extension)
    /// - Returns: Local file URL where the downloaded file was saved
    /// - Throws: AudioDownloadError if the download fails
    func download(from url: URL, filename: String) async throws -> URL

    /// Cancels the current download if one is in progress
    func cancelDownload()
}
