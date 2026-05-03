package com.stillmoment.domain.services

import android.net.Uri

/**
 * Downloads audio files from HTTP/HTTPS URLs.
 *
 * Used for Chrome URL-share: Chrome sends the URL as plain text,
 * this service downloads the audio to a local temp file so the
 * existing import flow can process it.
 */
interface UrlAudioDownloaderProtocol {

    /**
     * Downloads audio from [url] to a local temporary file.
     *
     * @return Uri to the downloaded local file on success,
     *         or failure with a descriptive exception.
     */
    suspend fun download(url: String): Result<Uri>

    /**
     * Cancels an active download, if any. No-op when no download is running.
     *
     * The active [download] call resolves with `Result.failure` wrapping a
     * `CancellationException` so callers can distinguish user cancellation
     * from network errors.
     */
    fun cancel()
}
