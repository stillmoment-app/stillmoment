package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.domain.repositories.SoundCatalogRepository
import com.stillmoment.domain.services.AudioSessionCoordinatorProtocol
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.MediaPlayerFactoryProtocol
import com.stillmoment.domain.services.MediaPlayerProtocol
import com.stillmoment.domain.services.VibrationServiceProtocol
import com.stillmoment.domain.services.VolumeAnimatorProtocol
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.doThrow
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

/**
 * A sound of the timer session that cannot be played is reported via
 * [AudioService.timerSoundFailedFlow], so the timer can show a calm message.
 *
 * The report is the only addition: the service still logs and carries on exactly as
 * before (no exception escapes, no extra stop, the session request is unchanged).
 * Previews never report.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class AudioServiceTimerSoundFailureTest {
    private val testDispatcher = StandardTestDispatcher()

    private lateinit var sut: AudioService
    private lateinit var coordinator: AudioSessionCoordinatorProtocol
    private lateinit var factory: MediaPlayerFactoryProtocol
    private lateinit var player: MediaPlayerProtocol
    private lateinit var logger: LoggerProtocol
    private lateinit var vibration: VibrationServiceProtocol

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        coordinator = mock()
        factory = mock()
        player = mock()
        logger = mock()
        vibration = mock()
        val soundCatalog: SoundCatalogRepository = mock()
        val customAudio: CustomAudioRepository = mock()

        whenever(coordinator.requestAudioSession(any())).thenReturn(true)
        whenever(factory.createFromResource(any())).thenReturn(player)
        whenever(factory.create()).thenReturn(player)
        whenever(soundCatalog.findById("forest")).thenReturn(
            BackgroundSound(
                id = "forest",
                nameEnglish = "Forest Ambience",
                nameGerman = "Waldatmosphäre",
                descriptionEnglish = "Natural forest sounds",
                descriptionGerman = "Natürliche Waldgeräusche",
                rawResourceName = "forest_ambience"
            )
        )

        sut = AudioService(
            coordinator,
            factory,
            mock<VolumeAnimatorProtocol>(),
            logger,
            customAudio,
            soundCatalog,
            vibration
        )
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    /** Counts reports while the test runs. */
    private fun TestScope.collectReports(): () -> Int {
        var reports = 0
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) {
            sut.timerSoundFailedFlow.collect { reports++ }
        }
        return { reports }
    }

    private fun playerCannotBeCreated() {
        whenever(factory.createFromResource(any())).thenReturn(null)
    }

    private fun playerFailsToStart() {
        doThrow(IllegalStateException("broken")).whenever(player).start()
    }

    @Nested
    inner class StartAndEndGong {
        @Test
        fun `gong that cannot be loaded is reported`() = runTest {
            val reports = collectReports()
            playerCannotBeCreated()

            sut.playGong("classic-bowl", 1.0f)

            assertEquals(1, reports())
            verify(logger).e(any(), any())
        }

        @Test
        fun `gong that fails to start is reported and logged, without crashing`() = runTest {
            val reports = collectReports()
            playerFailsToStart()

            sut.playGong("classic-bowl", 1.0f)

            assertEquals(1, reports())
            verify(logger).e(any(), any())
        }

        @Test
        fun `gong that plays is not reported`() = runTest {
            val reports = collectReports()

            sut.playGong("classic-bowl", 1.0f)

            assertEquals(0, reports())
            verify(player).start()
        }

        @Test
        fun `vibration instead of a gong is not reported`() = runTest {
            val reports = collectReports()

            sut.playGong(GongSound.VIBRATION_ID, 1.0f)

            assertEquals(0, reports())
            verify(vibration).vibrate()
        }
    }

    @Nested
    inner class IntervalGong {
        @Test
        fun `interval gong during the timer that fails is reported`() = runTest {
            val reports = collectReports()
            playerFailsToStart()

            sut.playTimerIntervalGong("temple-bell", 1.0f)

            assertEquals(1, reports())
        }

        @Test
        fun `interval gong during the timer that cannot be loaded is reported`() = runTest {
            val reports = collectReports()
            playerCannotBeCreated()

            sut.playTimerIntervalGong("temple-bell", 1.0f)

            assertEquals(1, reports())
        }

        @Test
        fun `interval gong during the timer that plays is not reported`() = runTest {
            val reports = collectReports()

            sut.playTimerIntervalGong("temple-bell", 1.0f)

            assertEquals(0, reports())
            verify(player).start()
        }

        @Test
        fun `interval gong preview in the settings that fails is not reported`() = runTest {
            val reports = collectReports()
            playerFailsToStart()

            sut.playIntervalGong("temple-bell", 1.0f)

            assertEquals(0, reports())
        }
    }

    @Nested
    inner class BackgroundSoundPlayback {
        @Test
        fun `background sound that cannot be loaded is reported`() = runTest {
            val reports = collectReports()
            playerCannotBeCreated()

            sut.startBackgroundAudio("forest", 0.5f)

            assertEquals(1, reports())
        }

        @Test
        fun `background sound that fails to start is reported`() = runTest {
            val reports = collectReports()
            playerFailsToStart()

            sut.startBackgroundAudio("forest", 0.5f)

            assertEquals(1, reports())
        }

        @Test
        fun `background sound that plays is not reported`() = runTest {
            val reports = collectReports()

            sut.startBackgroundAudio("forest", 0.5f)

            assertEquals(0, reports())
            verify(player).start()
        }

        @Test
        fun `own soundscape that fails while loading is reported`() = runTest {
            val reports = collectReports()
            val errorListener = argumentCaptor<(Int, Int) -> Boolean>()

            sut.startBackgroundAudioFromFile("/data/own.mp3", 0.5f)
            verify(player).setOnErrorListener(errorListener.capture())
            errorListener.firstValue.invoke(1, -1004)

            assertEquals(1, reports())
        }

        @Test
        fun `own soundscape that cannot be opened is reported`() = runTest {
            val reports = collectReports()
            doThrow(IllegalStateException("broken")).whenever(player).setDataSource(any())

            sut.startBackgroundAudioFromFile("/data/own.mp3", 0.5f)

            assertEquals(1, reports())
        }

        @Test
        fun `own soundscape that loads is not reported`() = runTest {
            val reports = collectReports()

            sut.startBackgroundAudioFromFile("/data/own.mp3", 0.5f)

            assertEquals(0, reports())
            verify(player).prepareAsync()
        }

        @Test
        fun `missing own soundscape reported by the timer service is passed on`() = runTest {
            val reports = collectReports()

            sut.reportTimerSoundFailed()

            assertEquals(1, reports())
        }
    }

    @Nested
    inner class AudioSession {
        @Test
        fun `audio that cannot be prepared is reported and nothing is played`() = runTest {
            val reports = collectReports()
            whenever(coordinator.requestAudioSession(AudioSource.TIMER)).thenReturn(false)

            sut.startBackgroundAudio("forest", 0.5f)

            assertEquals(1, reports())
            verify(factory, never()).createFromResource(any())
        }

        @Test
        fun `audio for an own soundscape that cannot be prepared is reported`() = runTest {
            val reports = collectReports()
            whenever(coordinator.requestAudioSession(AudioSource.TIMER)).thenReturn(false)

            sut.startBackgroundAudioFromFile("/data/own.mp3", 0.5f)

            assertEquals(1, reports())
            verify(factory, never()).create()
        }
    }

    @Nested
    inner class Previews {
        @Test
        fun `gong preview that fails is not reported`() = runTest {
            val reports = collectReports()
            playerFailsToStart()

            sut.playGongPreview("classic-bowl", 1.0f)

            assertEquals(0, reports())
        }

        @Test
        fun `background preview that fails is not reported`() = runTest {
            val reports = collectReports()
            playerFailsToStart()

            sut.playBackgroundPreview("forest", 0.5f)

            assertEquals(0, reports())
        }
    }
}
