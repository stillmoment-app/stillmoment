package com.stillmoment.testutil

import com.stillmoment.domain.models.ResolvedAttunement
import com.stillmoment.domain.services.AttunementResolverProtocol

/**
 * Test mock for AttunementResolverProtocol.
 *
 * Returns pre-configured results for resolve() and allAvailable().
 */
class MockAttunementResolver(
    private val resolveResult: Map<String, ResolvedAttunement> = emptyMap(),
    private val allAvailableResult: List<ResolvedAttunement> = emptyList()
) : AttunementResolverProtocol {
    override fun resolve(id: String): ResolvedAttunement? = resolveResult[id]
    override fun allAvailable(): List<ResolvedAttunement> = allAvailableResult
}
