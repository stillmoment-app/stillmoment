package com.stillmoment.presentation.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalConfiguration
import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.models.GongSound

/**
 * Returns the localized display name based on the current device locale.
 * Uses LocalConfiguration to track runtime locale changes.
 */
@Composable
fun BackgroundSound.localizedName(): String {
    val locale = LocalConfiguration.current.locales[0]
    return if (locale.language == "de") nameGerman else nameEnglish
}

/**
 * Returns the localized display description based on the current device locale.
 * Uses LocalConfiguration to track runtime locale changes.
 */
@Composable
fun BackgroundSound.localizedDescription(): String {
    val locale = LocalConfiguration.current.locales[0]
    return if (locale.language == "de") descriptionGerman else descriptionEnglish
}

/**
 * Returns the localized display name based on the current device locale.
 * Uses LocalConfiguration to track runtime locale changes.
 */
@Composable
fun GongSound.localizedName(): String {
    val locale = LocalConfiguration.current.locales[0]
    return if (locale.language == "de") nameGerman else nameEnglish
}
