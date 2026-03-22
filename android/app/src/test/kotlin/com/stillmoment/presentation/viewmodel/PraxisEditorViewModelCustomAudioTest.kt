package com.stillmoment.presentation.viewmodel

import android.net.Uri
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.models.Praxis
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * Unit tests for PraxisEditorViewModel custom audio methods.
 * Tests import, delete, error handling, and praxis reset behavior.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class PraxisEditorViewModelCustomAudioTest {
    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakePraxisRepository: FakePraxisRepository
    private lateinit var fakeAudioService: FakeAudioService
    private lateinit var fakeCustomAudioRepository: FakeCustomAudioRepository
    private lateinit var fakeSoundCatalogRepository: FakeSoundCatalogRepository

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        fakePraxisRepository = FakePraxisRepository()
        fakeAudioService = FakeAudioService()
        fakeCustomAudioRepository = FakeCustomAudioRepository()
        fakeSoundCatalogRepository = FakeSoundCatalogRepository()
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun createViewModel(): PraxisEditorViewModel {
        return PraxisEditorViewModel(
            praxisRepository = fakePraxisRepository,
            audioService = fakeAudioService,
            customAudioRepository = fakeCustomAudioRepository,
            soundCatalogRepository = fakeSoundCatalogRepository,
            attunementResolver = FakeAttunementResolver(),
            soundscapeResolver = FakeSoundscapeResolver()
        )
    }

    // MARK: - Import Custom Audio

    @Nested
    inner class ImportCustomAudio {
        @Test
        fun `importing soundscape appears in customSoundscapes state`() = runTest {
            val soundscape = CustomAudioFile(
                id = "soundscape-1",
                name = "Ocean Waves",
                filename = "ocean.mp3",
                durationMs = 120_000L,
                type = CustomAudioType.SOUNDSCAPE,
                dateAdded = 1000L
            )
            fakeCustomAudioRepository.importResult = Result.success(soundscape)

            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.importCustomAudio(mock<Uri>(), CustomAudioType.SOUNDSCAPE)
            advanceUntilIdle()

            val state = viewModel.uiState.value
            assertEquals(1, state.customSoundscapes.size)
            assertEquals("Ocean Waves", state.customSoundscapes.first().name)
            assertEquals(CustomAudioType.SOUNDSCAPE, state.customSoundscapes.first().type)
        }

        @Test
        fun `importing attunement appears in customAttunements state`() = runTest {
            val attunement = CustomAudioFile(
                id = "attunement-1",
                name = "Breathing Guide",
                filename = "breath.mp3",
                durationMs = 90_000L,
                type = CustomAudioType.ATTUNEMENT,
                dateAdded = 1000L
            )
            fakeCustomAudioRepository.importResult = Result.success(attunement)

            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.importCustomAudio(mock<Uri>(), CustomAudioType.ATTUNEMENT)
            advanceUntilIdle()

            val state = viewModel.uiState.value
            assertEquals(1, state.customAttunements.size)
            assertEquals("Breathing Guide", state.customAttunements.first().name)
            assertEquals(CustomAudioType.ATTUNEMENT, state.customAttunements.first().type)
        }

        @Test
        fun `import failure sets customAudioError`() = runTest {
            fakeCustomAudioRepository.importResult =
                Result.failure(IllegalArgumentException("Unsupported audio format"))

            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.importCustomAudio(mock<Uri>(), CustomAudioType.SOUNDSCAPE)
            advanceUntilIdle()

            val state = viewModel.uiState.value
            assertNotNull(state.customAudioError)
            assertEquals("Unsupported audio format", state.customAudioError)
        }
    }

    // MARK: - Delete Custom Audio

    @Nested
    inner class DeleteCustomAudio {
        @Test
        fun `deleting selected soundscape resets backgroundSoundId to default`() = runTest {
            val soundscapeId = "custom-soundscape-1"
            val soundscape = CustomAudioFile(
                id = soundscapeId,
                name = "Rain",
                filename = "rain.mp3",
                durationMs = 60_000L,
                type = CustomAudioType.SOUNDSCAPE,
                dateAdded = 1000L
            )
            fakeCustomAudioRepository.importResult = Result.success(soundscape)

            val viewModel = createViewModel()
            advanceUntilIdle()

            // Import and select the soundscape
            viewModel.importCustomAudio(mock<Uri>(), CustomAudioType.SOUNDSCAPE)
            advanceUntilIdle()
            viewModel.setBackgroundSoundId(soundscapeId)

            assertEquals(soundscapeId, viewModel.uiState.value.backgroundSoundId)

            // Delete the selected soundscape
            viewModel.deleteCustomAudio(soundscapeId)
            advanceUntilIdle()

            assertEquals(Praxis.DEFAULT_BACKGROUND_SOUND_ID, viewModel.uiState.value.backgroundSoundId)
            assertEquals(Praxis.DEFAULT_BACKGROUND_SOUND_ID, fakePraxisRepository.lastSavedPraxis?.backgroundSoundId)
        }

        @Test
        fun `deleting selected attunement resets attunementId to null`() = runTest {
            val attunementId = "custom-attunement-1"
            val attunement = CustomAudioFile(
                id = attunementId,
                name = "Breath Intro",
                filename = "breath.mp3",
                durationMs = 30_000L,
                type = CustomAudioType.ATTUNEMENT,
                dateAdded = 1000L
            )
            fakeCustomAudioRepository.importResult = Result.success(attunement)

            val viewModel = createViewModel()
            advanceUntilIdle()

            // Import and select the attunement
            viewModel.importCustomAudio(mock<Uri>(), CustomAudioType.ATTUNEMENT)
            advanceUntilIdle()
            viewModel.setAttunementId(attunementId)

            assertEquals(attunementId, viewModel.uiState.value.attunementId)

            // Delete the selected attunement
            viewModel.deleteCustomAudio(attunementId)
            advanceUntilIdle()

            assertNull(viewModel.uiState.value.attunementId)
            assertNull(fakePraxisRepository.lastSavedPraxis?.attunementId)
        }

        @Test
        fun `deleting unrelated soundscape does not change backgroundSoundId`() = runTest {
            val soundscape = CustomAudioFile(
                id = "other-soundscape",
                name = "Wind",
                filename = "wind.mp3",
                durationMs = 60_000L,
                type = CustomAudioType.SOUNDSCAPE,
                dateAdded = 1000L
            )
            fakeCustomAudioRepository.importResult = Result.success(soundscape)

            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.importCustomAudio(mock<Uri>(), CustomAudioType.SOUNDSCAPE)
            advanceUntilIdle()

            val originalBackgroundSoundId = viewModel.uiState.value.backgroundSoundId

            viewModel.deleteCustomAudio("other-soundscape")
            advanceUntilIdle()

            assertEquals(originalBackgroundSoundId, viewModel.uiState.value.backgroundSoundId)
        }

        @Test
        fun `delete calls repository delete with correct id`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.deleteCustomAudio("some-audio-id")
            advanceUntilIdle()

            assertEquals("some-audio-id", fakeCustomAudioRepository.lastDeletedId)
        }
    }

    // MARK: - Error Handling

    @Nested
    inner class ErrorHandling {
        @Test
        fun `clearCustomAudioError sets error to null`() = runTest {
            fakeCustomAudioRepository.importResult =
                Result.failure(IllegalArgumentException("Format error"))

            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.importCustomAudio(mock<Uri>(), CustomAudioType.SOUNDSCAPE)
            advanceUntilIdle()
            assertNotNull(viewModel.uiState.value.customAudioError)

            viewModel.clearCustomAudioError()

            assertNull(viewModel.uiState.value.customAudioError)
        }

        @Test
        fun `customAudioError is null initially`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            assertNull(viewModel.uiState.value.customAudioError)
        }
    }
}
