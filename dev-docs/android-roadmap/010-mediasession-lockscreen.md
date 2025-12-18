# Ticket 010: MediaSession Lock Screen Controls

**Status**: [ ] TODO
**Priorität**: MITTEL
**Aufwand**: Mittel (~2-3h)
**Abhängigkeiten**: 008

---

## Beschreibung

MediaSession für Lock Screen Controls implementieren:
- Play/Pause vom Lock Screen
- Now Playing Info (Titel, Artist)
- Notification mit Controls

---

## Akzeptanzkriterien

- [ ] MediaSession in AudioPlayerService integriert
- [ ] Lock Screen zeigt Now Playing Info
- [ ] Play/Pause Controls auf Lock Screen funktionieren
- [ ] Notification mit Meditation-Info und Controls
- [ ] Session wird bei Stop beendet
- [ ] Bluetooth/Headphone Controls funktionieren

---

## Betroffene Dateien

### Zu ändern:
- `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/AudioPlayerService.kt`

### Neu zu erstellen:
- `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/MediaSessionManager.kt`

### Manifest:
- `android/app/src/main/AndroidManifest.xml` (ggf. Service-Definition anpassen)

---

## Technische Details

### MediaSession Manager:
```kotlin
// infrastructure/audio/MediaSessionManager.kt
@Singleton
class MediaSessionManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private var mediaSession: MediaSessionCompat? = null

    fun createSession(
        onPlay: () -> Unit,
        onPause: () -> Unit,
        onStop: () -> Unit,
        onSeekTo: (Long) -> Unit
    ): MediaSessionCompat {
        mediaSession = MediaSessionCompat(context, "StillMomentPlayer").apply {
            setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay() = onPlay()
                override fun onPause() = onPause()
                override fun onStop() = onStop()
                override fun onSeekTo(pos: Long) = onSeekTo(pos)
            })
            isActive = true
        }
        return mediaSession!!
    }

    fun updateMetadata(meditation: GuidedMeditation) {
        mediaSession?.setMetadata(
            MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, meditation.effectiveName)
                .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, meditation.effectiveTeacher)
                .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, meditation.duration)
                .build()
        )
    }

    fun updatePlaybackState(isPlaying: Boolean, position: Long) {
        val state = if (isPlaying) {
            PlaybackStateCompat.STATE_PLAYING
        } else {
            PlaybackStateCompat.STATE_PAUSED
        }

        mediaSession?.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setState(state, position, 1f)
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_SEEK_TO or
                    PlaybackStateCompat.ACTION_STOP
                )
                .build()
        )
    }

    fun release() {
        mediaSession?.isActive = false
        mediaSession?.release()
        mediaSession = null
    }
}
```

### Updated AudioPlayerService:
```kotlin
// infrastructure/audio/AudioPlayerService.kt
@Singleton
class AudioPlayerService @Inject constructor(
    @ApplicationContext private val context: Context,
    private val mediaSessionManager: MediaSessionManager
) {
    private var mediaPlayer: MediaPlayer? = null
    private var currentMeditation: GuidedMeditation? = null

    fun play(meditation: GuidedMeditation) {
        currentMeditation = meditation
        stop()

        // Create MediaSession
        mediaSessionManager.createSession(
            onPlay = { resume() },
            onPause = { pause() },
            onStop = { stop() },
            onSeekTo = { seekTo(it) }
        )

        // Update metadata
        mediaSessionManager.updateMetadata(meditation)

        // Start playback
        mediaPlayer = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .build()
            )
            setDataSource(context, Uri.parse(meditation.fileUri))
            prepare()
            start()
        }

        mediaSessionManager.updatePlaybackState(true, 0)
        showNotification()
    }

    fun pause() {
        mediaPlayer?.pause()
        mediaSessionManager.updatePlaybackState(false, currentPosition)
        updateNotification()
    }

    fun resume() {
        mediaPlayer?.start()
        mediaSessionManager.updatePlaybackState(true, currentPosition)
        updateNotification()
    }

    fun stop() {
        mediaPlayer?.release()
        mediaPlayer = null
        mediaSessionManager.release()
        hideNotification()
    }

    private fun showNotification() {
        val meditation = currentMeditation ?: return
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle(meditation.effectiveName)
            .setContentText(meditation.effectiveTeacher)
            .setSmallIcon(R.drawable.ic_notification)
            .setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setMediaSession(mediaSessionManager.mediaSession?.sessionToken)
                    .setShowActionsInCompactView(0)
            )
            .addAction(
                if (isPlaying) R.drawable.ic_pause else R.drawable.ic_play,
                if (isPlaying) "Pause" else "Play",
                createPendingIntent(if (isPlaying) ACTION_PAUSE else ACTION_PLAY)
            )
            .build()

        // Show notification via NotificationManager or Foreground Service
    }
}
```

---

## Manifest Anpassungen

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />

<service
    android:name=".infrastructure.audio.MeditationPlayerService"
    android:exported="false"
    android:foregroundServiceType="mediaPlayback">
    <intent-filter>
        <action android:name="android.intent.action.MEDIA_BUTTON" />
    </intent-filter>
</service>
```

---

## Testanweisungen

```bash
# Build prüfen
cd android && ./gradlew assembleDebug

# Manueller Test:
# 1. Meditation starten
# 2. Bildschirm sperren
# 3. Lock Screen zeigt Now Playing
# 4. Play/Pause auf Lock Screen testen
# 5. Notification hat Controls
# 6. Bluetooth-Kopfhörer: Play/Pause-Button funktioniert
```

---

## iOS-Referenz

iOS verwendet `MPNowPlayingInfoCenter` und `MPRemoteCommandCenter`:
- `ios/StillMoment/Infrastructure/Services/AudioPlayerService.swift`
