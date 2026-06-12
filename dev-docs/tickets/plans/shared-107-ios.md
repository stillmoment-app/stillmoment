# Plan shared-107 (iOS): Waveform-Trim-Editor

Massgebliche Design-Referenz: `handoffs/design_handoff_trim_waveform/README.md`
(Masse, Layout, Interaktionen). Farben/Typografie werden auf das bestehende
Theme-/Token-System gemappt, NICHT die Handoff-Hexwerte uebernommen.

## Architektur-Entscheidungen

1. **`MeditationWaveform` (Domain, pure Swift):** `samples: [Float]` (220 Werte,
   normalisiert auf [0, 1]), Codable. Konstante `MeditationWaveform.barCount = 220`.
   Dazu `WaveformAccumulator` (Domain): nimmt PCM-Chunks als `[Float]` entgegen,
   verteilt sie auf Buckets (Peak = max. Absolutwert), `finalize()` normalisiert.
   Komplett ohne AVFoundation → unit-testbar mit synthetischen Samples.

2. **`WaveformGenerationService` (Infrastructure):** Protokoll
   `WaveformGenerating` im Domain-Layer (`generateWaveform(for fileURL: URL) async
   throws -> MeditationWaveform`). Implementierung liest die Datei mit
   `AVAudioFile` **chunkweise** (z.B. 1s-Bloecke) in einen PCM-Buffer und fuettert
   den `WaveformAccumulator` — niemals die ganze Datei in den Speicher
   (1h Audio dekodiert waeren ~600 MB). Laeuft off-main (async, eigener
   Task-Kontext). `Task.checkCancellation()` zwischen Chunks.

3. **`WaveformCacheService` (Infrastructure):** JSON-Datei pro Meditation unter
   Application Support/`Waveforms/{meditationID}.json`. API: `load(id)`,
   `save(id, waveform)`, `delete(id)`. Beim Loeschen einer Meditation wird der
   Cache-Eintrag mitgeloescht (GuidedMeditationService.delete-Pfad).

4. **`WaveformProvider` (Infrastructure, orchestriert):**
   `waveform(for meditation) async throws -> MeditationWaveform` — Cache-Hit →
   sofort; sonst generieren + cachen. **In-flight-Dedupe** pro Meditation-ID
   (Import-Task und Editor-Oeffnung duerfen nicht doppelt rechnen).
   - **Import-Hook:** Nach erfolgreichem `addMeditation` feuert ein
     fire-and-forget `Task` die Vorberechnung an (Import bleibt sofort fertig).
   - **Lazy-Fallback (Versions-Upgrade):** Editor fragt den Provider; fehlt der
     Cache, wird jetzt gerechnet — Editor zeigt Ladezustand.
   - Fehlerfall (DRM/exotisches Format): Provider wirft; Editor faellt auf
     schlichte Linie zurueck (Funktion bleibt erhalten), kein Re-Try-Loop.
   - ACHTUNG bekannter Fallstrick: neue Dependencies auch in convenience
     `init()`s verdrahten (Praezedenzfall shared-065).

5. **`TrimEditorState` (Domain, immutable):** `start`, `end`, `duration`,
   `activePoint (.start/.end)`. Pure Funktionen, geben neue Instanz zurueck:
   - `selecting(_ point)`, `moving(_ point, to:)` mit Clamping auf
     `[0, duration]` und **Mindestabstand 25 s**
   - `nudging(by: ±1)` auf den aktiven Punkt
   - `usingWholeFile()` → `{0, duration}`
   - `trimResult: (start, end)?` → `nil` wenn `start <= 1 && end >= duration − 1`
   - Initialisierung aus `GuidedMeditation` (`effectiveStart`/`effectiveEnd`).
   Playhead/`playing`/`previewing` sind UI-State im View/ViewModel, nicht Domain.

6. **EditSheetState schrumpft:** `editedTrimStartText`/`editedTrimEndText`,
   `parseTime`-Validierungspfade und die Trim-Textfeld-Logik entfallen.
   Stattdessen haelt das Edit-Sheet `editedTrimStart`/`editedTrimEnd` als
   `TimeInterval?` (vom Editor committet). `formatTime` bleibt (Anzeige).
   Bestehende `EditSheetStateTrimTests` werden auf das neue Verhalten umgebaut.

7. **UI-Komponenten (Presentation):**
   - `PlaybackRangeCard` — Formular-Zeile im Edit-Sheet (ersetzt die
     Trim-Section): ungetrimmt ("Ganze Datei · 19:05" / "Bereich waehlen") vs.
     getrimmt (Mini-Wellenform 44 pt + Zeitraum + "Zuschnitt entfernen").
   - `TrimEditorSheet` — Vollbild-Editor als `.sheet` mit
     `.presentationDetents([.large])` + ThemeRootView (Pattern ContentGuideSheet;
     Sheets erben kein Environment in iOS 16.0–16.3 → explizit setzen).
   - `WaveformView` — gemeinsamer Canvas-Renderer (Balken, Bereichs-Highlight,
     Playhead); Parameter `interactive: Bool` fuer Mini-Variante.
   - Griffe: `DragGesture` auf 44-pt-Hit-Areas, Zeit-Blase ueber dem aktiven
     Griff, Puls-Animation nur fuer den aktiven Griff (aus bei Drag und bei
     Reduced Motion, `@Environment(\.accessibilityReduceMotion)`).
   - Dateien klein halten (SwiftLint file_length 400/500) — Editor von
     vornherein in Subviews aufteilen (`TrimEditorSheet`, `WaveformView`,
     `TrimHandle`, `TrimTransportRow`, `TrimReadoutCards`).

8. **Vorhoeren:** ueber die bestehende Preview-Infrastruktur (shared-098,
   `AudioService+MeditationPreview`, `.preview`-Session), gereicht als Closures
   vom List-View (Pattern wie bisheriges `onPreviewFrom`). Playhead speist sich
   aus `previewCurrentTime` des ViewModels.
   - Durchgehend (Play-Button): `playMeditationPreview` + seek auf aktiven
     Punkt; Icon ▶/⏸ folgt NUR diesem Zustand.
   - Kurz-Vorschau (Drag-Ende: 2.6 s, Nudge: 1.5 s): gleicher Start, aber
     zeitgesteuerter Stop (Task + sleep, bei neuer Vorschau gecancelt);
     veraendert das Play-Icon nicht (`previewing`-Flag getrennt von `playing`).

9. **Typografie-Mapping (nur bestehende Tokens):** grosser Readout →
   `DisplayNumeral`/`.display`; "BEGINNT BEI"/Karten-Labels → `.eyebrow`;
   Karten-Werte → `.title`; Track-Titel → `.section`; Zeit-Blase/Nudges →
   `.body`; Captions/Achsen → `.micro`/`.caption`. Alle Zeitwerte
   `monospacedDigits` (tnum-Aequivalent des Token-Systems).

10. **Farb-Mapping (semantische Rollen):** Akzent-Balken/Griffe/Play-Button →
    `interactive`/Akzent-Rollen des Themes; Balken ausserhalb → abgesenkte
    Textfarbe; Bereichs-Highlight → `accentBackground`-artige Rolle; Karten →
    `cardBackground`. Konkrete Rollen beim Implementieren aus ThemeColors
    waehlen, keine neuen Hexwerte.

## Reihenfolge (TDD pro Schritt, Slices = Subagent-Auftraege)

- **A — Waveform-Fundament:** `MeditationWaveform` + `WaveformAccumulator`
  (Tests: Bucket-Verteilung, Peak, Normalisierung, Randfaelle leere/kurze
  Datei) → `WaveformCacheService` (Tests: save/load/delete-Roundtrip) →
  `WaveformGenerationService` (AVAudioFile-Teil; Logik steckt im Accumulator,
  Integration mit Test-Fixture-Audio wenn vorhanden, sonst manuell).
- **B — Provider + Hooks:** `WaveformProvider` (Tests mit Mock-Generator/-Cache:
  Cache-Hit, Miss→generate+save, in-flight-Dedupe, Fehler-Propagation),
  Import-Hook in `GuidedMeditationService`/ViewModel, Delete-Hook,
  convenience-init-Verdrahtung.
- **C — Editor-State:** `TrimEditorState` (Tests: Clamping, Mindestabstand,
  Nudge, whole-file→nil, Init aus Meditation) + `EditSheetState`-Umbau
  (bestehende Trim-Tests anpassen).
- **D — UI:** `PlaybackRangeCard` + `TrimEditorSheet` + `WaveformView` +
  Verdrahtung im Edit-Sheet/List-View, Lokalisierung (DE/EN), Accessibility
  (adjustable-Trait fuer Griffe, Labels fuer Transport), Reduced Motion.
- **Quality Gate:** `make check`, `make test-unit-agent`, Review, visuelle
  Verifikation gegen Handoff-Screenshots im Simulator.

## Risiken

- **Speicher beim Decode:** chunkweises Lesen ist Pflicht (1h ≈ 600 MB PCM).
- **Doppelberechnung** Import-Task vs. Editor-Oeffnung → in-flight-Dedupe im
  Provider.
- **Abbruch:** Editor schliessen waehrend Berechnung → Task-Cancellation,
  kein Zombie-Decode.
- **mm:ss-Felder entfallen:** UI-Tests/Screenshots, die auf die Textfelder
  referenzieren, brechen — mit anpassen.
- **Gesten vs. Sheet-Drag:** DragGesture auf den Griffen darf das
  Sheet-Dismiss-Gesture nicht ausloesen (highPriorityGesture pruefen).

## Nicht in Scope

- Zoom in der Wellenform
- Automatische Kanten-Erkennung
- Android (separater Durchlauf, setzt shared-105-Android voraus)

## Nachbesserung: touch-robuste Punkt-Bedienung (2. Handoff)

Quelle: `handoffs/design_handoff_trim_editor/` — die erste Umsetzung hatte drei
konkurrierende Drag-Elemente (Playhead-Scrub auf der Spur + 2 Handle-Gesten),
die sich auf der schmalen Timeline ins Gehege kamen. Umgesetzt am 2026-06-12:

- **Rein geometrisches Hit-Testing** (`TrimHitTesting`, pure + unit-getestet):
  EIN `DragGesture` auf der ganzen Spur entscheidet am Finger-Down aus x/y,
  was gezogen wird. Griffe sind rein visuell (`allowsHitTesting(false)`),
  A11y-Elemente (adjustable) bleiben erhalten.
- **Vertikale Zonen:** Playhead-Lane (34 pt, `TrimPlayheadLane`) + obere 45 %
  der Wellenform (`SPLIT = 0.45`) → Abspielposition; untere Zone → Marken.
  `GRAB = 22 pt`: nah am Griff = relativer Griff (offset, kein Sprung), freie
  Flaeche = aktive Marke springt zum Finger. Cluster (beide in Reichweite):
  die AKTIVE Marke gewinnt immer.
- **Playhead eigenstaendig + Sage:** neue Theme-Tokens `playheadAccent`/
  `playheadAccentHi` (bewusst andere Farbfamilie als Kupfer-Marken).
  `playheadTime` im ViewModel non-optional (Seed = Startpunkt). `seek()`
  pausiert laufende Wiedergabe zuerst (Handoff-Regel).
- **Auto-Vorschau:** Marken-Release 2,2 s / Nudge 1,4 s (`TrimPreviewDurations`,
  injectable fuer Tests); Karte tippen setzt aktiv + Playhead auf die Marke.
  "Set Mark auf aktuelle Position"-Button entfaellt (Scrub&Set-Modell ersetzt),
  stattdessen Hinweistext (`trim_editor.hint`).
- Visuell: Marken = Schnittkante volle Hoehe + Griff-Knopf bei 74 % (untere
  Zone), Sage-Greifer mit Spitze in der Lane, Zonen-Tint + Hairline bei 45 %.

Verifiziert: `make check` gruen, 1158 Unit-Tests gruen, Simulator-Durchlauf
(Marken-Drag untere Zone, Playhead-Drag Lane, Karten-Tap, Zuruecknavigation).

## Nachtrag: Waveform-Aufloesung 2200 statt 220 (Vorgriff auf shared-108)

Entschieden am 2026-06-12, bevor shared-107 released ist — so entstehen nie
Bestands-Caches in niedriger Aufloesung:

- `MeditationWaveform.barCount` (220) → `sampleCount` (2200). Der Cache traegt
  jetzt 10x mehr Peaks (~20 KB JSON), genug fuer echten Detail-Zoom in
  shared-108. Decode-Aufwand unveraendert (derselbe Durchlauf, mehr Buckets).
- Neu: `MeditationWaveform.downsampled(to:)` (Domain, pure, peak-erhaltend via
  Bucket-Maximum) — die Uebersicht (`TrimWaveformView`, `displayBarCount = 220`)
  rendert downgesampelt, optisch unveraendert.
- `WaveformProvider` behandelt Cache-Eintraege mit abweichender Aufloesung als
  Miss (Regeneration beim ersten Zugriff) — schuetzt Dev-Geraete/TestFlight.

Verifiziert: `make check` gruen, 1163 Unit-Tests gruen.
