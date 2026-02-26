package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for CustomAudioFile domain model.
 */
class CustomAudioFileTest {

    // MARK: - FormattedDuration Tests

    @Nested
    inner class FormattedDuration {
        @Test
        fun `returns null when duration is null`() {
            val file = CustomAudioFile(
                name = "test",
                filename = "test.mp3",
                durationMs = null,
                type = CustomAudioType.SOUNDSCAPE
            )
            assertNull(file.formattedDuration)
        }

        @Test
        fun `formats zero seconds as 0 colon 00`() {
            val file = CustomAudioFile(
                name = "test",
                filename = "test.mp3",
                durationMs = 0L,
                type = CustomAudioType.SOUNDSCAPE
            )
            assertEquals("0:00", file.formattedDuration)
        }

        @Test
        fun `formats 60 seconds as 1 colon 00`() {
            val file = CustomAudioFile(
                name = "test",
                filename = "test.mp3",
                durationMs = 60_000L,
                type = CustomAudioType.SOUNDSCAPE
            )
            assertEquals("1:00", file.formattedDuration)
        }

        @Test
        fun `formats 125 seconds as 2 colon 05`() {
            val file = CustomAudioFile(
                name = "test",
                filename = "test.mp3",
                durationMs = 125_000L,
                type = CustomAudioType.SOUNDSCAPE
            )
            assertEquals("2:05", file.formattedDuration)
        }

        @Test
        fun `formats 3600 seconds as 60 colon 00`() {
            val file = CustomAudioFile(
                name = "test",
                filename = "test.mp3",
                durationMs = 3_600_000L,
                type = CustomAudioType.SOUNDSCAPE
            )
            assertEquals("60:00", file.formattedDuration)
        }
    }

    // MARK: - Type Distinction Tests

    @Nested
    inner class TypeDistinction {
        @Test
        fun `soundscape type is SOUNDSCAPE`() {
            val file = CustomAudioFile(
                name = "ocean",
                filename = "ocean.mp3",
                durationMs = 60_000L,
                type = CustomAudioType.SOUNDSCAPE
            )
            assertEquals(CustomAudioType.SOUNDSCAPE, file.type)
        }

        @Test
        fun `attunement type is ATTUNEMENT`() {
            val file = CustomAudioFile(
                name = "breath",
                filename = "breath.mp3",
                durationMs = 90_000L,
                type = CustomAudioType.ATTUNEMENT
            )
            assertEquals(CustomAudioType.ATTUNEMENT, file.type)
        }
    }

    // MARK: - Identity Tests

    @Nested
    inner class Identity {
        @Test
        fun `two files with same id are equal`() {
            val id = "test-id-123"
            val file1 = CustomAudioFile(
                id = id,
                name = "a",
                filename = "a.mp3",
                durationMs = null,
                type = CustomAudioType.SOUNDSCAPE,
                dateAdded = 1000L
            )
            val file2 = CustomAudioFile(
                id = id,
                name = "a",
                filename = "a.mp3",
                durationMs = null,
                type = CustomAudioType.SOUNDSCAPE,
                dateAdded = 1000L
            )
            assertEquals(file1, file2)
        }

        @Test
        fun `default id is unique per instance`() {
            val file1 = CustomAudioFile(
                name = "a",
                filename = "a.mp3",
                durationMs = null,
                type = CustomAudioType.SOUNDSCAPE
            )
            val file2 = CustomAudioFile(
                name = "a",
                filename = "a.mp3",
                durationMs = null,
                type = CustomAudioType.SOUNDSCAPE
            )
            assertNotEquals(file1.id, file2.id)
        }
    }
}
