package com.stillmoment.infrastructure.audio

import android.content.Context
import android.net.Uri
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.MediaPlayerFactoryProtocol
import com.stillmoment.domain.services.MediaPlayerProtocol
import com.stillmoment.domain.services.ProgressSchedulerProtocol
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.MockedStatic
import org.mockito.Mockito
import org.mockito.kotlin.any
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

/**
 * Lock screen, media notification and headset controls for a guided meditation.
 *
 * The lock screen shows the trimmed range (shared-105): its position starts at 0 at the
 * trim start and its length is the effective (trimmed) length, not the whole file.
 */
class AudioPlayerServiceLockScreenTest {
    private lateinit var sut: AudioPlayerService
    private lateinit var mockMediaSessionManager: MediaSessionManager
    private lateinit var mockMediaPlayer: MediaPlayerProtocol
    private lateinit var mockProgressScheduler: ProgressSchedulerProtocol
    private lateinit var uriStatic: MockedStatic<Uri>

    /** 10-minute file, trimmed to play 1:00 – 9:00 (8 minutes audible). */
    private val trimmedMeditation =
        GuidedMeditation(
            fileUri = "file:///test/meditation.mp3",
            fileName = "meditation.mp3",
            duration = 600_000L,
            teacher = "Tara Brach",
            name = "Body Scan",
            trimStartMs = 60_000L,
            trimEndMs = 540_000L
        )

    @BeforeEach
    fun setUp() {
        mockMediaSessionManager = mock()
        mockMediaPlayer = mock()
        mockProgressScheduler = mock()
        val mockFactory: MediaPlayerFactoryProtocol = mock()
        whenever(mockFactory.create()).thenReturn(mockMediaPlayer)
        val mockCoordinator: AudioSessionCoordinatorProtocol = mock()
        whenever(mockCoordinator.requestAudioSession(any())).thenReturn(true)

        // Uri.parse is an Android stub; return a file URI so play(meditation) can run on the JVM.
        val fileUri: Uri = mock()
        whenever(fileUri.scheme).thenReturn("file")
        whenever(fileUri.path).thenReturn("/test/meditation.mp3")
        uriStatic = Mockito.mockStatic(Uri::class.java)
        uriStatic.`when`<Uri> { Uri.parse(any()) }.thenReturn(fileUri)

        val mockContext: Context = mock()
        sut =
            AudioPlayerService(
                mockContext,
                mockMediaSessionManager,
                mockCoordinator,
                mockFactory,
                mockProgressScheduler,
                mock<LoggerProtocol>()
            )
    }

    @AfterEach
    fun tearDown() {
        uriStatic.close()
    }

    /** Starts the trimmed meditation and lets the player reach the trim start. */
    private fun startPlaying() {
        sut.play(trimmedMeditation)
        val preparedCaptor = argumentCaptor<() -> Unit>()
        verify(mockMediaPlayer).setOnPreparedListener(preparedCaptor.capture())
        preparedCaptor.firstValue.invoke()
        val seekCompleteCaptor = argumentCaptor<() -> Unit>()
        verify(mockMediaPlayer).setOnSeekCompleteListener(seekCompleteCaptor.capture())
        seekCompleteCaptor.firstValue.invoke()
        whenever(mockMediaPlayer.isPlaying).thenReturn(true)
    }

    private fun lockScreenControls(): MediaSessionManager.MediaSessionCallback {
        val callbackCaptor = argumentCaptor<MediaSessionManager.MediaSessionCallback>()
        verify(mockMediaSessionManager).createSession(callbackCaptor.capture())
        return callbackCaptor.firstValue
    }

    @Nested
    inner class NowPlaying {
        @Test
        fun `playing a meditation shows its title and teacher on the lock screen`() {
            sut.play(trimmedMeditation)

            verify(mockMediaSessionManager).createSession(any())
            verify(mockMediaSessionManager).updateMetadata(trimmedMeditation)
        }

        @Test
        fun `lock screen starts at zero and shows the trimmed length`() {
            startPlaying()

            verify(mockMediaSessionManager).updatePlaybackState(
                isPlaying = true,
                position = 0L,
                duration = 480_000L
            )
        }

        @Test
        fun `lock screen progress counts from the trim start`() {
            startPlaying()
            val progressCaptor = argumentCaptor<() -> Unit>()
            verify(mockProgressScheduler).start(eq(500L), progressCaptor.capture())

            // 2:00 into the file = 1:00 into the trimmed meditation
            whenever(mockMediaPlayer.currentPosition).thenReturn(120_000)
            progressCaptor.firstValue.invoke()

            verify(mockMediaSessionManager).updatePlaybackState(
                isPlaying = true,
                position = 60_000L,
                duration = 480_000L
            )
        }
    }

    @Nested
    inner class Controls {
        @Test
        fun `pause on the lock screen pauses the meditation`() {
            startPlaying()

            lockScreenControls().onPause()

            verify(mockMediaPlayer).pause()
        }

        @Test
        fun `play on the lock screen resumes the paused meditation`() {
            startPlaying()
            lockScreenControls().onPause()
            whenever(mockMediaPlayer.isPlaying).thenReturn(false)

            lockScreenControls().onPlay()

            // once for the initial start, once for the resume
            verify(mockMediaPlayer, Mockito.times(2)).start()
        }

        @Test
        fun `seeking on the lock screen jumps to the chosen point of the trimmed meditation`() {
            startPlaying()

            // 0:30 on the lock screen = 1:30 in the file
            lockScreenControls().onSeekTo(30_000L)

            verify(mockMediaPlayer).seekTo(90_000)
        }

        @Test
        fun `stop on the lock screen stops the meditation`() {
            startPlaying()

            lockScreenControls().onStop()

            verify(mockMediaPlayer).release()
            verify(mockMediaSessionManager).release()
        }
    }

    @Nested
    inner class Ending {
        @Test
        fun `reaching the trim end removes the lock screen controls`() {
            startPlaying()
            val progressCaptor = argumentCaptor<() -> Unit>()
            verify(mockProgressScheduler).start(eq(500L), progressCaptor.capture())

            whenever(mockMediaPlayer.currentPosition).thenReturn(540_100)
            progressCaptor.firstValue.invoke()

            verify(mockMediaSessionManager).release()
        }

        @Test
        fun `reaching the file end removes the lock screen controls`() {
            startPlaying()
            val completionCaptor = argumentCaptor<() -> Unit>()
            verify(mockMediaPlayer).setOnCompletionListener(completionCaptor.capture())

            completionCaptor.firstValue.invoke()

            verify(mockMediaSessionManager).release()
        }

        @Test
        fun `pausing keeps the lock screen controls`() {
            startPlaying()

            sut.pause()

            verify(mockMediaSessionManager, never()).release()
        }
    }
}
