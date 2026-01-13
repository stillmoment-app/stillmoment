package com.stillmoment.infrastructure.audio

import android.content.Context
import android.net.Uri
import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.MediaPlayerFactoryProtocol
import com.stillmoment.domain.services.MediaPlayerProtocol
import com.stillmoment.domain.services.PlaybackState
import com.stillmoment.domain.services.ProgressSchedulerProtocol
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

/** Creates a mock Uri with the given scheme and path */
private fun mockUri(scheme: String, path: String): Uri {
    val uri = mock<Uri>()
    whenever(uri.scheme).thenReturn(scheme)
    whenever(uri.path).thenReturn(path)
    whenever(uri.toString()).thenReturn("$scheme://$path")
    return uri
}

/**
 * Unit tests for AudioPlayerService.
 * Tests guided meditation playback with MediaPlayer abstraction.
 */
class AudioPlayerServiceTest {
    private lateinit var sut: AudioPlayerService
    private lateinit var mockContext: Context
    private lateinit var mockMediaSessionManager: MediaSessionManager
    private lateinit var mockCoordinator: AudioSessionCoordinatorProtocol
    private lateinit var mockMediaPlayerFactory: MediaPlayerFactoryProtocol
    private lateinit var mockProgressScheduler: ProgressSchedulerProtocol
    private lateinit var mockMediaPlayer: MediaPlayerProtocol
    private lateinit var mockLogger: LoggerProtocol

    private lateinit var capturedConflictHandler: () -> Unit
    private lateinit var capturedPauseHandler: () -> Unit

    @BeforeEach
    fun setUp() {
        mockContext = mock()
        mockMediaSessionManager = mock()
        mockCoordinator = mock()
        mockMediaPlayerFactory = mock()
        mockProgressScheduler = mock()
        mockMediaPlayer = mock()
        mockLogger = mock()

        whenever(mockCoordinator.requestAudioSession(any())).thenReturn(true)
        whenever(mockMediaPlayerFactory.create()).thenReturn(mockMediaPlayer)

        // Capture handlers during registration
        val conflictCaptor = argumentCaptor<() -> Unit>()
        val pauseCaptor = argumentCaptor<() -> Unit>()

        sut = AudioPlayerService(
            mockContext,
            mockMediaSessionManager,
            mockCoordinator,
            mockMediaPlayerFactory,
            mockProgressScheduler,
            mockLogger
        )

        // Capture the registered handlers
        verify(mockCoordinator).registerConflictHandler(eq(AudioSource.GUIDED_MEDITATION), conflictCaptor.capture())
        verify(mockCoordinator).registerPauseHandler(eq(AudioSource.GUIDED_MEDITATION), pauseCaptor.capture())
        capturedConflictHandler = conflictCaptor.firstValue
        capturedPauseHandler = pauseCaptor.firstValue
    }

    // MARK: - Initial State Tests

    @Test
    fun `initial playback state is not playing`() = runTest {
        // When/Then
        val state = sut.playbackState.first()
        assertFalse(state.isPlaying)
        assertEquals(0L, state.currentPosition)
        assertEquals(0L, state.duration)
        assertNull(state.error)
    }

    @Test
    fun `initial currentMeditation is null`() {
        // When/Then
        assertNull(sut.currentMeditation)
    }

    // MARK: - Play Tests

    @Test
    fun `play creates media player from factory`() {
        // Given
        val uri = mockUri("file", "/test/audio.mp3")

        // When
        sut.play(uri, 60000L)

        // Then
        verify(mockMediaPlayerFactory).create()
    }

    @Test
    fun `play sets data source for file URI`() {
        // Given
        val uri = mockUri("file", "/test/audio.mp3")

        // When
        sut.play(uri, 60000L)

        // Then
        verify(mockMediaPlayer).setDataSource("/test/audio.mp3")
    }

    @Test
    fun `play prepares player asynchronously`() {
        // Given
        val uri = mockUri("file", "/test/audio.mp3")

        // When
        sut.play(uri, 60000L)

        // Then
        verify(mockMediaPlayer).prepareAsync()
    }

    @Test
    fun `play sets error for unsupported URI scheme`() = runTest {
        // Given
        val uri = mockUri("http", "example.com/audio.mp3")

        // When
        sut.play(uri, 60000L)

        // Then
        val state = sut.playbackState.first()
        assertFalse(state.isPlaying)
        assertEquals("Unsupported file type", state.error)
    }

    // MARK: - Pause Tests

    @Test
    fun `pause pauses playing media player`() {
        // Given
        whenever(mockMediaPlayer.isPlaying).thenReturn(true)
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)

        // When
        sut.pause()

        // Then
        verify(mockMediaPlayer).pause()
    }

    @Test
    fun `pause stops progress updates`() {
        // Given
        whenever(mockMediaPlayer.isPlaying).thenReturn(true)
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)

        // When
        sut.pause()

        // Then
        verify(mockProgressScheduler).stop()
    }

    @Test
    fun `pause updates playback state to not playing`() = runTest {
        // Given
        whenever(mockMediaPlayer.isPlaying).thenReturn(true)
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)

        // When
        sut.pause()

        // Then
        val state = sut.playbackState.first()
        assertFalse(state.isPlaying)
    }

    // MARK: - Resume Tests

    @Test
    fun `resume starts paused media player`() {
        // Given
        whenever(mockMediaPlayer.isPlaying).thenReturn(false)
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)

        // When
        sut.resume()

        // Then
        verify(mockMediaPlayer).start()
    }

    @Test
    fun `resume starts progress updates`() {
        // Given
        whenever(mockMediaPlayer.isPlaying).thenReturn(false)
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)

        // When
        sut.resume()

        // Then
        verify(mockProgressScheduler).start(eq(500L), any())
    }

    // MARK: - Seek Tests

    @Test
    fun `seekTo seeks media player to position`() {
        // Given
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)

        // When
        sut.seekTo(30000L)

        // Then
        verify(mockMediaPlayer).seekTo(30000)
    }

    @Test
    fun `seekTo updates playback state position`() = runTest {
        // Given
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)

        // When
        sut.seekTo(30000L)

        // Then
        val state = sut.playbackState.first()
        assertEquals(30000L, state.currentPosition)
    }

    // MARK: - Stop Tests

    @Test
    fun `stop stops and releases media player`() {
        // Given
        whenever(mockMediaPlayer.isPlaying).thenReturn(true)
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)

        // When
        sut.stop()

        // Then
        verify(mockMediaPlayer).stop()
        verify(mockMediaPlayer).release()
    }

    @Test
    fun `stop releases audio session`() {
        // Given
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)

        // When
        sut.stop()

        // Then
        verify(mockCoordinator).releaseAudioSession(AudioSource.GUIDED_MEDITATION)
    }

    @Test
    fun `stop releases media session`() {
        // Given
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)

        // When
        sut.stop()

        // Then
        verify(mockMediaSessionManager).release()
    }

    @Test
    fun `stop resets playback state`() = runTest {
        // Given
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)

        // When
        sut.stop()

        // Then
        val state = sut.playbackState.first()
        assertEquals(PlaybackState(), state)
    }

    // MARK: - Completion Listener Tests

    @Test
    fun `setOnCompletionListener stores callback`() {
        // Given
        var callbackCalled = false

        // When
        sut.setOnCompletionListener { callbackCalled = true }

        // Then: Callback is stored (will be invoked on completion)
        assertFalse(callbackCalled) // Not called yet
    }

    // MARK: - Prepared Listener Tests

    @Test
    fun `onPrepared starts playback and updates state`() = runTest {
        // Given
        val preparedCaptor = argumentCaptor<() -> Unit>()
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)
        verify(mockMediaPlayer).setOnPreparedListener(preparedCaptor.capture())

        // When: Prepared callback fires
        preparedCaptor.firstValue.invoke()

        // Then
        verify(mockMediaPlayer).start()
        val state = sut.playbackState.first()
        assertTrue(state.isPlaying)
        assertEquals(60000L, state.duration)
    }

    @Test
    fun `onPrepared starts progress updates`() {
        // Given
        val preparedCaptor = argumentCaptor<() -> Unit>()
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)
        verify(mockMediaPlayer).setOnPreparedListener(preparedCaptor.capture())

        // When: Prepared callback fires
        preparedCaptor.firstValue.invoke()

        // Then
        verify(mockProgressScheduler).start(eq(500L), any())
    }

    // MARK: - Error Listener Tests

    @Test
    fun `onError sets error state`() = runTest {
        // Given
        val errorCaptor = argumentCaptor<(Int, Int) -> Boolean>()
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)
        verify(mockMediaPlayer).setOnErrorListener(errorCaptor.capture())

        // When: Error callback fires
        val handled = errorCaptor.firstValue.invoke(1, 0)

        // Then
        assertTrue(handled)
        val state = sut.playbackState.first()
        assertFalse(state.isPlaying)
        assertNotNull(state.error)
    }

    // MARK: - Conflict Handler Tests

    @Test
    fun `conflict handler stops playback when invoked`() {
        // Given: Start playback
        whenever(mockMediaPlayer.isPlaying).thenReturn(true)
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)

        // When: Conflict handler is invoked
        capturedConflictHandler.invoke()

        // Then: Player is stopped
        verify(mockMediaPlayer).stop()
        verify(mockMediaPlayer).release()
    }

    // MARK: - Pause Handler Tests

    @Test
    fun `pause handler pauses playback when invoked`() {
        // Given: Start playback
        whenever(mockMediaPlayer.isPlaying).thenReturn(true)
        val uri = mockUri("file", "/test/audio.mp3")
        sut.play(uri, 60000L)

        // When: Pause handler is invoked
        capturedPauseHandler.invoke()

        // Then: Player is paused
        verify(mockMediaPlayer).pause()
    }
}
