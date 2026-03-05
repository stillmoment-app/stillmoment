package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.models.Introduction
import com.stillmoment.domain.models.ResolvedAttunement
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.domain.services.AttunementResolverProtocol
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.runBlocking

/**
 * Infrastructure implementation of AttunementResolverProtocol.
 *
 * Transparently resolves attunement IDs by checking built-in introductions first
 * (filtered by current language), then falling back to user-imported custom attunements.
 *
 * Uses [runBlocking] internally because the resolver protocol is synchronous
 * (called from pure reducer functions that cannot suspend).
 */
@Singleton
class AttunementResolver @Inject constructor(
    private val customAudioRepository: CustomAudioRepository
) : AttunementResolverProtocol {

    override fun resolve(id: String): ResolvedAttunement? {
        // Try built-in introduction first (language-filtered)
        val intro = Introduction.find(id)
        if (intro != null && intro.availableLanguages.contains(Introduction.currentLanguage)) {
            return ResolvedAttunement(
                id = intro.id,
                displayName = intro.localizedName,
                durationSeconds = intro.durationSeconds
            )
        }

        // Try custom attunement
        val customFile = runBlocking { customAudioRepository.findFile(id) }
        if (customFile != null && customFile.type == CustomAudioType.ATTUNEMENT) {
            return ResolvedAttunement(
                id = customFile.id,
                displayName = customFile.name,
                durationSeconds = customFile.durationMs?.let { (it / 1000).toInt() } ?: 0
            )
        }

        return null
    }

    override fun allAvailable(): List<ResolvedAttunement> {
        // Built-in introductions for current language
        val builtIn = Introduction.availableForCurrentLanguage().map { intro ->
            ResolvedAttunement(
                id = intro.id,
                displayName = intro.localizedName,
                durationSeconds = intro.durationSeconds
            )
        }

        // Custom attunements
        val custom = runBlocking {
            customAudioRepository.loadAll(CustomAudioType.ATTUNEMENT)
        }.map { file ->
            ResolvedAttunement(
                id = file.id,
                displayName = file.name,
                durationSeconds = file.durationMs?.let { (it / 1000).toInt() } ?: 0
            )
        }

        return builtIn + custom
    }
}
