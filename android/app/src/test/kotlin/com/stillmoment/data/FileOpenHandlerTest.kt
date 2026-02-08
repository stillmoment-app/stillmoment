package com.stillmoment.data

import com.stillmoment.domain.models.FileOpenError
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Tests for FileOpenHandler logic.
 *
 * Note: Full integration tests require Android instrumentation (ContentResolver, Uri).
 * These tests verify the domain error model and supported format constants.
 */
class FileOpenHandlerTest {

    @Nested
    inner class SupportedFormats {
        @Test
        fun `supported MIME types include audio mpeg`() {
            assertTrue("audio/mpeg" in FileOpenHandler.SUPPORTED_MIME_TYPES)
        }

        @Test
        fun `supported MIME types include audio mp4`() {
            assertTrue("audio/mp4" in FileOpenHandler.SUPPORTED_MIME_TYPES)
        }

        @Test
        fun `supported MIME types include audio x-m4a`() {
            assertTrue("audio/x-m4a" in FileOpenHandler.SUPPORTED_MIME_TYPES)
        }

        @Test
        fun `supported MIME types do not include wav`() {
            assertTrue("audio/wav" !in FileOpenHandler.SUPPORTED_MIME_TYPES)
        }

        @Test
        fun `supported MIME types do not include pdf`() {
            assertTrue("application/pdf" !in FileOpenHandler.SUPPORTED_MIME_TYPES)
        }

        @Test
        fun `supported extensions include mp3 and m4a`() {
            assertTrue("mp3" in FileOpenHandler.SUPPORTED_EXTENSIONS)
            assertTrue("m4a" in FileOpenHandler.SUPPORTED_EXTENSIONS)
        }

        @Test
        fun `supported extensions do not include wav`() {
            assertTrue("wav" !in FileOpenHandler.SUPPORTED_EXTENSIONS)
        }
    }

    @Nested
    inner class FileOpenErrorModel {
        @Test
        fun `all error types are distinct`() {
            val errors = FileOpenError.entries
            assertEquals(3, errors.size)
            assertEquals(3, errors.toSet().size)
        }

        @Test
        fun `error names are stable for logging`() {
            assertEquals("UNSUPPORTED_FORMAT", FileOpenError.UNSUPPORTED_FORMAT.name)
            assertEquals("IMPORT_FAILED", FileOpenError.IMPORT_FAILED.name)
            assertEquals("ALREADY_IMPORTED", FileOpenError.ALREADY_IMPORTED.name)
        }
    }

    @Nested
    inner class FileOpenExceptionModel {
        @Test
        fun `exception carries error type`() {
            val exception = FileOpenException(FileOpenError.UNSUPPORTED_FORMAT)
            assertEquals(FileOpenError.UNSUPPORTED_FORMAT, exception.error)
        }

        @Test
        fun `exception carries cause`() {
            val cause = RuntimeException("test")
            val exception = FileOpenException(FileOpenError.IMPORT_FAILED, cause)
            assertEquals(cause, exception.cause)
        }

        @Test
        fun `exception message contains error name`() {
            val exception = FileOpenException(FileOpenError.ALREADY_IMPORTED)
            assertNotNull(exception.message)
            assertTrue(exception.message!!.contains("ALREADY_IMPORTED"))
        }
    }
}
