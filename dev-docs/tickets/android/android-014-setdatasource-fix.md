# Ticket android-014: setDataSource Failed Fix

**Status**: [ ] TODO
**Prioritaet**: KRITISCH
**Aufwand**: Klein (~1-2h)
**Abhaengigkeiten**: android-008
**Phase**: 1-Quick Fix

---

## Beschreibung

Beim Abspielen von Guided Meditations erscheint der Fehler:
- "Failed to play" -> "setDataSource failed"

Das Problem tritt auf, wenn `MediaPlayer.setDataSource()` mit einer Content-URI aufgerufen wird.

Moegliche Ursachen:
1. **URI-Persistenz**: SAF (Storage Access Framework) URIs verlieren Berechtigung nach App-Neustart
2. **URI-Format**: URI wird nicht korrekt geparst oder ist ungueltig
3. **Fehlende Berechtigung**: `takePersistableUriPermission()` wurde nicht aufgerufen
4. **Content Resolver**: URI muss ueber ContentResolver geoeffnet werden

---

## Akzeptanzkriterien

- [ ] Audio-Dateien koennen nach App-Neustart abgespielt werden
- [ ] Fehlerbehandlung zeigt aussagekraeftige Fehlermeldung
- [ ] URI-Berechtigungen werden persistent gespeichert
- [ ] Logging zeigt URI-Details bei Fehlern

### Tests (PFLICHT)
- [ ] Unit Tests fuer URI-Handling
- [ ] Bestehende Tests weiterhin gruen
- [ ] Manueller Test: Audio importieren, App beenden, neu starten, abspielen

### Dokumentation
- [ ] CHANGELOG.md: Fix Eintrag

---

## Betroffene Dateien

### Zu aendern:
- `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/AudioPlayerService.kt`
  - `play()` Methode: URI-Handling verbessern
- `android/app/src/main/kotlin/com/stillmoment/data/repositories/GuidedMeditationRepositoryImpl.kt`
  - `importMeditation()`: URI-Berechtigung persistent machen

### Tests:
- `android/app/src/test/kotlin/com/stillmoment/infrastructure/audio/AudioPlayerServiceTest.kt`

---

## Technische Details

### Problem 1: URI-Berechtigung nicht persistent

Beim Import einer Datei ueber SAF muss die Berechtigung persistent gemacht werden:

```kotlin
// In GuidedMeditationRepositoryImpl.importMeditation()
context.contentResolver.takePersistableUriPermission(
    uri,
    Intent.FLAG_GRANT_READ_URI_PERMISSION
)
```

### Problem 2: setDataSource mit Content-URI

`MediaPlayer.setDataSource(context, uri)` kann bei Content-URIs fehlschlagen.
Sichere Alternative:

```kotlin
// Option A: FileDescriptor verwenden
val pfd = context.contentResolver.openFileDescriptor(uri, "r")
pfd?.use { descriptor ->
    mediaPlayer.setDataSource(descriptor.fileDescriptor)
}

// Option B: AssetFileDescriptor verwenden
val afd = context.contentResolver.openAssetFileDescriptor(uri, "r")
afd?.use { descriptor ->
    mediaPlayer.setDataSource(
        descriptor.fileDescriptor,
        descriptor.startOffset,
        descriptor.length
    )
}
```

### Problem 3: Bessere Fehlerbehandlung

```kotlin
try {
    val pfd = context.contentResolver.openFileDescriptor(Uri.parse(meditation.fileUri), "r")
    if (pfd == null) {
        _playbackState.update { it.copy(error = "Datei nicht mehr verfuegbar") }
        return
    }
    pfd.use { descriptor ->
        mediaPlayer.setDataSource(descriptor.fileDescriptor)
    }
} catch (e: SecurityException) {
    Logger.audio.error("URI-Berechtigung verloren: ${meditation.fileUri}")
    _playbackState.update { it.copy(error = "Berechtigung fehlt - bitte Datei erneut importieren") }
} catch (e: FileNotFoundException) {
    Logger.audio.error("Datei nicht gefunden: ${meditation.fileUri}")
    _playbackState.update { it.copy(error = "Datei wurde geloescht oder verschoben") }
}
```

---

## Testanweisungen

```bash
cd android && ./gradlew test
cd android && ./gradlew assembleDebug
```

### Manueller Test:
1. App starten
2. Eine MP3-Datei in die Library importieren
3. Meditation abspielen -> sollte funktionieren
4. App komplett beenden (aus Recent Apps entfernen)
5. App neu starten
6. Dieselbe Meditation abspielen
7. **Erwartung**: Audio spielt ab (nicht "setDataSource failed")

### Debug-Test:
1. Logcat filtern nach "AudioPlayerService"
2. Bei Fehler: URI und Exception-Details pruefen
3. Pruefen ob `takePersistableUriPermission` aufgerufen wurde

---

## Referenzen

- [Android SAF Guide](https://developer.android.com/guide/topics/providers/document-provider)
- [MediaPlayer setDataSource](https://developer.android.com/reference/android/media/MediaPlayer#setDataSource(android.content.Context,%20android.net.Uri))
- [Persistable URI Permissions](https://developer.android.com/training/data-storage/shared/documents-files#persist-permissions)
