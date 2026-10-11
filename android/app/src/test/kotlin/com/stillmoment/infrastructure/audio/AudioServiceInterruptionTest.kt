package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.AudioSource
import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.domain.repositories.SoundCatalogRepository
import com.stillmoment.domain.services.AudioFocusManagerProtocol
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.MediaPlayerFactoryProtocol
import com.stillmoment.domain.services.MediaPlayerProtocol
import com.stillmoment.domain.services.VibrationServiceProtocol
import com.stillmoment.domain.services.VolumeAnimatorProtocol
import java.io.FileDescriptor
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
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

/**
 * shared-147: a running timer goes on after an interruption (phone call, voice assistant, alarm).
 *
 * Real [AudioSessionCoordinator] behind a fake audio focus: an interruption is a focus loss, the
 * system giving the sound back is a focus gain. During a phone call Android refuses new focus
 * requests. The timer keeps counting in the ViewModel; here only its sounds are checked:
 * - the background sound pauses and comes back once the system gives the sound back,
 * - no timer gong sounds during the interruption; a start or end gong that is interrupted or due
 *   during it counts as finished (reported exactly once), so the timer never hangs,
 * - nothing during the interruption is reported as a sound that could not be played.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class AudioServiceInterruptionTest {
    private val testDispatcher = StandardTestDispatcher()

    private lateinit var sut: AudioService
    private lateinit var focus: FakeAudioFocusManager
    private lateinit var coordinator: AudioSessionCoordinator
    private lateinit var players: FakeMediaPlayerFactory
    private lateinit var vibration: VibrationServiceProtocol

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        focus = FakeAudioFocusManager()
        coordinator = AudioSessionCoordinator(focus)
        players = FakeMediaPlayerFactory()
        vibration = mock()
        val soundCatalog: SoundCatalogRepository = mock()
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
            players,
            mock<VolumeAnimatorProtocol>(),
            mock<LoggerProtocol>(),
            mock<CustomAudioRepository>(),
            soundCatalog,
            vibration
        )
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // MARK: - Timer steps, as the timer's foreground service drives them

    private fun timerStarts() {
        sut.startBackgroundAudio("silent", 0.15f)
    }

    private fun startGongSounds() {
        sut.playGong("classic-bowl", 1.0f)
    }

    private fun meditationBeginsWithForest() {
        sut.startBackgroundAudio("forest", 0.5f)
    }

    private fun meditationRunsWithForest() {
        timerStarts()
        meditationBeginsWithForest()
    }

    // MARK: - Interruptions

    /** A phone call: the sound is taken away, and Android refuses new requests until it ends. */
    private fun phoneCallBegins() {
        focus.refusesRequests = true
        focus.loseFocus()
    }

    /** The call ends and the system gives the sound back. */
    private fun systemGivesSoundBack() {
        focus.refusesRequests = false
        focus.gainFocus()
    }

    private fun TestScope.countGongEnds(): () -> Int {
        var ends = 0
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) {
            sut.gongCompletionFlow.collect { ends++ }
        }
        return { ends }
    }

    private fun TestScope.countFailureReports(): () -> Int {
        var reports = 0
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) {
            sut.timerSoundFailedFlow.collect { reports++ }
        }
        return { reports }
    }

    private fun forestSounds(): Boolean = players.forest()?.isPlaying == true

    @Nested
    inner class DuringTheMeditation {
        @Test
        fun `background sound pauses when an interruption begins`() {
            meditationRunsWithForest()

            phoneCallBegins()

            assertFalse(forestSounds())
        }

        @Test
        fun `background sound sounds again once the system gives the sound back`() {
            meditationRunsWithForest()
            phoneCallBegins()

            systemGivesSoundBack()

            assertTrue(forestSounds())
        }

        @Test
        fun `background sound comes back after each of two interruptions`() {
            meditationRunsWithForest()

            phoneCallBegins()
            systemGivesSoundBack()
            phoneCallBegins()
            systemGivesSoundBack()

            assertTrue(forestSounds())
        }

        @Test
        fun `background sound comes back when a second interruption began during the first`() {
            meditationRunsWithForest()
            phoneCallBegins()

            // e.g. the voice assistant during the call
            focus.loseFocus()
            systemGivesSoundBack()

            assertTrue(forestSounds())
        }

        @Test
        fun `background sound stays off when the system does not give the sound back`() {
            meditationRunsWithForest()

            // Another app plays music: the loss is permanent, no gain follows
            focus.loseFocus()

            assertFalse(forestSounds())
        }

        @Test
        fun `own soundscape that finishes loading during an interruption waits for the sound to come back`() {
            timerStarts()
            sut.startBackgroundAudioFromFile("/data/own.mp3", 0.5f)
            val ownSoundscape = players.last()

            phoneCallBegins()
            ownSoundscape.finishPreparing()
            assertFalse(ownSoundscape.isPlaying)

            systemGivesSoundBack()
            assertTrue(ownSoundscape.isPlaying)
        }
    }

    @Nested
    inner class DuringTheStartGong {
        @Test
        fun `interrupted start gong falls silent and counts as finished`() = runTest {
            val gongEnds = countGongEnds()
            val reports = countFailureReports()
            timerStarts()
            startGongSounds()
            val gong = players.last()

            phoneCallBegins()

            assertFalse(gong.isPlaying)
            assertEquals(1, gongEnds())
            assertEquals(0, reports())
        }

        @Test
        fun `interrupted start gong is reported finished only once`() = runTest {
            val gongEnds = countGongEnds()
            timerStarts()
            startGongSounds()
            val gong = players.last()

            phoneCallBegins()
            gong.finishPlaying()
            systemGivesSoundBack()

            assertEquals(1, gongEnds())
        }

        @Test
        fun `meditation beginning during the call shows no message and asks the system for nothing`() = runTest {
            val reports = countFailureReports()
            timerStarts()
            startGongSounds()
            phoneCallBegins()
            val requestsBefore = focus.requests

            meditationBeginsWithForest()

            assertEquals(0, reports())
            assertEquals(requestsBefore, focus.requests)
            assertFalse(forestSounds())
        }

        @Test
        fun `background sound of a meditation that began during the call sounds once the call ends`() = runTest {
            timerStarts()
            startGongSounds()
            phoneCallBegins()
            meditationBeginsWithForest()

            systemGivesSoundBack()

            assertTrue(forestSounds())
        }

        @Test
        fun `start gong due during an interruption stays silent and counts as finished`() = runTest {
            val gongEnds = countGongEnds()
            val reports = countFailureReports()
            timerStarts()
            phoneCallBegins()
            val createdBefore = players.created.size

            startGongSounds()

            assertEquals(createdBefore, players.created.size)
            assertEquals(1, gongEnds())
            assertEquals(0, reports())
        }

        @Test
        fun `vibration instead of a gong still vibrates during an interruption`() {
            timerStarts()
            phoneCallBegins()

            sut.playGong(GongSound.VIBRATION_ID, 1.0f)

            verify(vibration).vibrate()
        }

        @Test
        fun `interval gongs sound again after the interruption`() {
            timerStarts()
            startGongSounds()
            phoneCallBegins()
            meditationBeginsWithForest()
            systemGivesSoundBack()

            sut.playTimerIntervalGong("temple-bell", 1.0f)

            assertTrue(players.last().isPlaying)
        }
    }

    @Nested
    inner class IntervalGongs {
        @Test
        fun `interval gong due during an interruption stays silent without a message`() = runTest {
            val reports = countFailureReports()
            meditationRunsWithForest()
            phoneCallBegins()
            val createdBefore = players.created.size

            sut.playTimerIntervalGong("temple-bell", 1.0f)

            assertEquals(createdBefore, players.created.size)
            assertEquals(0, reports())
        }

        @Test
        fun `interrupted interval gong falls silent without a gong end`() = runTest {
            val gongEnds = countGongEnds()
            meditationRunsWithForest()
            sut.playTimerIntervalGong("temple-bell", 1.0f)
            val gong = players.last()

            phoneCallBegins()

            assertFalse(gong.isPlaying)
            assertEquals(0, gongEnds())
        }

        @Test
        fun `interval gong preview in the settings is not affected`() {
            meditationRunsWithForest()
            phoneCallBegins()

            sut.playIntervalGong("temple-bell", 1.0f)

            assertTrue(players.last().isPlaying)
        }
    }

    @Nested
    inner class DuringTheEndGong {
        @Test
        fun `interrupted end gong falls silent and counts as finished`() = runTest {
            val gongEnds = countGongEnds()
            meditationRunsWithForest()
            sut.playGong("classic-bowl", 1.0f)
            val gong = players.last()

            phoneCallBegins()

            assertFalse(gong.isPlaying)
            assertEquals(1, gongEnds())
        }

        @Test
        fun `end gong due during an interruption stays silent and counts as finished`() = runTest {
            val gongEnds = countGongEnds()
            val reports = countFailureReports()
            meditationRunsWithForest()
            phoneCallBegins()

            sut.playGong("classic-bowl", 1.0f)

            assertEquals(1, gongEnds())
            assertEquals(0, reports())
        }

        @Test
        fun `nothing sounds when the sound comes back after the session ended`() {
            meditationRunsWithForest()
            phoneCallBegins()
            sut.playGong("classic-bowl", 1.0f)
            sut.stopBackgroundAudio()

            systemGivesSoundBack()

            assertTrue(players.created.none { it.isPlaying })
            assertNull(coordinator.activeSource.value)
        }
    }

    @Nested
    inner class WithoutInterruption {
        @Test
        fun `start gong reports its end only when it finishes, exactly once`() = runTest {
            val gongEnds = countGongEnds()
            timerStarts()
            startGongSounds()
            val gong = players.last()
            assertEquals(0, gongEnds())

            gong.finishPlaying()

            assertEquals(1, gongEnds())
        }

        @Test
        fun `start gong that already finished adds no gong end when an interruption begins`() = runTest {
            val gongEnds = countGongEnds()
            timerStarts()
            startGongSounds()
            players.last().finishPlaying()

            phoneCallBegins()

            assertEquals(1, gongEnds())
        }

        @Test
        fun `background sound the system refuses is still reported`() = runTest {
            val reports = countFailureReports()
            focus.refusesRequests = true

            meditationRunsWithForest()

            assertEquals(2, reports())
        }

        @Test
        fun `reset during an interruption leaves everything silent when the sound comes back`() {
            timerStarts()
            startGongSounds()
            phoneCallBegins()
            meditationBeginsWithForest()

            sut.stopBackgroundAudio()
            systemGivesSoundBack()

            assertTrue(players.created.none { it.isPlaying })
        }

        @Test
        fun `guided meditation started during an interruption keeps the timer silent afterwards`() {
            meditationRunsWithForest()
            phoneCallBegins()

            coordinator.requestAudioSession(AudioSource.GUIDED_MEDITATION)
            systemGivesSoundBack()

            assertTrue(players.created.none { it.isPlaying })
        }
    }

    // MARK: - Fakes

    /** System audio focus: hands out focus unless refused, and delivers loss and gain on demand. */
    private class FakeAudioFocusManager : AudioFocusManagerProtocol {
        var refusesRequests = false
        var requests = 0
            private set
        private var onLost: (() -> Unit)? = null
        private var onGained: (() -> Unit)? = null

        override fun requestFocus(onFocusLost: () -> Unit, onFocusGained: () -> Unit): Boolean {
            requests++
            if (refusesRequests) return false
            onLost = onFocusLost
            onGained = onFocusGained
            return true
        }

        override fun releaseFocus() {
            onLost = null
            onGained = null
        }

        fun loseFocus() {
            onLost?.invoke()
        }

        fun gainFocus() {
            onGained?.invoke()
        }
    }

    private inner class FakeMediaPlayerFactory : MediaPlayerFactoryProtocol {
        val created = mutableListOf<FakeMediaPlayer>()

        override fun createFromResource(resourceId: Int): MediaPlayerProtocol = record(FakeMediaPlayer(resourceId))

        override fun createFromContentUri(uriString: String): MediaPlayerProtocol = record(FakeMediaPlayer(null))

        override fun create(): MediaPlayerProtocol = record(FakeMediaPlayer(null))

        fun last(): FakeMediaPlayer = created.last()

        /** The most recent forest background sound, if one was created. */
        fun forest(): FakeMediaPlayer? =
            created.lastOrNull { it.resourceId == AudioService.resolveRawResourceId("forest_ambience") }

        private fun record(player: FakeMediaPlayer): FakeMediaPlayer {
            created += player
            return player
        }
    }

    /** Behaves like MediaPlayer where it matters: a released player never reports completion. */
    private class FakeMediaPlayer(val resourceId: Int?) : MediaPlayerProtocol {
        private var playing = false
        private var released = false
        private var onCompletion: (() -> Unit)? = null
        private var onPrepared: (() -> Unit)? = null

        override fun start() {
            check(!released) { "start after release" }
            playing = true
        }

        override fun pause() {
            playing = false
        }

        override fun stop() {
            playing = false
        }

        override fun release() {
            playing = false
            released = true
        }

        override fun seekTo(position: Int) = Unit

        override val currentPosition: Int = 0
        override val duration: Int = 0
        override val isPlaying: Boolean get() = playing

        override fun setVolume(leftVolume: Float, rightVolume: Float) = Unit

        override var isLooping: Boolean = false

        override fun setOnPreparedListener(listener: () -> Unit) {
            onPrepared = listener
        }

        override fun setOnCompletionListener(listener: () -> Unit) {
            onCompletion = listener
        }

        override fun setOnSeekCompleteListener(listener: () -> Unit) = Unit

        override fun setOnErrorListener(listener: (what: Int, extra: Int) -> Boolean) = Unit

        override fun prepareAsync() = Unit

        override fun setDataSource(path: String) = Unit

        override fun setDataSourceFromFd(fd: FileDescriptor) = Unit

        fun finishPlaying() {
            if (released) return
            playing = false
            onCompletion?.invoke()
        }

        fun finishPreparing() {
            onPrepared?.invoke()
        }
    }
}
