package com.stillmoment.infrastructure.audio

import android.content.Context
import android.media.MediaPlayer
import com.stillmoment.domain.services.MediaPlayerFactoryProtocol
import com.stillmoment.domain.services.MediaPlayerProtocol
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Factory for creating MediaPlayer instances.
 *
 * Provides testable MediaPlayer creation via MediaPlayerProtocol.
 */
@Singleton
class MediaPlayerFactory
@Inject
constructor(
    @ApplicationContext private val context: Context
) : MediaPlayerFactoryProtocol {

    override fun createFromResource(resourceId: Int): MediaPlayerProtocol? {
        val mediaPlayer = MediaPlayer.create(context, resourceId) ?: return null
        return MediaPlayerWrapper(mediaPlayer)
    }

    override fun create(): MediaPlayerProtocol {
        return MediaPlayerWrapper(MediaPlayer())
    }
}
