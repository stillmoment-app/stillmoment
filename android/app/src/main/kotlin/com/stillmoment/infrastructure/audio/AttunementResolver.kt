package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.models.Introduction
import com.stillmoment.domain.models.ResolvedAttunement
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.domain.services.AttunementResolverProtocol
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Resolves attunement IDs by checking the built-in catalog first, then custom audio imports.
 *
 * All consumers that need to resolve an attunement ID should use this resolver
 * instead of directly calling [Introduction.find] or [CustomAudioRepository.findFile].
 */
@Singleton
class AttunementResolver
@Inject
constructor(
    private val customAudioRepository: CustomAudioRepository
) : AttunementResolverProtocol {

    override suspend fun resolve(id: String): ResolvedAttunement? {
        resolveBuiltIn(id)?.let { return it }

        val customFile = customAudioRepository.findFile(id) ?: return null
        if (customFile.type != CustomAudioType.ATTUNEMENT) return null
        return ResolvedAttunement(
            id = customFile.id,
            name = customFile.name,
            durationSeconds = ((customFile.durationMs ?: 0L) / 1000).toInt(),
            isBuiltIn = false
        )
    }

    override fun resolveBuiltIn(id: String): ResolvedAttunement? {
        val intro = Introduction.find(id) ?: return null
        return ResolvedAttunement(
            id = intro.id,
            name = intro.localizedName,
            durationSeconds = intro.durationSeconds,
            isBuiltIn = true
        )
    }

    override fun isBuiltInAvailableForCurrentLanguage(id: String): Boolean {
        return Introduction.isAvailableForCurrentLanguage(id)
    }
}
