package com.stillmoment.presentation.util

import java.util.Locale

/**
 * Name of the language [languageCode], written in the language [inLanguageCode],
 * with a capital first letter (shared-137).
 *
 * The names come from the system, not from own strings: on a German device "en"
 * becomes "Englisch", on an English one "de" becomes "German".
 */
fun languageDisplayName(languageCode: String, inLanguageCode: String): String {
    val displayLocale = Locale.forLanguageTag(inLanguageCode)
    val name = Locale.forLanguageTag(languageCode).getDisplayLanguage(displayLocale)
    return name.replaceFirstChar { if (it.isLowerCase()) it.titlecase(displayLocale) else it.toString() }
}
