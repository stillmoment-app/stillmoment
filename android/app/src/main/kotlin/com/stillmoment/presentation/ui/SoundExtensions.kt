package com.stillmoment.presentation.ui

import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.models.GongSound

/**
 * Returns the display name for the given language code.
 * Resolves the correct language variant in the Presentation layer,
 * keeping the Domain model free of Locale dependencies.
 *
 * @param language BCP 47 language code, e.g. "de" or "en"
 */
fun BackgroundSound.localizedName(language: String): String = if (language == "de") nameGerman else nameEnglish

/**
 * Returns the display description for the given language code.
 * Resolves the correct language variant in the Presentation layer.
 *
 * @param language BCP 47 language code, e.g. "de" or "en"
 */
fun BackgroundSound.localizedDescription(language: String): String =
    if (language == "de") descriptionGerman else descriptionEnglish

/**
 * Returns the display name for the given language code.
 * Resolves the correct language variant in the Presentation layer,
 * keeping the Domain model free of Locale dependencies.
 *
 * @param language BCP 47 language code, e.g. "de" or "en"
 */
fun GongSound.localizedName(language: String): String = if (language == "de") nameGerman else nameEnglish
