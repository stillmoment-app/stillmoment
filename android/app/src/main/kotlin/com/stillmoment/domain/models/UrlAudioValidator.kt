package com.stillmoment.domain.models

/**
 * Pure utility for validating audio URLs shared via text (e.g. from Chrome).
 *
 * Chrome Android sends ACTION_SEND with text/plain + EXTRA_TEXT = URL.
 * This validator checks if that URL points to a supported audio file.
 */
object UrlAudioValidator {

    private val AUDIO_EXTENSIONS = setOf("mp3", "m4a")

    /**
     * Returns true if the given string is an HTTP/HTTPS URL pointing to
     * a supported audio file (MP3 or M4A).
     */
    fun isAudioUrl(url: String): Boolean {
        if (!url.startsWith("http://") && !url.startsWith("https://")) return false
        val extension = extractExtension(url)
        return extension in AUDIO_EXTENSIONS
    }

    /**
     * Extracts the filename from a URL path.
     * Strips query parameters and fragments.
     */
    fun extractFilename(url: String): String {
        val path = url.substringBefore("?").substringBefore("#")
        val filename = path.substringAfterLast("/")
        return filename.takeIf { it.isNotBlank() } ?: "audio.mp3"
    }

    private fun extractExtension(url: String): String {
        val path = url.substringBefore("?").substringBefore("#")
        return path.substringAfterLast(".", "").lowercase()
    }
}
