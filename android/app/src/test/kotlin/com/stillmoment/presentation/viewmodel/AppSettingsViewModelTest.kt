package com.stillmoment.presentation.viewmodel

import com.stillmoment.domain.models.GuidedMeditationSettings
import com.stillmoment.domain.repositories.GuidedMeditationSettingsRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for AppSettingsViewModel.
 *
 * Tests settings observation and persistence for guided meditation settings
 * displayed in the global App Settings screen.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class AppSettingsViewModelTest {
    private val testDispatcher = StandardTestDispatcher()
    private lateinit var fakeSettingsRepository: FakeGuidedMeditationSettingsRepository
    private lateinit var viewModel: AppSettingsViewModel

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        fakeSettingsRepository = FakeGuidedMeditationSettingsRepository()
        viewModel = AppSettingsViewModel(fakeSettingsRepository)
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Nested
    inner class Initialization {
        @Test
        fun `initial state has default guided settings`() {
            val state = viewModel.uiState.value
            assertEquals(GuidedMeditationSettings.Default, state.guidedSettings)
        }

        @Test
        fun `observes settings from repository on init`() = runTest {
            // Given
            val customSettings = GuidedMeditationSettings(
                preparationTimeEnabled = true,
                preparationTimeSeconds = 15
            )
            fakeSettingsRepository.emitSettings(customSettings)

            // When
            advanceUntilIdle()

            // Then
            assertEquals(customSettings, viewModel.uiState.value.guidedSettings)
        }
    }

    @Nested
    inner class UpdateSettings {
        @Test
        fun `updateGuidedSettings persists to repository`() = runTest {
            // Given
            val newSettings = GuidedMeditationSettings(
                preparationTimeEnabled = true,
                preparationTimeSeconds = 30
            )

            // When
            viewModel.updateGuidedSettings(newSettings)
            advanceUntilIdle()

            // Then
            assertTrue(fakeSettingsRepository.updateWasCalled)
            assertEquals(newSettings, fakeSettingsRepository.lastUpdatedSettings)
        }

        @Test
        fun `enabling preparation time persists correctly`() = runTest {
            // Given - default settings (disabled)
            advanceUntilIdle()
            assertFalse(viewModel.uiState.value.guidedSettings.preparationTimeEnabled)

            // When
            val enabled = viewModel.uiState.value.guidedSettings.withPreparationTimeEnabled(true)
            viewModel.updateGuidedSettings(enabled)
            advanceUntilIdle()

            // Then
            assertTrue(viewModel.uiState.value.guidedSettings.preparationTimeEnabled)
        }

        @Test
        fun `changing preparation time seconds persists correctly`() = runTest {
            // Given
            val initial = GuidedMeditationSettings(
                preparationTimeEnabled = true,
                preparationTimeSeconds = 10
            )
            fakeSettingsRepository.emitSettings(initial)
            advanceUntilIdle()

            // When
            val updated = initial.withPreparationTimeSeconds(45)
            viewModel.updateGuidedSettings(updated)
            advanceUntilIdle()

            // Then
            assertEquals(45, viewModel.uiState.value.guidedSettings.preparationTimeSeconds)
        }
    }

    @Nested
    inner class SettingsPersistence {
        @Test
        fun `settings survive repository emission changes`() = runTest {
            // Given
            val settings1 = GuidedMeditationSettings(
                preparationTimeEnabled = false,
                preparationTimeSeconds = 5
            )
            fakeSettingsRepository.emitSettings(settings1)
            advanceUntilIdle()
            assertEquals(settings1, viewModel.uiState.value.guidedSettings)

            // When - repository emits new settings
            val settings2 = GuidedMeditationSettings(
                preparationTimeEnabled = true,
                preparationTimeSeconds = 20
            )
            fakeSettingsRepository.emitSettings(settings2)
            advanceUntilIdle()

            // Then - viewModel reflects latest
            assertEquals(settings2, viewModel.uiState.value.guidedSettings)
        }
    }
}

// ============================================================
// MARK: - Fake Settings Repository
// ============================================================

/**
 * Fake implementation of GuidedMeditationSettingsRepository for testing.
 */
class FakeGuidedMeditationSettingsRepository : GuidedMeditationSettingsRepository {
    private val _settings = MutableStateFlow(GuidedMeditationSettings.Default)

    var updateWasCalled = false
        private set
    var lastUpdatedSettings: GuidedMeditationSettings? = null
        private set

    override val settingsFlow: Flow<GuidedMeditationSettings>
        get() = _settings

    override suspend fun getSettings(): GuidedMeditationSettings {
        return _settings.value
    }

    override suspend fun updateSettings(settings: GuidedMeditationSettings) {
        updateWasCalled = true
        lastUpdatedSettings = settings
        _settings.value = settings
    }

    fun emitSettings(settings: GuidedMeditationSettings) {
        _settings.value = settings
    }
}
