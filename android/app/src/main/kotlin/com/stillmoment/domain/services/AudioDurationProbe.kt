package com.stillmoment.domain.services

/**
 * Detects the play length of an audio file that is already stored in app-internal
 * storage.
 *
 * Detection can be slow (some MP3s have to be scanned completely), so callers run
 * it in the background and never let an import wait for it (android-079).
 */
interface AudioDurationProbe {
    /**
     * @param filePath Absolute path of the local audio file.
     * @return Play length in milliseconds, or null if it cannot be determined.
     *   Implementations never throw for unreadable or missing files.
     */
    suspend fun durationMs(filePath: String): Long?
}
