package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.MediaPlayerFactoryProtocol
import com.stillmoment.domain.services.MediaPlayerProtocol
import com.stillmoment.domain.services.VolumeAnimatorProtocol
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.atLeastOnce
import org.mockito.kotlin.clearInvocations
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

/**
 * Unit tests for AudioService.
 * Tests gong playback and background audio management.
 */
class AudioServiceTest {
    private lateinit var sut: AudioService
    private lateinit var mockCoordinator: AudioSessionCoordinatorProtocol
    private lateinit var mockMediaPlayerFactory: MediaPlayerFactoryProtocol
    private lateinit var mockVolumeAnimator: VolumeAnimatorProtocol
    private lateinit var mockMediaPlayer: MediaPlayerProtocol
    private lateinit var mockLogger: LoggerProtocol

    private lateinit var capturedConflictHandler: () -> Unit
    private lateinit var capturedPauseHandler: () -> Unit

    @BeforeEach
    fun setUp() {
        mockCoordinator = mock()
        mockMediaPlayerFactory = mock()
        mockVolumeAnimator = mock()
        mockMediaPlayer = mock()
        mockLogger = mock()

        // Capture handlers during registration
        val conflictCaptor = argumentCaptor<() -> Unit>()
        val pauseCaptor = argumentCaptor<() -> Unit>()

        whenever(mockCoordinator.requestAudioSession(any())).thenReturn(true)
        whenever(mockMediaPlayerFactory.createFromResource(any())).thenReturn(mockMediaPlayer)

        sut = AudioService(mockCoordinator, mockMediaPlayerFactory, mockVolumeAnimator, mockLogger)

        // Capture the registered handlers
        verify(mockCoordinator).registerConflictHandler(eq(AudioSource.TIMER), conflictCaptor.capture())
        verify(mockCoordinator).registerPauseHandler(eq(AudioSource.TIMER), pauseCaptor.capture())
        capturedConflictHandler = conflictCaptor.firstValue
        capturedPauseHandler = pauseCaptor.firstValue
    }

    // MARK: - Gong Playback Tests

    @Test
    fun `playGong creates media player from resource`() {
        // When
        sut.playGong()

        // Then
        verify(mockMediaPlayerFactory).createFromResource(any())
    }

    @Test
    fun `playGong starts the media player`() {
        // When
        sut.playGong()

        // Then
        verify(mockMediaPlayer).start()
    }

    @Test
    fun `playGong sets completion listener that releases player`() {
        // Given
        val listenerCaptor = argumentCaptor<() -> Unit>()

        // When
        sut.playGong()

        // Then
        verify(mockMediaPlayer).setOnCompletionListener(listenerCaptor.capture())

        // When: Completion callback fires
        listenerCaptor.firstValue.invoke()

        // Then: Player is released
        verify(mockMediaPlayer).release()
    }

    @Test
    fun `playIntervalGong creates media player from resource`() {
        // When
        sut.playIntervalGong()

        // Then
        verify(mockMediaPlayerFactory).createFromResource(any())
    }

    @Test
    fun `playIntervalGong starts the media player`() {
        // When
        sut.playIntervalGong()

        // Then
        verify(mockMediaPlayer).start()
    }

    // MARK: - Background Audio Tests

    @Test
    fun `startBackgroundAudio requests audio session`() {
        // When
        sut.startBackgroundAudio("forest")

        // Then
        verify(mockCoordinator).requestAudioSession(AudioSource.TIMER)
    }

    @Test
    fun `startBackgroundAudio does nothing when session denied`() {
        // Given
        whenever(mockCoordinator.requestAudioSession(any())).thenReturn(false)

        // When
        sut.startBackgroundAudio("forest")

        // Then: Factory should only be called from setUp, not from startBackgroundAudio
        verify(mockMediaPlayerFactory, never()).createFromResource(any())
    }

    @Test
    fun `startBackgroundAudio creates media player from resource`() {
        // When
        sut.startBackgroundAudio("forest")

        // Then
        verify(mockMediaPlayerFactory).createFromResource(any())
    }

    @Test
    fun `startBackgroundAudio sets looping and starts player`() {
        // When
        sut.startBackgroundAudio("forest")

        // Then
        verify(mockMediaPlayer).isLooping = true
        verify(mockMediaPlayer).setVolume(0f, 0f)
        verify(mockMediaPlayer).start()
    }

    @Test
    fun `startBackgroundAudio triggers fade in`() {
        // When
        sut.startBackgroundAudio("forest")

        // Then
        verify(mockVolumeAnimator).animate(eq(0f), eq(0.15f), eq(3000L), any())
    }

    @Test
    fun `stopBackgroundAudio cancels animation and releases session`() {
        // Given: Start background audio first
        sut.startBackgroundAudio("forest")
        clearInvocations(mockVolumeAnimator)

        // When
        sut.stopBackgroundAudio()

        // Then: cancel() is called twice (once in stopBackgroundAudio, once in stopBackgroundAudioInternal)
        verify(mockVolumeAnimator, atLeastOnce()).cancel()
        verify(mockCoordinator).releaseAudioSession(AudioSource.TIMER)
    }

    @Test
    fun `pauseBackgroundAudio cancels animation and pauses player`() {
        // Given: Start background audio first
        whenever(mockMediaPlayer.isPlaying).thenReturn(true)
        sut.startBackgroundAudio("forest")
        clearInvocations(mockVolumeAnimator, mockMediaPlayer)

        // When
        sut.pauseBackgroundAudio()

        // Then
        verify(mockVolumeAnimator).cancel()
        verify(mockMediaPlayer).pause()
    }

    @Test
    fun `resumeBackgroundAudio restarts and fades in`() {
        // Given: Start and pause background audio
        whenever(mockMediaPlayer.isPlaying).thenReturn(false)
        sut.startBackgroundAudio("forest")
        clearInvocations(mockMediaPlayer, mockVolumeAnimator)

        // When
        sut.resumeBackgroundAudio()

        // Then: Should set volume to 0, start, and fade in
        verify(mockMediaPlayer).setVolume(0f, 0f)
        verify(mockMediaPlayer).start()
    }

    @Test
    fun `isBackgroundAudioPlaying returns player playing state`() {
        // Given
        whenever(mockMediaPlayer.isPlaying).thenReturn(true)
        sut.startBackgroundAudio("forest")

        // When/Then
        assertTrue(sut.isBackgroundAudioPlaying())
    }

    @Test
    fun `isBackgroundAudioPlaying returns false when no player`() {
        // When/Then
        assertFalse(sut.isBackgroundAudioPlaying())
    }

    // MARK: - Conflict Handler Tests

    @Test
    fun `conflict handler stops background audio when invoked`() {
        // Given: Start background audio
        whenever(mockMediaPlayer.isPlaying).thenReturn(true)
        sut.startBackgroundAudio("forest")
        clearInvocations(mockVolumeAnimator, mockMediaPlayer)

        // When: Conflict handler is invoked
        capturedConflictHandler.invoke()

        // Then: Animation is cancelled and player is stopped
        verify(mockVolumeAnimator).cancel()
        verify(mockMediaPlayer).stop()
    }

    // MARK: - Pause Handler Tests

    @Test
    fun `pause handler pauses background audio when invoked`() {
        // Given: Start background audio
        whenever(mockMediaPlayer.isPlaying).thenReturn(true)
        sut.startBackgroundAudio("forest")

        // When: Pause handler is invoked
        capturedPauseHandler.invoke()

        // Then: Player is paused
        verify(mockMediaPlayer).pause()
    }

    // MARK: - Release Tests

    @Test
    fun `release stops all audio`() {
        // Given
        whenever(mockMediaPlayer.isPlaying).thenReturn(true)
        sut.playGong()
        sut.startBackgroundAudio("forest")

        // When
        sut.release()

        // Then
        verify(mockCoordinator).releaseAudioSession(AudioSource.TIMER)
    }
}
