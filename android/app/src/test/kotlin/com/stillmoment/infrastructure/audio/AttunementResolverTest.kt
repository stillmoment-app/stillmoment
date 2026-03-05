package com.stillmoment.infrastructure.audio

import android.net.Uri
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.models.Introduction
import com.stillmoment.domain.repositories.CustomAudioRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for AttunementResolver.
 * Verifies that attunement IDs are resolved correctly from both
 * built-in catalog and custom audio imports.
 */
class AttunementResolverTest {
    private lateinit var fakeCustomAudioRepo: FakeCustomAudioRepository
    private lateinit var sut: AttunementResolver

    @BeforeEach
    fun setUp() {
        Introduction.languageOverride = "en"
        fakeCustomAudioRepo = FakeCustomAudioRepository()
        sut = AttunementResolver(fakeCustomAudioRepo)
    }

    @AfterEach
    fun tearDown() {
        Introduction.languageOverride = null
    }

    @Nested
    inner class Resolve {
        @Test
        fun `returns built-in attunement for known built-in ID`() = runTest {
            val result = sut.resolve("breath")

            assertEquals("breath", result?.id)
            assertEquals("Breathing Exercise", result?.name)
            assertEquals(95, result?.durationSeconds)
            assertTrue(result?.isBuiltIn == true)
        }

        @Test
        fun `returns custom attunement for custom audio UUID`() = runTest {
            val customFile = CustomAudioFile(
                id = "custom-uuid-123",
                name = "My Meditation",
                filename = "custom-uuid-123.mp3",
                durationMs = 180_000L,
                type = CustomAudioType.ATTUNEMENT
            )
            fakeCustomAudioRepo.addFile(customFile)

            val result = sut.resolve("custom-uuid-123")

            assertEquals("custom-uuid-123", result?.id)
            assertEquals("My Meditation", result?.name)
            assertEquals(180, result?.durationSeconds)
            assertFalse(result?.isBuiltIn == true)
        }

        @Test
        fun `returns null for unknown ID`() = runTest {
            val result = sut.resolve("nonexistent-id")

            assertNull(result)
        }

        @Test
        fun `returns null for custom audio with soundscape type`() = runTest {
            val soundscapeFile = CustomAudioFile(
                id = "soundscape-uuid",
                name = "Rain Sounds",
                filename = "soundscape-uuid.mp3",
                durationMs = 300_000L,
                type = CustomAudioType.SOUNDSCAPE
            )
            fakeCustomAudioRepo.addFile(soundscapeFile)

            val result = sut.resolve("soundscape-uuid")

            assertNull(result)
        }

        @Test
        fun `returns zero duration when custom audio has null durationMs`() = runTest {
            val customFile = CustomAudioFile(
                id = "no-duration",
                name = "Unknown Duration",
                filename = "no-duration.mp3",
                durationMs = null,
                type = CustomAudioType.ATTUNEMENT
            )
            fakeCustomAudioRepo.addFile(customFile)

            val result = sut.resolve("no-duration")

            assertEquals(0, result?.durationSeconds)
        }
    }

    @Nested
    inner class ResolveBuiltIn {
        @Test
        fun `returns attunement for known built-in ID`() {
            val result = sut.resolveBuiltIn("breath")

            assertEquals("breath", result?.id)
            assertEquals("Breathing Exercise", result?.name)
            assertEquals(95, result?.durationSeconds)
            assertTrue(result?.isBuiltIn == true)
        }

        @Test
        fun `returns null for custom audio ID`() {
            val result = sut.resolveBuiltIn("custom-uuid-123")

            assertNull(result)
        }
    }

    @Nested
    inner class IsBuiltInAvailableForCurrentLanguage {
        @Test
        fun `returns true for built-in with matching language`() {
            Introduction.languageOverride = "en"

            val result = sut.isBuiltInAvailableForCurrentLanguage("breath")

            assertTrue(result)
        }

        @Test
        fun `returns false for built-in with unavailable language`() {
            Introduction.languageOverride = "fr"

            val result = sut.isBuiltInAvailableForCurrentLanguage("breath")

            assertFalse(result)
        }

        @Test
        fun `returns false for unknown ID`() {
            val result = sut.isBuiltInAvailableForCurrentLanguage("nonexistent")

            assertFalse(result)
        }
    }
}

/**
 * Simple in-memory fake for CustomAudioRepository used in resolver tests.
 */
private class FakeCustomAudioRepository : CustomAudioRepository {
    private val files = mutableListOf<CustomAudioFile>()

    fun addFile(file: CustomAudioFile) {
        files.add(file)
    }

    override suspend fun findFile(id: String): CustomAudioFile? = files.find { it.id == id }

    override fun filesFlow(type: CustomAudioType): Flow<List<CustomAudioFile>> =
        flowOf(files.filter { it.type == type })

    override suspend fun loadAll(type: CustomAudioType) = files.filter { it.type == type }

    override suspend fun importFile(uri: Uri, type: CustomAudioType): Result<CustomAudioFile> =
        Result.failure(UnsupportedOperationException("Not needed in resolver tests"))

    override suspend fun delete(id: String) {
        files.removeAll { it.id == id }
    }

    override suspend fun getFilePath(id: String): String? = null

    override suspend fun rename(id: String, newName: String) {}
}
