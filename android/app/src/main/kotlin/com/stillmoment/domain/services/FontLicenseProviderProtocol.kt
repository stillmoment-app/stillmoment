package com.stillmoment.domain.services

/**
 * Provides the license text of the fonts bundled with the app (SIL Open Font License 1.1).
 *
 * The text is the license file shipped alongside the fonts, not a copy kept in code.
 */
interface FontLicenseProviderProtocol {
    /** @return the complete license text, or null if it could not be read. */
    suspend fun loadLicenseText(): String?
}
