package com.stillmoment.data

import android.content.Context
import android.net.Uri
import com.stillmoment.domain.models.ApplePodcastsLink
import com.stillmoment.domain.models.LinkImportFailure
import com.stillmoment.domain.models.PodcastEpisode
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.PodcastEpisodeResolverProtocol
import com.stillmoment.infrastructure.network.UrlAudioDownloaderImpl
import java.io.ByteArrayInputStream
import java.io.File
import java.net.HttpURLConnection
import kotlin.io.path.createTempDirectory
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock
import org.mockito.kotlin.whenever

/**
 * shared-131: Link-Import und Podcast-Import entscheiden mit derselben Liste von
 * Dateitypen, ob eine Datei als Audio angenommen wird — und zeigen bei Ablehnung
 * jeweils ihre bestehende Meldung. Laeuft mit dem echten Downloader, nur die
 * Server-Antwort ist nachgestellt.
 */
class LinkImportContentTypeTest {

    private val episodeLink =
        "https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478?i=1000792422344"
    private val directLink = "https://www.audiodharma.org/talks/25401/download"

    private val episode = PodcastEpisode(
        audioUrl = "https://podcast-mp3.dradio.de/folge.mp3",
        title = "MBCT - Achtsame Therapie gegen Depressionen",
        podcastAuthor = "Deutschlandfunk Nova",
        podcastName = "Achtsam - Deutschlandfunk Nova"
    )

    private lateinit var cacheDir: File
    private lateinit var connection: HttpURLConnection
    private lateinit var sut: LinkImportHandler

    @BeforeEach
    fun setUp() {
        cacheDir = createTempDirectory("link_import_content_type").toFile()
        val context: Context = mock()
        whenever(context.cacheDir).thenReturn(cacheDir)
        connection = mock()
        val downloadedFile: Uri = mock()
        val logger: LoggerProtocol = mock()
        val downloader = UrlAudioDownloaderImpl(
            context = context,
            logger = logger,
            connectionFactory = { connection },
            uriFromFile = { downloadedFile }
        )
        sut = LinkImportHandler(
            downloader = downloader,
            episodeResolver = EpisodeFound(episode),
            logger = logger
        )
    }

    @AfterEach
    fun tearDown() {
        cacheDir.deleteRecursively()
    }

    private fun serverAnnounces(contentType: String?) {
        whenever(connection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
        whenever(connection.contentType).thenReturn(contentType)
        whenever(connection.inputStream).thenReturn(ByteArrayInputStream("audio".toByteArray()))
    }

    @Nested
    inner class LinkImport {

        @Test
        fun `mp3 announced as audio-x-mpeg lands in the library`() = runTest {
            serverAnnounces("audio/x-mpeg")

            val outcome = sut.import(directLink)

            assertTrue(outcome is LinkImportOutcome.Imported) { "Expected Imported, got $outcome" }
        }

        @Test
        fun `ogg file shows no recording found`() = runTest {
            serverAnnounces("audio/ogg")

            assertEquals(LinkImportOutcome.Failed(LinkImportFailure.NotAudio), sut.import(directLink))
        }

        @Test
        fun `playlist shows no recording found`() = runTest {
            serverAnnounces("audio/x-mpegurl")

            assertEquals(LinkImportOutcome.Failed(LinkImportFailure.NotAudio), sut.import(directLink))
        }
    }

    @Nested
    inner class PodcastImport {

        @Test
        fun `episode announced as audio-x-mpeg is imported`() = runTest {
            serverAnnounces("audio/x-mpeg")

            val outcome = sut.import(episodeLink)

            assertTrue(outcome is LinkImportOutcome.Imported) { "Expected Imported, got $outcome" }
        }

        @Test
        fun `episode announced as audio-mpeg3 is imported`() = runTest {
            serverAnnounces("audio/mpeg3")

            val outcome = sut.import(episodeLink)

            assertTrue(outcome is LinkImportOutcome.Imported) { "Expected Imported, got $outcome" }
        }

        @Test
        fun `ogg episode shows episode unavailable`() = runTest {
            serverAnnounces("audio/ogg")

            assertEquals(LinkImportOutcome.Failed(LinkImportFailure.EpisodeUnavailable), sut.import(episodeLink))
        }

        @Test
        fun `playlist instead of episode shows episode unavailable`() = runTest {
            serverAnnounces("audio/mpegurl")

            assertEquals(LinkImportOutcome.Failed(LinkImportFailure.EpisodeUnavailable), sut.import(episodeLink))
        }

        @Test
        fun `episode without announced type is still imported`() = runTest {
            serverAnnounces(null)

            val outcome = sut.import(episodeLink)

            assertTrue(outcome is LinkImportOutcome.Imported) { "Expected Imported, got $outcome" }
        }
    }

    private class EpisodeFound(private val episode: PodcastEpisode) : PodcastEpisodeResolverProtocol {
        override suspend fun resolveEpisode(link: ApplePodcastsLink.Episode): Result<PodcastEpisode> =
            Result.success(episode)

        override fun cancel() = Unit
    }
}
