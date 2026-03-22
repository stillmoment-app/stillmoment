package com.stillmoment.infrastructure.audio

import com.stillmoment.domain.models.Attunement
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.presentation.viewmodel.FakeCustomAudioRepository
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

class AttunementResolverTest {

    private lateinit var fakeCustomAudioRepository: FakeCustomAudioRepository
    private lateinit var resolver: AttunementResolver

    @BeforeEach
    fun setUp() {
        fakeCustomAudioRepository = FakeCustomAudioRepository()
        resolver = AttunementResolver(fakeCustomAudioRepository)
    }

    @AfterEach
    fun tearDown() {
        Attunement.languageOverride = null
    }

    @Nested
    inner class Resolve {

        @Test
        fun `returns built-in attunement when available for current language`() {
            Attunement.languageOverride = "en"

            val result = resolver.resolve("breath")

            assertNotNull(result)
            assertEquals("breath", result?.id)
            assertEquals("Breathing Exercise", result?.displayName)
            assertEquals(95, result?.durationSeconds)
        }

        @Test
        fun `returns localized name for German language`() {
            Attunement.languageOverride = "de"

            val result = resolver.resolve("breath")

            assertNotNull(result)
            assertEquals("Atem\u00fcbung", result?.displayName)
        }

        @Test
        fun `returns null for built-in attunement not available for current language`() {
            Attunement.languageOverride = "fr"

            val result = resolver.resolve("breath")

            assertNull(result)
        }

        @Test
        fun `returns custom attunement by ID`() {
            Attunement.languageOverride = "en"
            val customFile = CustomAudioFile(
                id = "custom-attunement-1",
                name = "My Attunement",
                filename = "custom-attunement-1.mp3",
                durationMs = 120_000L,
                type = CustomAudioType.ATTUNEMENT
            )
            fakeCustomAudioRepository.addFile(customFile)

            val result = resolver.resolve("custom-attunement-1")

            assertNotNull(result)
            assertEquals("custom-attunement-1", result?.id)
            assertEquals("My Attunement", result?.displayName)
            assertEquals(120, result?.durationSeconds)
        }

        @Test
        fun `returns null for custom soundscape ID`() {
            Attunement.languageOverride = "en"
            val soundscapeFile = CustomAudioFile(
                id = "custom-soundscape-1",
                name = "Forest Rain",
                filename = "custom-soundscape-1.mp3",
                durationMs = 300_000L,
                type = CustomAudioType.SOUNDSCAPE
            )
            fakeCustomAudioRepository.addFile(soundscapeFile)

            val result = resolver.resolve("custom-soundscape-1")

            assertNull(result)
        }

        @Test
        fun `returns null for unknown ID`() {
            Attunement.languageOverride = "en"

            val result = resolver.resolve("nonexistent-id")

            assertNull(result)
        }

        @Test
        fun `prefers built-in over custom for same ID`() {
            Attunement.languageOverride = "en"
            val customFile = CustomAudioFile(
                id = "breath",
                name = "Custom Breath",
                filename = "custom-breath.mp3",
                durationMs = 200_000L,
                type = CustomAudioType.ATTUNEMENT
            )
            fakeCustomAudioRepository.addFile(customFile)

            val result = resolver.resolve("breath")

            assertNotNull(result)
            assertEquals("Breathing Exercise", result?.displayName)
            assertEquals(95, result?.durationSeconds)
        }

        @Test
        fun `returns zero duration when custom attunement has null durationMs`() {
            Attunement.languageOverride = "en"
            val customFile = CustomAudioFile(
                id = "no-duration",
                name = "Unknown Duration",
                filename = "no-duration.mp3",
                durationMs = null,
                type = CustomAudioType.ATTUNEMENT
            )
            fakeCustomAudioRepository.addFile(customFile)

            val result = resolver.resolve("no-duration")

            assertNotNull(result)
            assertEquals(0, result?.durationSeconds)
        }
    }

    @Nested
    inner class AllAvailable {

        @Test
        fun `returns built-in and custom attunements`() {
            Attunement.languageOverride = "en"
            val customFile = CustomAudioFile(
                id = "custom-attunement-1",
                name = "My Attunement",
                filename = "custom-attunement-1.mp3",
                durationMs = 60_000L,
                type = CustomAudioType.ATTUNEMENT
            )
            fakeCustomAudioRepository.addFile(customFile)

            val result = resolver.allAvailable()

            assertEquals(2, result.size)
            assertEquals("breath", result[0].id)
            assertEquals("Breathing Exercise", result[0].displayName)
            assertEquals("custom-attunement-1", result[1].id)
            assertEquals("My Attunement", result[1].displayName)
        }

        @Test
        fun `returns empty when no attunements available`() {
            Attunement.languageOverride = "fr"

            val result = resolver.allAvailable()

            assertEquals(0, result.size)
        }

        @Test
        fun `excludes custom soundscapes from results`() {
            Attunement.languageOverride = "en"
            val soundscapeFile = CustomAudioFile(
                id = "custom-soundscape",
                name = "Rain",
                filename = "rain.mp3",
                durationMs = 300_000L,
                type = CustomAudioType.SOUNDSCAPE
            )
            fakeCustomAudioRepository.addFile(soundscapeFile)

            val result = resolver.allAvailable()

            assertEquals(1, result.size)
            assertEquals("breath", result[0].id)
        }
    }
}
