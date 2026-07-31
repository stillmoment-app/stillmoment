package com.stillmoment.presentation.ui.meditations

import androidx.annotation.StringRes
import com.stillmoment.R
import com.stillmoment.domain.models.DurationFilter

/**
 * Lokalisierte Beschriftung einer Dauer-Stufe (shared-081).
 *
 * Liegt in der Presentation-Schicht, damit [DurationFilter] frei von Android-Ressourcen
 * bleibt — dasselbe Muster wie `SoundExtensions.kt` fuer Gong- und Hintergrund-Namen.
 */
@StringRes
fun DurationFilter.labelRes(): Int = when (this) {
    DurationFilter.ALL -> R.string.library_filter_all
    DurationFilter.UP_TO_5 -> R.string.library_filter_up_to_5
    DurationFilter.FROM_5_TO_15 -> R.string.library_filter_5_to_15
    DurationFilter.FROM_15_TO_30 -> R.string.library_filter_15_to_30
    DurationFilter.OVER_30 -> R.string.library_filter_over_30
}
