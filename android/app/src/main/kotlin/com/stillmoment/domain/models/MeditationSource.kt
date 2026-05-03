package com.stillmoment.domain.models

/**
 * A curated, free source for guided meditations shown in the Content Guide.
 *
 * Source content is loaded from `meditation_sources.json` per locale at runtime.
 * The Domain layer holds the resolved strings — no localization-key lookup in views.
 */
data class MeditationSource(
    val id: String,
    val name: String,
    val author: String?,
    val description: String,
    val host: String,
    val url: String
)
