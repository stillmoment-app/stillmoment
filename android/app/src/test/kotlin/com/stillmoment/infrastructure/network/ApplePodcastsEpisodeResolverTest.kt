package com.stillmoment.infrastructure.network

import com.stillmoment.domain.models.ApplePodcastsLink
import com.stillmoment.domain.models.PodcastEpisodeResolveError
import com.stillmoment.domain.services.LoggerProtocol
import java.io.ByteArrayInputStream
import java.io.IOException
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.SocketTimeoutException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.ValueSource
import org.mockito.kotlin.any
import org.mockito.kotlin.doAnswer
import org.mockito.kotlin.mock
import org.mockito.kotlin.times
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

/**
 * shared-128: Asking Apple's lookup service for the shared episode.
 * No real network — the connection is a mock behind the factory seam.
 */
class ApplePodcastsEpisodeResolverTest {

    private val link = ApplePodcastsLink.Episode(country = "de", podcastId = 1528936478L, episodeId = 1000792422344L)

    private val answer = """
        {"resultCount":2,"results":[
          {"wrapperType":"track","kind":"podcast","trackId":1528936478,"artistName":"Deutschlandfunk Nova",
           "collectionName":"Achtsam - Deutschlandfunk Nova"},
          {"wrapperType":"podcastEpisode","trackId":1000792422344,"trackName":"Body Scan",
           "episodeContentType":"audio","episodeUrl":"https://podcast-mp3.dradio.de/folge.mp3"}
        ]}
    """.trimIndent()

    private lateinit var mockConnection: HttpURLConnection
    private val requestedUrls = mutableListOf<String>()
    private lateinit var sut: ApplePodcastsEpisodeResolver

    @BeforeEach
    fun setUp() {
        mockConnection = mock()
        val logger: LoggerProtocol = mock()
        sut = ApplePodcastsEpisodeResolver(
            logger = logger,
            connectionFactory = { url ->
                requestedUrls.add(url)
                mockConnection
            }
        )
    }

    private fun answerWith(code: Int, body: String = answer) {
        whenever(mockConnection.responseCode).thenReturn(code)
        whenever(mockConnection.inputStream).thenReturn(ByteArrayInputStream(body.toByteArray()))
    }

    @Nested
    inner class Request {

        @Test
        fun `asks exactly for the podcast's newest episodes in the link's store`() = runTest {
            answerWith(HttpURLConnection.HTTP_OK)

            sut.resolveEpisode(link)

            assertEquals(
                listOf("https://itunes.apple.com/lookup?id=1528936478&entity=podcastEpisode&limit=200&country=de"),
                requestedUrls
            )
        }

        @Test
        fun `link without country asks without store country`() = runTest {
            answerWith(HttpURLConnection.HTTP_OK)

            sut.resolveEpisode(link.copy(country = null))

            assertEquals(
                listOf("https://itunes.apple.com/lookup?id=1528936478&entity=podcastEpisode&limit=200"),
                requestedUrls
            )
        }

        @Test
        fun `sends no identifying headers besides the app name`() = runTest {
            answerWith(HttpURLConnection.HTTP_OK)

            sut.resolveEpisode(link)

            verify(mockConnection, times(1)).setRequestProperty(any(), any())
            verify(mockConnection).setRequestProperty("User-Agent", "StillMoment/1.0")
        }
    }

    @Nested
    inner class Outcomes {

        @Test
        fun `found episode is returned`() = runTest {
            answerWith(HttpURLConnection.HTTP_OK)

            val episode = sut.resolveEpisode(link).getOrNull()

            assertEquals("https://podcast-mp3.dradio.de/folge.mp3", episode?.audioUrl)
            assertEquals("Body Scan", episode?.title)
            assertEquals("Deutschlandfunk Nova", episode?.teacherSuggestion)
        }

        @ParameterizedTest
        @ValueSource(ints = [403, 429])
        fun `apple overloaded is not reachable right now`(code: Int) = runTest {
            answerWith(code)

            assertTrue(sut.resolveEpisode(link).exceptionOrNull() is PodcastEpisodeResolveError.NotReachable)
        }

        @ParameterizedTest
        @ValueSource(ints = [404, 500])
        fun `other server errors mean the episode cannot be imported`(code: Int) = runTest {
            answerWith(code)

            assertTrue(sut.resolveEpisode(link).exceptionOrNull() is PodcastEpisodeResolveError.Unavailable)
        }

        @Test
        fun `episode missing from the answer cannot be imported`() = runTest {
            answerWith(HttpURLConnection.HTTP_OK, body = """{"resultCount":0,"results":[]}""")

            assertTrue(sut.resolveEpisode(link).exceptionOrNull() is PodcastEpisodeResolveError.Unavailable)
        }

        @Test
        fun `broken answer means the episode cannot be imported`() = runTest {
            answerWith(HttpURLConnection.HTTP_OK, body = "<html>Service Unavailable</html>")

            assertTrue(sut.resolveEpisode(link).exceptionOrNull() is PodcastEpisodeResolveError.Unavailable)
        }

        @Test
        fun `no connection is not reachable right now`() = runTest {
            whenever(mockConnection.responseCode).thenAnswer { throw IOException("offline") }

            assertTrue(sut.resolveEpisode(link).exceptionOrNull() is PodcastEpisodeResolveError.NotReachable)
        }

        @Test
        fun `timeout is not reachable right now`() = runTest {
            whenever(mockConnection.responseCode).thenAnswer { throw SocketTimeoutException("timeout") }

            assertTrue(sut.resolveEpisode(link).exceptionOrNull() is PodcastEpisodeResolveError.NotReachable)
        }
    }

    @Nested
    inner class Cancel {

        @Test
        fun `cancel without active lookup is a no-op`() {
            sut.cancel()
        }

        @OptIn(ExperimentalCoroutinesApi::class)
        @Test
        fun `cancel during running lookup ends with cancellation`() = runTest(UnconfinedTestDispatcher()) {
            val lookupStarted = CompletableDeferred<Unit>()
            val disconnected = CountDownLatch(1)
            doAnswer {
                disconnected.countDown()
                null
            }.whenever(mockConnection).disconnect()
            val blockingStream = object : InputStream() {
                override fun read(): Int {
                    lookupStarted.complete(Unit)
                    disconnected.await(5, TimeUnit.SECONDS)
                    throw IOException("Socket closed")
                }
            }
            whenever(mockConnection.responseCode).thenReturn(HttpURLConnection.HTTP_OK)
            whenever(mockConnection.inputStream).thenReturn(blockingStream)

            val deferred = async { sut.resolveEpisode(link) }
            lookupStarted.await()
            sut.cancel()

            val error = deferred.await().exceptionOrNull()
            assertTrue(error is CancellationException) { "Expected CancellationException, got $error" }
        }

        @Test
        fun `next lookup after cancel runs normally`() = runTest {
            sut.cancel()
            answerWith(HttpURLConnection.HTTP_OK)

            assertTrue(sut.resolveEpisode(link).isSuccess)
        }
    }
}
