package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.models.Introduction
import com.stillmoment.domain.models.ResolvedSoundscape
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.domain.repositories.SoundCatalogRepository
import com.stillmoment.domain.services.SoundscapeResolverProtocol
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Resolves soundscape IDs by checking the built-in catalog first, then custom audio imports.
 *
 * All consumers that need to resolve a soundscape ID should use this resolver
 * instead of directly calling [SoundCatalogRepository.findById] or [CustomAudioRepository.findFile].
 */
@Singleton
class SoundscapeResolver
@Inject
constructor(
    private val soundCatalogRepository: SoundCatalogRepository,
    private val customAudioRepository: CustomAudioRepository
) : SoundscapeResolverProtocol {

    override suspend fun resolve(id: String): ResolvedSoundscape? {
        resolveBuiltIn(id)?.let { return it }

        val customFile = customAudioRepository.findFile(id) ?: return null
        if (customFile.type != CustomAudioType.SOUNDSCAPE) return null
        return ResolvedSoundscape(
            id = customFile.id,
            name = customFile.name,
            isBuiltIn = false,
            isSilent = false
        )
    }

    override fun resolveBuiltIn(id: String): ResolvedSoundscape? {
        val sound = soundCatalogRepository.findById(id) ?: return null
        val language = Introduction.currentLanguage
        val name = if (language == "de") sound.nameGerman else sound.nameEnglish
        return ResolvedSoundscape(
            id = sound.id,
            name = name,
            isBuiltIn = true,
            isSilent = sound.isSilent
        )
    }
}
