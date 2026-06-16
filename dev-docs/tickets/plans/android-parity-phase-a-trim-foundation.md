# Implementierungsplan: Android-Parität Phase A — Trim-Fundament

Tickets: [shared-105](../shared/shared-105-trim-punkte-gefuehrte-meditationen.md) (Datenmodell + Playback-Teil)
Erstellt: 2026-06-16
Kontext: Erstes von vier Paketen, um Android auf den iOS-Stand der Trim-/Gong-/Wellenform-Feature-Familie zu bringen (Phasen A–D). Die Pakete sind bewusst gegenüber den iOS-Tickets **kollabiert**: iOS hat sich iterativ zum Ziel gearbeitet (mm:ss-Textfelder in shared-105 → durch Wellenform-Karte in shared-107 ersetzt → Save-Semantik in shared-112 geändert). Der iOS-**Code** ist der Endzustand; Android baut direkt diesen, ohne die verworfenen Zwischenschritte.

## Ziel

Das Datenmodell und das Wiedergabe-Verhalten für nicht-destruktive Trim-Punkte (Startpunkt/Endpunkt pro Meditation). **Kein sichtbares Editor-UI** — die mm:ss-Textfelder aus iOS shared-105 wurden dort später entfernt; das UI zum Setzen der Punkte ist der Wellenform-Editor und kommt in Phase C.

**Konsequenz aus dem Kollabieren:** Phase A ist für sich genommen **nicht** user-sichtbar abschließbar — sie liefert das Substrat (Modell + getrimmtes Playback). Erst zusammen mit Phase C (Wellenform-Editor) entsteht das vollständige shared-105-Feature. Das ist gewollt: lieber das Fundament sauber und testbar isoliert, als die verworfene Textfeld-UI nachzubauen.

## Annahmen

- **Dauer-Einheit ist Millisekunden (`Long`).** Anders als iOS (`TimeInterval`/Sekunden, `Double`) arbeitet Android durchgängig in ms (`GuidedMeditation.duration: Long`, `MediaPlayer.seekTo(Int)`, `PlaybackState` in ms). Trim-Felder daher als `trimStartMs: Long?` / `trimEndMs: Long?`.
- **Rückwärtskompatible Persistenz ohne Migration.** `GuidedMeditationDataStore` nutzt `Json { ignoreUnknownKeys = true; encodeDefaults = true }`. Neue nullable-Felder mit Default `null` decodieren bestehende Library-Einträge ohne die Keys problemlos (kotlinx.serialization füllt fehlende optionale Felder mit dem Default). Kein Pre-Decode-Sweep nötig (anders als shared-103, das Felder *umbenannte*).
- **Getrimmtes Playback über den bestehenden `MediaPlayerProtocol`-Seam.** Der Guided-Player nutzt `MediaPlayerProtocol` (Wrapper über `android.media.MediaPlayer`), nicht ExoPlayer direkt. Start-Offset via `seekTo`, End-Punkt via Polling im bereits laufenden `ProgressScheduler` (500 ms) — MediaPlayer hat **keinen** nativen End-Boundary-Observer wie iOS' AVPlayer-`addBoundaryTimeObserver`.
- **`effectiveDuration` wird die überall angezeigte Dauer.** Bibliothek und Player zeigen die getrimmte Länge; die volle Dateilänge bleibt als Referenz erhalten (`formattedFileDuration`, für Phase C).
- **Keine UI-Änderungen am Editor in dieser Phase.** `MeditationEditSheet` bleibt unangetastet.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `domain/models/GuidedMeditation.kt` | Domain | Erweitern | Felder `trimStartMs: Long? = null`, `trimEndMs: Long? = null`; computed `effectiveStartMs`/`effectiveEndMs`/`effectiveDurationMs`; `formattedDuration` auf `effectiveDurationMs` umstellen; `formattedFileDuration` (volle Länge) ergänzen |
| `data/local/GuidedMeditationDataStore.kt` | Data | Unverändert | `encodeDefaults`/`ignoreUnknownKeys` bereits gesetzt — neue Felder serialisieren/deserialisieren ohne Änderung; Backward-Compat per Test absichern |
| `infrastructure/audio/AudioPlayerService.kt` | Infra | Erweitern | `playMeditation`: nach `onPrepared` auf `trimStartMs` seeken; `duration` an `configureListeners`/`PlaybackState` = `effectiveDurationMs`; End-Boundary-Check im Progress-Loop (`position >= effectiveEndMs` → reguläres Completion wie `onCompletion`); `seekTo` auf `[trimStartMs, trimEndMs]` klemmen |
| `infrastructure/audio/ProgressScheduler.kt` | Infra | Prüfen | Läuft im Foreground-Service-Pfad weiter (Lock Screen) — verifizieren, dass der 500-ms-Tick zuverlässig auch bei gesperrtem Screen feuert |
| `infrastructure/audio/MediaSessionManager.kt` | Infra | Erweitern | Lock-Screen-Seek/Skip (±15 s) auf den Trim-Bereich klemmen; Now-Playing-Position/-Dauer relativ zum Bereich (Position − `trimStartMs`, Dauer = `effectiveDurationMs`) |
| `presentation/viewmodel/GuidedMeditationPlayerViewModel.kt` | ViewModel | Erweitern | Skip ±10 s auf `[trimStartMs, trimEndMs]` klemmen; angezeigte Position/Dauer relativ zum Bereich; Restart nach Abschluss beginnt bei `trimStartMs` |
| `presentation/ui/meditations/GuidedMeditationPlayerScreen.kt` | UI | Prüfen | Fortschritts-Anzeige/Slider nutzt effektive Dauer und Bereichs-relative Position |
| `presentation/ui/meditations/components/MeditationListItem.kt` (o.ä.) | UI | Prüfen | Library-Zeile zeigt `formattedDuration` — durch Modell-Änderung automatisch effektiv; visuell prüfen |
| `test/.../GuidedMeditationTest.kt` | Tests | Neu/Erweitern | Domain: effective-Properties, Codable-Backward-Compat |
| `test/.../AudioPlayerServiceTest.kt` | Tests | Erweitern | Seek-to-Start, End-Boundary-Completion, Klemmung — via Mock-`MediaPlayerProtocol` |

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `MediaPlayer.seekTo(Int)` | API 1 / `SEEK_CLOSEST` ab API 26 | Android Docs | minSdk 26 → `seekTo(ms, SEEK_CLOSEST)` für framegenaues Seek verfügbar; relevanter erst in Phase C |
| `kotlinx.serialization` nullable-Defaults | - | kotlinx Docs | Fehlende optionale Felder → Default beim Decode; mit `encodeDefaults=true` werden sie auch geschrieben |
| `ClippingMediaSource` (Media3/ExoPlayer) | - | Media3 Docs | **Alternative** für natives Start/End-Clipping; nur relevant, falls Polling-Präzision nicht reicht (siehe Risiken). Der Guided-Pfad nutzt aktuell MediaPlayer, kein ExoPlayer — Umstieg wäre ein größerer Eingriff, daher nicht Default. |

## Design-Entscheidungen

### 1. End-Punkt via Progress-Polling statt nativem Boundary-Observer

**Problem:** iOS löst das Ende über `AVPlayer.addBoundaryTimeObserver` (exakt, OS-getrieben, lock-screen-fest). Androids `MediaPlayer` hat kein Pendant.
**Entscheidung:** Den bereits für die Fortschritts-Anzeige laufenden `ProgressScheduler` (500 ms) nutzen: Sobald `currentPosition >= effectiveEndMs`, denselben Completion-Pfad auslösen wie `setOnCompletionListener` (Abschluss-Screen, Service-Stop, Session-Release). Minimal-Change, nutzt vorhandene Infrastruktur, läuft im Foreground-Service auch bei gesperrtem Screen.
**Trade-off:** Granularität ~500 ms → das Ende kann um bis zu einen halben Tick überschossen werden, bevor gestoppt wird. Für ein Meditations-Ende akzeptabel (sanftes Ausklingen, kein harter Schnitt mitten im Wort). Falls sich das in der Praxis als zu unpräzise zeigt: Tick nahe dem Endpunkt verdichten oder auf `ClippingMediaSource` (ExoPlayer) wechseln — als Folge-Entscheidung, nicht jetzt.

### 2. Trim-Werte als nullable ms, `null` = ganze Datei

Spiegelt das iOS-Modell (`trimStart`/`trimEnd` optional, `nil` = Rand). `effectiveStartMs = trimStartMs ?: 0`, `effectiveEndMs = trimEndMs ?: duration`. Bestehende Einträge ohne Trim verhalten sich unverändert.

### 3. Bereichs-relative Anzeige zentral im ViewModel/Service, nicht in jeder View

Position und Dauer werden für Anzeige, Slider und Lock Screen einmal relativ zum Trim-Bereich gerechnet (Position − `trimStartMs`, Dauer = `effectiveDurationMs`), damit alle Oberflächen konsistent „die Zeit, die man tatsächlich meditiert" zeigen.

## Fachliche Szenarien (Akzeptanzkriterien)

### AK: Wiedergabe startet am Startpunkt
- Gegeben: Meditation mit `trimStartMs = 30_000`
  Wenn: Wiedergabe startet
  Dann: Audio beginnt bei 0:30 der Datei; die angezeigte Position startet bei 0:00 (bereichs-relativ).

### AK: Wiedergabe endet am Endpunkt mit regulärem Abschluss
- Gegeben: Meditation mit `trimEndMs` vor dem Dateiende
  Wenn: die Wiedergabe den Endpunkt erreicht
  Dann: sie endet wie ein reguläres Dateiende — Abschluss-Screen erscheint, Service/Session werden freigegeben.

### AK: Ende greift auch bei gesperrtem Bildschirm
- Gegeben: Meditation mit Endpunkt, Bildschirm gesperrt, Foreground-Service aktiv
  Wenn: der Endpunkt erreicht wird
  Dann: die Wiedergabe stoppt zuverlässig am Endpunkt (Progress-Loop feuert im Service weiter).

### AK: Spulen bleibt im Bereich
- Gegeben: Meditation mit `trimStartMs`/`trimEndMs`
  Wenn: Nutzer im Player ±10 s skippt oder am Lock Screen ±15 s / scrubt
  Dann: die Zielposition wird auf `[trimStartMs, trimEndMs]` geklemmt — nie in Intro/Outro.

### AK: Angezeigte Dauer ist die effektive Dauer
- Gegeben: 20-Minuten-Datei mit Trim auf 14 Minuten hörbaren Bereich
  Wenn: Nutzer die Meditation in Bibliothek und Player sieht
  Dann: angezeigt werden 14:00 (effektiv); die volle Dateilänge bleibt nur als Referenz erhalten (`formattedFileDuration`, in Phase C sichtbar).

### AK: Restart nach Abschluss beginnt am Startpunkt
- Gegeben: getrimmte Meditation, gerade beendet
  Wenn: Nutzer sie erneut startet
  Dann: die Wiedergabe beginnt wieder bei `trimStartMs`, nicht bei 0.

### AK: Bestehende Meditationen unverändert
- Gegeben: Library-Eintrag ohne Trim-Felder (vor diesem Update gespeichert)
  Wenn: er geladen und abgespielt wird
  Dann: `trimStartMs`/`trimEndMs` sind `null`, volle Datei spielt, angezeigte Dauer = volle Länge.

### AK: Trim-Punkte bleiben nach App-Neustart erhalten
- Gegeben: Meditation mit gesetzten Trim-Werten (in Phase C über den Editor gesetzt; hier per Test/Fixture)
  Wenn: App neu gestartet wird
  Dann: die Werte werden korrekt deserialisiert.

## Reihenfolge der Akzeptanzkriterien (TDD)

1. **Domain `GuidedMeditation`** — Felder + `effectiveStartMs`/`effectiveEndMs`/`effectiveDurationMs` + `formattedDuration`(effektiv)/`formattedFileDuration`. Reine Domain-Tests zuerst.
2. **Persistenz-Backward-Compat** — Test: alter JSON ohne Trim-Keys decodiert zu `null`-Feldern; Round-Trip mit gesetzten Werten.
3. **`AudioPlayerService`: Seek-to-Start** — nach `onPrepared` auf `trimStartMs` seeken (Mock-`MediaPlayerProtocol` verifiziert `seekTo`).
4. **`AudioPlayerService`: End-Boundary** — Progress-Tick ≥ `effectiveEndMs` löst Completion-Pfad aus.
5. **Klemmung Skip/Seek** — Player-ViewModel und `MediaSessionManager` klemmen auf den Bereich.
6. **Bereichs-relative Anzeige** — Position/Dauer relativ in Player + Lock Screen.
7. **Library-Dauer** — `formattedDuration` zeigt effektiv (visuell + Test).

## Risiken

| Risiko | Mitigation |
|--------|------------|
| Progress-Polling-Präzision am Endpunkt (~500 ms Überschuss) | Für Meditations-Ende akzeptabel; Tick nahe Ende ggf. verdichten; Fallback `ClippingMediaSource` dokumentiert |
| Progress-Loop feuert bei gesperrtem Screen nicht zuverlässig | Verifizieren, dass `ProgressScheduler` im `MeditationPlayerForegroundService`-Kontext weiterläuft (er treibt schon heute die Lock-Screen-Position); manueller Lock-Screen-Test |
| `seekTo` vor `prepare` / im falschen Player-State → IllegalStateException | Seek strikt im `onPreparedListener` (Player ist dann prepared); bestehende State-Guards nutzen |
| Phase A ohne UI wirkt „unfertig" im Review | Im Plan explizit als Substrat markiert; user-sichtbares Feature entsteht mit Phase C |
| Cross-Platform-Divergenz bei der Anzeige-Semantik | `effectiveDuration` exakt wie iOS (`max(end − start, 0)`); bereichs-relative Position wie iOS |

## Offene Fragen

- Keine blockierenden. Die Präzisions-Entscheidung (Polling vs. `ClippingMediaSource`) wird nach dem ersten Lock-Screen-Test bestätigt — Default ist Polling (Minimal-Change).
