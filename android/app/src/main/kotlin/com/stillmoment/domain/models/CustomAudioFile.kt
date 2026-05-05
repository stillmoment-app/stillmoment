package com.stillmoment.domain.models

import java.util.Locale
import java.util.UUID
import kotlinx.serialization.Serializable

/**
 * A user-imported audio file stored in local app storage.
 *
 * Custom audio files are copied to internal storage and used as
 * soundscapes (background loops) within a Praxis configuration.
 *
 * CustomAudioFile is an immutable value object -- all state changes produce new instances.
 *
 * @property id Unique identifier (UUID as String)
 * @property name Display name (derived from filename without extension on import)
 * @property filename Actual filename in local storage (UUID-based, e.g. "3A9F...mp3")
 * @property durationMs Audio duration in milliseconds (null if detection failed)
 * @property type The custom-audio kind (currently only SOUNDSCAPE; field kept for forward-compat)
 * @property dateAdded When the file was imported (epoch millis)
 */
@Serializable
data class CustomAudioFile(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val filename: String,
    val durationMs: Long?,
    val type: CustomAudioType,
    val dateAdded: Long = System.currentTimeMillis()
) {
    /**
     * Human-readable duration string (e.g. "3:45"), or null if duration is unknown.
     */
    val formattedDuration: String?
        get() {
            val ms = durationMs ?: return null
            val totalSeconds = (ms / 1000).toInt()
            val minutes = totalSeconds / 60
            val seconds = totalSeconds % 60
            return String.format(Locale.US, "%d:%02d", minutes, seconds)
        }
}
