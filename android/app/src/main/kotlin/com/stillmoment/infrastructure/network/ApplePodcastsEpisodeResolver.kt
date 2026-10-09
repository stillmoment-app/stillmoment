package com.stillmoment.infrastructure.network

import com.stillmoment.domain.models.ApplePodcastsLink
import com.stillmoment.domain.models.PodcastEpisode
import com.stillmoment.domain.models.PodcastEpisodeResolveError
import com.stillmoment.domain.services.LoggerProtocol
import com.stillmoment.domain.services.PodcastEpisodeResolverProtocol
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerializationException

/**
 * Resolves an Apple Podcasts episode link via Apple's public lookup service
 * (shared-128). No key, no user or device identifiers — the request carries
 * only the podcast id, the store country from the shared link and fixed
 * parameters.
 *
 * Apple only returns the newest (at most 200) episodes; older ones end as
 * [PodcastEpisodeResolveError.Unavailable]. HTTP 403/429 are Apple's rate limit
 * and map to [PodcastEpisodeResolveError.NotReachable] — only here is it known
 * that the status comes from the lookup service.
 */
@Singleton
class ApplePodcastsEpisodeResolver @Inject constructor(
    private val logger: LoggerProtocol
) : PodcastEpisodeResolverProtocol {

    // Secondary constructor for testing — injects a seam for HttpURLConnection
    internal constructor(
        logger: LoggerProtocol,
        connectionFactory: (String) -> HttpURLConnection
    ) : this(logger) {
        this.connectionFactory = connectionFactory
    }

    private var connectionFactory: (String) -> HttpURLConnection = { url ->
        URL(url).openConnection() as HttpURLConnection
    }

    // Single-import assumption like UrlAudioDownloaderImpl: cancel() disconnects the
    // connection so a blocked read unblocks; the flag turns the resulting IOException
    // into a CancellationException.
    @Volatile
    private var currentConnection: HttpURLConnection? = null

    @Volatile
    private var cancelled: Boolean = false

    companion object {
        private const val TAG = "PodcastLookup"
        private const val TIMEOUT_MS = 30_000
        private const val EPISODE_LIMIT = 200
        private const val HTTP_TOO_MANY_REQUESTS = 429
        private val RATE_LIMIT_CODES = setOf(HttpURLConnection.HTTP_FORBIDDEN, HTTP_TOO_MANY_REQUESTS)

        /** Without a country segment in the shared link, `country` is omitted (Apple's default store). */
        internal fun lookupUrl(country: String?, podcastId: Long): String {
            val base = "https://itunes.apple.com/lookup?id=$podcastId&entity=podcastEpisode&limit=$EPISODE_LIMIT"
            return if (country != null) "$base&country=$country" else base
        }
    }

    override suspend fun resolveEpisode(link: ApplePodcastsLink.Episode): Result<PodcastEpisode> =
        withContext(Dispatchers.IO) {
            cancelled = false
            val url = lookupUrl(link.country, link.podcastId)
            var connection: HttpURLConnection? = null
            try {
                connection = connectionFactory(url).also { currentConnection = it }
                connection.connectTimeout = TIMEOUT_MS
                connection.readTimeout = TIMEOUT_MS
                connection.requestMethod = "GET"
                connection.setRequestProperty("User-Agent", "StillMoment/1.0")
                readAnswer(connection, link.episodeId)
            } catch (e: IOException) {
                ioFailure(url, e)
            } catch (e: SecurityException) {
                logger.e(TAG, "Security error during lookup $url", e)
                Result.failure(PodcastEpisodeResolveError.NotReachable)
            } finally {
                connection?.disconnect()
                currentConnection = null
            }
        }

    override fun cancel() {
        cancelled = true
        currentConnection?.disconnect()
    }

    private fun readAnswer(connection: HttpURLConnection, episodeId: Long): Result<PodcastEpisode> {
        val code = connection.responseCode
        if (code != HttpURLConnection.HTTP_OK) {
            logger.w(TAG, "Lookup answered HTTP $code")
            val error = if (code in RATE_LIMIT_CODES) {
                PodcastEpisodeResolveError.NotReachable
            } else {
                PodcastEpisodeResolveError.Unavailable
            }
            return Result.failure(error)
        }
        val body = connection.inputStream.bufferedReader().use { it.readText() }
        if (cancelled) {
            return Result.failure(CancellationException("Lookup cancelled"))
        }
        val result = try {
            ApplePodcastsLookupResponse.parse(body, episodeId)
        } catch (e: SerializationException) {
            logger.e(TAG, "Malformed lookup answer", e)
            Result.failure(PodcastEpisodeResolveError.Unavailable)
        }
        if (result.isFailure) {
            logger.w(TAG, "Episode $episodeId not importable from lookup answer")
        }
        return result
    }

    private fun ioFailure(url: String, error: IOException): Result<PodcastEpisode> {
        return if (cancelled) {
            logger.d(TAG, "Lookup cancelled for $url")
            Result.failure(CancellationException("Lookup cancelled"))
        } else {
            logger.e(TAG, "IO error during lookup $url", error)
            Result.failure(PodcastEpisodeResolveError.NotReachable)
        }
    }
}
