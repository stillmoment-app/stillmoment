package com.stillmoment.domain.models

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Domain tests for [ImportPrefill]. 1:1 port of the iOS `ImportPrefillTests`
 * suite (see `ios-043` + `ios-044`).
 */
class ImportPrefillTest {

    // MARK: - Sanitize

    @Nested
    inner class Sanitize {
        @Test
        fun `null input yields null`() {
            assertNull(ImportPrefill.sanitize(null))
        }

        @Test
        fun `blank string yields null`() {
            assertNull(ImportPrefill.sanitize(""))
            assertNull(ImportPrefill.sanitize("   "))
            assertNull(ImportPrefill.sanitize("\t\n"))
        }

        @Test
        fun `unknown artist variants yield null`() {
            assertNull(ImportPrefill.sanitize("Unknown Artist"))
            assertNull(ImportPrefill.sanitize("unknown_artist"))
            assertNull(ImportPrefill.sanitize("unknown-artist"))
            assertNull(ImportPrefill.sanitize("UNKNOWN ARTIST"))
            assertNull(ImportPrefill.sanitize("Unknown   Artist"))
        }

        @Test
        fun `further blacklist tokens yield null`() {
            assertNull(ImportPrefill.sanitize("Untitled"))
            assertNull(ImportPrefill.sanitize("audio"))
            assertNull(ImportPrefill.sanitize("recording"))
            assertNull(ImportPrefill.sanitize("voice memo"))
            assertNull(ImportPrefill.sanitize("voice_memo"))
        }

        @Test
        fun `track numbering yields null`() {
            assertNull(ImportPrefill.sanitize("Track 01"))
            assertNull(ImportPrefill.sanitize("01"))
            assertNull(ImportPrefill.sanitize("1"))
            assertNull(ImportPrefill.sanitize("track 03"))
            assertNull(ImportPrefill.sanitize("track03"))
        }

        @Test
        fun `clean value passes through unchanged`() {
            assertEquals("Tara Brach", ImportPrefill.sanitize("Tara Brach"))
        }

        @Test
        fun `whitespace is trimmed but inner content untouched`() {
            assertEquals("Body Scan", ImportPrefill.sanitize("  Body Scan  "))
        }
    }

    // MARK: - Preprocess filename

    @Nested
    inner class PreprocessFilename {
        @Test
        fun `strips extension and track prefix`() {
            assertEquals("body scan", ImportPrefill.preprocessFilename("01-body-scan.mp3"))
        }

        @Test
        fun `keeps short title verbatim`() {
            assertEquals("Bodyscan", ImportPrefill.preprocessFilename("Bodyscan.mp3"))
        }

        @Test
        fun `keeps lowercase German title verbatim`() {
            assertEquals(
                "meditation im sitzen",
                ImportPrefill.preprocessFilename("meditation-im-sitzen.mp3")
            )
        }

        @Test
        fun `keeps multi-word filename with mixed case`() {
            assertEquals(
                "Anleitung Bodyscan Deutsch MBSR",
                ImportPrefill.preprocessFilename("Anleitung-Bodyscan-Deutsch-MBSR.mp3")
            )
        }

        @Test
        fun `inserts boundary at CamelCase transition`() {
            assertEquals("Moment Mal", ImportPrefill.preprocessFilename("MomentMal.mp3"))
        }

        @Test
        fun `inserts boundary at acronym end`() {
            assertEquals("MBSR Bodyscan", ImportPrefill.preprocessFilename("MBSRBodyscan.mp3"))
        }

        @Test
        fun `inserts boundary at digit-letter transition`() {
            assertEquals("04 Fuesse", ImportPrefill.preprocessFilename("04Fuesse.mp3"))
        }

        @Test
        fun `combines separator normalization and digit boundary`() {
            assertEquals(
                "Moment mal 04 Fuesse",
                ImportPrefill.preprocessFilename("Moment-mal-04Fuesse.mp3")
            )
        }
    }

    // MARK: - Garbage detection

    @Nested
    inner class GarbageDetection {
        @Test
        fun `UUID v4 is garbage`() {
            assertTrue(
                ImportPrefill.isGarbageFilename("d067c0ea-2c04-b934-1e04-94b2dc2f13dd")
            )
        }

        @Test
        fun `long unbroken token is garbage`() {
            assertTrue(
                ImportPrefill.isGarbageFilename("thisistheverylongunbrokenfilename")
            )
        }

        @Test
        fun `empty string is garbage`() {
            assertTrue(ImportPrefill.isGarbageFilename(""))
        }

        @Test
        fun `short token is not garbage`() {
            assertFalse(ImportPrefill.isGarbageFilename("bodyscan"))
        }

        @Test
        fun `multi-token filename is not garbage even if long`() {
            assertFalse(ImportPrefill.isGarbageFilename("anleitung bodyscan deutsch mbsr"))
        }
    }

    // MARK: - Teacher cascade

    @Nested
    inner class TeacherCascade {
        @Test
        fun `id3 artist wins over filename`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = "Tara Brach", title = null),
                fileName = "some-file.mp3",
                knownTeachers = emptyList()
            )
            assertEquals("Tara Brach", result.teacher)
        }

        @Test
        fun `unknown artist sanitized and falls back to filename match`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = "Unknown Artist", title = null),
                fileName = "bodyscan-tara_brach.mp3",
                knownTeachers = listOf("Tara Brach")
            )
            assertEquals("Tara Brach", result.teacher)
        }

        @Test
        fun `filename match against known teacher`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = null, title = null),
                fileName = "bodyscan-tara_brach.mp3",
                knownTeachers = listOf("Tara Brach")
            )
            assertEquals("Tara Brach", result.teacher)
        }

        @Test
        fun `known teachers with Unknown Artist are filtered`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = null, title = null),
                fileName = "unknown-bodyscan.mp3",
                knownTeachers = listOf("Unknown Artist", "Tara Brach")
            )
            assertNull(result.teacher)
        }

        @Test
        fun `longest matching known teacher wins`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = null, title = null),
                fileName = "bodyscan-tara-brach.mp3",
                knownTeachers = listOf("Tara", "Tara Brach")
            )
            assertEquals("Tara Brach", result.teacher)
        }

        @Test
        fun `short single-word teacher is ineligible for filename match`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = null, title = null),
                fileName = "tara-bodyscan.mp3",
                knownTeachers = listOf("Tara")
            )
            assertNull(result.teacher)
        }

        @Test
        fun `empty known teachers leaves teacher null`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = null, title = null),
                fileName = "bodyscan.mp3",
                knownTeachers = emptyList()
            )
            assertNull(result.teacher)
        }
    }

    // MARK: - Title cascade

    @Nested
    inner class TitleCascade {
        @Test
        fun `id3 title wins`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = null, title = "Body Scan"),
                fileName = "irrelevant.mp3",
                knownTeachers = emptyList()
            )
            assertEquals("Body Scan", result.name)
        }

        @Test
        fun `untitled id3 falls back to filename`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = null, title = "Untitled"),
                fileName = "Anleitung-Bodyscan-Deutsch-MBSR.mp3",
                knownTeachers = emptyList()
            )
            assertEquals("Anleitung Bodyscan Deutsch MBSR", result.name)
        }

        @Test
        fun `verbatim filename used when no id3 title`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = null, title = null),
                fileName = "meditation-im-sitzen.mp3",
                knownTeachers = emptyList()
            )
            assertEquals("meditation im sitzen", result.name)
        }

        @Test
        fun `teacher matched from filename is stripped from name`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = null, title = null),
                fileName = "bodyscan-tara_brach.mp3",
                knownTeachers = listOf("Tara Brach")
            )
            assertEquals("Tara Brach", result.teacher)
            assertEquals("bodyscan", result.name)
        }

        @Test
        fun `teacher from id3 is also stripped from filename`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = "Tara Brach", title = null),
                fileName = "bodyscan-tara_brach.mp3",
                knownTeachers = emptyList()
            )
            assertEquals("Tara Brach", result.teacher)
            assertEquals("bodyscan", result.name)
        }

        @Test
        fun `teacher not in filename leaves filename as name`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = "Tara Brach", title = null),
                fileName = "morning-meditation.mp3",
                knownTeachers = emptyList()
            )
            assertEquals("morning meditation", result.name)
        }

        @Test
        fun `UUID filename yields null name`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = null, title = null),
                fileName = "d067c0ea-2c04-b934-1e04-94b2dc2f13dd.mp3",
                knownTeachers = emptyList()
            )
            assertNull(result.name)
        }

        @Test
        fun `audio placeholder filename yields null name`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = null, title = null),
                fileName = "audio.mp3",
                knownTeachers = emptyList()
            )
            assertNull(result.name)
        }

        @Test
        fun `track prefix stripped from name`() {
            val result = ImportPrefill.compute(
                metadata = AudioMetadata(0L, artist = null, title = null),
                fileName = "01-body-scan.mp3",
                knownTeachers = emptyList()
            )
            assertEquals("body scan", result.name)
        }
    }
}
