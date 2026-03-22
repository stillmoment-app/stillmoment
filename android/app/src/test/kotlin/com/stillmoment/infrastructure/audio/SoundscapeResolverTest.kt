package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.Attunement
import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.presentation.viewmodel.FakeCustomAudioRepository
import com.stillmoment.presentation.viewmodel.FakeSoundCatalogRepository
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

class SoundscapeResolverTest {

    private lateinit var fakeSoundCatalogRepository: FakeSoundCatalogRepository
    private lateinit var fakeCustomAudioRepository: FakeCustomAudioRepository
    private lateinit var resolver: SoundscapeResolver

    @BeforeEach
    fun setUp() {
        fakeSoundCatalogRepository = FakeSoundCatalogRepository()
        fakeCustomAudioRepository = FakeCustomAudioRepository()
        resolver = SoundscapeResolver(fakeSoundCatalogRepository, fakeCustomAudioRepository)
    }

    @AfterEach
    fun tearDown() {
        Attunement.languageOverride = null
    }

    @Nested
    inner class Resolve {

        @Test
        fun `returns null for silent ID`() {
            val result = resolver.resolve(BackgroundSound.SILENT_ID)

            assertNull(result)
        }

        @Test
        fun `returns built-in sound with English name`() {
            Attunement.languageOverride = "en"

            val result = resolver.resolve("forest")

            assertNotNull(result)
            assertEquals("forest", result?.id)
            assertEquals("Forest Ambience", result?.displayName)
        }

        @Test
        fun `returns built-in sound with German name`() {
            Attunement.languageOverride = "de"

            val result = resolver.resolve("forest")

            assertNotNull(result)
            assertEquals("Waldatmosph\u00e4re", result?.displayName)
        }

        @Test
        fun `returns custom soundscape by ID`() {
            Attunement.languageOverride = "en"
            val customFile = CustomAudioFile(
                id = "custom-soundscape-1",
                name = "Ocean Waves",
                filename = "custom-soundscape-1.mp3",
                durationMs = 300_000L,
                type = CustomAudioType.SOUNDSCAPE
            )
            fakeCustomAudioRepository.addFile(customFile)

            val result = resolver.resolve("custom-soundscape-1")

            assertNotNull(result)
            assertEquals("custom-soundscape-1", result?.id)
            assertEquals("Ocean Waves", result?.displayName)
        }

        @Test
        fun `returns null for custom attunement ID`() {
            Attunement.languageOverride = "en"
            val attunementFile = CustomAudioFile(
                id = "custom-attunement-1",
                name = "My Attunement",
                filename = "custom-attunement-1.mp3",
                durationMs = 120_000L,
                type = CustomAudioType.ATTUNEMENT
            )
            fakeCustomAudioRepository.addFile(attunementFile)

            val result = resolver.resolve("custom-attunement-1")

            assertNull(result)
        }

        @Test
        fun `returns null for unknown ID`() {
            Attunement.languageOverride = "en"

            val result = resolver.resolve("nonexistent-id")

            assertNull(result)
        }
    }

    @Nested
    inner class AllAvailable {

        @Test
        fun `returns built-in and custom soundscapes`() {
            Attunement.languageOverride = "en"
            val customFile = CustomAudioFile(
                id = "custom-soundscape-1",
                name = "Ocean Waves",
                filename = "custom-soundscape-1.mp3",
                durationMs = 300_000L,
                type = CustomAudioType.SOUNDSCAPE
            )
            fakeCustomAudioRepository.addFile(customFile)

            val result = resolver.allAvailable()

            assertEquals(2, result.size)
            assertEquals("forest", result[0].id)
            assertEquals("Forest Ambience", result[0].displayName)
            assertEquals("custom-soundscape-1", result[1].id)
            assertEquals("Ocean Waves", result[1].displayName)
        }

        @Test
        fun `excludes silent from built-in`() {
            Attunement.languageOverride = "en"

            val result = resolver.allAvailable()

            assertEquals(1, result.size)
            assertEquals("forest", result[0].id)
        }

        @Test
        fun `excludes custom attunements from results`() {
            Attunement.languageOverride = "en"
            val attunementFile = CustomAudioFile(
                id = "custom-attunement",
                name = "My Attunement",
                filename = "attunement.mp3",
                durationMs = 120_000L,
                type = CustomAudioType.ATTUNEMENT
            )
            fakeCustomAudioRepository.addFile(attunementFile)

            val result = resolver.allAvailable()

            assertEquals(1, result.size)
            assertEquals("forest", result[0].id)
        }
    }
}
