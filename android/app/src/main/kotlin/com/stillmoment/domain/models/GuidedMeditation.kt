package com.stillmoment.domain.models

import java.util.UUID
import kotlinx.serialization.Serializable

/**
 * Represents a guided meditation audio file with metadata.
 *
 * This model stores references to external audio files via Content URIs (SAF),
 * allowing the app to access files in the user's file system without copying them.
 *
 * Metadata can be customized by the user, overriding values read from ID3 tags.
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
    /** Teacher/Artist name (from ID3 tag or default) */
    val teacher: String,
    /** Meditation name/title (from ID3 tag or file name) */
    val name: String,
    /** Custom teacher name set by user (overrides ID3 tag) */
    val customTeacher: String? = null,
    /** Custom meditation name set by user (overrides ID3 tag) */
    val customName: String? = null,
    /** Timestamp when the meditation was added to the library */
    val dateAdded: Long = System.currentTimeMillis(),
) {
    /**
     * Returns the effective teacher name (custom if set, otherwise original)
     */
    val effectiveTeacher: String
        get() = customTeacher ?: teacher

    /**
     * Returns the effective meditation name (custom if set, otherwise original)
     */
    val effectiveName: String
        get() = customName ?: name

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
                String.format("%d:%02d:%02d", hours, minutes, seconds)
            } else {
                String.format("%d:%02d", minutes, seconds)
            }
        }

    /**
     * Creates a copy with a custom teacher name
     */
    fun withCustomTeacher(teacher: String?): GuidedMeditation = copy(customTeacher = teacher)

    /**
     * Creates a copy with a custom meditation name
     */
    fun withCustomName(name: String?): GuidedMeditation = copy(customName = name)
}
