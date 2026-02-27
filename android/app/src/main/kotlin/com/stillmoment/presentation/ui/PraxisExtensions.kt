package com.stillmoment.presentation.ui

import android.content.Context
import com.stillmoment.R
import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.models.Praxis

private const val SHORT_DESCRIPTION_SEPARATOR = " \u00B7 "

/**
 * Returns a localized short description of the praxis configuration.
 *
 * Example: "10 min . Silence . Temple Bell . 15s preparation"
 * Parts: duration, "Silence" if silent background, gong name, preparation time.
 */
fun Praxis.shortDescription(context: Context): String {
    val parts = mutableListOf<String>()

    parts.add(context.getString(R.string.praxis_description_duration, durationMinutes))

    if (backgroundSoundId == Praxis.DEFAULT_BACKGROUND_SOUND_ID) {
        parts.add(context.getString(R.string.praxis_description_silent))
    }

    val language = context.resources.configuration.locales[0].language
    val gongName = GongSound.findOrDefault(gongSoundId).localizedName(language)
    parts.add(gongName)

    if (preparationTimeEnabled) {
        parts.add(
            context.getString(R.string.praxis_description_preparation, preparationTimeSeconds)
        )
    }

    return parts.joinToString(SHORT_DESCRIPTION_SEPARATOR)
}
