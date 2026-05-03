package com.stillmoment.data.repositories

import android.content.Context
import com.stillmoment.domain.models.MeditationSource
import com.stillmoment.domain.repositories.MeditationSourceRepository
import com.stillmoment.domain.services.LoggerProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json

@Serializable
internal data class MeditationSourceDto(
    val id: String,
    val name: String,
    val author: String? = null,
    val description: String,
    val host: String,
    val url: String
) {
    fun toDomainOrNull(): MeditationSource? {
        if (!url.startsWith("http")) return null
        val cleanedAuthor = author?.trim().takeUnless { it.isNullOrEmpty() }
        return MeditationSource(
            id = id,
            name = name,
            author = cleanedAuthor,
            description = description,
            host = host,
            url = url
        )
    }
}

/**
 * Implementation of [MeditationSourceRepository].
 *
 * Reads curated sources from `assets/meditation_sources.json`. The JSON is keyed
 * by language code (`"de"`, `"en"`). Missing or unparseable files fall back to an
 * empty list so the Content Guide remains functional but unobtrusive.
 */
@Singleton
class MeditationSourceRepositoryImpl
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val logger: LoggerProtocol
) : MeditationSourceRepository {

    private val catalog: Map<String, List<MeditationSource>> by lazy {
        try {
            val jsonString = context.assets
                .open(SOURCES_JSON_PATH)
                .bufferedReader()
                .use { it.readText() }
            parseSourcesJson(jsonString)
        } catch (e: IOException) {
            logger.e(TAG, "Failed to read meditation_sources.json", e)
            emptyMap()
        } catch (e: SerializationException) {
            logger.e(TAG, "Failed to parse meditation_sources.json", e)
            emptyMap()
        }
    }

    override fun sources(languageCode: String): List<MeditationSource> {
        return catalog[languageCode] ?: catalog["en"].orEmpty()
    }

    companion object {
        private const val TAG = "MeditationSources"
        private const val SOURCES_JSON_PATH = "meditation_sources.json"

        private val json = Json { ignoreUnknownKeys = true }

        /**
         * Parses the meditation_sources.json content.
         * Exposed for unit testing without Android Context.
         */
        fun parseSourcesJson(jsonString: String): Map<String, List<MeditationSource>> {
            val raw = json.decodeFromString<Map<String, List<MeditationSourceDto>>>(jsonString)
            return raw.mapValues { (_, list) -> list.mapNotNull { it.toDomainOrNull() } }
        }
    }
}
