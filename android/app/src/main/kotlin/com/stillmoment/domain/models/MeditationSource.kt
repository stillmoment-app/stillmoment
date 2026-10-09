package com.stillmoment.domain.models

/**
 * A curated, free source for guided meditations shown in the Content Guide.
 *
 * Source content is loaded from `meditation_sources.json` per language at runtime.
 * The Domain layer holds the resolved strings — no localization-key lookup in views.
 *
 * Since shared-137 [name] is mostly the teacher, [offer] the name of the offering
 * (centre, podcast, website) when it has a name of its own.
 */
data class MeditationSource(
    val id: String,
    val name: String,
    val offer: String?,
    val description: String,
    val host: String,
    val url: String
)
