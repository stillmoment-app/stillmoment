# Implementierungsplan: Android-Parität Phase C — Wellenform-Infrastruktur + Trim-Editor

Tickets: [shared-107](../shared/shared-107-waveform-trim-editor.md) + [shared-108](../shared/shared-108-waveform-zoom-trim-editor.md) + [shared-112](../shared/shared-112-trim-zurueck-dirtied-editor.md) (kollabiert)
Erstellt: 2026-06-16
Kontext: Drittes von vier Paketen der Android-Parität. **Das schwere Paket** — und das einzige echte Neuland, weil Android die Audio-Dekodierung zur Wellenform selbst machen muss. Hängt an [Phase A](android-parity-phase-a-trim-foundation.md) (Trim-Modell + getrimmtes Playback). iOS hat den Editor in shared-107 gebaut, in shared-108 um Zoom erweitert und in shared-112 die Save-Semantik geändert — Android baut direkt den Endzustand (Zoom + finale Save-Semantik von Anfang an).

## Ziel

Die Wellenform-Karte „Wiedergabe-Bereich" im Editor (ersetzt die in Phase A bewusst weggelassenen mm:ss-Felder) plus den Vollbild-Trim-Editor: echte Wellenform der Aufnahme, zwei ziehbare Marken (Anfang/Ende), eigener Abspiel-Playhead, Vorschau beim Loslassen, Zoom auf eine Marke mit Minimap, und die finale Save-Semantik (nur „Zurück", das den äußeren Editor als verändert markiert — kein eigenes Speichern/Verwerfen).

**Mit Phase C wird das shared-105-Feature user-sichtbar abgeschlossen.**

## ⚠️ Voranzustellender Spike: PCM-Dekodierung auf Android

iOS bekommt Samples geschenkt (`AVAudioFile` → `AVAudioPCMBuffer`). Android hat **kein** Pendant: komprimiertes Audio (MP3/M4A hinter einem Content-URI) muss über `MediaExtractor` + `MediaCodec` manuell zu PCM dekodiert werden. **Vor** der Detailplanung der Generierung einen kurzen Spike (separates, wegwerfbares Branch):

- `MediaExtractor.setDataSource(contentResolver.openFileDescriptor(uri))` → Audio-Track selektieren
- `MediaCodec` (Decoder) im Async-/Sync-Loop: Input-Buffer füttern, Output-PCM (`ByteBuffer`, 16-bit signed) lesen
- Peak-Bucketing über den Stream (nie ganze Datei in Memory — eine Stunde PCM ≈ hunderte MB)
- Messen: Dauer für eine 60-Min-Datei, Speicher-Peak, Korrektheit gegen eine bekannte Datei

Ergebnis des Spikes bestimmt, ob die unten skizzierte Architektur 1:1 trägt oder angepasst werden muss. Erst danach Phase C final planen/umsetzen.

## Annahmen

- **Architektur spiegelt iOS' Waveform-Stack**, mit Android-Decoder statt AVFoundation:
  - `WaveformGenerationService` (chunk-weise Dekodierung über `MediaCodec`)
  - `WaveformAccumulator` (Domain, bucket-weises Peak-Tracking, finale Normalisierung gegen Global-Max)
  - `AudioFrameReader`-Seam (Protokoll über den Decoder → Fake-Reader im Test)
  - `WaveformCacheService` (JSON pro Meditation, invalidiert nur bei geänderter `sampleCount`)
  - `WaveformProvider` (Request-Dedup für gleiche Meditation, `precompute` fire-and-forget nach Import)
- **`MeditationWaveform`** (Domain): `samples: List<Float>` fester Länge (iOS: 2200); `downsampled(to)` für Display-Bars (iOS: 220), `windowed(from, to)` für Zoom.
- **Wellenform wird beim Import im Hintergrund vorberechnet und gecacht** — Import bleibt schnell. Bestands-Meditationen ohne Cache berechnen beim ersten Öffnen einmalig (Ladezustand). Dekodier-Fehler → schlichte Linie statt Balken, Funktion bleibt erhalten.
- **Zoom ist reiner Fenster-State** (`ClosedRange<Long>` in ms), kein Neu-Dekodieren — nur `windowed()` auf den vorhandenen Samples.
- **Finale Save-Semantik (shared-112):** der Trim-Editor hat nur „Zurück". „Zurück" übernimmt die Auswahl in den äußeren Editor (`EditSheetState`) und markiert ihn als verändert; gespeichert/verworfen wird ausschließlich über den äußeren Editor (Phase A/Phase B `EditSheetState` + Discard-Dialog aus shared-110). „Ganze Datei verwenden" setzt den Schnitt im Editor zurück.
- **Mindestabstand 25 s** zwischen Anfang und Ende (wie iOS `TrimEditorState.minimumRange`).
- **Vollbild, kein BottomSheet** — wegen der Zoom-/Drag-Gesten. State-basiertes Vollbild-Overlay analog zum Meditation-Editor (shared-110-Muster).

## Betroffene Codestellen (nach Spike zu verfeinern)

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `domain/models/MeditationWaveform.kt` | Domain | **Neu** | Samples + `downsampled`/`windowed` |
| `domain/models/WaveformAccumulator.kt` | Domain | **Neu** | Bucket-Peak-Builder + Normalisierung |
| `domain/models/TrimEditorState.kt` | Domain | **Neu** | `start`/`end`/`duration`/`activePoint`/`minimumRange`; `resultTrimStart/End` (null am Rand); immutable |
| `domain/models/TrimZoomWindow.kt` | Domain | **Neu** | Reine Fenster-Berechnung (18 % der Dauer, min 120 s) |
| `domain/services/AudioFrameReader.kt` | Domain | **Neu** | Decoder-Seam (Protokoll) |
| `infrastructure/audio/WaveformGenerationService.kt` | Infra | **Neu** | `MediaExtractor`/`MediaCodec`-Dekodierung, chunk-weise |
| `infrastructure/audio/WaveformCacheService.kt` | Infra | **Neu** | JSON-Cache (App-internes Verzeichnis) |
| `infrastructure/audio/WaveformProvider.kt` | Infra | **Neu** | Dedup + `precompute` |
| `infrastructure/di/AppModule.kt` | Infra | Erweitern | Bindings für die neuen Services |
| `data/FileOpenHandler.kt` (Import) | Data | Erweitern | `precompute` nach erfolgreichem Import anstoßen |
| `presentation/viewmodel/TrimEditorViewModel.kt` | ViewModel | **Neu** | `editorState`, `waveform`, `window`, `isPlaying/isPreviewing`, `playheadTime`; Intents `selectPoint/movePoint/markDragEnded/nudge/useWholeFile/focusPoint/zoomOut/panWindow/seek/togglePlayback` |
| `presentation/ui/meditations/trimeditor/TrimWaveformView.kt` | UI | **Neu** | Canvas: Bars je nach Bereich gefärbt, Playhead, Fehler-Fallback-Linie |
| `presentation/ui/meditations/trimeditor/TrimMinimap.kt` | UI | **Neu** | Gesamtstreifen mit Bereich/Marken/Position/Fensterrahmen |
| `presentation/ui/meditations/trimeditor/TrimMarkHandle.kt` | UI | **Neu** | Ziehbare Anfang/Ende-Marke (untere Hälfte) |
| `presentation/ui/meditations/trimeditor/TrimPlayheadGrabber.kt` | UI | **Neu** | Ziehbarer Playhead (obere Hälfte) |
| `presentation/ui/meditations/trimeditor/TrimEditorScreen.kt` | UI | **Neu** | Vollbild-Editor: Readout, Anfang/Ende-Karten, Zoom-Controls, Play/Pause, „Zurück", „Ganze Datei" |
| `presentation/ui/meditations/components/PlaybackRangeCard.kt` | UI | **Neu** | Karte im Editor: ungetrimmt „Ganze Datei · {Dauer}", getrimmt Mini-Wellenform + Zeitraum + „Zuschnitt entfernen" |
| `presentation/ui/meditations/MeditationEditSheet.kt` | UI | Erweitern | `PlaybackRangeCard` unter Abschnitt „Wiedergabebereich" (Section-Titel kommt aus Phase B) |
| `infrastructure/audio/AudioService.kt` | Infra | Erweitern | Trim-Editor-Vorschau über den bestehenden `meditationPreview`-Pfad (Position-Flow nutzen) |
| `test/.../*` | Tests | **Neu** | Accumulator, `MeditationWaveform`, `TrimEditorState`, `TrimZoomWindow`, Provider-Dedup, Cache-Roundtrip, ViewModel-Intents — alles mit Fake-Reader, ohne echtes Audio |

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `MediaExtractor` + `MediaCodec` | API 16 / robust ab 21 | Android Docs | PCM-Dekodierung; minSdk 26 unkritisch. Async-Callback-API ab API 23 |
| `MediaCodec` PCM 16-bit | - | Android Docs | Output `ByteBuffer` → `ShortBuffer`; Peak je Bucket |
| `Canvas`/`drawIntoCanvas` (Compose) | - | Compose Docs | Bar-Rendering wie iOS `Canvas`; Vorbild: bestehende `GongWaveform.kt` |
| `pointerInput`/`detectDragGestures` | - | Compose Docs | Marken-/Playhead-Drag; Vorbild: `BreathDial`-Drag |
| `seekTo(ms, SEEK_CLOSEST)` | API 26 | Android Docs | Framegenaue Vorschau-Seeks |

## Design-Entscheidungen

### 1. iOS-Waveform-Stack spiegeln, Decoder austauschen
Die Domain-Teile (`MeditationWaveform`, `WaveformAccumulator`, `TrimEditorState`, `TrimZoomWindow`) sind reine Logik und 1:1 aus iOS portierbar — gut testbar ohne Audio. Nur `WaveformGenerationService` ist plattformspezifisch (MediaCodec). Der `AudioFrameReader`-Seam hält den Decoder aus den Tests.

### 2. Display-Bars und Sample-Count exakt wie iOS
`sampleCount` und Display-Bar-Zahl von iOS übernehmen (2200 / 220), damit beide Plattformen dieselbe Wellenform-Auflösung zeigen (Cross-Platform-Konsistenz).

### 3. Drei ziehbare Punkte auf einer Timeline — Zonen-Trennung
Playhead-Griff in der oberen Hälfte (Salbeigrün), Anfang/Ende-Marken in der unteren Hälfte (Kupfer). Liegen Anfang/Ende übereinander, greift die per Karte aktive Marke — exakt wie iOS, damit sich die Punkte auf der schmalen Timeline nie in die Quere kommen.

### 4. Finale Save-Semantik direkt (shared-112)
Kein eigenes „Fertig"/„Verwerfen" im Trim-Editor. „Zurück" schreibt `resultTrimStart/End` in den `EditSheetState` des äußeren Editors und markiert ihn dirty; Speichern/Verwerfen passiert dort. Vermeidet den stillen Datenverlust, den iOS in shared-112 nachträglich beheben musste.

## Fachliche Szenarien (Akzeptanzkriterien)

### AK: Karte im Editor zeigt den Bereich
- Ungetrimmt: „Ganze Datei · {Dauer}" + „Bereich wählen"-Hinweis. Getrimmt: Mini-Wellenform mit hervorgehobenem Bereich, Zeitraum, „Zuschnitt entfernen".

### AK: Trim-Editor zeigt die echte Wellenform
- Sprach-dichte Blöcke heben sich sichtbar von stillen Passagen ab; ein Griff lässt sich an die Kante ziehen.

### AK: Vorschau beim Loslassen
- Beim Anfang: die ersten Sekunden ab der Marke. Beim Ende: die letzten Sekunden bis zur Marke. Nie den abgeschnittenen Teil.

### AK: Zoom auf eine Marke
- Tipp auf „Anfang"/„Ende" zoomt auf ~18 % der Dauer (min 2 min) um die Marke; echte Detail-Balken; Minimap zeigt Ausschnitt; „Ganze Datei" zoomt zurück, ohne Marken zu ändern.

### AK: Marke außerhalb des Fensters
- Chip am näheren Rand (z. B. „Ende 19:05 ›") springt dorthin.

### AK: Mindestabstand
- Anfang/Ende behalten ≥ 25 s Abstand.

### AK: „Zurück" übernimmt, markiert dirty, speichert nicht
- „Zurück" überträgt die Auswahl in den Editor und markiert ihn verändert; erst der äußere Editor speichert/verwirft. Ist der Bereich praktisch die ganze Datei, wird kein Zuschnitt gespeichert.

### AK: Kurze Dateien (≤ 2 min)
- Kein Zoom; Editor funktioniert ohne Zoom-Schritt.

### AK: Dekodierung schlägt fehl
- Statt Balken eine schlichte Linie; Trimmen per Karten/Nudge bleibt möglich.

## Reihenfolge der Akzeptanzkriterien (TDD)

0. **Spike** (s. o.) — Dekodierung verifizieren, dann Architektur fixieren.
1. **Domain** — `MeditationWaveform`, `WaveformAccumulator`, `TrimEditorState`, `TrimZoomWindow` (reine Logik, Fake-Reader).
2. **Generierung + Cache + Provider** — mit Fake-Reader; Cache-Roundtrip; Dedup.
3. **Import-Precompute** — `precompute` nach Import, Import bleibt schnell.
4. **TrimEditorViewModel** — Intents, Vorschau-Anbindung, Zoom-State.
5. **UI: Wellenform/Marken/Playhead/Minimap** — Canvas + Gesten.
6. **PlaybackRangeCard + Editor-Einbindung** — ersetzt die (nie gebauten) mm:ss-Felder.
7. **Save-Semantik** — „Zurück" dirtied äußeren Editor; Roundtrip mit Phase-A-Persistenz.

## Risiken

| Risiko | Mitigation |
|--------|------------|
| MediaCodec-Dekodierung komplexer/langsamer als erwartet | Vorgeschalteter Spike; falls zu langsam: gröberes Bucketing / Hintergrund mit Ladezustand |
| Speicher bei langen Dateien | Streaming-Bucketing, nie ganze PCM-Datei halten (wie iOS Chunking) |
| Content-URI-Zugriff für Decoder (SAF-Permissions) | `openFileDescriptor` wie im bestehenden Playback-Pfad; Fehler → Fallback-Linie |
| Drei-Punkte-Drag-Konflikte auf schmaler Timeline | Zonen-Trennung + karten-aktive Marke (Design 3); XCUITest/manueller Geste-Test |
| Cross-Platform-Wellenform-Divergenz | `sampleCount`/Bar-Zahl/Normalisierung exakt von iOS; visueller Side-by-Side-Vergleich |
| Umfang des Pakets | Spike + klare TDD-Reihenfolge; ggf. Generierung (1–4) und Editor-UI (5–7) in zwei Merges |

## Offene Fragen

- Spike-Ergebnis offen: bestätigt oder korrigiert die Decoder-Architektur.
- Cache-Speicherort (App-internes `filesDir/waveforms/`) bestätigen — analog zu iOS `Application Support/Waveforms/`.
