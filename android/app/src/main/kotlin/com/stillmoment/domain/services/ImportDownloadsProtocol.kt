package com.stillmoment.domain.services

/**
 * Audio files the link and podcast import loaded from the internet (android-087).
 *
 * A downloaded file is only needed until its import ends — saved, discarded,
 * "already there", failed or replaced by a newer share. The library keeps its
 * own copy, so every download must be discarded afterwards; otherwise each
 * import takes up the recording's storage twice.
 */
interface ImportDownloadsProtocol {

    /**
     * Removes the downloaded file behind [uri].
     *
     * Does nothing for any file the app did not download itself — in particular
     * files other apps hand over via "Open with" or Share (`content://`), and the
     * library's own copies.
     */
    suspend fun discard(uri: String)

    /**
     * Removes downloads left behind by earlier app runs (crash, process ended
     * with an open edit sheet, versions before android-087). Downloads of the
     * running app are kept.
     */
    suspend fun removeLeftovers()
}
