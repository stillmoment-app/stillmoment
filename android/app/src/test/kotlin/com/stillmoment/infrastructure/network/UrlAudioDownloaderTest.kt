package com.stillmoment.infrastructure.network

import android.content.Context
import android.net.Uri
import com.stillmoment.domain.services.LoggerProtocol
import java.io.ByteArrayInputStream
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock
import org.mockito.kotlin.whenever

/**
 * Tests for UrlAudioDownloaderImpl.
 *
 * Covers successful download, HTTP errors, unsupported content type,
 * and connection error handling.
 */
class UrlAudioDownloaderTest {

    private lateinit var mockContext: Context
    private lateinit var mockLogger: LoggerProtocol
    private lateinit var mockConnection: HttpURLConnection
    private lateinit var mockUri: Uri
    private lateinit var cacheDir: File
    private lateinit var sut: UrlAudioDownloaderImpl

    @BeforeEach
    fun setUp() {
        cacheDir = createTempDir("downloader_test")
        mockContext = mock()
        mockLogger = mock()
        mockConnection = mock()
        mockUri = mock()
        whenever(mockContext.cacheDir).thenReturn(cacheDir)

        sut = UrlAudioDownloaderImpl(
            context = mockContext,
            logger = mockLogger,
            connectionFactory = { mockConnection },
            uriFromFile = { mockUri }
        )
    }

    @AfterEach
    fun tearDown() {
        cacheDir.deleteRecursively()
    }

    @Nested
    inner class SuccessfulDownload {

        @Test
        fun `downloads mp3 and returns uri`() = kotlinx.coroutines.test.runTest {
            val audioBytes = "fake-audio-content".toByteArray()
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("audio/mpeg")
            whenever(mockConnection.inputStream).thenReturn(ByteArrayInputStream(audioBytes))

            val result = sut.download("https://example.com/meditation.mp3")

            assertTrue(result.isSuccess)
            assertTrue(result.getOrThrow() === mockUri)
        }

        @Test
        fun `writes audio bytes to cache file`() = kotlinx.coroutines.test.runTest {
            val audioBytes = "fake-audio-content".toByteArray()
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("audio/mpeg")
            whenever(mockConnection.inputStream).thenReturn(ByteArrayInputStream(audioBytes))

            sut.download("https://example.com/meditation.mp3")

            val files = cacheDir.listFiles() ?: emptyArray()
            assertTrue(files.isNotEmpty()) { "Expected a temp file in cacheDir" }
            assertTrue(files.any { it.length() == audioBytes.size.toLong() })
        }

        @Test
        fun `downloads m4a with audio-slash-mp4 content type`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("audio/mp4")
            whenever(mockConnection.inputStream).thenReturn(ByteArrayInputStream("data".toByteArray()))

            val result = sut.download("https://example.com/session.m4a")

            assertTrue(result.isSuccess)
        }

        @Test
        fun `accepts octet-stream content type as fallback`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("application/octet-stream")
            whenever(mockConnection.inputStream).thenReturn(ByteArrayInputStream("data".toByteArray()))

            val result = sut.download("https://example.com/audio.mp3")

            assertTrue(result.isSuccess)
        }

        @Test
        fun `accepts null content type`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn(null)
            whenever(mockConnection.inputStream).thenReturn(ByteArrayInputStream("data".toByteArray()))

            val result = sut.download("https://example.com/audio.mp3")

            assertTrue(result.isSuccess)
        }

        @Test
        fun `temp filename includes original filename`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("audio/mpeg")
            whenever(mockConnection.inputStream).thenReturn(ByteArrayInputStream("data".toByteArray()))

            sut.download("https://cdn.example.com/my-meditation.mp3")

            val files = cacheDir.listFiles() ?: emptyArray()
            assertTrue(files.any { it.name.contains("my-meditation.mp3") })
        }
    }

    @Nested
    inner class HttpErrors {

        @Test
        fun `returns failure for 404 not found`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_NOT_FOUND)

            val result = sut.download("https://example.com/missing.mp3")

            assertTrue(result.isFailure)
        }

        @Test
        fun `returns failure for 403 forbidden`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_FORBIDDEN)

            val result = sut.download("https://example.com/protected.mp3")

            assertTrue(result.isFailure)
        }

        @Test
        fun `returns failure for 500 server error`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_INTERNAL_ERROR)

            val result = sut.download("https://example.com/error.mp3")

            assertTrue(result.isFailure)
        }
    }

    @Nested
    inner class UnsupportedContentType {

        @Test
        fun `returns failure for html content type`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("text/html")

            val result = sut.download("https://example.com/page.html")

            assertTrue(result.isFailure)
        }

        @Test
        fun `returns failure for video content type`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("video/mp4")

            val result = sut.download("https://example.com/video.mp4")

            assertTrue(result.isFailure)
        }
    }

    @Nested
    inner class ConnectionErrors {

        @Test
        fun `returns failure when connection throws io exception`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenThrow(IOException("Network unreachable"))

            val result = sut.download("https://example.com/audio.mp3")

            assertTrue(result.isFailure)
        }
    }
}
