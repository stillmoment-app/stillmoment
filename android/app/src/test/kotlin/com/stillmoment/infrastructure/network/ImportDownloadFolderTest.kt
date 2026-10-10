package com.stillmoment.infrastructure.network

import java.io.File
import kotlin.io.path.createTempDirectory
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * android-087: Files loaded by the link and podcast import are only needed until
 * the import ends. The library keeps its own copy.
 */
class ImportDownloadFolderTest {

    private lateinit var cacheDir: File
    private lateinit var sut: ImportDownloadFolder

    @BeforeEach
    fun setUp() {
        cacheDir = createTempDirectory("import_download_folder").toFile()
        sut = newFolder()
    }

    @AfterEach
    fun tearDown() {
        cacheDir.deleteRecursively()
    }

    /** A new app process: same storage, nothing known about earlier downloads. */
    private fun newFolder() = ImportDownloadFolder(cacheDir = { cacheDir }, logger = mock())

    private fun downloadedFile(folder: ImportDownloadFolder = sut, name: String = "talk.mp3"): File {
        val file = File(folder.createDownloadDirectory(), name)
        file.writeText("audio")
        return file
    }

    private fun filesLeft(): List<File> = cacheDir.walkTopDown().filter { it.isFile }.toList()

    @Nested
    inner class Discard {
        @Test
        fun `discarding a downloaded file frees its storage`() = runTest {
            val file = downloadedFile()

            sut.discard(file.toURI().toString())

            assertEquals(emptyList<File>(), filesLeft())
            assertFalse(file.parentFile?.exists() == true) { "The download's own directory is gone too" }
        }

        @Test
        fun `discarding a download whose name contains spaces frees its storage`() = runTest {
            val file = downloadedFile(name = "Moment mal 01 Atem.mp3")

            sut.discard(file.toURI().toString())

            assertEquals(emptyList<File>(), filesLeft())
        }

        @Test
        fun `discarding one download keeps the other`() = runTest {
            val first = downloadedFile()
            val second = downloadedFile()

            sut.discard(first.toURI().toString())

            assertEquals(listOf(second.canonicalFile), filesLeft().map { it.canonicalFile })
        }

        @Test
        fun `a file handed over by another app is never deleted`() = runTest {
            sut.discard("content://com.android.providers.downloads.documents/document/42")

            // Nothing to assert on the provider; the call must simply be a no-op without crashing.
            assertEquals(emptyList<File>(), filesLeft())
        }

        @Test
        fun `a local file outside the download folder is never deleted`() = runTest {
            val libraryCopy = File(cacheDir, "meditations/abc.mp3").apply {
                parentFile?.mkdirs()
                writeText("audio")
            }

            sut.discard(libraryCopy.toURI().toString())

            assertTrue(libraryCopy.exists())
        }

        @Test
        fun `a path that climbs out of the download folder is never deleted`() = runTest {
            val outside = File(cacheDir, "keep.mp3").apply { writeText("audio") }
            val dir = sut.createDownloadDirectory()
            val sneaky = File(dir, "../../keep.mp3")

            sut.discard(sneaky.toURI().toString())

            assertTrue(outside.exists())
        }
    }

    @Nested
    inner class TwoDownloadsAtOnce {
        @Test
        fun `two downloads started at the same time get their own place`() {
            val first = sut.createDownloadDirectory()
            val second = sut.createDownloadDirectory()

            assertNotEquals(first.canonicalPath, second.canonicalPath)
            assertTrue(first.isDirectory)
            assertTrue(second.isDirectory)
        }
    }

    @Nested
    inner class LeftoversAtStart {
        @Test
        fun `downloads of an earlier app run are removed at start`() = runTest {
            downloadedFile(folder = newFolder())

            sut.removeLeftovers()

            assertEquals(emptyList<File>(), filesLeft())
        }

        @Test
        fun `downloads of versions before android-087 are removed at start`() = runTest {
            File(cacheDir, "dl_1712345678901/Moment-mal-01Atem.mp3").apply {
                parentFile?.mkdirs()
                writeText("audio")
            }

            sut.removeLeftovers()

            assertEquals(emptyList<File>(), filesLeft())
        }

        @Test
        fun `a download of the running app survives the start clean-up`() = runTest {
            val loading = downloadedFile()

            sut.removeLeftovers()

            assertTrue(loading.exists())
        }

        @Test
        fun `other cached data is left alone`() = runTest {
            val other = File(cacheDir, "image_cache/thumb.png").apply {
                parentFile?.mkdirs()
                writeText("png")
            }
            val looseFile = File(cacheDir, "dl_notes.txt").apply { writeText("x") }

            sut.removeLeftovers()

            assertTrue(other.exists())
            assertTrue(looseFile.exists())
        }
    }
}
