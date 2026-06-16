package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.MediaPlayerFactoryProtocol
import com.stillmoment.domain.services.MediaPlayerProtocol
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

/**
 * Unit tests for [MeditationGongPlayer] (shared-106).
 *
 * The player rings the per-meditation start/end gong through the
 * [MediaPlayerFactoryProtocol], at the requested volume, and reports completion.
 * It never touches the audio session (that stays with AudioPlayerService), so
 * these tests only cover playback, volume and completion behaviour.
 */
class MeditationGongPlayerTest {
    private lateinit var mockFactory: MediaPlayerFactoryProtocol
    private lateinit var mockPlayer: MediaPlayerProtocol
    private lateinit var mockLogger: LoggerProtocol
    private lateinit var sut: MeditationGongPlayer

    @BeforeEach
    fun setUp() {
        mockFactory = mock()
        mockPlayer = mock()
        mockLogger = mock()
        whenever(mockFactory.createFromResource(any())).thenReturn(mockPlayer)
        sut = MeditationGongPlayer(mockFactory, mockLogger)
    }

    @Test
    fun `play creates a media player from the gong resource and starts it`() {
        // When
        sut.play(GongSound.DEFAULT_SOUND_ID, volume = 1.0f) {}

        // Then
        verify(mockFactory).createFromResource(any())
        verify(mockPlayer).start()
    }

    @Test
    fun `play applies the requested volume`() {
        // When
        sut.play(GongSound.DEFAULT_SOUND_ID, volume = 0.5f) {}

        // Then
        verify(mockPlayer).setVolume(eq(0.5f), eq(0.5f))
    }

    @Test
    fun `completion callback fires once the gong finishes playing`() {
        // Given
        var completed = false
        val listenerCaptor = argumentCaptor<() -> Unit>()

        // When
        sut.play(GongSound.DEFAULT_SOUND_ID, volume = 1.0f) { completed = true }
        verify(mockPlayer).setOnCompletionListener(listenerCaptor.capture())
        // Simulate the gong finishing
        listenerCaptor.firstValue.invoke()

        // Then
        assertTrue(completed)
    }

    @Test
    fun `completion callback still fires when player creation fails`() {
        // Given - factory cannot create a player (e.g. resource missing)
        whenever(mockFactory.createFromResource(any())).thenReturn(null)
        var completed = false

        // When
        sut.play(GongSound.DEFAULT_SOUND_ID, volume = 1.0f) { completed = true }

        // Then - callers can still rely on completion to continue their flow
        assertTrue(completed)
        verify(mockPlayer, never()).start()
    }

    @Test
    fun `completion callback still fires and player is released when start throws`() {
        // Given - the created player rejects start() with an invalid state
        whenever(mockPlayer.start()).thenThrow(IllegalStateException("not prepared"))
        var completed = false

        // When
        sut.play(GongSound.DEFAULT_SOUND_ID, volume = 1.0f) { completed = true }

        // Then - completion still fires (the only trigger for session release after
        // the end gong) and the half-created player is released, not leaked.
        assertTrue(completed)
        verify(mockPlayer).release()
    }

    @Test
    fun `stop does not fire the pending completion callback`() {
        // Given
        var completed = false
        whenever(mockPlayer.isPlaying).thenReturn(true)
        sut.play(GongSound.DEFAULT_SOUND_ID, volume = 1.0f) { completed = true }

        // When
        sut.stop()

        // Then - stop drops the completion (documented), like iOS' AVAudioPlayer.stop()
        assertTrue(!completed)
        verify(mockPlayer).release()
    }
}
