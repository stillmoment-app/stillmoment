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
     * @param resourceId Raw resource ID (e.g., R.raw.completion)
     * @return Configured MediaPlayerProtocol instance, or null if creation fails
     */
    fun createFromResource(resourceId: Int): MediaPlayerProtocol?

    /**
     * Creates a new unconfigured media player.
     *
     * The caller is responsible for setting the data source and preparing.
     *
     * @return New MediaPlayerProtocol instance
     */
    fun create(): MediaPlayerProtocol
}
