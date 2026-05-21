package com.stillmoment.domain.models

/**
 * Metadata extracted from an audio file (ID3 tags + duration).
 *
 * Pure value object — no Android framework dependency. Used as the input for
 * the [ImportPrefill] cascade.
 *
 * @property duration File duration in milliseconds. `0L` when unknown.
 * @property artist ID3 `TPE1`-equivalent (artist) value, or `null` when absent.
 * @property title ID3 `TIT2`-equivalent (title) value, or `null` when absent.
 */
data class AudioMetadata(
    val duration: Long,
    val artist: String?,
    val title: String?
)
