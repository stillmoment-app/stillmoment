package com.stillmoment.domain.models

import java.text.Collator

/** The curated sources of one language in the Content Guide (shared-137). */
data class MeditationSourceGroup(
    /** Language code of the sources, e.g. `"de"` or `"en"` */
    val languageCode: String,
    /** Sources in catalog order */
    val sources: List<MeditationSource>
)

/**
 * All curated meditation sources, keyed by language code (shared-137).
 *
 * Immutable value object. [groups] orders the languages for the Content Guide:
 * own language first, then English, then all others alphabetically by their
 * displayed name. Languages without sources are left out.
 */
data class MeditationSourceCatalog(
    val sourcesByLanguage: Map<String, List<MeditationSource>>
) {
    /**
     * Language groups for the Content Guide. The first group is the user's own language.
     *
     * @param ownLanguageCode language of the app; falls back to English when the
     *   catalog has no sources for it
     * @param displayName name of a language as shown to the user — injected so the
     *   Domain stays free of locale lookups
     */
    fun groups(ownLanguageCode: String, displayName: (String) -> String): List<MeditationSourceGroup> {
        val available = sourcesByLanguage.filterValues { it.isNotEmpty() }
        val own = resolvedOwnLanguage(ownLanguageCode)
        val collator = Collator.getInstance()
        val others = available.keys
            .filter { it != own && it != FALLBACK_LANGUAGE }
            .sortedWith { a, b -> collator.compare(displayName(a), displayName(b)) }
        val order = listOf(own, FALLBACK_LANGUAGE).distinct() + others
        return order.mapNotNull { code ->
            available[code]?.let { MeditationSourceGroup(languageCode = code, sources = it) }
        }
    }

    /** The user's own language: [ownLanguageCode] when the catalog has sources for it, else English. */
    fun resolvedOwnLanguage(ownLanguageCode: String): String =
        if (sourcesByLanguage[ownLanguageCode].isNullOrEmpty()) FALLBACK_LANGUAGE else ownLanguageCode

    companion object {
        const val FALLBACK_LANGUAGE = "en"
    }
}
