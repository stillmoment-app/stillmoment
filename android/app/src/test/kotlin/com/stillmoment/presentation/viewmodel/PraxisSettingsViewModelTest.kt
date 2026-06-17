package com.stillmoment.presentation.viewmodel

import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.models.IntervalMode
import com.stillmoment.domain.models.Praxis
import com.stillmoment.domain.repositories.PraxisRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
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

/**
 * Unit tests for PraxisSettingsViewModel.
 * Tests loading, editing, saving, validation, and audio preview delegation.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class PraxisSettingsViewModelTest {
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

    private fun createViewModel(): PraxisSettingsViewModel {
        return PraxisSettingsViewModel(
            praxisRepository = fakePraxisRepository,
            audioService = fakeAudioService,
            customAudioRepository = fakeCustomAudioRepository,
            soundCatalogRepository = fakeSoundCatalogRepository,
            soundscapeResolver = FakeSoundscapeResolver()
        )
    }

    // MARK: - Loading

    @Nested
    inner class Loading {
        @Test
        fun `isLoading starts true`() = runTest {
            val viewModel = createViewModel()
            assertTrue(viewModel.uiState.value.isLoading)
        }

        @Test
        fun `isLoading becomes false after load completes`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()
            assertFalse(viewModel.uiState.value.isLoading)
        }

        @Test
        fun `loads current praxis values on init`() = runTest {
            val customPraxis = Praxis.create(
                id = "test-id",
                durationMinutes = 25,
                preparationTimeEnabled = false,
                preparationTimeSeconds = 30,
                gongSoundId = "clear-strike",
                gongVolume = 0.8f,
                intervalGongsEnabled = true,
                intervalMinutes = 10,
                intervalMode = IntervalMode.BEFORE_END,
                intervalSoundId = "temple-bell",
                intervalGongVolume = 0.6f,
                backgroundSoundId = "forest",
                backgroundSoundVolume = 0.4f
            )
            fakePraxisRepository.storedPraxis = customPraxis

            val viewModel = createViewModel()
            advanceUntilIdle()
            val state = viewModel.uiState.value

            assertEquals(25, state.durationMinutes)
            assertFalse(state.preparationTimeEnabled)
            assertEquals(30, state.preparationTimeSeconds)
            assertEquals("clear-strike", state.gongSoundId)
            assertEquals(0.8f, state.gongVolume)
            assertTrue(state.intervalGongsEnabled)
            assertEquals(10, state.intervalMinutes)
            assertEquals(IntervalMode.BEFORE_END, state.intervalMode)
            assertEquals("temple-bell", state.intervalSoundId)
            assertEquals(0.6f, state.intervalGongVolume)
            assertEquals("forest", state.backgroundSoundId)
            assertEquals(0.4f, state.backgroundSoundVolume)
        }
    }

    // MARK: - Setter Methods

    @Nested
    inner class SetterMethods {
        @Test
        fun `setPreparationEnabled updates state`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setPreparationEnabled(false)

            assertFalse(viewModel.uiState.value.preparationTimeEnabled)
        }

        @Test
        fun `setPreparationSeconds updates state`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setPreparationSeconds(30)

            assertEquals(30, viewModel.uiState.value.preparationTimeSeconds)
        }

        @Test
        fun `setGongSoundId updates state`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setGongSoundId("singing-bowl")

            assertEquals("singing-bowl", viewModel.uiState.value.gongSoundId)
        }

        @Test
        fun `setGongVolume updates state`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setGongVolume(0.5f)

            assertEquals(0.5f, viewModel.uiState.value.gongVolume)
        }

        @Test
        fun `setIntervalGongsEnabled updates state`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setIntervalGongsEnabled(true)

            assertTrue(viewModel.uiState.value.intervalGongsEnabled)
        }

        @Test
        fun `setIntervalMinutes updates state`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setIntervalMinutes(15)

            assertEquals(15, viewModel.uiState.value.intervalMinutes)
        }

        @Test
        fun `setIntervalMode updates state`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setIntervalMode(IntervalMode.AFTER_START)

            assertEquals(IntervalMode.AFTER_START, viewModel.uiState.value.intervalMode)
        }

        @Test
        fun `setIntervalSoundId updates state`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setIntervalSoundId("temple-bell")

            assertEquals("temple-bell", viewModel.uiState.value.intervalSoundId)
        }

        @Test
        fun `setIntervalGongVolume updates state`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setIntervalGongVolume(0.5f)

            assertEquals(0.5f, viewModel.uiState.value.intervalGongVolume)
        }

        @Test
        fun `setBackgroundSoundId updates state`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setBackgroundSoundId("forest")

            assertEquals("forest", viewModel.uiState.value.backgroundSoundId)
        }

        @Test
        fun `setBackgroundSoundVolume updates state`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setBackgroundSoundVolume(0.3f)

            assertEquals(0.3f, viewModel.uiState.value.backgroundSoundVolume)
        }
    }

    // MARK: - Validation

    @Nested
    inner class Validation {
        @Test
        fun `setIntervalMinutes coerces to minimum 1`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setIntervalMinutes(0)

            assertEquals(1, viewModel.uiState.value.intervalMinutes)
        }

        @Test
        fun `setIntervalMinutes coerces to maximum 60`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setIntervalMinutes(100)

            assertEquals(60, viewModel.uiState.value.intervalMinutes)
        }

        @Test
        fun `setGongVolume coerces to range 0 to 1`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setGongVolume(-0.5f)
            assertEquals(0f, viewModel.uiState.value.gongVolume)

            viewModel.setGongVolume(1.5f)
            assertEquals(1f, viewModel.uiState.value.gongVolume)
        }

        @Test
        fun `setIntervalGongVolume coerces to range 0 to 1`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setIntervalGongVolume(-1f)
            assertEquals(0f, viewModel.uiState.value.intervalGongVolume)

            viewModel.setIntervalGongVolume(2f)
            assertEquals(1f, viewModel.uiState.value.intervalGongVolume)
        }

        @Test
        fun `setBackgroundSoundVolume coerces to range 0 to 1`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setBackgroundSoundVolume(-0.1f)
            assertEquals(0f, viewModel.uiState.value.backgroundSoundVolume)

            viewModel.setBackgroundSoundVolume(1.1f)
            assertEquals(1f, viewModel.uiState.value.backgroundSoundVolume)
        }

        @Test
        fun `setPreparationSeconds snaps to nearest valid value`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setPreparationSeconds(12)

            assertEquals(10, viewModel.uiState.value.preparationTimeSeconds)
        }

        @Test
        fun `disabling and re-enabling preparation keeps the chosen duration`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()
            viewModel.setPreparationSeconds(35)

            viewModel.setPreparationEnabled(false)
            viewModel.setPreparationEnabled(true)

            assertTrue(viewModel.uiState.value.preparationTimeEnabled)
            assertEquals(35, viewModel.uiState.value.preparationTimeSeconds)
        }
    }

    // MARK: - Resolved Audio Names

    @Nested
    inner class ResolvedAudioNames {
        @Test
        fun `resolves built-in background sound name on init`() = runTest {
            fakePraxisRepository.storedPraxis = Praxis.create(backgroundSoundId = "forest")

            val viewModel = createViewModel()
            advanceUntilIdle()

            assertEquals(
                "Forest Ambience",
                viewModel.uiState.value.resolvedBackgroundSoundName
            )
        }

        @Test
        fun `setBackgroundSoundId updates resolvedBackgroundSoundName`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setBackgroundSoundId("forest")
            advanceUntilIdle()

            assertEquals(
                "Forest Ambience",
                viewModel.uiState.value.resolvedBackgroundSoundName
            )
        }

        @Test
        fun `resolves silent soundscape name as null on init`() = runTest {
            fakePraxisRepository.storedPraxis = Praxis.create(
                backgroundSoundId = BackgroundSound.SILENT_ID
            )

            val viewModel = createViewModel()
            advanceUntilIdle()

            assertNull(
                viewModel.uiState.value.resolvedBackgroundSoundName,
                "Silent soundscape should resolve to null (UI handles display name)"
            )
        }
    }

    // MARK: - Save

    @Nested
    inner class Save {
        @Test
        fun `save returns Praxis with all edited fields`() = runTest {
            fakePraxisRepository.storedPraxis = Praxis.create(durationMinutes = 45)
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setPreparationEnabled(false)
            viewModel.setPreparationSeconds(30)
            viewModel.setGongSoundId("clear-strike")
            viewModel.setGongVolume(0.7f)
            viewModel.setIntervalGongsEnabled(true)
            viewModel.setIntervalMinutes(15)
            viewModel.setIntervalMode(IntervalMode.AFTER_START)
            viewModel.setIntervalSoundId("temple-bell")
            viewModel.setIntervalGongVolume(0.9f)
            viewModel.setBackgroundSoundId("forest")
            viewModel.setBackgroundSoundVolume(0.4f)

            val saved = viewModel.save()

            assertEquals(45, saved.durationMinutes)
            assertFalse(saved.preparationTimeEnabled)
            assertEquals(30, saved.preparationTimeSeconds)
            assertEquals("clear-strike", saved.gongSoundId)
            assertEquals(0.7f, saved.gongVolume)
            assertTrue(saved.intervalGongsEnabled)
            assertEquals(15, saved.intervalMinutes)
            assertEquals(IntervalMode.AFTER_START, saved.intervalMode)
            assertEquals("temple-bell", saved.intervalSoundId)
            assertEquals(0.9f, saved.intervalGongVolume)
            assertEquals("forest", saved.backgroundSoundId)
            assertEquals(0.4f, saved.backgroundSoundVolume)
        }

        @Test
        fun `save persists via repository`() = runTest {
            fakePraxisRepository.storedPraxis = Praxis.create(durationMinutes = 20)
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.save()
            advanceUntilIdle()

            assertEquals(20, fakePraxisRepository.lastSavedPraxis?.durationMinutes)
        }

        @Test
        fun `save preserves original praxis id`() = runTest {
            val customPraxis = Praxis.create(id = "my-unique-id", durationMinutes = 15)
            fakePraxisRepository.storedPraxis = customPraxis

            val viewModel = createViewModel()
            advanceUntilIdle()

            val saved = viewModel.save()

            assertEquals("my-unique-id", saved.id)
        }
    }

    // MARK: - Audio Preview

    @Nested
    inner class AudioPreview {
        @Test
        fun `playGongPreview delegates to audio service with current volume`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()
            viewModel.setGongVolume(0.7f)

            viewModel.playGongPreview("singing-bowl")

            assertEquals("singing-bowl", fakeAudioService.lastGongPreviewSoundId)
            assertEquals(0.7f, fakeAudioService.lastGongPreviewVolume)
        }

        @Test
        fun `playIntervalGongPreview delegates to audio service with current volume`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()
            viewModel.setIntervalGongVolume(0.6f)

            viewModel.playIntervalGongPreview("temple-bell")

            assertEquals("temple-bell", fakeAudioService.lastIntervalGongSoundId)
            assertEquals(0.6f, fakeAudioService.lastIntervalGongVolume)
        }

        @Test
        fun `playBackgroundPreview delegates to audio service with current volume`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()
            viewModel.setBackgroundSoundVolume(0.3f)

            viewModel.playBackgroundPreview("forest")

            assertEquals("forest", fakeAudioService.lastBackgroundPreviewSoundId)
            assertEquals(0.3f, fakeAudioService.lastBackgroundPreviewVolume)
        }

        @Test
        fun `stopPreviews stops gong and background previews`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.stopPreviews()

            assertTrue(fakeAudioService.gongPreviewStopped)
            assertTrue(fakeAudioService.backgroundPreviewStopped)
        }
    }

    // MARK: - Soundscape Loop Preview (shared-121)

    @Nested
    inner class SoundscapeLoopPreview {
        @Test
        fun `selecting a real sound starts its loop preview and marks it previewing`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()
            viewModel.setBackgroundSoundVolume(0.3f)

            viewModel.selectBackgroundSound("forest")

            assertEquals("forest", viewModel.uiState.value.backgroundSoundId)
            assertEquals("forest", viewModel.uiState.value.previewingSoundscapeId)
            assertEquals("forest", fakeAudioService.lastBackgroundPreviewSoundId)
            assertEquals(0.3f, fakeAudioService.lastBackgroundPreviewVolume)
        }

        @Test
        fun `selecting silence stops every preview and clears previewing id`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()
            viewModel.selectBackgroundSound("forest")

            viewModel.selectBackgroundSound(BackgroundSound.SILENT_ID)

            assertEquals(BackgroundSound.SILENT_ID, viewModel.uiState.value.backgroundSoundId)
            assertNull(viewModel.uiState.value.previewingSoundscapeId)
            assertTrue(fakeAudioService.backgroundPreviewStopped)
        }

        @Test
        fun `toggling a sound that is not playing starts it without changing selection`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()
            viewModel.selectBackgroundSound("forest")

            viewModel.toggleBackgroundPreview("cozy-rain")

            assertEquals("forest", viewModel.uiState.value.backgroundSoundId)
            assertEquals("cozy-rain", viewModel.uiState.value.previewingSoundscapeId)
            assertEquals("cozy-rain", fakeAudioService.lastBackgroundPreviewSoundId)
        }

        @Test
        fun `toggling the currently playing sound stops it`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()
            viewModel.selectBackgroundSound("forest")

            viewModel.toggleBackgroundPreview("forest")

            assertNull(viewModel.uiState.value.previewingSoundscapeId)
            assertTrue(fakeAudioService.backgroundPreviewStopped)
        }

        @Test
        fun `toggling silence is a no-op`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.toggleBackgroundPreview(BackgroundSound.SILENT_ID)

            assertNull(viewModel.uiState.value.previewingSoundscapeId)
            assertNull(fakeAudioService.lastBackgroundPreviewSoundId)
        }

        @Test
        fun `setBackgroundPreviewVolume updates the running preview live`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setBackgroundPreviewVolume(0.7f)

            assertEquals(0.7f, fakeAudioService.lastBackgroundPreviewLiveVolume)
        }

        @Test
        fun `stopPreviews clears previewing id`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()
            viewModel.selectBackgroundSound("forest")

            viewModel.stopPreviews()

            assertNull(viewModel.uiState.value.previewingSoundscapeId)
        }
    }

    // MARK: - Custom Audio (shared-121)

    @Nested
    inner class CustomAudio {
        @Test
        fun `renaming a custom file updates its name`() = runTest {
            fakeCustomAudioRepository.addFile(
                CustomAudioFile(
                    id = "file-1",
                    name = "Old Name",
                    filename = "file-1.mp3",
                    durationMs = 60_000L,
                    type = CustomAudioType.SOUNDSCAPE
                )
            )
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.renameCustomAudio("file-1", "New Name")
            advanceUntilIdle()

            assertEquals(
                "New Name",
                viewModel.uiState.value.customSoundscapes.first { it.id == "file-1" }.name
            )
        }

        @Test
        fun `renaming trims surrounding whitespace`() = runTest {
            fakeCustomAudioRepository.addFile(
                CustomAudioFile(
                    id = "file-1",
                    name = "Old Name",
                    filename = "file-1.mp3",
                    durationMs = 60_000L,
                    type = CustomAudioType.SOUNDSCAPE
                )
            )
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.renameCustomAudio("file-1", "  Trimmed  ")
            advanceUntilIdle()

            assertEquals(
                "Trimmed",
                viewModel.uiState.value.customSoundscapes.first { it.id == "file-1" }.name
            )
        }

        @Test
        fun `renaming with a blank name is ignored`() = runTest {
            fakeCustomAudioRepository.addFile(
                CustomAudioFile(
                    id = "file-1",
                    name = "Keep Me",
                    filename = "file-1.mp3",
                    durationMs = 60_000L,
                    type = CustomAudioType.SOUNDSCAPE
                )
            )
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.renameCustomAudio("file-1", "   ")
            advanceUntilIdle()

            assertEquals(
                "Keep Me",
                viewModel.uiState.value.customSoundscapes.first { it.id == "file-1" }.name
            )
        }

        @Test
        fun `importing the same uri twice in a row imports only once`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()
            // android.net.Uri is an Android stub in JVM tests; a single mock
            // instance reused for both calls compares equal to itself, which is
            // exactly the duplicate-callback case the guard protects against.
            val uri = org.mockito.kotlin.mock<android.net.Uri>()

            viewModel.importCustomAudio(uri, CustomAudioType.SOUNDSCAPE)
            advanceUntilIdle()
            viewModel.importCustomAudio(uri, CustomAudioType.SOUNDSCAPE)
            advanceUntilIdle()

            assertEquals(1, viewModel.uiState.value.customSoundscapes.size)
        }
    }
}

// ============================================================
// MARK: - Fake PraxisRepository
// ============================================================

/**
 * Fake implementation of PraxisRepository for testing.
 * Provides a configurable stored Praxis and tracks save calls.
 */
class FakePraxisRepository : PraxisRepository {
    var storedPraxis: Praxis = Praxis.Default
    var lastSavedPraxis: Praxis? = null

    private val _praxisState = MutableStateFlow<Praxis?>(null)
    override val praxisFlow: Flow<Praxis> = _praxisState.filterNotNull()

    override suspend fun load(): Praxis {
        _praxisState.value = storedPraxis
        return storedPraxis
    }

    override suspend fun save(praxis: Praxis) {
        lastSavedPraxis = praxis
        storedPraxis = praxis
        _praxisState.value = praxis
    }
}

// ============================================================
// MARK: - Fake CustomAudioRepository
// ============================================================

// FakeCustomAudioRepository is shared via TimerViewModelTestFakes.kt
