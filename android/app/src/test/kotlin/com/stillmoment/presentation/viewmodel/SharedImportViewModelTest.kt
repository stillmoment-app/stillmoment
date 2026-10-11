package com.stillmoment.presentation.viewmodel

import android.net.Uri
import com.stillmoment.data.FileOpenHandler
import com.stillmoment.data.LinkImportHandler
import com.stillmoment.domain.models.ApplePodcastsLink
import com.stillmoment.domain.models.LinkImportFailure
import com.stillmoment.domain.models.PodcastEpisode
import com.stillmoment.domain.models.UrlAudioDownloadError
import com.stillmoment.domain.services.PodcastEpisodeResolverProtocol
import com.stillmoment.domain.services.UrlAudioDownloaderProtocol
import com.stillmoment.presentation.navigation.SharedEntryGate
import com.stillmoment.testutil.FakeImportDownloads
import java.io.IOException
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock
import org.mockito.kotlin.whenever

/**
 * Sharing with Still Moment while an import runs (shared-138): the running
 * import is finished, an entry shared meanwhile waits and is handed over to the
 * library afterwards. Uses the real gate, link import and link handler; only the
 * network and the library's end of an import are stood in for.
 *
 * The ViewModel outlives the Activity (dark mode, font size), so whatever a
 * newly built screen reads from it is what the user sees afterwards (shared-132).
 */
@OptIn(ExperimentalCoroutinesApi::class)
class SharedImportViewModelTest {

    private val talk25401 = "https://www.audiodharma.org/talks/25401/download"
    private val talk25402 = "https://www.audiodharma.org/talks/25402/download"
    private val podcastWithoutEpisode =
        "https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478"

    private val testDispatcher = StandardTestDispatcher()
    private val downloader = ControlledDownloader()
    private val importDownloads = FakeImportDownloads()
    private val fileOpenHandler = mock<FileOpenHandler>()
    private val gate = SharedEntryGate(logger = mock())
    private lateinit var viewModel: SharedImportViewModel

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        val handler = LinkImportHandler(downloader = downloader, episodeResolver = NoPodcasts(), logger = mock())
        viewModel = SharedImportViewModel(handler, importDownloads, fileOpenHandler, gate)
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun sharedFile(name: String, size: Long = 4_200_000L): Uri {
        val uri = mock<Uri>()
        whenever(fileOpenHandler.getFileName(uri)).thenReturn(name)
        whenever(fileOpenHandler.getFileSize(uri)).thenReturn(size)
        return uri
    }

    /** The library opens the edit sheet for the handed-over entry. */
    private fun libraryTakesOver(): Uri {
        val handedOver = checkNotNull(viewModel.handover.value) { "Nothing handed over" }
        viewModel.consumeHandover()
        return handedOver.uri
    }

    /** The user saves or discards the edit sheet, or closes the library's message. */
    private fun libraryEndsImport() = gate.importEnded()

    @Nested
    inner class SingleShare {

        @Test
        fun `a link still loading is shown as loading to a re-created screen`() = runTest(testDispatcher) {
            viewModel.shareLink(talk25401)
            advanceUntilIdle()

            assertTrue(viewModel.linkImport.isLoading.value)
        }

        @Test
        fun `a link that finished loading waits for the library to open the edit sheet`() = runTest(testDispatcher) {
            val file = mock<Uri>()
            viewModel.shareLink(talk25401)
            advanceUntilIdle()

            downloader.finish(talk25401, Result.success(file))
            advanceUntilIdle()

            assertEquals(file, viewModel.handover.value?.uri)
            assertFalse(viewModel.linkImport.isLoading.value)
        }

        @Test
        fun `the loaded link opens only one edit sheet and is kept`() = runTest(testDispatcher) {
            viewModel.shareLink(talk25401)
            advanceUntilIdle()
            downloader.finish(talk25401, Result.success(mock()))
            advanceUntilIdle()

            libraryTakesOver()
            advanceUntilIdle()

            assertNull(viewModel.handover.value)
            assertTrue(importDownloads.discarded.isEmpty())
        }

        @Test
        fun `a failure stays visible to a re-created screen`() = runTest(testDispatcher) {
            viewModel.shareLink(talk25401)
            advanceUntilIdle()

            downloader.finish(talk25401, Result.failure(UrlAudioDownloadError.Network(IOException("offline"))))
            advanceUntilIdle()

            assertNotNull(viewModel.linkImport.failure.value)
            assertNull(viewModel.handover.value)
        }

        @Test
        fun `a shared file is handed over to the library right away`() = runTest(testDispatcher) {
            val file = sharedFile("body-scan.mp3")

            viewModel.shareFile(file)
            advanceUntilIdle()

            assertEquals(file, viewModel.handover.value?.uri)
            assertNull(viewModel.handover.value?.suggestion)
        }
    }

    @Nested
    inner class LinkWhileLinkLoads {

        @Test
        fun `the loading link keeps loading and is the one handed over`() = runTest(testDispatcher) {
            val file25401 = mock<Uri>()
            viewModel.shareLink(talk25401)
            advanceUntilIdle()

            viewModel.shareLink(talk25402)
            advanceUntilIdle()
            downloader.finish(talk25401, Result.success(file25401))
            advanceUntilIdle()

            assertEquals(listOf(talk25401), downloader.requested, "25402 does not load yet")
            assertEquals(file25401, viewModel.handover.value?.uri)
        }

        @Test
        fun `the waiting link loads once the edit sheet of the first is done`() = runTest(testDispatcher) {
            val file25402 = mock<Uri>()
            viewModel.shareLink(talk25401)
            advanceUntilIdle()
            viewModel.shareLink(talk25402)
            advanceUntilIdle()
            downloader.finish(talk25401, Result.success(mock()))
            advanceUntilIdle()
            libraryTakesOver()
            advanceUntilIdle()
            assertEquals(listOf(talk25401), downloader.requested, "Still waiting while the edit sheet is open")

            libraryEndsImport()
            advanceUntilIdle()
            assertTrue(viewModel.linkImport.isLoading.value, "25402 loads on its own")
            downloader.finish(talk25402, Result.success(file25402))
            advanceUntilIdle()

            assertEquals(file25402, viewModel.handover.value?.uri)
        }
    }

    @Nested
    inner class FileWhileLinkLoads {

        @Test
        fun `the link's edit sheet comes first, the file's afterwards`() = runTest(testDispatcher) {
            val linkFile = mock<Uri>()
            val sharedMp3 = sharedFile("body-scan.mp3")
            viewModel.shareLink(talk25401)
            advanceUntilIdle()

            viewModel.shareFile(sharedMp3)
            advanceUntilIdle()
            assertNull(viewModel.handover.value, "The file does not replace anything")
            downloader.finish(talk25401, Result.success(linkFile))
            advanceUntilIdle()

            assertEquals(linkFile, libraryTakesOver())
            assertNull(viewModel.handover.value)
            libraryEndsImport()
            advanceUntilIdle()
            assertEquals(sharedMp3, libraryTakesOver())
        }
    }

    @Nested
    inner class MessageOfTheRunningImport {

        @Test
        fun `the waiting file starts once the link's message is closed`() = runTest(testDispatcher) {
            val sharedMp3 = sharedFile("body-scan.mp3")
            viewModel.shareLink(talk25401)
            advanceUntilIdle()
            viewModel.shareFile(sharedMp3)
            downloader.finish(talk25401, Result.failure(UrlAudioDownloadError.Network(IOException("offline"))))
            advanceUntilIdle()
            assertNull(viewModel.handover.value, "The message stays until it is closed")

            viewModel.linkImport.dismissFailure()
            advanceUntilIdle()

            assertEquals(sharedMp3, viewModel.handover.value?.uri)
        }

        @Test
        fun `retry continues the import while the waiting entry keeps waiting`() = runTest(testDispatcher) {
            val linkFile = mock<Uri>()
            viewModel.shareLink(talk25401)
            advanceUntilIdle()
            viewModel.shareLink(talk25402)
            downloader.finish(talk25401, Result.failure(UrlAudioDownloadError.Network(IOException("offline"))))
            advanceUntilIdle()

            viewModel.linkImport.retry()
            advanceUntilIdle()
            downloader.finish(talk25401, Result.success(linkFile))
            advanceUntilIdle()

            assertEquals(listOf(talk25401, talk25401), downloader.requested)
            assertEquals(linkFile, libraryTakesOver())
            libraryEndsImport()
            advanceUntilIdle()
            assertEquals(talk25402, downloader.requested.last(), "25402 loads after the retried import")
        }

        @Test
        fun `the failed link shared again keeps its message and loads nothing`() = runTest(testDispatcher) {
            viewModel.shareLink(talk25401)
            advanceUntilIdle()
            downloader.finish(talk25401, Result.failure(UrlAudioDownloadError.Network(IOException("offline"))))
            advanceUntilIdle()

            viewModel.shareLink(talk25401)
            advanceUntilIdle()

            assertEquals(LinkImportFailure.NotReachable, viewModel.linkImport.failure.value?.failure)
            assertEquals(listOf(talk25401), downloader.requested)
        }

        @Test
        fun `a podcast link without episode lets the waiting file start once its message is closed`() =
            runTest(testDispatcher) {
                val sharedMp3 = sharedFile("body-scan.mp3")

                viewModel.shareLink(podcastWithoutEpisode)
                advanceUntilIdle()
                viewModel.shareFile(sharedMp3)
                advanceUntilIdle()
                assertEquals(
                    LinkImportFailure.PodcastWithoutEpisode,
                    viewModel.linkImport.failure.value?.failure
                )
                viewModel.linkImport.dismissFailure()
                advanceUntilIdle()

                assertEquals(sharedMp3, viewModel.handover.value?.uri)
            }
    }

    @Nested
    inner class CancelInTheLoadingWindow {

        @Test
        fun `cancelling ends quietly and the waiting link loads`() = runTest(testDispatcher) {
            viewModel.shareLink(talk25401)
            advanceUntilIdle()
            viewModel.shareLink(talk25402)
            advanceUntilIdle()

            viewModel.linkImport.cancel()
            advanceUntilIdle()

            assertNull(viewModel.linkImport.failure.value, "No message")
            assertEquals(listOf(talk25401, talk25402), downloader.requested)
            assertTrue(viewModel.linkImport.isLoading.value, "25402 loads")
        }

        @Test
        fun `cancelling with nothing waiting lets the next share start right away`() = runTest(testDispatcher) {
            viewModel.shareLink(talk25401)
            advanceUntilIdle()
            viewModel.linkImport.cancel()
            advanceUntilIdle()

            viewModel.shareLink(talk25402)
            advanceUntilIdle()

            assertEquals(listOf(talk25401, talk25402), downloader.requested)
            assertTrue(viewModel.linkImport.isLoading.value)
        }
    }

    @Nested
    inner class SharedSeveralTimes {

        @Test
        fun `only the last entry shared while loading is imported, the replaced link never loads`() =
            runTest(testDispatcher) {
                val sharedMp3 = sharedFile("body-scan.mp3")
                viewModel.shareLink(talk25401)
                advanceUntilIdle()
                viewModel.shareLink(talk25402)
                viewModel.shareFile(sharedMp3)
                downloader.finish(talk25401, Result.success(mock()))
                advanceUntilIdle()
                libraryTakesOver()

                libraryEndsImport()
                advanceUntilIdle()

                assertEquals(sharedMp3, viewModel.handover.value?.uri)
                assertEquals(listOf(talk25401), downloader.requested, "25402 is never downloaded")
            }

        @Test
        fun `the loading link shared again downloads once and opens one edit sheet`() = runTest(testDispatcher) {
            viewModel.shareLink(talk25401)
            advanceUntilIdle()

            viewModel.shareLink(talk25401)
            advanceUntilIdle()
            downloader.finish(talk25401, Result.success(mock()))
            advanceUntilIdle()
            libraryTakesOver()
            libraryEndsImport()
            advanceUntilIdle()

            assertEquals(listOf(talk25401), downloader.requested)
            assertNull(viewModel.handover.value, "Nothing waits afterwards")
        }

        @Test
        fun `the file shared again under a new address while its edit sheet is open is not handed over again`() =
            runTest(testDispatcher) {
                viewModel.shareFile(sharedFile("body-scan.mp3"))
                advanceUntilIdle()
                libraryTakesOver()

                viewModel.shareFile(sharedFile("body-scan.mp3"))
                advanceUntilIdle()
                libraryEndsImport()
                advanceUntilIdle()

                assertNull(viewModel.handover.value)
            }

        @Test
        fun `a link shared again after its import ended loads again for the library to say already there`() =
            runTest(testDispatcher) {
                viewModel.shareLink(talk25401)
                advanceUntilIdle()
                downloader.finish(talk25401, Result.success(mock()))
                advanceUntilIdle()
                libraryTakesOver()
                libraryEndsImport()

                viewModel.shareLink(talk25401)
                advanceUntilIdle()

                assertEquals(listOf(talk25401, talk25401), downloader.requested)
            }
    }

    /** Downloads run until the test finishes them; "Cancel" stops the running one like the real downloader. */
    private class ControlledDownloader : UrlAudioDownloaderProtocol {
        private val running = mutableMapOf<String, CompletableDeferred<Result<Uri>>>()
        val requested = mutableListOf<String>()

        override suspend fun download(url: String): Result<Uri> {
            requested += url
            val result = CompletableDeferred<Result<Uri>>()
            running[url] = result
            return result.await()
        }

        override fun cancel() {
            running.values.forEach { it.complete(Result.failure(CancellationException("cancelled"))) }
        }

        fun finish(url: String, outcome: Result<Uri>) {
            val result = checkNotNull(running[url]) { "No download for $url" }
            result.complete(outcome)
        }
    }

    private class NoPodcasts : PodcastEpisodeResolverProtocol {
        override suspend fun resolveEpisode(link: ApplePodcastsLink.Episode): Result<PodcastEpisode> =
            Result.failure(IllegalStateException("not used"))

        override fun cancel() = Unit
    }
}
