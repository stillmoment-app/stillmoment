package com.stillmoment.infrastructure.audio

import android.content.Context
import com.stillmoment.domain.models.GuidedMeditation
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * Unit tests for MediaSessionManager without an active session.
 *
 * Creating a Media3 session needs a real Android runtime; the session's behaviour
 * (lock screen, notification, headset buttons) is covered by AudioPlayerServiceLockScreenTest
 * against the manager's contract and verified on a device.
 */
class MediaSessionManagerTest {
    private lateinit var sut: MediaSessionManager

    @BeforeEach
    fun setUp() {
        sut = MediaSessionManager(mock<Context>())
    }

    @Test
    fun `no lock screen session before a meditation starts`() {
        assertNull(sut.mediaSession)
    }

    @Test
    fun `updates without a session are ignored`() {
        sut.updateMetadata(
            GuidedMeditation(
                fileUri = "file:///test/meditation.mp3",
                fileName = "meditation.mp3",
                duration = 600_000L,
                teacher = "Test Teacher",
                name = "Test Meditation"
            )
        )
        sut.updatePlaybackState(isPlaying = true, position = 0L, duration = 600_000L)
        sut.release()

        assertNull(sut.mediaSession)
    }
}
