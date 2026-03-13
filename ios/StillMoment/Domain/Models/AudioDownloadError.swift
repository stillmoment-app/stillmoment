//
//  AudioDownloadError.swift
//  Still Moment
//
//  Domain Model - Audio Download Error Types
//

import Foundation

/// Errors that can occur during audio file download
enum AudioDownloadError: Error, Equatable, LocalizedError {
    case networkError
    case invalidResponse
    case unsupportedContentType
    case downloadCancelled
    case downloadFailed

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .networkError:
            NSLocalizedString(
                "audio_download_error_network",
                value: "Unable to download file. Please check your internet connection.",
                comment: "Error when network is unavailable during audio download"
            )
        case .invalidResponse:
            NSLocalizedString(
                "audio_download_error_invalid_response",
                value: "The server returned an unexpected response.",
                comment: "Error when server returns non-2xx status code"
            )
        case .unsupportedContentType:
            NSLocalizedString(
                "audio_download_error_unsupported_content_type",
                value: "The file is not a supported audio format.",
                comment: "Error when server returns non-audio content type"
            )
        case .downloadCancelled:
            NSLocalizedString(
                "audio_download_error_cancelled",
                value: "The download was cancelled.",
                comment: "Error when user cancels an audio download"
            )
        case .downloadFailed:
            NSLocalizedString(
                "audio_download_error_failed",
                value: "The download failed. Please try again.",
                comment: "General download failure error"
            )
        }
    }
}
