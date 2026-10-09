package com.stillmoment.presentation.viewmodel

import android.net.Uri
import com.stillmoment.data.LinkImportHandler
import com.stillmoment.domain.models.ApplePodcastsLink
import com.stillmoment.domain.models.PodcastEpisode
import com.stillmoment.domain.models.UrlAudioDownloadError
import com.stillmoment.domain.services.PodcastEpisodeResolverProtocol
import com.stillmoment.domain.services.UrlAudioDownloaderProtocol
import java.io.IOException
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
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * shared-132: A link import outlives the screen being re-created (dark mode,
 * font size). The ViewModel outlives the Activity, so whatever a newly built
 * screen reads from it is what the user sees afterwards.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class SharedLinkImportViewModelTest {

    private val talk25401 = "https://www.audiodharma.org/talks/25401/download"
    private val testDispatcher = StandardTestDispatcher()
    private val downloader = ControlledDownloader()
    private lateinit var viewModel: SharedLinkImportViewModel

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        val handler = LinkImportHandler(downloader = downloader, episodeResolver = NoPodcasts(), logger = mock())
        viewModel = SharedLinkImportViewModel(handler)
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `a link still loading is shown as loading to a re-created screen`() = runTest(testDispatcher) {
        viewModel.linkImport.share(talk25401)
        advanceUntilIdle()

        assertTrue(viewModel.linkImport.isLoading.value)
    }

    @Test
    fun `a link that finished loading waits for the screen to open the edit sheet`() = runTest(testDispatcher) {
        val file = mock<Uri>()
        viewModel.linkImport.share(talk25401)
        advanceUntilIdle()

        downloader.finish(Result.success(file))
        advanceUntilIdle()

        assertEquals(file, viewModel.importedLink.value?.uri)
        assertFalse(viewModel.linkImport.isLoading.value)
    }

    @Test
    fun `the loaded link opens only one edit sheet`() = runTest(testDispatcher) {
        viewModel.linkImport.share(talk25401)
        advanceUntilIdle()
        downloader.finish(Result.success(mock()))
        advanceUntilIdle()

        viewModel.consumeImportedLink()

        assertNull(viewModel.importedLink.value)
    }

    @Test
    fun `a failure stays visible to a re-created screen`() = runTest(testDispatcher) {
        viewModel.linkImport.share(talk25401)
        advanceUntilIdle()

        downloader.finish(Result.failure(UrlAudioDownloadError.Network(IOException("offline"))))
        advanceUntilIdle()

        assertNotNull(viewModel.linkImport.failure.value)
        assertNull(viewModel.importedLink.value)
    }

    /** Download that runs until the test finishes it. */
    private class ControlledDownloader : UrlAudioDownloaderProtocol {
        private var result = CompletableDeferred<Result<Uri>>()

        override suspend fun download(url: String): Result<Uri> = result.await()

        override fun cancel() = Unit

        fun finish(outcome: Result<Uri>) {
            result.complete(outcome)
        }
    }

    private class NoPodcasts : PodcastEpisodeResolverProtocol {
        override suspend fun resolveEpisode(link: ApplePodcastsLink.Episode): Result<PodcastEpisode> =
            Result.failure(IllegalStateException("not used"))

        override fun cancel() = Unit
    }
}
