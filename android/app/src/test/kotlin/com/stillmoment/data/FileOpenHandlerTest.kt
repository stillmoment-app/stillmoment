package com.stillmoment.data

import android.content.ContentResolver
import android.content.Context
import android.database.MatrixCursor
import android.net.Uri
import android.provider.OpenableColumns
import com.stillmoment.domain.models.FileOpenError
import com.stillmoment.domain.repositories.GuidedMeditationRepository
import com.stillmoment.domain.services.LoggerProtocol
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.isNull
import org.mockito.kotlin.mock
import org.mockito.kotlin.whenever

/**
 * Tests for FileOpenHandler logic.
 *
 * Covers format validation (MP3/M4A acceptance, unsupported rejection)
 * and verifies that validateFileFormat is side-effect-free.
 */
class FileOpenHandlerTest {

    private lateinit var mockContext: Context
    private lateinit var mockContentResolver: ContentResolver
    private lateinit var mockRepository: GuidedMeditationRepository
    private lateinit var mockLogger: LoggerProtocol
    private lateinit var sut: FileOpenHandler

    @BeforeEach
    fun setUp() {
        mockContext = mock()
        mockContentResolver = mock()
        mockRepository = mock()
        mockLogger = mock()
        whenever(mockContext.contentResolver).thenReturn(mockContentResolver)
        sut = FileOpenHandler(mockContext, mockRepository, mockLogger)
    }

    /**
     * Creates a mock URI that returns the given MIME type and display name.
     * Uses thenAnswer to provide a fresh cursor for each query call,
     * since MatrixCursor has internal position state and cannot be reused.
     */
    private fun createMockUri(mimeType: String?, displayName: String): Uri {
        val uri = mock<Uri>()
        whenever(mockContentResolver.getType(uri)).thenReturn(mimeType)

        whenever(
            mockContentResolver.query(any(), isNull(), isNull(), isNull(), isNull())
        ).thenAnswer {
            MatrixCursor(arrayOf(OpenableColumns.DISPLAY_NAME)).apply {
                addRow(arrayOf(displayName))
            }
        }

        return uri
    }

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
    inner class FormatValidation {
        @Test
        fun `mp3 file passes format validation`() {
            val uri = createMockUri("audio/mpeg", "meditation.mp3")
            val result = sut.validateFileFormat(uri)
            assertTrue(result.isSuccess)
        }

        @Test
        fun `m4a file passes format validation`() {
            val uri = createMockUri("audio/mp4", "meditation.m4a")
            val result = sut.validateFileFormat(uri)
            assertTrue(result.isSuccess)
        }

        @Test
        fun `m4a file with x-m4a MIME type passes format validation`() {
            val uri = createMockUri("audio/x-m4a", "meditation.m4a")
            val result = sut.validateFileFormat(uri)
            assertTrue(result.isSuccess)
        }

        @Test
        fun `wav file is rejected`() {
            val uri = createMockUri("audio/wav", "nature.wav")
            val result = sut.validateFileFormat(uri)
            assertTrue(result.isFailure)
            val error = (result.exceptionOrNull() as FileOpenException).error
            assertEquals(FileOpenError.UNSUPPORTED_FORMAT, error)
        }

        @Test
        fun `pdf file is rejected`() {
            val uri = createMockUri("application/pdf", "document.pdf")
            val result = sut.validateFileFormat(uri)
            assertTrue(result.isFailure)
        }

        @Test
        fun `text file is rejected`() {
            val uri = createMockUri("text/plain", "notes.txt")
            val result = sut.validateFileFormat(uri)
            assertTrue(result.isFailure)
        }

        @Test
        fun `format validation does not import the file`() {
            val uri = createMockUri("audio/mpeg", "meditation.mp3")

            sut.validateFileFormat(uri)

            // Repository should never be called — validateFileFormat is side-effect-free
            org.mockito.kotlin.verifyNoInteractions(mockRepository)
        }

        @Test
        fun `format validation does not check for duplicates`() {
            val uri = createMockUri("audio/mpeg", "meditation.mp3")

            sut.validateFileFormat(uri)

            // No duplicate check should happen — only format is validated
            org.mockito.kotlin.verifyNoInteractions(mockRepository)
        }
    }

    @Nested
    inner class CanHandle {
        @Test
        fun `mp3 file can be handled`() {
            val uri = createMockUri("audio/mpeg", "meditation.mp3")
            assertTrue(sut.canHandle(uri))
        }

        @Test
        fun `unsupported file cannot be handled`() {
            val uri = createMockUri("video/mp4", "movie.mp4")
            assertFalse(sut.canHandle(uri))
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
