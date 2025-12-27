package com.stillmoment.domain.services

/**
 * Protocol for media player operations.
 *
 * Abstracts Android's MediaPlayer for testability.
 * Implementation wraps the actual MediaPlayer and forwards calls.
 */
@Suppress("TooManyFunctions") // Complete MediaPlayer abstraction requires all these methods
interface MediaPlayerProtocol {
    /**
     * Starts or resumes playback.
     */
    fun start()

    /**
     * Pauses playback.
     */
    fun pause()

    /**
     * Stops playback.
     */
    fun stop()

    /**
     * Releases the media player resources.
     */
    fun release()

    /**
     * Seeks to the specified position.
     *
     * @param position Position in milliseconds
     */
    fun seekTo(position: Int)

    /**
     * Gets the current playback position.
     *
     * @return Position in milliseconds
     */
    val currentPosition: Int

    /**
     * Checks if the player is currently playing.
     */
    val isPlaying: Boolean

    /**
     * Sets the volume for both channels.
     *
     * @param leftVolume Left channel volume (0.0 to 1.0)
     * @param rightVolume Right channel volume (0.0 to 1.0)
     */
    fun setVolume(leftVolume: Float, rightVolume: Float)

    /**
     * Sets whether the playback should loop.
     */
    var isLooping: Boolean

    /**
     * Sets the listener for preparation completion.
     *
     * @param listener Called when the player is ready to play
     */
    fun setOnPreparedListener(listener: () -> Unit)

    /**
     * Sets the listener for playback completion.
     *
     * @param listener Called when playback completes
     */
    fun setOnCompletionListener(listener: () -> Unit)

    /**
     * Sets the listener for errors.
     *
     * @param listener Called with error codes when an error occurs, returns true if handled
     */
    fun setOnErrorListener(listener: (what: Int, extra: Int) -> Boolean)

    /**
     * Prepares the player asynchronously.
     */
    fun prepareAsync()

    /**
     * Sets the data source from a file path.
     *
     * @param path File path to the audio file
     */
    fun setDataSource(path: String)

    /**
     * Sets the data source from a file descriptor.
     *
     * @param fd File descriptor for the audio file
     */
    fun setDataSourceFromFd(fd: java.io.FileDescriptor)
}
