package com.stillmoment.presentation.viewmodel

import com.stillmoment.domain.services.FontLicenseProviderProtocol
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test

/**
 * Tests for the "Font Attributions" screen state (shared-136).
 */
@OptIn(ExperimentalCoroutinesApi::class)
class FontAttributionsViewModelTest {
    private val testDispatcher = StandardTestDispatcher()

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `shows the bundled license text once loaded`() = runTest {
        val viewModel = FontAttributionsViewModel(FakeFontLicenseProvider("Copyright ... FONT SOFTWARE."))

        advanceUntilIdle()

        assertEquals("Copyright ... FONT SOFTWARE.", viewModel.licenseText.value)
    }

    @Test
    fun `shows no license text when the file cannot be read`() = runTest {
        val viewModel = FontAttributionsViewModel(FakeFontLicenseProvider(null))

        advanceUntilIdle()

        assertNull(viewModel.licenseText.value)
    }

    private class FakeFontLicenseProvider(private val text: String?) : FontLicenseProviderProtocol {
        override suspend fun loadLicenseText(): String? = text
    }
}
