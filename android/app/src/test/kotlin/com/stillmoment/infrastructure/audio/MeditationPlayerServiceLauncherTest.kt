package com.stillmoment.infrastructure.audio

import android.content.Context
import com.stillmoment.domain.services.LoggerProtocol
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertDoesNotThrow
import org.mockito.kotlin.any
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

/**
 * Android refuses to start a foreground service while the app is in the background
 * (e.g. the start gong finished after the user left the app). The meditation must keep
 * playing; only the notification is missing.
 */
class MeditationPlayerServiceLauncherTest {
    @Test
    fun `a refused notification start does not stop the meditation`() {
        val context: Context = mock()
        whenever(context.startService(any())).thenThrow(IllegalStateException("not allowed in background"))
        whenever(context.startForegroundService(any())).thenThrow(IllegalStateException("not allowed in background"))
        val logger: LoggerProtocol = mock()
        val sut = MeditationPlayerServiceLauncher(context, logger)

        assertDoesNotThrow { sut.start() }

        verify(logger).w(eq("MeditationPlayerLauncher"), any())
    }
}
