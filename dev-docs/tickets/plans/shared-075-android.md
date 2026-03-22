# Implementierungsplan: shared-075 (Android)

Ticket: [shared-075](../shared/shared-075-library-long-press-preview.md)
Erstellt: 2026-03-20

## Hintergrund

iOS ist fertig. Dieser Plan beschreibt die Android-Implementierung: Long-Press-Preview im Play-Button,
Swipe-Actions fuer Edit+Delete, Overflow-Menu-Entfernung.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `domain/services/MediaPlayerFactoryProtocol.kt` | Domain | Erweitern | `createFromContentUri(uriString: String)` hinzufuegen — fuer SAF-Content-URIs |
| `domain/services/AudioServiceProtocol.kt` | Domain | Erweitern | `playMeditationPreview(fileUri: String)` / `stopMeditationPreview()` hinzufuegen |
| `infrastructure/audio/MediaPlayerFactory.kt` | Infrastructure | Erweitern | `createFromContentUri` implementieren via `MediaPlayer.create(context, Uri.parse(...))` |
| `infrastructure/audio/AudioService.kt` | Infrastructure | Erweitern | `meditationPreviewPlayer` + Methoden implementieren |
| `presentation/viewmodel/GuidedMeditationsListViewModel.kt` | Application | Erweitern | `AudioServiceProtocol`-Dependency, `startPreview`/`stopPreview`, `onCleared` |
| `presentation/viewmodel/GuidedMeditationsListUiState` (in ViewModel-Datei) | Application | Erweitern | `previewingMeditationId: String? = null` |
| `presentation/ui/meditations/MeditationListItem.kt` | Presentation | Umbauen | Overflow-Menu entfernen, Play-Button mit `combinedClickable` + Icon-Toggle |
| `presentation/ui/meditations/GuidedMeditationsListScreen.kt` | Presentation | Anpassen | Swipe-Actions: Edit (`StartToEnd`) + Delete (`EndToStart`), Preview-Callbacks verdrahten |
| `res/values/strings.xml` + `res/values-de/strings.xml` | Resources | Ergaenzen | Accessibility-Strings fuer Preview-Start/-Stop, Edit-Swipe |

## API-Recherche

- **`Modifier.combinedClickable()`** — `androidx.compose.foundation` ab 1.2.0 stabil. Braucht `@OptIn(ExperimentalFoundationApi::class)` bis Foundation 1.4, danach stabil ohne Opt-In. Projet nutzt `foundation:1.x` — kurz checken ob Opt-In noetig.
  ```kotlin
  Box(Modifier.combinedClickable(
      onClick = { onPlayClick() },
      onLongClick = { onPreviewStart() }
  )) { ... }
  ```
- **`HapticFeedbackType.LongPress`** — korrekte Konstante fuer Long-Press-Feedback (nicht `TextHandleMove`). Existierendes Muster: `val haptic = LocalHapticFeedback.current` + `haptic.performHapticFeedback(HapticFeedbackType.LongPress)`.
- **`MediaPlayer.create(context, Uri)`** — verfuegbar seit API 1, stabil. Nimmt `android.net.Uri` (Content URIs von SAF werden unterstuetzt). Gibt `null` zurueck bei Fehler.
- **`SwipeToDismissBox` zwei Richtungen** — `enableDismissFromStartToEnd = true` + `enableDismissFromEndToStart = true`. `backgroundContent` erhaelt via `dismissState.dismissDirection` die aktuelle Richtung. Bereits importiert im Screen.

## Design-Entscheidungen

### 1. Content URI-Playback fuer Preview

**Problem:** `AudioService` spielt bisher nur Raw-Resources (`createFromResource`) und File-Paths (`setDataSource(path)`). Guided Meditations verwenden Content URIs (SAF) — `android.net.Uri` — die im Domain-Layer nicht erlaubt sind.

**Entscheidung:** `MediaPlayerFactoryProtocol` erhaelt eine neue Methode `createFromContentUri(uriString: String)`: URI als `String` (domain-neutral), Implementierung in `MediaPlayerFactory` parsed zu `android.net.Uri` und nutzt `MediaPlayer.create(context, uri)`.

**Vorteil:** Kein Android-Import im Domain-Layer, nahtlose Integration ins bestehende Factory-Pattern, kein neuer Service noetig.

### 2. Swipe-Richtungen: Edit rechts, Delete links

**Problem:** Das iOS-Wireframe zeigt Edit+Delete auf demselben Swipe. `SwipeToDismissBox` (Material3) unterstuetzt nur eine Aktion pro Swipe-Richtung ohne Custom-Implementation.

**Entscheidung:** Zwei Richtungen nutzen — standard Android-Muster:
- `StartToEnd` (Wischen nach rechts) → Bearbeiten (blau, `Icons.Default.Edit`)
- `EndToStart` (Wischen nach links) → Loeschen (rot, `Icons.Default.Delete`)

**Vorteil:** Kein Custom-Component, nutzt bestehendes `SwipeToDismissBox`, klare visuelle Trennumg (destruktive Aktion = links, nicht-destruktiv = rechts).

### 3. `combinedClickable` auf Box statt IconButton

**Problem:** `IconButton` unterstuetzt kein Long-Press. `Button`/`IconButton` feuert nur `onClick`.

**Entscheidung:** Play-Icon in eine `Box` mit `Modifier.combinedClickable(onClick = ..., onLongClick = ...)` wrappen. Kein `IconButton` mehr an dieser Stelle — Ripple-Effekt via `rememberRipple()` manuell setzen oder `indication = rememberRipple(bounded = false)`.

### 4. Preview-Zustand ausschliesslich im ViewModel

**Entscheidung:** Kein lokaler View-State in `MeditationListItem`. Der Preview-Zustand lebt in `GuidedMeditationsListUiState.previewingMeditationId`. Das ist die einzige Source of Truth — konsistent mit iOS-Ansatz.

### 5. Preview stoppt automatisch bei Navigation zum Player

**Kein expliziter Code noetig.** Wenn der Player `requestAudioSession(AudioSource.GUIDED_MEDITATION)` aufruft, loest `AudioSessionCoordinator` den bereits registrierten Conflict-Handler fuer `AudioSource.PREVIEW` aus, der alle Preview-Player stoppt (inkl. `meditationPreviewPlayer`). Gilt auch fuer andere Quellen (Timer).

### 6. `GuidedMeditationsListViewModel.onCleared()` stoppt Preview

**Entscheidung:** `override fun onCleared()` ruft `audioService.stopMeditationPreview()` auf — sauber bei Navigation weg von der List-Screen.

## Fachliche Szenarien

### AK-Tap: Tap auf Play-Button startet Meditation

- Gegeben: Bibliothek mit einer Meditation, keine Preview aktiv
  Wenn: User tippt kurz auf den Play-Button (▶)
  Dann: Navigation zum Full Player, Meditation kann starten

- Gegeben: Preview laeuft fuer diese Meditation
  Wenn: User tippt kurz auf den Stop-Button (■)
  Dann: Audio stoppt (Fade-out ~0.3s), Icon wechselt zurueck zu ▶

### AK-LongPress: Long-Press startet Preview

- Gegeben: Bibliothek mit einer Meditation
  Wenn: User drueckt lang auf den Play-Button (~0.5s)
  Dann: Haptisches Feedback (LongPress), Icon wechselt zu ■, Audio startet ab Anfang

- Gegeben: Preview laeuft fuer Meditation A
  Wenn: User drueckt lang auf Play-Button von Meditation B
  Dann: Preview A stoppt, Preview B startet, Icon A → ▶, Icon B → ■

### AK-Icon: Icon-Toggle korrekt

- Gegeben: Meditation A previewed, Meditation B nicht
  Dann: Meditation A zeigt ■, Meditation B zeigt ▶

### AK-Swipe: Swipe-Actions korrekt

- Gegeben: Liste mit Meditationen
  Wenn: User wischt nach links (EndToStart) auf einer Row
  Dann: Roter "Loeschen"-Hintergrund erscheint mit Delete-Icon; beim Loslassen: Bestaetigugnsdialog

- Gegeben: Liste mit Meditationen
  Wenn: User wischt nach rechts (StartToEnd) auf einer Row
  Dann: Blauer "Bearbeiten"-Hintergrund erscheint; beim Loslassen: Edit-Sheet oeffnet sich

### AK-KeinRowTap: Row-Text ist nicht tappbar

- Gegeben: Bibliothek mit einer Meditation
  Wenn: User tippt auf Meditationstitel oder Dauer (nicht auf Play-Button)
  Dann: Nichts passiert (kein `clickable` auf Card), nur Scroll

### AK-Preview-Source: Verwendet AudioSource.PREVIEW

- Gegeben: Preview wird gestartet
  Dann: `AudioSessionCoordinator.requestAudioSession(AudioSource.PREVIEW)` wird aufgerufen (nicht GUIDED_MEDITATION)

### AK-AutoStop: Navigation zum Player stoppt Preview

- Gegeben: Preview laeuft
  Wenn: User tippt Play-Button einer Meditation → Navigation zum Player → `requestAudioSession(GUIDED_MEDITATION)`
  Dann: Conflict-Handler stoppt Preview automatisch; `previewingMeditationId` wird nach onCleared/Screen-Verlassen aufgeraeumt

### AK-Fade: Fade-out beim Stop

- Gegeben: Preview laeuft
  Wenn: User tippt Stop-Button (■)
  Dann: Audio stoppt mit kurzem Fade-out (~0.3s, konsistent mit iOS)

## Reihenfolge der Implementierung

1. **Strings** — `accessibility_start_preview`, `accessibility_stop_preview`, `accessibility_swipe_edit` in EN+DE
2. **`MediaPlayerFactoryProtocol` + `MediaPlayerFactory`** — `createFromContentUri` (Basis fuer AudioService)
3. **`AudioServiceProtocol` + `AudioService`** — `playMeditationPreview`/`stopMeditationPreview`, Fade-out
4. **`GuidedMeditationsListUiState`** — `previewingMeditationId: String?` ergaenzen
5. **`GuidedMeditationsListViewModel`** — `AudioServiceProtocol` einhaengen, `startPreview`/`stopPreview`/`onCleared`
6. **`MeditationListItem`** — Overflow-Menu entfernen, `combinedClickable` Play-Button, Icon-Toggle, `clickable` von Card entfernen
7. **`GuidedMeditationsListScreen`** — `SwipeToDeleteItem` → `SwipeToEditDeleteItem` (beide Richtungen), Preview-Callbacks verdrahten
8. **Tests** — `GuidedMeditationsListViewModelTest` erweitern um `PreviewTests` nested class

## Implementierungsdetails

### AudioService: `playMeditationPreview`

```kotlin
// Neues Feld
private var meditationPreviewPlayer: MediaPlayerProtocol? = null

override fun playMeditationPreview(fileUri: String) {
    stopMeditationPreview()
    stopGongPreview()
    stopBackgroundPreview()

    val player = mediaPlayerFactory.createFromContentUri(fileUri)
    if (player == null) {
        logger.e(TAG, "Failed to create player for meditation preview: $fileUri")
        return
    }
    coordinator.requestAudioSession(AudioSource.PREVIEW)
    meditationPreviewPlayer = player.apply {
        setVolume(1.0f, 1.0f)
        setOnCompletionListener {
            release()
            meditationPreviewPlayer = null
            coordinator.releaseAudioSession(AudioSource.PREVIEW)
        }
        start()
    }
}

override fun stopMeditationPreview() {
    // Fade-out analog zu stopBackgroundPreview
    val hadPlayer = meditationPreviewPlayer != null
    mainScope.launch {
        fadeOutMeditationPreview()
    }
    if (hadPlayer) {
        coordinator.releaseAudioSession(AudioSource.PREVIEW)
    }
}
```

Fade-out: eigene `fadeOutMeditationPreview()` analog zu `fadeOutBackgroundPreview()` (~0.3s, 10 Schritte).

### cleanupPreviewPlayers()

Muss `meditationPreviewPlayer` ebenfalls aufraumen (Conflict-Handler-Pfad).

### MeditationListItem: Play-Button

```kotlin
// Parameter-Aenderungen:
// + onPlayClick: () -> Unit  (ersetzt onClick)
// + onPreviewStart: () -> Unit
// + onStopPreview: () -> Unit
// + isPreviewActive: Boolean
// - onDeleteClick: () -> Unit  (entfernt — via Swipe)
// onClick: () -> Unit bleibt NICHT auf der Card

val playIcon = if (isPreviewActive) Icons.Default.Stop else Icons.Default.PlayCircle

Box(
    Modifier
        .size(40.dp)
        .combinedClickable(
            onClick = { if (isPreviewActive) onStopPreview() else onPlayClick() },
            onLongClick = { if (!isPreviewActive) onPreviewStart() }
        )
) {
    Icon(imageVector = playIcon, ...)
}
```

### SwipeToEditDeleteItem

```kotlin
SwipeToDismissBox(
    enableDismissFromStartToEnd = true,   // Edit
    enableDismissFromEndToStart = true,   // Delete
    backgroundContent = {
        when (dismissState.dismissDirection) {
            SwipeToDismissBoxValue.StartToEnd -> EditBackground()
            SwipeToDismissBoxValue.EndToStart -> DeleteBackground()
            else -> {}
        }
    }
) { ... }
```

`confirmValueChange`:
- `StartToEnd` → `onEditClick()`, return `false` (reset swipe)
- `EndToStart` → `onDelete()`, return `false` (reset — Dialog bestaetigt erst)

## Neue Strings

```xml
<!-- EN -->
<string name="accessibility_start_preview">Preview meditation</string>
<string name="accessibility_stop_preview">Stop preview</string>
<string name="accessibility_edit_meditation">Edit meditation</string>
```

```xml
<!-- DE -->
<string name="accessibility_start_preview">Meditation vorschauen</string>
<string name="accessibility_stop_preview">Vorschau stoppen</string>
<string name="accessibility_edit_meditation">Meditation bearbeiten</string>
```

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| `combinedClickable` Opt-In noetig | `@OptIn(ExperimentalFoundationApi::class)` beim Composable oder bis Foundation 1.7 stabilisiert |
| `MediaPlayer.create(context, contentUri)` scheitert bei abgelaufener URI-Permission | Fehlerbehandlung in `playMeditationPreview` (log + kein Crash); URI-Permissions werden bei Import via `takePersistableUriPermission` gesichert |
| Swipe-Reset nach Dialog-Abbruch | `confirmValueChange` gibt `false` zurueck → Swipe-State resetet automatisch |
| detekt LongMethod | `MeditationListItem` wachst durch Play-Button-Logik — ggf. `PlayButton` als eigenes Composable auslagern |
