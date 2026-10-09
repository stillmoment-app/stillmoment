package com.stillmoment.infrastructure.fonts

import android.content.Context
import com.stillmoment.domain.services.FontLicenseProviderProtocol
import com.stillmoment.domain.services.LoggerProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.IOException
import java.io.InputStream
import javax.inject.Inject
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Reads the SIL Open Font License shipped next to the bundled fonts (`assets/fonts/OFL.txt`).
 *
 * The file is read as-is so the app always shows the license that accompanies the fonts (shared-136).
 */
class AssetFontLicenseProvider(
    private val openAsset: (String) -> InputStream,
    private val logger: LoggerProtocol
) : FontLicenseProviderProtocol {

    @Inject
    constructor(
        @ApplicationContext context: Context,
        logger: LoggerProtocol
    ) : this(openAsset = { path -> context.assets.open(path) }, logger = logger)

    override suspend fun loadLicenseText(): String? = withContext(Dispatchers.IO) {
        try {
            openAsset(LICENSE_ASSET_PATH).bufferedReader(Charsets.UTF_8).use { it.readText() }
        } catch (e: IOException) {
            logger.e(TAG, "Failed to read font license from assets/$LICENSE_ASSET_PATH", e)
            null
        }
    }

    private companion object {
        const val TAG = "FontLicense"
        const val LICENSE_ASSET_PATH = "fonts/OFL.txt"
    }
}
