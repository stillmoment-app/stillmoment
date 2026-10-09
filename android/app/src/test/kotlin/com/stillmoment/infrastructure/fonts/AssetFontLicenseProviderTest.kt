package com.stillmoment.infrastructure.fonts

import com.stillmoment.domain.services.LoggerProtocol
import java.io.File
import java.io.IOException
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify

/**
 * Tests for the font license shown on the "Font Attributions" screen (shared-136).
 *
 * The license text must be the file shipped with the app's fonts, read as-is — the OFL (§2)
 * requires the complete text to accompany the fonts.
 */
class AssetFontLicenseProviderTest {

    /** Opens files from the app's asset directory in the source tree (unit-test working dir = app module). */
    private val openAppAsset: (String) -> java.io.InputStream = { path ->
        File(APP_ASSETS_DIR, path).inputStream()
    }

    @Test
    fun `license text from app assets names both fonts at the start`() = runTest {
        val sut = AssetFontLicenseProvider(openAsset = openAppAsset, logger = mock())

        val text = sut.loadLicenseText()

        assertNotNull(text)
        val lines = requireNotNull(text).lines()
        assertTrue(lines[0].startsWith("Copyright 2020 The Newsreader Project Authors"), lines[0])
        assertTrue(lines[1].startsWith("Copyright 2024 The Geist Project Authors"), lines[1])
    }

    @Test
    fun `license text from app assets is complete up to the end of the disclaimer`() = runTest {
        val sut = AssetFontLicenseProvider(openAsset = openAppAsset, logger = mock())

        val text = requireNotNull(sut.loadLicenseText())

        assertTrue(text.contains("SIL OPEN FONT LICENSE Version 1.1"))
        assertTrue(text.trimEnd().endsWith("OTHER DEALINGS IN THE FONT SOFTWARE."))
    }

    @Test
    fun `unreadable license file yields no text and logs an error`() = runTest {
        val logger: LoggerProtocol = mock()
        val failure = IOException("asset missing")
        val sut = AssetFontLicenseProvider(openAsset = { throw failure }, logger = logger)

        val text = sut.loadLicenseText()

        assertNull(text)
        verify(logger).e(any(), any(), eq(failure))
    }

    private companion object {
        const val APP_ASSETS_DIR = "src/main/assets"
    }
}
