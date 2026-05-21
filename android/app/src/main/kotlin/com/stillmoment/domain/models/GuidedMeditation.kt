package com.stillmoment.domain.models

import java.util.Locale
import java.util.UUID
import kotlinx.serialization.Serializable

/**
 * Represents a guided meditation audio file with metadata.
 *
 * This model stores references to external audio files via Content URIs (SAF),
 * allowing the app to access files in the user's file system without copying them.
 *
 * `teacher` and `name` are the single source of truth — there is no override
 * mechanism. Legacy entries with `customTeacher` / `customName` are folded
 * during repository init (see `migrateLegacyOverridesIfNeeded`).
 */
@Serializable
data class GuidedMeditation(
    /** Unique identifier */
    val id: String = UUID.randomUUID().toString(),
    /** Content URI for accessing the file (SAF) */
    val fileUri: String,
    /** Original file name (for debugging/display purposes) */
    val fileName: String,
    /** Duration in milliseconds (read from audio file) */
    val duration: Long,
    /** Teacher/Artist name (single source of truth) */
    val teacher: String,
    /** Meditation name/title (single source of truth) */
    val name: String,
    /** Timestamp when the meditation was added to the library */
    val dateAdded: Long = System.currentTimeMillis()
) {
    /**
     * Formatted duration string (MM:SS or HH:MM:SS)
     */
    val formattedDuration: String
        get() {
            val totalSeconds = duration / 1000
            val hours = totalSeconds / 3600
            val minutes = (totalSeconds % 3600) / 60
            val seconds = totalSeconds % 60

            return if (hours > 0) {
                String.format(Locale.ROOT, "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                String.format(Locale.ROOT, "%d:%02d", minutes, seconds)
            }
        }
}
