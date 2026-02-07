package com.stillmoment.domain.repositories

import com.stillmoment.domain.models.MeditationSettings
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Contract tests for SettingsRepository.
 * Verifies that the interface contract for hasSeenSettingsHint is correct
 * using a fake implementation.
 */
class SettingsRepositoryContractTest {

    private class FakeSettingsRepository : SettingsRepository {
        private val _settings = MutableStateFlow(MeditationSettings.Default)
        private var hasSeenHint = false

        override val settingsFlow: Flow<MeditationSettings> = _settings

        override suspend fun updateSettings(settings: MeditationSettings) {
            _settings.value = settings
        }

        override suspend fun getSettings(): MeditationSettings = _settings.first()

        override suspend fun getHasSeenSettingsHint(): Boolean = hasSeenHint

        override suspend fun setHasSeenSettingsHint(seen: Boolean) {
            hasSeenHint = seen
        }
    }

    private val repository: SettingsRepository = FakeSettingsRepository()

    @Nested
    inner class HasSeenSettingsHint {

        @Test
        fun `default value is false`() = runBlocking {
            assertFalse(repository.getHasSeenSettingsHint())
        }

        @Test
        fun `can be set to true`() = runBlocking {
            repository.setHasSeenSettingsHint(true)
            assertTrue(repository.getHasSeenSettingsHint())
        }

        @Test
        fun `can be set back to false`() = runBlocking {
            repository.setHasSeenSettingsHint(true)
            repository.setHasSeenSettingsHint(false)
            assertFalse(repository.getHasSeenSettingsHint())
        }
    }
}
