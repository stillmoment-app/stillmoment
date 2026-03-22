package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.Attunement
import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.models.ResolvedSoundscape
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.domain.repositories.SoundCatalogRepository
import com.stillmoment.domain.services.SoundscapeResolverProtocol
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.runBlocking

/**
 * Infrastructure implementation of SoundscapeResolverProtocol.
 *
 * Transparently resolves soundscape IDs by checking the built-in sound catalog first,
 * then falling back to user-imported custom soundscapes. The special "silent" ID
 * returns null (no sound to resolve).
 *
 * Uses [runBlocking] internally because the resolver protocol is synchronous
 * (called from pure reducer functions that cannot suspend).
 */
@Singleton
class SoundscapeResolver @Inject constructor(
    private val soundCatalogRepository: SoundCatalogRepository,
    private val customAudioRepository: CustomAudioRepository
) : SoundscapeResolverProtocol {

    override fun resolve(id: String): ResolvedSoundscape? {
        if (id == BackgroundSound.SILENT_ID) return null

        // Try built-in sound
        val sound = soundCatalogRepository.findById(id)
        if (sound != null) {
            return ResolvedSoundscape(
                id = sound.id,
                displayName = localizedSoundName(sound)
            )
        }

        // Try custom soundscape
        val customFile = runBlocking { customAudioRepository.findFile(id) }
        if (customFile != null && customFile.type == CustomAudioType.SOUNDSCAPE) {
            return ResolvedSoundscape(
                id = customFile.id,
                displayName = customFile.name
            )
        }

        return null
    }

    override fun allAvailable(): List<ResolvedSoundscape> {
        // Built-in sounds (excluding silent)
        val builtIn = soundCatalogRepository.getAllSounds()
            .filter { it.id != BackgroundSound.SILENT_ID }
            .map { sound ->
                ResolvedSoundscape(
                    id = sound.id,
                    displayName = localizedSoundName(sound)
                )
            }

        // Custom soundscapes
        val custom = runBlocking {
            customAudioRepository.loadAll(CustomAudioType.SOUNDSCAPE)
        }.map { file ->
            ResolvedSoundscape(
                id = file.id,
                displayName = file.name
            )
        }

        return builtIn + custom
    }

    private fun localizedSoundName(sound: BackgroundSound): String {
        val language = Attunement.currentLanguage
        return if (language == "de") sound.nameGerman else sound.nameEnglish
    }
}
