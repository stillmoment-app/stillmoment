package com.stillmoment.domain.models

/**
 * Typed failure cases for [com.stillmoment.domain.services.UrlAudioDownloaderProtocol].
 *
 * The UI differentiates [NotAudio] (no retry — the URL won't change) from
 * network/server failures (retry-able), so the failure type cannot be a plain
 * [Exception] string. Cancellation stays on its own channel via
 * [kotlinx.coroutines.CancellationException].
 */
sealed class UrlAudioDownloadError(message: String) : Throwable(message) {

    /** The server responded successfully but the content-type is not audio. */
    object NotAudio : UrlAudioDownloadError("URL did not point to an audio file")

    /** Server returned a non-2xx HTTP status. */
    class Http(val code: Int) : UrlAudioDownloadError("HTTP $code")

    /** IO error (no connection, timeout, broken pipe). */
    class Network(cause: Throwable) : UrlAudioDownloadError("Network error: ${cause.message}")
}
