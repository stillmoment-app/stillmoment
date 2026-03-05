package com.stillmoment.infrastructure.audio

import android.net.Uri
import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.models.Introduction
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.domain.repositories.SoundCatalogRepository
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
 * Unit tests for SoundscapeResolver.
 * Verifies that soundscape IDs are resolved correctly from both
 * built-in catalog and custom audio imports.
 */
class SoundscapeResolverTest {
    private lateinit var fakeSoundCatalog: FakeSoundCatalogRepository
    private lateinit var fakeCustomAudioRepo: SoundscapeFakeCustomAudioRepository
    private lateinit var sut: SoundscapeResolver

    @BeforeEach
    fun setUp() {
        Introduction.languageOverride = "en"
        fakeSoundCatalog = FakeSoundCatalogRepository()
        fakeCustomAudioRepo = SoundscapeFakeCustomAudioRepository()
        sut = SoundscapeResolver(fakeSoundCatalog, fakeCustomAudioRepo)
    }

    @AfterEach
    fun tearDown() {
        Introduction.languageOverride = null
    }

    @Nested
    inner class Resolve {
        @Test
        fun `returns built-in soundscape for known catalog ID`() = runTest {
            val result = sut.resolve("forest")

            assertEquals("forest", result?.id)
            assertEquals("Forest Ambience", result?.name)
            assertTrue(result?.isBuiltIn == true)
            assertFalse(result?.isSilent == true)
        }

        @Test
        fun `returns silent soundscape for silent ID`() = runTest {
            val result = sut.resolve(BackgroundSound.SILENT_ID)

            assertEquals(BackgroundSound.SILENT_ID, result?.id)
            assertTrue(result?.isBuiltIn == true)
            assertTrue(result?.isSilent == true)
        }

        @Test
        fun `returns custom soundscape for custom audio UUID`() = runTest {
            val customFile = CustomAudioFile(
                id = "custom-soundscape-uuid",
                name = "Rain Sounds",
                filename = "custom-soundscape-uuid.mp3",
                durationMs = 600_000L,
                type = CustomAudioType.SOUNDSCAPE
            )
            fakeCustomAudioRepo.addFile(customFile)

            val result = sut.resolve("custom-soundscape-uuid")

            assertEquals("custom-soundscape-uuid", result?.id)
            assertEquals("Rain Sounds", result?.name)
            assertFalse(result?.isBuiltIn == true)
            assertFalse(result?.isSilent == true)
        }

        @Test
        fun `returns null for unknown ID`() = runTest {
            val result = sut.resolve("nonexistent-id")

            assertNull(result)
        }

        @Test
        fun `returns null for custom audio with attunement type`() = runTest {
            val attunementFile = CustomAudioFile(
                id = "attunement-uuid",
                name = "Breathing",
                filename = "attunement-uuid.mp3",
                durationMs = 90_000L,
                type = CustomAudioType.ATTUNEMENT
            )
            fakeCustomAudioRepo.addFile(attunementFile)

            val result = sut.resolve("attunement-uuid")

            assertNull(result)
        }

        @Test
        fun `returns localized German name for built-in when language is German`() = runTest {
            Introduction.languageOverride = "de"

            val result = sut.resolve("forest")

            assertEquals("Waldatmosph\u00e4re", result?.name)
        }
    }

    @Nested
    inner class ResolveBuiltIn {
        @Test
        fun `returns soundscape for known catalog ID`() {
            val result = sut.resolveBuiltIn("forest")

            assertEquals("forest", result?.id)
            assertEquals("Forest Ambience", result?.name)
            assertTrue(result?.isBuiltIn == true)
        }

        @Test
        fun `returns null for custom audio ID`() {
            val result = sut.resolveBuiltIn("custom-soundscape-uuid")

            assertNull(result)
        }
    }
}

/**
 * Simple in-memory fake for SoundCatalogRepository used in resolver tests.
 */
private class FakeSoundCatalogRepository : SoundCatalogRepository {
    private val sounds = listOf(
        BackgroundSound(
            id = BackgroundSound.SILENT_ID,
            nameEnglish = "Silence",
            nameGerman = "Stille",
            descriptionEnglish = "Meditate in silence.",
            descriptionGerman = "Meditiere in Stille.",
            rawResourceName = ""
        ),
        BackgroundSound(
            id = "forest",
            nameEnglish = "Forest Ambience",
            nameGerman = "Waldatmosph\u00e4re",
            descriptionEnglish = "Natural forest sounds",
            descriptionGerman = "Nat\u00fcrliche Waldger\u00e4usche",
            rawResourceName = "forest_ambience"
        )
    )

    override fun getAllSounds(): List<BackgroundSound> = sounds

    override fun findById(id: String): BackgroundSound? = sounds.find { it.id == id }

    override fun findByIdOrDefault(id: String): BackgroundSound = findById(id) ?: sounds.first()
}

/**
 * Simple in-memory fake for CustomAudioRepository used in resolver tests.
 */
private class SoundscapeFakeCustomAudioRepository : CustomAudioRepository {
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
