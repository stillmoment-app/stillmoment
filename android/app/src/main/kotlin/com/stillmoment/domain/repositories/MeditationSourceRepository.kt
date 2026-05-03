package com.stillmoment.domain.repositories

import com.stillmoment.domain.models.MeditationSource

/**
 * Loads curated meditation sources for the Content Guide.
 *
 * The catalog is static, ships with the app (assets/meditation_sources.json),
 * and contains separate lists per language. Falls back to English when the
 * requested language is not curated.
 */
interface MeditationSourceRepository {
    fun sources(languageCode: String): List<MeditationSource>
}
