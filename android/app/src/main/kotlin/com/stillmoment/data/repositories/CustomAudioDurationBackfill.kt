package com.stillmoment.data.repositories

import com.stillmoment.data.local.CustomAudioDataStore
import com.stillmoment.domain.services.AudioDurationProbe
import com.stillmoment.domain.services.LoggerProtocol
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Adds the play length to an imported custom audio file after it has been listed
 * (android-079).
 *
 * Detecting the length of a long MP3 can take more than a minute on slow devices,
 * so the import saves the file without a length and hands it over here. The work
 * runs in an app-wide scope (this class is a singleton), so it survives the
 * import sheet and its ViewModel being closed.
 *
 * Outcomes:
 * - length detected in time → stored, the list row updates via the repository flow
 * - detection failed or exceeded [timeoutMs] → nothing stored, the row simply shows
 *   no length
 * - file deleted in the meantime → the store ignores the unknown ID
 * - process killed while detecting → the file keeps no length; there is
 *   deliberately no retry on app start, the length is display-only
 *
 * The native scan itself cannot be aborted; the timeout only guarantees that a
 * late result is discarded.
 */
@Singleton
class CustomAudioDurationBackfill(
    private val probe: AudioDurationProbe,
    private val storeDuration: suspend (id: String, durationMs: Long) -> Unit,
    private val scope: CoroutineScope,
    private val timeoutMs: Long = DEFAULT_TIMEOUT_MS
) {
    @Inject
    constructor(
        probe: AudioDurationProbe,
        dataStore: CustomAudioDataStore,
        logger: LoggerProtocol
    ) : this(
        probe = probe,
        storeDuration = dataStore::updateDuration,
        scope = CoroutineScope(
            SupervisorJob() + Dispatchers.IO + CoroutineExceptionHandler { _, throwable ->
                logger.e(TAG, "Play length detection failed", throwable)
            }
        )
    )

    /**
     * Starts detecting the play length of the local file at [filePath] and stores
     * it for [fileId]. Returns immediately.
     */
    fun schedule(fileId: String, filePath: String) {
        scope.launch {
            val durationMs = withTimeoutOrNull(timeoutMs) { probe.durationMs(filePath) }
            if (durationMs != null) {
                storeDuration(fileId, durationMs)
            }
        }
    }

    companion object {
        private const val TAG = "DurationBackfill"

        /** Generous bound: the detection is off the critical path, a slow result is still welcome. */
        const val DEFAULT_TIMEOUT_MS = 5 * 60 * 1000L
    }
}
