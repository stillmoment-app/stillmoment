package com.stillmoment.presentation.navigation

import com.stillmoment.data.LinkImportOutcome
import com.stillmoment.domain.models.LinkImportFailure
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** A failed link import plus the shared address, so "Retry" can run the whole import again. */
data class FailedLinkImport(val sharedUrl: String, val failure: LinkImportFailure)

/**
 * Imports shared links one at a time while the loading window is shown (shared-132).
 *
 * Rule: the last shared address wins. Sharing the address that is loading right
 * now changes nothing; any other address replaces the running import. "Retry"
 * runs through the same rule, so a newer share replaces it as well.
 *
 * Plain class instead of Compose state so the rule is unit-testable — same
 * pattern as [PlayerCompletionWiring].
 *
 * @param import Loads a shared address into a local file (`LinkImportHandler::import`).
 * @param cancelRunning Stops the running lookup/download (`LinkImportHandler::cancel`).
 * @param onImported Hands a loaded file over to the edit sheet.
 */
class SharedLinkImport(
    private val scope: CoroutineScope,
    private val import: suspend (String) -> LinkImportOutcome,
    private val cancelRunning: () -> Unit,
    private val onImported: (LinkImportOutcome.Imported) -> Unit
) {
    private val _isLoading = MutableStateFlow(false)

    /** True while the loading window is to be shown. */
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _failure = MutableStateFlow<FailedLinkImport?>(null)

    /** The message to show, or `null`. */
    val failure: StateFlow<FailedLinkImport?> = _failure.asStateFlow()

    private var job: Job? = null
    private var loadingUrl: String? = null

    /** A link was shared with the app. */
    fun share(url: String) {
        if (url == loadingUrl) {
            return
        }
        start(url)
    }

    /** "Retry" in the message: load the failed address again. */
    fun retry() {
        val failed = _failure.value ?: return
        start(failed.sharedUrl)
    }

    /** The message was closed without retrying. */
    fun dismissFailure() {
        _failure.value = null
    }

    /** "Cancel" in the loading window — ends quietly, no message. */
    fun cancel() {
        cancelRunning()
    }

    private fun start(url: String) {
        _failure.value = null
        job?.cancel()
        loadingUrl = url
        _isLoading.value = true
        job = scope.launch {
            val outcome = import(url)
            ensureActive()
            loadingUrl = null
            _isLoading.value = false
            when (outcome) {
                is LinkImportOutcome.Imported -> onImported(outcome)
                is LinkImportOutcome.Failed -> _failure.value = FailedLinkImport(url, outcome.failure)
                LinkImportOutcome.Cancelled -> Unit
            }
        }
    }
}
