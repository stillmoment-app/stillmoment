package com.stillmoment.domain.models

/**
 * Represents the source requesting audio session access.
 * Used by AudioSessionCoordinator to manage exclusive audio access.
 */
enum class AudioSource {
    TIMER,
    GUIDED_MEDITATION
}
