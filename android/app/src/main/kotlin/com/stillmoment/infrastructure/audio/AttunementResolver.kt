package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.Attunement
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.models.ResolvedAttunement
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.domain.services.AttunementResolverProtocol
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.runBlocking

/**
 * Infrastructure implementation of AttunementResolverProtocol.
 *
 * Transparently resolves attunement IDs by checking built-in attunements first
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
        // Try built-in attunement first (language-filtered)
        val attunement = Attunement.find(id)
        if (attunement != null && attunement.availableLanguages.contains(Attunement.currentLanguage)) {
            return ResolvedAttunement(
                id = attunement.id,
                displayName = attunement.localizedName,
                durationSeconds = attunement.durationSeconds
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
        // Built-in attunements for current language
        val builtIn = Attunement.availableForCurrentLanguage().map { item ->
            ResolvedAttunement(
                id = item.id,
                displayName = item.localizedName,
                durationSeconds = item.durationSeconds
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
