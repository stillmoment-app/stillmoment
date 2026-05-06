package com.stillmoment.infrastructure.network

import android.content.Context
import android.net.Uri
import com.stillmoment.domain.models.UrlAudioDownloadError
import com.stillmoment.domain.services.LoggerProtocol
import java.io.ByteArrayInputStream
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.net.HttpURLConnection
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.io.path.createTempDirectory
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.doAnswer
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
        cacheDir = createTempDirectory("downloader_test").toFile()
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

            // android-077: file lives in a per-download sub-directory with original name
            val downloadedFiles = cacheDir.walkTopDown().filter { it.isFile }.toList()
            assertTrue(downloadedFiles.isNotEmpty()) { "Expected a downloaded file under cacheDir" }
            assertTrue(downloadedFiles.any { it.length() == audioBytes.size.toLong() })
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
        fun `accepts non-standard audio-slash-mp3 content type`() = kotlinx.coroutines.test.runTest {
            // Many CDNs (audiodharma's S3 backend at linodeobjects.com is one example)
            // send the non-standard "audio/mp3" instead of the official "audio/mpeg".
            // Both must be accepted — otherwise the user sees "Keine Aufnahme gefunden"
            // for what is clearly a valid MP3 download.
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("audio/mp3")
            whenever(mockConnection.inputStream).thenReturn(ByteArrayInputStream("data".toByteArray()))

            val result = sut.download("https://example.com/audio.mp3")

            assertTrue(result.isSuccess) {
                "Expected success for audio/mp3, got ${result.exceptionOrNull()?.javaClass?.simpleName}"
            }
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
        fun `downloaded file uses original filename without prefix`() = kotlinx.coroutines.test.runTest {
            // android-077: downloaded file should be named exactly like the URL filename,
            // so the imported meditation shows a clean name in the library
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("audio/mpeg")
            whenever(mockConnection.inputStream).thenReturn(ByteArrayInputStream("data".toByteArray()))

            sut.download("https://cdn.example.com/my-meditation.mp3")

            val downloadedFiles = cacheDir.walkTopDown().filter { it.isFile }.toList()
            val names = downloadedFiles.map { it.name }
            assertTrue(
                names.contains("my-meditation.mp3"),
                "Expected file 'my-meditation.mp3' (no prefix). Found: $names"
            )
        }
    }

    @Nested
    inner class HttpErrors {

        @Test
        fun `returns Http error for 404 not found`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_NOT_FOUND)

            val result = sut.download("https://example.com/missing.mp3")

            val error = result.exceptionOrNull()
            assertTrue(error is UrlAudioDownloadError.Http) { "Expected Http error, got ${error?.javaClass}" }
            assertEquals(HttpURLConnection.HTTP_NOT_FOUND, (error as UrlAudioDownloadError.Http).code)
        }

        @Test
        fun `returns Http error for 403 forbidden`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_FORBIDDEN)

            val result = sut.download("https://example.com/protected.mp3")

            val error = result.exceptionOrNull()
            assertTrue(error is UrlAudioDownloadError.Http)
            assertEquals(HttpURLConnection.HTTP_FORBIDDEN, (error as UrlAudioDownloadError.Http).code)
        }

        @Test
        fun `returns Http error for 500 server error`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_INTERNAL_ERROR)

            val result = sut.download("https://example.com/error.mp3")

            val error = result.exceptionOrNull()
            assertTrue(error is UrlAudioDownloadError.Http)
        }
    }

    @Nested
    inner class UnsupportedContentType {

        @Test
        fun `returns NotAudio for html content type`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("text/html")

            val result = sut.download("https://example.com/page.html")

            assertTrue(result.exceptionOrNull() is UrlAudioDownloadError.NotAudio)
        }

        @Test
        fun `returns NotAudio for video content type`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("video/mp4")

            val result = sut.download("https://example.com/video.mp4")

            assertTrue(result.exceptionOrNull() is UrlAudioDownloadError.NotAudio)
        }
    }

    @Nested
    inner class ConnectionErrors {

        @Test
        fun `returns Network error when connection throws io exception`() = kotlinx.coroutines.test.runTest {
            whenever(mockConnection.responseCode).thenThrow(IOException("Network unreachable"))

            val result = sut.download("https://example.com/audio.mp3")

            assertTrue(result.exceptionOrNull() is UrlAudioDownloadError.Network)
        }

        @Test
        fun `returns Network error when connection factory throws`() = kotlinx.coroutines.test.runTest {
            // shared-091 "kein silent fail": pathological inputs (malformed URLs that pass
            // the scheme-only validator) must surface as a typed error too — otherwise the
            // exception escapes download() and the LaunchedEffect leaves the loading modal
            // stuck on screen.
            val throwingSut = UrlAudioDownloaderImpl(
                context = mockContext,
                logger = mockLogger,
                connectionFactory = { throw IOException("malformed url") },
                uriFromFile = { mockUri }
            )

            val result = throwingSut.download("https://invalid url with spaces")

            assertTrue(result.exceptionOrNull() is UrlAudioDownloadError.Network) {
                "Expected Network error, got ${result.exceptionOrNull()?.javaClass}"
            }
        }
    }

    @Nested
    inner class FilenameResolution {

        @Test
        fun `uses Content-Disposition filename when present`() = kotlinx.coroutines.test.runTest {
            // shared-091: audiodharma.org/talks/.../download → S3 redirect with
            // Content-Disposition: attachment; filename="20260504-talk.mp3"
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("audio/mpeg")
            whenever(mockConnection.getHeaderField("Content-Disposition"))
                .thenReturn("attachment; filename=\"20260504-talk.mp3\"")
            whenever(mockConnection.inputStream).thenReturn(ByteArrayInputStream("data".toByteArray()))

            sut.download("https://www.audiodharma.org/talks/25401/download")

            val names = cacheDir.walkTopDown().filter { it.isFile }.map { it.name }.toList()
            assertTrue("20260504-talk.mp3" in names) {
                "Expected file '20260504-talk.mp3', found: $names"
            }
        }

        @Test
        fun `parses Content-Disposition filename star encoding`() = kotlinx.coroutines.test.runTest {
            // RFC 6266: filename*=UTF-8''percent-encoded-name takes precedence
            // when both filename and filename* are present.
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("audio/mpeg")
            whenever(mockConnection.getHeaderField("Content-Disposition"))
                .thenReturn("""attachment; filename="ascii.mp3"; filename*=UTF-8''Sch%C3%B6n.mp3""")
            whenever(mockConnection.inputStream).thenReturn(ByteArrayInputStream("data".toByteArray()))

            sut.download("https://example.com/talk")

            val names = cacheDir.walkTopDown().filter { it.isFile }.map { it.name }.toList()
            assertTrue("Schön.mp3" in names) { "Expected decoded UTF-8 filename, found: $names" }
        }

        @Test
        fun `falls back to audio_mp3 for url without extension and no Content-Disposition`() =
            kotlinx.coroutines.test.runTest {
                whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
                whenever(mockConnection.contentType).thenReturn("audio/mpeg")
                whenever(mockConnection.getHeaderField("Content-Disposition")).thenReturn(null)
                whenever(mockConnection.inputStream).thenReturn(ByteArrayInputStream("data".toByteArray()))

                sut.download("https://www.audiodharma.org/talks/25401/download")

                val names = cacheDir.walkTopDown().filter { it.isFile }.map { it.name }.toList()
                assertTrue("audio.mp3" in names) { "Expected fallback audio.mp3, found: $names" }
            }

        @Test
        fun `falls back to audio_m4a when content type is audio-mp4`() = runTest {
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("audio/mp4")
            whenever(mockConnection.getHeaderField("Content-Disposition")).thenReturn(null)
            whenever(mockConnection.inputStream).thenReturn(ByteArrayInputStream("data".toByteArray()))

            sut.download("https://example.com/episode")

            val names = cacheDir.walkTopDown().filter { it.isFile }.map { it.name }.toList()
            assertTrue("audio.m4a" in names) { "Expected fallback audio.m4a, found: $names" }
        }

        @Test
        fun `prefers URL filename over Content-Disposition without audio extension`() =
            kotlinx.coroutines.test.runTest {
                // If the server's Content-Disposition lacks an audio extension
                // (e.g. just "track"), don't import the file under that name —
                // it would be rejected by the importer downstream. Use the URL
                // path filename instead, since it has the right extension.
                whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
                whenever(mockConnection.contentType).thenReturn("audio/mpeg")
                whenever(mockConnection.getHeaderField("Content-Disposition"))
                    .thenReturn("attachment; filename=\"track\"")
                whenever(mockConnection.inputStream).thenReturn(ByteArrayInputStream("data".toByteArray()))

                sut.download("https://example.com/song.mp3")

                val names = cacheDir.walkTopDown().filter { it.isFile }.map { it.name }.toList()
                assertTrue("song.mp3" in names) { "Expected URL filename song.mp3, found: $names" }
            }

        @Test
        fun `strips path separators from Content-Disposition filename`() = runTest {
            // Defence against directory traversal — the header is from the server
            // and must not be allowed to write outside the per-download directory.
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("audio/mpeg")
            whenever(mockConnection.getHeaderField("Content-Disposition"))
                .thenReturn("""attachment; filename="../../etc/passwd.mp3"""")
            whenever(mockConnection.inputStream).thenReturn(ByteArrayInputStream("data".toByteArray()))

            sut.download("https://example.com/track")

            val files = cacheDir.walkTopDown().filter { it.isFile }.toList()
            val names = files.map { it.name }
            assertTrue("passwd.mp3" in names) { "Expected sanitised passwd.mp3, found: $names" }
            // No file should leak outside the per-download directory.
            assertNull(files.firstOrNull { it.path.contains("..") })
        }
    }

    @Nested
    inner class Cancellation {

        @Test
        fun `cancel without active download is a no-op`() {
            // Should not crash
            sut.cancel()
        }

        @OptIn(ExperimentalCoroutinesApi::class)
        @Test
        fun `cancel during running download returns CancellationException`() = runTest(
            UnconfinedTestDispatcher()
        ) {
            // Deterministic synchronisation: don't rely on `delay()` (which is virtual time
            // under UnconfinedTestDispatcher) to wait for the IO-thread to start the
            // download. Use real latches instead.
            // 1. The slow stream signals `downloadStarted` once read() blocks, so the test
            //    only calls cancel() after the download genuinely entered the read.
            // 2. disconnect() on the mock counts down `cancelLatch`, releasing the read so
            //    the download finishes promptly instead of waiting on Thread.sleep(10s).
            val downloadStarted = CompletableDeferred<Unit>()
            val cancelLatch = CountDownLatch(1)
            doAnswer {
                cancelLatch.countDown()
                null
            }.whenever(mockConnection).disconnect()

            val slowStream = object : InputStream() {
                override fun read(): Int {
                    downloadStarted.complete(Unit)
                    cancelLatch.await(5, TimeUnit.SECONDS)
                    return -1
                }
            }
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("audio/mpeg")
            whenever(mockConnection.inputStream).thenReturn(slowStream)

            val deferred = async { sut.download("https://example.com/slow.mp3") }
            downloadStarted.await()
            sut.cancel()

            val result = deferred.await()
            assertTrue(result.isFailure) { "Expected failure after cancel" }
            val exception = result.exceptionOrNull()
            assertNotNull(exception)
            assertTrue(
                exception is CancellationException,
                "Expected CancellationException but got ${exception?.javaClass?.simpleName}"
            )
        }

        @OptIn(ExperimentalCoroutinesApi::class)
        @Test
        fun `subsequent download after cancel runs cleanly`() = runTest(UnconfinedTestDispatcher()) {
            val downloadStarted = CompletableDeferred<Unit>()
            val cancelLatch = CountDownLatch(1)
            doAnswer {
                cancelLatch.countDown()
                null
            }.whenever(mockConnection).disconnect()

            val slowStream = object : InputStream() {
                override fun read(): Int {
                    downloadStarted.complete(Unit)
                    cancelLatch.await(5, TimeUnit.SECONDS)
                    return -1
                }
            }
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.contentType).thenReturn("audio/mpeg")
            whenever(mockConnection.inputStream).thenReturn(slowStream)

            val firstDeferred = async { sut.download("https://example.com/slow.mp3") }
            downloadStarted.await()
            sut.cancel()
            firstDeferred.await()

            // Reset mocks for the second, fast download (new connection from factory)
            val freshConnection: HttpURLConnection = mock()
            val freshUri: Uri = mock()
            whenever(freshConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(freshConnection.contentType).thenReturn("audio/mpeg")
            whenever(freshConnection.inputStream).thenReturn(ByteArrayInputStream("ok".toByteArray()))
            val sutFresh = UrlAudioDownloaderImpl(
                context = mockContext,
                logger = mockLogger,
                connectionFactory = { freshConnection },
                uriFromFile = { freshUri }
            )

            val secondResult = sutFresh.download("https://example.com/fast.mp3")
            assertTrue(secondResult.isSuccess) { "Second download should succeed after cancel" }
            assertEquals(freshUri, secondResult.getOrNull())
        }
    }
}
