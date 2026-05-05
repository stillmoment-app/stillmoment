package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Tests for ImportAudioType — verifies the import type selection model
 * supports the required import destinations after shared-088 removed Attunement.
 */
class ImportAudioTypeTest {

    @Nested
    inner class AvailableImportTypes {
        @Test
        fun `exactly two import types are available`() {
            assertEquals(2, ImportAudioType.entries.size)
        }

        @Test
        fun `guided meditation is an available import type`() {
            assertTrue(ImportAudioType.entries.contains(ImportAudioType.GUIDED_MEDITATION))
        }

        @Test
        fun `soundscape is an available import type`() {
            assertTrue(ImportAudioType.entries.contains(ImportAudioType.SOUNDSCAPE))
        }
    }

    @Nested
    inner class ImportTypeMapping {
        @Test
        fun `soundscape import type corresponds to soundscape custom audio type`() {
            // ImportAudioType.SOUNDSCAPE should map to CustomAudioType.SOUNDSCAPE
            // This verifies the naming convention that NavGraph uses for routing
            assertEquals(
                CustomAudioType.SOUNDSCAPE.name,
                ImportAudioType.SOUNDSCAPE.name
            )
        }

        @Test
        fun `guided meditation has no corresponding custom audio type`() {
            // GUIDED_MEDITATION routes to the library, not custom audio
            val customAudioNames = CustomAudioType.entries.map { it.name }.toSet()
            assertTrue(ImportAudioType.GUIDED_MEDITATION.name !in customAudioNames)
        }
    }
}
