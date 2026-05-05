package com.stillmoment.infrastructure.audio

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
        resolver.languageOverride = null
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
            resolver.languageOverride = "en"

            val result = resolver.resolve("forest")

            assertNotNull(result)
            assertEquals("forest", result?.id)
            assertEquals("Forest Ambience", result?.displayName)
        }

        @Test
        fun `returns built-in sound with German name`() {
            resolver.languageOverride = "de"

            val result = resolver.resolve("forest")

            assertNotNull(result)
            assertEquals("Waldatmosphäre", result?.displayName)
        }

        @Test
        fun `returns custom soundscape by ID`() {
            resolver.languageOverride = "en"
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
        fun `returns null for unknown ID`() {
            resolver.languageOverride = "en"

            val result = resolver.resolve("nonexistent-id")

            assertNull(result)
        }
    }

    @Nested
    inner class AllAvailable {

        @Test
        fun `returns built-in and custom soundscapes`() {
            resolver.languageOverride = "en"
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
            resolver.languageOverride = "en"

            val result = resolver.allAvailable()

            assertEquals(1, result.size)
            assertEquals("forest", result[0].id)
        }
    }
}
