package com.stillmoment.domain.models

/**
 * Pure utility for validating audio URLs shared via text (e.g. from Chrome).
 *
 * Chrome Android sends ACTION_SEND with text/plain + EXTRA_TEXT = URL.
 * This validator only checks that the URL uses HTTP/HTTPS — the actual
 * audio check happens in [com.stillmoment.domain.services.UrlAudioDownloaderProtocol]
 * against the server's Content-Type, since many audio CDNs serve files
 * behind redirect-URLs without `.mp3`/`.m4a` in the path
 * (e.g. `https://www.audiodharma.org/talks/25401/download`).
 */
object UrlAudioValidator {

    /**
     * Result of classifying the text payload of an `ACTION_SEND` text/plain
     * share. Drives the silent-fail guard: every share the user routes to
     * Still Moment maps to either a download attempt or a visible "no link"
     * snackbar — there is no third "silently ignore" path.
     */
    sealed class ShareTextResult {
        data class AudioUrl(val url: String) : ShareTextResult()
        data object NotALink : ShareTextResult()
    }

    /**
     * Returns true if the given string is an HTTP/HTTPS URL.
     * Audio-vs-not-audio is decided later from the server's Content-Type.
     */
    fun isAudioUrl(url: String): Boolean {
        return url.startsWith("http://") || url.startsWith("https://")
    }

    /**
     * Classifies the text payload of a text/plain share for the silent-fail guard.
     * Anything that is not a usable HTTP/HTTPS URL — including null, blank,
     * whitespace-only, or non-HTTP schemes — collapses to [ShareTextResult.NotALink],
     * so the caller can show a single "no link found" snackbar instead of letting
     * the share disappear without feedback.
     */
    fun classifyShareText(text: String?): ShareTextResult {
        if (text.isNullOrBlank()) return ShareTextResult.NotALink
        return if (isAudioUrl(text)) ShareTextResult.AudioUrl(text) else ShareTextResult.NotALink
    }

    /**
     * Extracts the filename from a URL path.
     * Strips query parameters and fragments. Falls back to `audio.mp3`
     * when the path has no usable filename — the downloader may overwrite
     * this with the server's `Content-Disposition` filename.
     */
    fun extractFilename(url: String): String {
        val path = url.substringBefore("?").substringBefore("#")
        val filename = path.substringAfterLast("/")
        return filename.takeIf { it.isNotBlank() } ?: "audio.mp3"
    }
}
