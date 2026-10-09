package com.stillmoment.infrastructure.network

import com.stillmoment.domain.models.PodcastEpisode
import com.stillmoment.domain.models.PodcastEpisodeResolveError
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.longOrNull

/**
 * Reads Apple's lookup answer (`itunes.apple.com/lookup?entity=podcastEpisode`)
 * and picks the shared episode (shared-128).
 *
 * Answer shape: `{"resultCount": n, "results": [...]}`. The podcast itself is the
 * entry with `wrapperType == "track"` and `kind == "podcast"` — its `trackId`
 * equals the podcast id, so only `podcastEpisode` entries are compared with
 * the episode id. Returns raw values; the teacher rule lives in [PodcastEpisode].
 *
 * Everything unexpected (missing results, episode missing, video, no audio
 * address) maps to [PodcastEpisodeResolveError.Unavailable]. Malformed JSON
 * throws [SerializationException]; the resolver logs it and maps it to
 * [PodcastEpisodeResolveError.Unavailable] as well.
 */
internal object ApplePodcastsLookupResponse {

    private const val WRAPPER_EPISODE = "podcastEpisode"
    private const val WRAPPER_TRACK = "track"
    private const val KIND_PODCAST = "podcast"
    private const val CONTENT_TYPE_VIDEO = "video"
    private val WEB_ADDRESS_PREFIXES = listOf("https://", "http://")

    @Throws(SerializationException::class)
    fun parse(json: String, episodeId: Long): Result<PodcastEpisode> {
        val results = parseResults(json) ?: return unavailable()
        val episode = results.firstOrNull { it.isEpisode() && it.long("trackId") == episodeId }
        val audioUrl = episode?.audioUrl() ?: return unavailable()
        val podcast = results.firstOrNull { it.isPodcast() }
        return Result.success(
            PodcastEpisode(
                audioUrl = audioUrl,
                title = episode.string("trackName"),
                podcastAuthor = podcast?.string("artistName"),
                podcastName = podcast?.string("collectionName")?.takeIf { it.isNotBlank() }
                    ?: episode.string("collectionName")
            )
        )
    }

    private fun parseResults(json: String): List<JsonObject>? {
        val root = Json.parseToJsonElement(json)
        val results = (root as? JsonObject)?.get("results") as? JsonArray ?: return null
        return results.mapNotNull { it as? JsonObject }
    }

    private fun unavailable(): Result<PodcastEpisode> = Result.failure(PodcastEpisodeResolveError.Unavailable)

    private fun JsonObject.isEpisode() = string("wrapperType") == WRAPPER_EPISODE

    private fun JsonObject.isPodcast() = string("wrapperType") == WRAPPER_TRACK && string("kind") == KIND_PODCAST

    /** Audio address of an audio episode; `null` for video or a missing/non-web address. */
    private fun JsonObject.audioUrl(): String? {
        if (string("episodeContentType").equals(CONTENT_TYPE_VIDEO, ignoreCase = true)) {
            return null
        }
        return string("episodeUrl")?.takeIf { url -> WEB_ADDRESS_PREFIXES.any { url.startsWith(it) } }
    }

    private fun JsonObject.primitive(key: String): JsonPrimitive? = get(key) as? JsonPrimitive

    private fun JsonObject.string(key: String): String? = primitive(key)?.contentOrNull

    private fun JsonObject.long(key: String): Long? = primitive(key)?.longOrNull
}
