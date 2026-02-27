package com.stillmoment.data.repositories

import android.content.Context
import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.repositories.SoundCatalogRepository
import com.stillmoment.domain.services.LoggerProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json

@Serializable
internal data class SoundNameDto(
    val en: String,
    val de: String
)

@Serializable
internal data class SoundDescriptionDto(
    val en: String,
    val de: String
)

@Serializable
internal data class SoundEntryDto(
    val id: String,
    val filename: String,
    val name: SoundNameDto,
    val description: SoundDescriptionDto,
    @SerialName("iconName") val iconName: String = "",
    val volume: Double = 0.15
) {
    fun toBackgroundSound(): BackgroundSound {
        val rawResourceName = if (id == BackgroundSound.SILENT_ID) {
            ""
        } else {
            filename.substringBeforeLast(".").replace("-", "_")
        }
        return BackgroundSound(
            id = id,
            nameEnglish = name.en,
            nameGerman = name.de,
            descriptionEnglish = description.en,
            descriptionGerman = description.de,
            rawResourceName = rawResourceName
        )
    }
}

@Serializable
internal data class SoundCatalogDto(
    val sounds: List<SoundEntryDto>
)

/**
 * Implementation of SoundCatalogRepository.
 *
 * Reads background sounds from a `sounds.json` asset file, parsing it with
 * kotlinx.serialization. Falls back to a minimal hardcoded catalog (silent + forest)
 * if the JSON file cannot be loaded or parsed.
 */
@Singleton
class SoundCatalogRepositoryImpl
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val logger: LoggerProtocol
) : SoundCatalogRepository {

    private val sounds: List<BackgroundSound> by lazy {
        try {
            val jsonString = context.assets.open(SOUNDS_JSON_PATH).bufferedReader().use { it.readText() }
            parseSoundsJson(jsonString)
        } catch (e: IOException) {
            logger.e(TAG, "Failed to read sounds.json from assets, using fallback catalog", e)
            FALLBACK_SOUNDS
        } catch (e: SerializationException) {
            logger.e(TAG, "Failed to parse sounds.json, using fallback catalog", e)
            FALLBACK_SOUNDS
        }
    }

    override fun getAllSounds(): List<BackgroundSound> = sounds

    override fun findById(id: String): BackgroundSound? = sounds.find { it.id == id }

    override fun findByIdOrDefault(id: String): BackgroundSound = findById(id) ?: sounds.first()

    companion object {
        private const val TAG = "SoundCatalog"
        private const val SOUNDS_JSON_PATH = "sounds.json"

        private val json = Json { ignoreUnknownKeys = true }

        private val FALLBACK_SOUNDS = listOf(
            BackgroundSound(
                id = BackgroundSound.SILENT_ID,
                nameEnglish = "Silence",
                nameGerman = "Stille",
                descriptionEnglish = "Meditate in silence.",
                descriptionGerman = "Meditiere in Stille.",
                rawResourceName = ""
            ),
            BackgroundSound(
                id = "forest",
                nameEnglish = "Forest Ambience",
                nameGerman = "Waldatmosph\u00e4re",
                descriptionEnglish = "Natural forest sounds",
                descriptionGerman = "Nat\u00fcrliche Waldger\u00e4usche",
                rawResourceName = "forest_ambience"
            )
        )

        /**
         * Parses the sounds.json content into a list of BackgroundSound.
         * Exposed for unit testing without Android Context.
         */
        fun parseSoundsJson(json: String): List<BackgroundSound> {
            val catalog = this.json.decodeFromString<SoundCatalogDto>(json)
            return catalog.sounds.map { it.toBackgroundSound() }
        }
    }
}
