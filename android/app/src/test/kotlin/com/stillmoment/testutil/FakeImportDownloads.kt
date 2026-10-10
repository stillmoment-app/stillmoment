package com.stillmoment.testutil

import com.stillmoment.domain.services.ImportDownloadsProtocol

/**
 * Records which downloaded files were discarded (android-087).
 */
class FakeImportDownloads : ImportDownloadsProtocol {
    val discarded = mutableListOf<String>()

    /** Runs on every discard — lets a test look at the state at that moment. */
    var onDiscard: (String) -> Unit = {}

    override suspend fun discard(uri: String) {
        onDiscard(uri)
        discarded += uri
    }

    override suspend fun removeLeftovers() = Unit
}
