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
    val dateAdded: Long = System.currentTimeMillis(),
    /**
     * Playback start offset in milliseconds (null = play from file start).
     * Non-destructive: the audio file itself is never modified (shared-105).
     */
    val trimStartMs: Long? = null,
    /** Playback end offset in milliseconds (null = play to file end). */
    val trimEndMs: Long? = null,
    /**
     * Whether a gong rings at the start of playback (shared-106).
     * Defaults to off — entries from before this feature play without a gong.
     */
    val startGongEnabled: Boolean = false,
    /**
     * Whether a gong rings at the end of playback (shared-106).
     * Defaults to off — entries from before this feature play without a gong.
     */
    val endGongEnabled: Boolean = false,
    /**
     * Per-meditation gong sound ID (references [GongSound.id]); defaults to the
     * standard sound. The volume follows the timer's gong volume, not stored here.
     */
    val gongSoundId: String = GongSound.DEFAULT_SOUND_ID
) {
    /** Where playback effectively begins (file start unless trimmed) */
    val effectiveStartMs: Long
        get() = trimStartMs ?: 0L

    /** Where playback effectively ends (file end unless trimmed) */
    val effectiveEndMs: Long
        get() = trimEndMs ?: duration

    /** The duration the user actually meditates (trimmed range, never negative) */
    val effectiveDurationMs: Long
        get() = (effectiveEndMs - effectiveStartMs).coerceAtLeast(0L)

    /**
     * Formatted effective duration (MM:SS or HH:MM:SS) — shown in library and player.
     */
    val formattedDuration: String
        get() = format(effectiveDurationMs)

    /** Formatted full file length — reference while editing trim points (Phase C). */
    val formattedFileDuration: String
        get() = format(duration)

    private fun format(ms: Long): String {
        val totalSeconds = ms / 1000
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
