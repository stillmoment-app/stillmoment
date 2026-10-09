package com.stillmoment.presentation.ui.common

import androidx.annotation.StringRes
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.stillmoment.R
import com.stillmoment.domain.models.LinkImportFailure

/**
 * Message for a failed link import (shared-046, shared-091, shared-128).
 *
 * "Retry" + "Cancel" only when [LinkImportFailure.canRetry]; otherwise just "Close".
 */
@Composable
fun LinkImportErrorDialog(failure: LinkImportFailure, onRetry: () -> Unit, onDismiss: () -> Unit) {
    val (titleRes, messageRes) = failure.messageResources()
    if (failure.canRetry) {
        RetryErrorDialog(titleRes = titleRes, messageRes = messageRes, onRetry = onRetry, onDismiss = onDismiss)
    } else {
        CloseOnlyErrorDialog(titleRes = titleRes, messageRes = messageRes, onDismiss = onDismiss)
    }
}

/** Shared text without any link (shared-091). */
@Composable
fun NoLinkErrorDialog(onDismiss: () -> Unit) {
    CloseOnlyErrorDialog(
        titleRes = R.string.download_error_no_link_title,
        messageRes = R.string.download_error_no_link_message,
        onDismiss = onDismiss
    )
}

private fun LinkImportFailure.messageResources(): Pair<Int, Int> = when (this) {
    LinkImportFailure.PodcastWithoutEpisode ->
        R.string.download_error_whole_podcast_title to R.string.download_error_whole_podcast_message
    LinkImportFailure.NotReachable ->
        R.string.download_error_not_reachable_title to R.string.download_error_not_reachable_message
    LinkImportFailure.EpisodeUnavailable ->
        R.string.download_error_episode_unavailable_title to R.string.download_error_episode_unavailable_message
    LinkImportFailure.NotAudio ->
        R.string.download_error_not_audio_title to R.string.download_error_not_audio_message
    LinkImportFailure.DownloadFailed ->
        R.string.download_error_title to R.string.download_error_message
}

@Composable
private fun CloseOnlyErrorDialog(@StringRes titleRes: Int, @StringRes messageRes: Int, onDismiss: () -> Unit) {
    val closeText = stringResource(R.string.download_error_close)
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(titleRes)) },
        text = { Text(stringResource(messageRes)) },
        confirmButton = {
            TextButton(onClick = onDismiss) { Text(closeText) }
        }
    )
}

@Composable
private fun RetryErrorDialog(
    @StringRes titleRes: Int,
    @StringRes messageRes: Int,
    onRetry: () -> Unit,
    onDismiss: () -> Unit
) {
    val retryText = stringResource(R.string.download_error_retry)
    val cancelText = stringResource(R.string.download_error_cancel)
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(titleRes)) },
        text = { Text(stringResource(messageRes)) },
        confirmButton = {
            TextButton(onClick = onRetry) { Text(retryText) }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(cancelText) }
        }
    )
}
