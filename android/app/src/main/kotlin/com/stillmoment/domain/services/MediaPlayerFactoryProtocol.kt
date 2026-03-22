package com.stillmoment.domain.services

/**
 * Protocol for creating media player instances.
 *
 * Abstracts MediaPlayer creation for testability.
 * Supports creating players from resource IDs or for custom configuration.
 */
interface MediaPlayerFactoryProtocol {
    /**
     * Creates a media player from a raw resource.
     *
     * The returned player is already prepared and ready to play.
     *
     * @param resourceId Raw resource ID (e.g., R.raw.gong_temple_bell)
     * @return Configured MediaPlayerProtocol instance, or null if creation fails
     */
    fun createFromResource(resourceId: Int): MediaPlayerProtocol?

    /**
     * Creates a media player from a content URI string (SAF / content://).
     *
     * The returned player is already prepared and ready to play.
     * Uses MediaPlayer.create(context, Uri) internally to support SAF content URIs.
     *
     * @param uriString Content URI as string (e.g., "content://...")
     * @return Configured MediaPlayerProtocol instance, or null if creation fails
     */
    fun createFromContentUri(uriString: String): MediaPlayerProtocol?

    /**
     * Creates a new unconfigured media player.
     *
     * The caller is responsible for setting the data source and preparing.
     *
     * @return New MediaPlayerProtocol instance
     */
    fun create(): MediaPlayerProtocol
}
