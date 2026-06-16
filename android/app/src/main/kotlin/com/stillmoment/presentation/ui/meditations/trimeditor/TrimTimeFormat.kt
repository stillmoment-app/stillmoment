package com.stillmoment.presentation.ui.meditations.trimeditor

import java.util.Locale

/**
 * Formats a millisecond time as `M:SS` (or `H:MM:SS` past an hour) for the trim editor
 * read-outs and axis labels (shared-107). Locale-independent digits (`Locale.ROOT`),
 * mirroring iOS `EditSheetState.formatTime` and [com.stillmoment.domain.models.GuidedMeditation]'s
 * own duration formatting.
 */
internal fun formatTrimTime(ms: Long): String {
    val totalSeconds = (ms.coerceAtLeast(0L)) / 1000
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60
    return if (hours > 0) {
        String.format(Locale.ROOT, "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        String.format(Locale.ROOT, "%d:%02d", minutes, seconds)
    }
}
