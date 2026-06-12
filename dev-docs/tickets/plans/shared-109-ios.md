# Implementierungsplan: shared-109 (iOS)

Ticket: [shared-109](../shared/shared-109-waveform-player-tonkopf.md)
Erstellt: 2026-06-12
Plattform: iOS (Android folgt mit dieser Implementierung als Referenz)

---

## Ziel in einem Satz

Die Playing-Phase des Guided-Players zeigt statt des Atemkreises ein an einer mittigen Salbei-Jetzt-Linie vorbeiscrollendes Waveform-Fenster (±30 s), das per Drag gespult wird; Pre-Roll und Gongs bleiben unangetastet.

---

## Annahmen

- **Playhead-Farbe = Salbei** (`playheadAccent`/`playheadAccentHi`), nicht das Kupfer-Glow des Handoffs. Begruendung: App-Konvention reserviert Salbei fuer Playheads (Trim-Editor), und die vergangene Welle ist bereits kupfern — Salbei hebt die Jetzt-Linie klar ab. (Vom User bestaetigt.)
- **Vergangene Welle = `interactive` (Kupfer), kommende Welle = `textPrimary` blass (~0.16 Alpha)** — direkte Uebersetzung der Handoff-Tokens `--sm-accent` / `--sm-text` auf das semantische Layer.
- **Fortschritts-Variante = `mini`**, antippbar/ziehbar als absolutes Seek (Ticket-Entscheidung). `bar`/`keiner` entfallen.
- **`windowSec = 60` (±30 s sichtbar)**, `edgeFade` an, Drag-Hint und Breath-Hint an — Handoff-Defaults uebernommen, auf Geraet gegenzuchecken.
- **Waveform wird wie im Trim-Editor ueber `WaveformProviderProtocol.waveform(for:)` geladen** (Cache-Hit sofort, sonst Generierung). Kein neues Speicherformat, kein Feld an `GuidedMeditation`.
- **Restzeit/Position relativ zum Trim**: Die Zeitlogik nutzt durchgehend `effectiveStart`/`effectiveEnd`/`effectiveDuration` — wie der bestehende Player schon. „Gesamtlaenge" beim Drag = `effectiveDuration`.
- **Bestehender Pre-Roll-/Gong-/Completion-/Zen-Flow bleibt unveraendert.** Nur `playerContent` (Playing-Phase) wird ausgetauscht. `preRoll` rendert weiter den Atemkreis-Countdown (`PlayerRingView` + `DisplayNumeral`).
- **Atemkreis-Komponenten der Playing-Phase werden entfernt**, sobald sie nicht mehr referenziert sind: `PlayerCenterDisc`, `GlassPauseButton`. `PlayerRingView` bleibt (Pre-Roll-Countdown nutzt ihn weiter). `DisplayNumeral`, `MeditationCompletionView`, `DankeLotusMandala` bleiben (anderweitig genutzt).

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift` | Presentation | Refactoring | Playing-Phase: Atemkreis → Waveform-Komposition (Titel/Close/Completion-Rahmen bleiben). |
| `Presentation/Views/GuidedMeditations/Player/WaveformWindowView.swift` | Presentation | Neu | Canvas-„Tonkopf": scrollendes ±30 s-Fenster, Jetzt-Linie, Marker, Drag-Scrub. |
| `Presentation/Views/GuidedMeditations/Player/WaveformMiniOverview.swift` | Presentation | Neu | Mini-Uebersicht der ganzen (getrimmten) Spur, Tap/Drag = absolutes Seek. |
| `Presentation/Views/GuidedMeditations/Player/PlayheadWindowGeometry.swift` | Presentation | Neu | Reiner Geometrie-Helper: `sec ↔ x` fuer ein um `now` zentriertes Zeitfenster (testbar, analog `TrimGeometry`). |
| `Application/ViewModels/GuidedMeditationPlayerViewModel.swift` | Application | Erweitern | Waveform laden (Provider), Scrub-Intents (`beginScrub`/`scrub(to:)`/`endScrub`), Live-Position waehrend Drag, `isDragging`, `loadFailed`-Fallback. |
| `Resources/*.lproj/Localizable.strings` (de/en) | Presentation | Erweitern | Neue Keys: Drag-Hint, „Pausiert"/„Beendet"-Restzeile, Live-Position-Format, Slider-A11y-Value, Mini-Overview-A11y. |
| `StillMomentTests/GuidedMeditationPlayerViewModelTests*.swift` | Tests | Erweitern | Scrub-/Live-Position-/Fenster-Mapping-/Fallback-Szenarien. |
| `StillMomentTests/PlayheadWindowGeometryTests.swift` | Tests | Neu | Reine Geometrie-Unit-Tests (sec↔x, Clamping, Trim-Fenster). |

Zu loeschen, sobald referenzfrei (Grep bestaetigt: nur im Player verwendet): `PlayerCenterDisc`, `GlassPauseButton` (+ ggf. deren Tests/Previews). Vor dem Loeschen erneut per `findReferences`/Grep absichern.

---

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `Canvas`/`GraphicsContext` | iOS 15+ | Apple Docs | Wird im Trim-Editor bereits genutzt; Balken via `context.fill(Path(roundedRect:))`. |
| `TimelineView(.animation(paused:))` | iOS 15+ | Apple Docs | Treibt das kontinuierliche Scrollen zwischen den 0,5-s-Player-Ticks; pausieren bei `scenePhase != .active` und bei Reduce Motion (Pattern aus `ConstellationLoader`). |
| `DragGesture(minimumDistance: 0)` | iOS 13+ | Apple Docs | Scrub auf dem Fenster; `minimumDistance: 0` laesst auch Tap auf die Mini-Overview zu. |
| `@Environment(\.accessibilityReduceMotion)` | iOS 15+ | Apple Docs | Pattern in `TrimMarkHandle`/`TimerView` etabliert: Puls aus, Scroll ggf. ruckweise. |
| `.accessibilityRepresentation` / `.accessibilityValue` + adjustable | iOS 15+ | Apple Docs | Scrub als Slider exponieren (Welle selbst bleibt `accessibilityHidden`). |

**Quelle der Wahrheit fuer `now`:** weiterhin `playerService.currentTime` (Combine, 0,5-s-Periode). `TimelineView` interpoliert nur visuell zwischen Ticks (sauberes Recovery nach Hintergrund/Suspend bleibt erhalten — kein eigener Frame-Counter als Wahrheit).

---

## Design-Entscheidungen

### 1. Playhead in Salbei statt Kupfer-Glow
**Trade-off:** Handoff-Pixeltreue (Kupfer) vs. App-Konvention + Lesbarkeit (Salbei). Die vergangene Welle ist kupfern; ein kupferner Playhead verschmilzt mit ihr.
**Entscheidung:** Salbei (`playheadAccent`/`playheadAccentHi`), konsistent mit Trim-Editor. Dreieck-Marker + Puls-Punkt ebenfalls Salbei.

### 2. Neuer Geometrie-Helper statt TrimGeometry-Erweiterung
**Trade-off:** `TrimGeometry` kennt nur ein statisches `[0, duration]`- bzw. festes Zoom-Fenster. Der Player braucht ein um `now` *gleitendes* Fenster mit fixer Mitte.
**Entscheidung:** Eigener `PlayheadWindowGeometry` (rein, statische Funktionen, ohne State) — testbar, kein Vermischen zweier Mappings. `TrimGeometry` bleibt unberuehrt.

### 3. Scrub-Logik im ViewModel, nicht in der View
**Trade-off:** Drag-State (`startNow`, `wasPlaying`) koennte lokal in der View leben.
**Entscheidung:** ViewModel haelt `isDragging` + Scrub-Intents (`beginScrub`/`scrub(to:)`/`endScrub`). Begruendung: testbar (Pause-bei-Greifen, Resume-bei-Loslassen, Clamping auf Trim) und konsistent mit dem bestehenden `seek(to:)`. Die View liefert nur die Translation.

### 4. Pre-Roll behaelt den Atemkreis
**Trade-off:** Einheitliche Waveform-Optik auch im Countdown vs. minimaler Eingriff.
**Entscheidung:** Nur die Playing-Phase wechselt zur Welle; `preRoll` bleibt der bestehende Atemkreis-Countdown (Ticket: „Flow unveraendert"). Vermeidet Risiko an der Gong-/Transition-Sequenz.

---

## Fachliche Szenarien

### AK-1: Wiedergabe zeigt scrollende Welle
- Gegeben: Eine Meditation spielt bei 5:00 von 26:00.
  Wenn: die Wiedergabe laeuft.
  Dann: die Welle scrollt nach links an der mittigen Jetzt-Linie vorbei; links der Linie ist die Welle kupfern (Vergangenes), rechts blass (Kommendes).

### AK-2: Greifen pausiert, Loslassen setzt fort
- Gegeben: Wiedergabe laeuft.
  Wenn: der Nutzer die Welle greift.
  Dann: die Wiedergabe pausiert, der Puls stoppt, die Mitte zeigt die Live-Position `mm:ss / gesamt`.
- Gegeben: gegriffen, Wiedergabe lief vorher.
  Wenn: losgelassen (innerhalb der Spur).
  Dann: Wiedergabe laeuft ab der neuen Position weiter.
- Gegeben: Wiedergabe war **vor** dem Greifen pausiert.
  Wenn: losgelassen.
  Dann: bleibt pausiert (nur die Position hat sich geaendert).

### AK-3: Ziehrichtung
- Gegeben: Welle gegriffen bei 13:30.
  Wenn: nach rechts gezogen.
  Dann: die Position sinkt (zurueck); nach links ziehen erhoeht sie (vor). Geklemmt auf `[effectiveStart, effectiveEnd]`.

### AK-4: Restzeit-Zeile und Sonderzustaende
- Gegeben: laufende Wiedergabe.
  Dann: zentrale Zeile zeigt „Noch mm:ss" (Restzeit zum Trim-Ende).
- Gegeben: pausiert (nicht gegriffen).
  Dann: Zeile zeigt „Pausiert".
- Gegeben: Ende erreicht.
  Dann: Zeile zeigt „Beendet".
- Gegeben: Drag aktiv.
  Dann: Zeile wird durch die grosse Live-Position ersetzt.

### AK-5: Mini-Uebersicht = absolutes Seek
- Gegeben: Mini-Uebersicht sichtbar.
  Wenn: an Position p (0…1) getippt/gezogen.
  Dann: Position springt auf `effectiveStart + p * effectiveDuration`; gespielter Teil kupfern, Rest blass; Marker an p.

### AK-6: Trim begrenzt das Fenster
- Gegeben: Meditation mit `trimStart=2:00`, `trimEnd=20:00`.
  Wenn: der Player geoeffnet wird.
  Dann: Gesamtlaenge = 18:00, Restzeit relativ dazu; ueber 2:00/20:00 hinaus laesst sich nicht spulen; das Fenster zeigt jenseits der Grenzen keine Balken.

### AK-7: Ende und Neustart
- Gegeben: Wiedergabe erreicht `effectiveEnd`.
  Dann: Zustand `finished`, End-Gong-/Completion-Verhalten unveraendert; Tap auf Play startet ab `effectiveStart` neu (bestehende Logik).

### AK-8: Waveform-Fallback
- Gegeben: die Waveform-Generierung schlaegt fehl (z. B. exotisches Format).
  Wenn: der Player laeuft.
  Dann: statt Amplituden eine schlichte Mittellinie; Scrub, Zeiten, Mini-Uebersicht (als schlichter Balken) funktionieren voll.

### AK-9: Reduce Motion
- Gegeben: „Bewegung reduzieren" ist aktiv.
  Dann: kein Puls; das Scrollen darf ruckweise (pro Sekunde) statt kontinuierlich sein; Zahl + Position tragen die Information.

### AK-10: Accessibility
- Gegeben: VoiceOver aktiv.
  Dann: die Welle ist verborgen; der Scrub ist als anpassbarer Slider mit Zeit-Wert exponiert; Play/Pause und Close haben klare Labels; Restzeit ist sparsame Live-Region.

### AK-11: Hintergrund/Lock Screen
- Gegeben: laufende Wiedergabe, Bildschirm wird gesperrt.
  Wenn: zurueckgekehrt.
  Dann: Position stimmt (aus `currentTime` abgeleitet); Lock-Screen-Controls/Now-Playing/Keep-Alive/End-Gong unveraendert.

---

## Reihenfolge der Akzeptanzkriterien (TDD)

1. **PlayheadWindowGeometry** (rein, testbar) — Fundament fuer Rendering & Scrub. Unit-Tests zuerst (sec↔x, Clamping, Trim-Fenster). → AK-3, AK-6.
2. **ViewModel: Waveform laden + Fallback** — `waveform`/`loadFailed` via Provider-Mock. → AK-1, AK-8.
3. **ViewModel: Scrub-Intents** — `beginScrub`/`scrub(to:)`/`endScrub`, Pause/Resume/Clamping, `isDragging`, Live-Position. → AK-2, AK-3.
4. **WaveformWindowView (Canvas)** — Balken, Jetzt-Linie (Salbei), Marker, Edge-Fade; an ViewModel gebunden. → AK-1, AK-9.
5. **WaveformMiniOverview** — Rendering + absolutes Seek. → AK-5.
6. **Restzeit-/Live-Position-Zeile** + Lokalisierung (Pausiert/Beendet/Live). → AK-4.
7. **Player-View-Komposition** — Playing-Phase austauschen, Pre-Roll/Completion/Close behalten; alte Komponenten entfernen. → AK-7.
8. **Accessibility-Pass** — Slider-Repraesentation, Labels, Live-Region; Reduce-Motion verifizieren. → AK-9, AK-10.
9. **Geraete-Check** — Lock-Screen/Hintergrund + Scroll-Geschwindigkeit/`windowSec` auf echtem Geraet. → AK-11.

---

## Risiken

| Risiko | Mitigation |
|--------|------------|
| Ruckeliges Scrollen / Akku | Zeichnen im `Canvas`, nicht via Layout; nur ~120 sichtbare Balken pro Frame; `TimelineView` bei inaktiver App/Reduce Motion pausieren. |
| Scrub kollidiert mit Mini-Overview-Tap | Getrennte Gesten-Zonen; Presses auf Statusbar/Close/Mini-Overview loesen kein Fenster-Scrub aus (Handoff `data-no-scrub`). |
| Lange Dateien: erstes Oeffnen ohne Cache | `precompute(for:)` laeuft bereits beim Import; im Player Lade-/Fallback-Zustand sauber zeigen, Player bleibt bedienbar. |
| Versehentliches Entfernen genutzter Komponenten | Vor dem Loeschen `findReferences` + Grep; nur `PlayerCenterDisc`/`GlassPauseButton` entfernen, `DisplayNumeral`/`PlayerRingView`/Completion behalten. |
| Regression an Gong-/Transition-Sequenz | Playing-Phase isoliert austauschen; Pre-Roll/Gong/Transition-Code nicht anfassen; bestehende Gong-/Completion-Tests muessen gruen bleiben. |

---

## Offene Fragen

- Keine offen — Playhead-Farbe (Salbei), Fortschritts-Variante (`mini`), Player-Ersatz (komplett) und Flow (unveraendert) sind geklaert.
