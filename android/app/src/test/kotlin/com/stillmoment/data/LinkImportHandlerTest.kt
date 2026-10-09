package com.stillmoment.data

import android.net.Uri
import com.stillmoment.domain.models.ApplePodcastsLink
import com.stillmoment.domain.models.ImportPrefill
import com.stillmoment.domain.models.LinkImportFailure
import com.stillmoment.domain.models.PodcastEpisode
import com.stillmoment.domain.models.PodcastEpisodeResolveError
import com.stillmoment.domain.models.UrlAudioDownloadError
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.PodcastEpisodeResolverProtocol
import com.stillmoment.domain.services.UrlAudioDownloaderProtocol
import java.io.IOException
import java.net.SocketTimeoutException
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock

/**
 * shared-128: From a shared link to a local file plus edit-sheet suggestion —
 * including which message every failure leads to and cancelling.
 */
class LinkImportHandlerTest {

    private val episodeLink =
        "https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478?i=1000792422344"
    private val podcastLink = "https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478"
    private val directLink = "https://www.audiodharma.org/talks/25401/download"

    private val episode = PodcastEpisode(
        audioUrl = "https://podcast-mp3.dradio.de/folge.mp3",
        title = "MBCT - Achtsame Therapie gegen Depressionen",
        podcastAuthor = "Deutschlandfunk Nova",
        podcastName = "Achtsam - Deutschlandfunk Nova"
    )

    private lateinit var downloadedFile: Uri
    private lateinit var resolver: FakeResolver
    private lateinit var downloader: FakeDownloader
    private lateinit var sut: LinkImportHandler

    @BeforeEach
    fun setUp() {
        downloadedFile = mock()
        resolver = FakeResolver(Result.success(episode))
        downloader = FakeDownloader(Result.success(downloadedFile))
        val logger: LoggerProtocol = mock()
        sut = LinkImportHandler(downloader = downloader, episodeResolver = resolver, logger = logger)
    }

    @Nested
    inner class PodcastImport {

        @Test
        fun `shared episode is loaded from the provider with title and author as suggestion`() = runTest {
            val outcome = sut.import(episodeLink)

            assertEquals(
                LinkImportOutcome.Imported(
                    uri = downloadedFile,
                    suggestion = ImportPrefill(
                        teacher = "Deutschlandfunk Nova",
                        name = "MBCT - Achtsame Therapie gegen Depressionen"
                    )
                ),
                outcome
            )
            assertEquals(listOf("https://podcast-mp3.dradio.de/folge.mp3"), downloader.requestedUrls)
        }

        @Test
        fun `lookup asks for the episode from the shared link`() = runTest {
            sut.import(episodeLink)

            assertEquals(
                listOf(ApplePodcastsLink.Episode(country = "de", podcastId = 1528936478L, episodeId = 1000792422344L)),
                resolver.requestedLinks
            )
        }

        @Test
        fun `http audio address is loaded via https`() = runTest {
            resolver.result = Result.success(episode.copy(audioUrl = "http://anbieter.example/folge.mp3"))

            sut.import(episodeLink)

            assertEquals(listOf("https://anbieter.example/folge.mp3"), downloader.requestedUrls)
        }

        @Test
        fun `whole podcast asks for a single episode without any network access`() = runTest {
            val outcome = sut.import(podcastLink)

            assertEquals(LinkImportOutcome.Failed(LinkImportFailure.PodcastWithoutEpisode), outcome)
            assertTrue(resolver.requestedLinks.isEmpty())
            assertTrue(downloader.requestedUrls.isEmpty())
        }

        @Test
        fun `lookup not reachable leads to not reachable`() = runTest {
            resolver.result = Result.failure(PodcastEpisodeResolveError.NotReachable)

            assertEquals(LinkImportOutcome.Failed(LinkImportFailure.NotReachable), sut.import(episodeLink))
            assertTrue(downloader.requestedUrls.isEmpty())
        }

        @Test
        fun `episode not importable leads to episode unavailable`() = runTest {
            resolver.result = Result.failure(PodcastEpisodeResolveError.Unavailable)

            assertEquals(LinkImportOutcome.Failed(LinkImportFailure.EpisodeUnavailable), sut.import(episodeLink))
        }

        @Test
        fun `timeout while loading the episode leads to not reachable`() = runTest {
            downloader.result = Result.failure(UrlAudioDownloadError.Network(SocketTimeoutException("timeout")))

            assertEquals(LinkImportOutcome.Failed(LinkImportFailure.NotReachable), sut.import(episodeLink))
        }

        @Test
        fun `episode file gone at the provider leads to episode unavailable`() = runTest {
            downloader.result = Result.failure(UrlAudioDownloadError.Http(404))

            assertEquals(LinkImportOutcome.Failed(LinkImportFailure.EpisodeUnavailable), sut.import(episodeLink))
        }

        @Test
        fun `episode address delivering no audio leads to episode unavailable`() = runTest {
            downloader.result = Result.failure(UrlAudioDownloadError.NotAudio)

            assertEquals(LinkImportOutcome.Failed(LinkImportFailure.EpisodeUnavailable), sut.import(episodeLink))
        }
    }

    @Nested
    inner class DirectLinkImport {

        @Test
        fun `ordinary link is downloaded without asking Apple`() = runTest {
            val outcome = sut.import(directLink)

            assertEquals(LinkImportOutcome.Imported(uri = downloadedFile, suggestion = null), outcome)
            assertEquals(listOf(directLink), downloader.requestedUrls)
            assertTrue(resolver.requestedLinks.isEmpty())
        }

        @Test
        fun `connection error now leads to not reachable`() = runTest {
            downloader.result = Result.failure(UrlAudioDownloadError.Network(IOException("offline")))

            assertEquals(LinkImportOutcome.Failed(LinkImportFailure.NotReachable), sut.import(directLink))
        }

        @Test
        fun `server error stays download failed`() = runTest {
            downloader.result = Result.failure(UrlAudioDownloadError.Http(404))

            assertEquals(LinkImportOutcome.Failed(LinkImportFailure.DownloadFailed), sut.import(directLink))
        }

        @Test
        fun `web page stays no recording found`() = runTest {
            downloader.result = Result.failure(UrlAudioDownloadError.NotAudio)

            assertEquals(LinkImportOutcome.Failed(LinkImportFailure.NotAudio), sut.import(directLink))
        }
    }

    @Nested
    inner class Cancel {

        @Test
        fun `cancel during lookup ends quietly and loads nothing`() = runTest {
            resolver.onResolve = {
                sut.cancel()
                Result.failure(CancellationException("Lookup cancelled"))
            }

            assertEquals(LinkImportOutcome.Cancelled, sut.import(episodeLink))
            assertTrue(resolver.cancelCalled)
            assertTrue(downloader.requestedUrls.isEmpty())
        }

        @Test
        fun `cancel right after the lookup does not start the download`() = runTest {
            resolver.onResolve = {
                sut.cancel()
                Result.success(episode)
            }

            assertEquals(LinkImportOutcome.Cancelled, sut.import(episodeLink))
            assertTrue(downloader.requestedUrls.isEmpty())
        }

        @Test
        fun `cancel during download ends quietly`() = runTest {
            downloader.result = Result.failure(CancellationException("Download cancelled"))

            assertEquals(LinkImportOutcome.Cancelled, sut.import(episodeLink))
        }

        @Test
        fun `cancel reaches both lookup and download`() {
            sut.cancel()

            assertTrue(resolver.cancelCalled)
            assertTrue(downloader.cancelCalled)
        }

        @Test
        fun `same link shared again after cancel imports normally`() = runTest {
            resolver.onResolve = {
                sut.cancel()
                Result.failure(CancellationException("Lookup cancelled"))
            }
            sut.import(episodeLink)
            resolver.onResolve = null

            val outcome = sut.import(episodeLink)

            assertTrue(outcome is LinkImportOutcome.Imported) { "Expected Imported, got $outcome" }
        }
    }

    @Nested
    inner class Retry {

        @Test
        fun `retry is only offered when another attempt can help`() {
            val retryable = listOf(
                LinkImportFailure.PodcastWithoutEpisode,
                LinkImportFailure.NotReachable,
                LinkImportFailure.EpisodeUnavailable,
                LinkImportFailure.NotAudio,
                LinkImportFailure.DownloadFailed
            ).filter { it.canRetry }

            assertEquals(listOf(LinkImportFailure.NotReachable, LinkImportFailure.DownloadFailed), retryable)
        }

        @Test
        fun `not reachable episode imports after retry`() = runTest {
            resolver.result = Result.failure(PodcastEpisodeResolveError.NotReachable)
            sut.import(episodeLink)
            resolver.result = Result.success(episode)

            val outcome = sut.import(episodeLink)

            assertTrue(outcome is LinkImportOutcome.Imported) { "Expected Imported, got $outcome" }
            assertEquals(2, resolver.requestedLinks.size)
            assertFalse(downloader.requestedUrls.isEmpty())
        }
    }

    private class FakeResolver(var result: Result<PodcastEpisode>) : PodcastEpisodeResolverProtocol {
        val requestedLinks = mutableListOf<ApplePodcastsLink.Episode>()
        var cancelCalled = false
        var onResolve: (() -> Result<PodcastEpisode>)? = null

        override suspend fun resolveEpisode(link: ApplePodcastsLink.Episode): Result<PodcastEpisode> {
            requestedLinks.add(link)
            return onResolve?.invoke() ?: result
        }

        override fun cancel() {
            cancelCalled = true
        }
    }

    private class FakeDownloader(var result: Result<Uri>) : UrlAudioDownloaderProtocol {
        val requestedUrls = mutableListOf<String>()
        var cancelCalled = false

        override suspend fun download(url: String): Result<Uri> {
            requestedUrls.add(url)
            return result
        }

        override fun cancel() {
            cancelCalled = true
        }
    }
}
