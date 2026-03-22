package com.stillmoment.domain.models

/**
 * The type of audio file selected during the file import flow.
 * Determines how a shared audio file is imported and where it appears in the app.
 */
enum class ImportAudioType {
    /** Import as guided meditation into the library */
    GUIDED_MEDITATION,

    /** Import as custom soundscape (background loop) */
    SOUNDSCAPE,

    /** Import as custom attunement (one-shot attunement) */
    ATTUNEMENT
}
