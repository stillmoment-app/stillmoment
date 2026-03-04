package com.stillmoment.presentation.viewmodel

import com.stillmoment.domain.models.IntervalMode
import com.stillmoment.domain.models.Introduction
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
 * Unit tests for PraxisEditorViewModel.
 * Tests loading, editing, saving, validation, and audio preview delegation.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class PraxisEditorViewModelTest {
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
            soundCatalogRepository = fakeSoundCatalogRepository
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
                introductionId = "breath",
                introductionEnabled = true,
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
            assertEquals("breath", state.introductionId)
            assertTrue(state.introductionEnabled)
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
        fun `setIntroductionId updates state`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setIntroductionId("breath")

            assertEquals("breath", viewModel.uiState.value.introductionId)
        }

        @Test
        fun `setIntroductionId allows null`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()
            viewModel.setIntroductionId("breath")

            viewModel.setIntroductionId(null)

            assertNull(viewModel.uiState.value.introductionId)
        }

        @Test
        fun `setIntroductionEnabled updates state`() = runTest {
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setIntroductionEnabled(true)

            assertTrue(viewModel.uiState.value.introductionEnabled)
        }

        @Test
        fun `setIntroductionEnabled selects first available introduction when none selected`() = runTest {
            Introduction.languageOverride = "de"
            try {
                val viewModel = createViewModel()
                advanceUntilIdle()

                viewModel.setIntroductionEnabled(true)

                val available = Introduction.availableForCurrentLanguage()
                assertEquals(available.firstOrNull()?.id, viewModel.uiState.value.introductionId)
            } finally {
                Introduction.languageOverride = null
            }
        }

        @Test
        fun `setIntroductionEnabled preserves existing introduction selection`() = runTest {
            fakePraxisRepository.storedPraxis = Praxis.create(introductionId = "breath")
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setIntroductionEnabled(true)

            assertEquals("breath", viewModel.uiState.value.introductionId)
        }

        @Test
        fun `setIntroductionEnabled false preserves introductionId for later reuse`() = runTest {
            fakePraxisRepository.storedPraxis = Praxis.create(
                introductionId = "breath",
                introductionEnabled = true
            )
            val viewModel = createViewModel()
            advanceUntilIdle()

            viewModel.setIntroductionEnabled(false)

            assertFalse(viewModel.uiState.value.introductionEnabled)
            assertEquals("breath", viewModel.uiState.value.introductionId)
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
            viewModel.setIntroductionId("breath")
            viewModel.setIntroductionEnabled(true)
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
            assertEquals("breath", saved.introductionId)
            assertTrue(saved.introductionEnabled)
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
