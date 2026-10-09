package com.stillmoment.domain.repositories

import com.stillmoment.domain.models.MeditationSourceCatalog

/**
 * Loads curated meditation sources for the Content Guide.
 *
 * The catalog is static, ships with the app (assets/meditation_sources.json),
 * and contains separate lists per language. Which language comes first, and the
 * fallback to English, is decided by [MeditationSourceCatalog.groups] (shared-137).
 */
interface MeditationSourceRepository {
    fun catalog(): MeditationSourceCatalog
}
