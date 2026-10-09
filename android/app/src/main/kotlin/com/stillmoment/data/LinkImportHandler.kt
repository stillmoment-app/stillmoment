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
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.CancellationException

/** Result of importing a shared link (shared-128). */
sealed class LinkImportOutcome {

    /** Audio file is local; [suggestion] (podcast import only) beats the file's own ID3 values. */
    data class Imported(val uri: Uri, val suggestion: ImportPrefill?) : LinkImportOutcome()

    /** Shown to the user as one of the link-import messages. */
    data class Failed(val failure: LinkImportFailure) : LinkImportOutcome()

    /** User cancelled in the loading window — no message, no entry. */
    data object Cancelled : LinkImportOutcome()
}

/**
 * Turns a shared address into a local audio file plus edit-sheet suggestion
 * (shared-128).
 *
 * - Apple Podcasts episode link → ask Apple's lookup service for the episode,
 *   load its audio file directly from the podcast's provider, suggest episode
 *   title and podcast author.
 * - Apple Podcasts link without episode → ask for a single episode, no network.
 * - Any other link → download as before (ordinary link import).
 *
 * Maps every technical outcome to exactly one [LinkImportFailure]; the UI never
 * sees exceptions. Single-import assumption like [UrlAudioDownloaderProtocol].
 */
@Singleton
class LinkImportHandler
@Inject
constructor(
    private val downloader: UrlAudioDownloaderProtocol,
    private val episodeResolver: PodcastEpisodeResolverProtocol,
    private val logger: LoggerProtocol
) {
    companion object {
        private const val TAG = "LinkImport"
    }

    // Set by cancel(); checked between lookup and download so a cancel exactly
    // between the two steps is not lost (the downloader resets its own flag on start).
    @Volatile
    private var cancelled: Boolean = false

    suspend fun import(sharedUrl: String): LinkImportOutcome {
        cancelled = false
        return when (val link = ApplePodcastsLink.parse(sharedUrl)) {
            is ApplePodcastsLink.Episode -> importPodcastEpisode(link)
            is ApplePodcastsLink.Podcast -> {
                logger.d(TAG, "Shared link is a whole podcast (${link.podcastId})")
                LinkImportOutcome.Failed(LinkImportFailure.PodcastWithoutEpisode)
            }
            null -> importDirectLink(sharedUrl)
        }
    }

    /** Cancels the running lookup and download. No-op when nothing runs. */
    fun cancel() {
        cancelled = true
        episodeResolver.cancel()
        downloader.cancel()
    }

    private suspend fun importPodcastEpisode(link: ApplePodcastsLink.Episode): LinkImportOutcome {
        val episode = episodeResolver.resolveEpisode(link).getOrElse { error ->
            return lookupFailure(error)
        }
        if (cancelled) {
            logger.d(TAG, "Podcast import cancelled after lookup")
            return LinkImportOutcome.Cancelled
        }
        val audioUrl = PodcastEpisode.upgradeToHttps(episode.audioUrl)
        return downloader.download(audioUrl).fold(
            onSuccess = { uri -> LinkImportOutcome.Imported(uri = uri, suggestion = episode.importSuggestion()) },
            onFailure = { error -> podcastDownloadFailure(error) }
        )
    }

    private suspend fun importDirectLink(url: String): LinkImportOutcome {
        return downloader.download(url).fold(
            onSuccess = { uri -> LinkImportOutcome.Imported(uri = uri, suggestion = null) },
            onFailure = { error -> directDownloadFailure(error) }
        )
    }

    private fun lookupFailure(error: Throwable): LinkImportOutcome = when (error) {
        is CancellationException -> LinkImportOutcome.Cancelled
        PodcastEpisodeResolveError.NotReachable -> LinkImportOutcome.Failed(LinkImportFailure.NotReachable)
        else -> LinkImportOutcome.Failed(LinkImportFailure.EpisodeUnavailable)
    }

    private fun podcastDownloadFailure(error: Throwable): LinkImportOutcome = when (error) {
        is CancellationException -> LinkImportOutcome.Cancelled
        is UrlAudioDownloadError.Network -> LinkImportOutcome.Failed(LinkImportFailure.NotReachable)
        else -> LinkImportOutcome.Failed(LinkImportFailure.EpisodeUnavailable)
    }

    private fun directDownloadFailure(error: Throwable): LinkImportOutcome = when (error) {
        is CancellationException -> LinkImportOutcome.Cancelled
        is UrlAudioDownloadError.Network -> LinkImportOutcome.Failed(LinkImportFailure.NotReachable)
        UrlAudioDownloadError.NotAudio -> LinkImportOutcome.Failed(LinkImportFailure.NotAudio)
        else -> LinkImportOutcome.Failed(LinkImportFailure.DownloadFailed)
    }
}
