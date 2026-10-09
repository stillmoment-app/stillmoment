package com.stillmoment.domain.models

/**
 * A podcast episode resolved from an Apple Podcasts link (shared-128).
 *
 * Holds the raw values from Apple's lookup service; the domain rules for the
 * edit-sheet suggestions live here, not in the JSON parser.
 *
 * 1:1 counterpart of the iOS `PodcastEpisode`.
 *
 * @property audioUrl Address of the audio file at the podcast's provider
 * @property title Episode title (`trackName`)
 * @property podcastAuthor Author of the podcast (`artistName` of the podcast entry)
 * @property podcastName Name of the podcast (`collectionName`)
 */
data class PodcastEpisode(
    val audioUrl: String,
    val title: String?,
    val podcastAuthor: String?,
    val podcastName: String?
) {
    /** Teacher suggestion: the podcast author, otherwise the podcast name. Blank counts as missing. */
    val teacherSuggestion: String?
        get() = podcastAuthor.nonBlankTrimmed() ?: podcastName.nonBlankTrimmed()

    /**
     * Suggestion for the import edit sheet: episode title → name, teacher
     * suggestion → teacher. The title is only trimmed — additions like
     * "(20:34 Min.)" stay, the edit sheet is there to correct them.
     */
    fun importSuggestion(): ImportPrefill = ImportPrefill(
        teacher = teacherSuggestion,
        name = title.nonBlankTrimmed()
    )

    companion object {
        private const val HTTP_PREFIX = "http://"
        private const val HTTPS_PREFIX = "https://"

        /**
         * Android blocks cleartext traffic, so an `http://` episode address is
         * loaded via `https://` instead (same on iOS). Other addresses stay unchanged.
         */
        fun upgradeToHttps(url: String): String {
            return if (url.startsWith(HTTP_PREFIX)) HTTPS_PREFIX + url.removePrefix(HTTP_PREFIX) else url
        }
    }
}

private fun String?.nonBlankTrimmed(): String? = this?.trim()?.takeIf { it.isNotEmpty() }
