package com.stillmoment.domain.models

/**
 * A resolved attunement audio, agnostic to its source (built-in catalog or custom import).
 *
 * Produced by [com.stillmoment.domain.services.AttunementResolverProtocol] to provide
 * a uniform representation that consumers can use without knowing the underlying source.
 *
 * @property id Unique identifier (built-in ID like "breath" or custom UUID)
 * @property name Localized display name
 * @property durationSeconds Audio duration in seconds
 * @property isBuiltIn True if from built-in catalog, false if user-imported
 */
data class ResolvedAttunement(
    val id: String,
    val name: String,
    val durationSeconds: Int,
    val isBuiltIn: Boolean
)
