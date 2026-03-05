package com.stillmoment.testutil

import com.stillmoment.domain.models.ResolvedSoundscape
import com.stillmoment.domain.services.SoundscapeResolverProtocol

/**
 * Test mock for SoundscapeResolverProtocol.
 *
 * Returns pre-configured results for resolve() and allAvailable().
 */
class MockSoundscapeResolver(
    private val resolveResult: Map<String, ResolvedSoundscape> = emptyMap(),
    private val allAvailableResult: List<ResolvedSoundscape> = emptyList()
) : SoundscapeResolverProtocol {
    override fun resolve(id: String): ResolvedSoundscape? = resolveResult[id]
    override fun allAvailable(): List<ResolvedSoundscape> = allAvailableResult
}
