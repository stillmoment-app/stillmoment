# Implementierungsplan: shared-108 (iOS)

Ticket: [shared-108](../shared/shared-108-waveform-zoom-trim-editor.md)
Erstellt: 2026-06-12

Massgebliche Design-Referenz: `handoffs/design_handoff_trim_zoom/README.md`, Abschnitt
„Praezises Zuschneiden an den Raendern" + Prototyp `reference/trim-editor.jsx`
(`frameWindow`, `panWindow`, `MiniMap`, `edgeChip`, `onScrubEnd`).

## Annahmen

Verhalten exakt nach Prototyp (dort verifiziert):

- **Karten-Tap zoomt immer** — auch aus der Uebersicht heraus (`pick()` setzt `active`, `head` und `win = frameWindow(...)` bedingungslos).
- **Recentering nur im Zoom**: Nudge und Marken-Drag-Ende rahmen das Fenster nur neu, wenn bereits gezoomt ist (`if (zoomed)`); in der Uebersicht bleibt das Fenster die ganze Datei. Playhead-Drag (Seek) recentert nie.
- **Zwei getrennte „Ganze Datei"-Aktionen**: Der neue Chip „⌕ Ganze Datei" zoomt nur heraus (`win = [0, TOTAL]`, Marken unberuehrt). Der bestehende Link „Ganze Datei verwenden" setzt weiterhin die Marken zurueck und setzt jetzt zusaetzlich das Fenster auf die ganze Datei.
- **Edge-Chip-Tap = Karten-Tap**: identische Aktion (Marke waehlen + rahmen, `onPickMark` → `pick`). Kein separater Intent noetig.
- **Kurze Dateien (Dauer ≤ 120 s)**: `frameWindow` liefert die ganze Datei — es gibt effektiv keinen Zoom; Karten-Tap wirkt wie heute (nur Auswahl + Playhead). Minimap und Chip erscheinen nie (`isZoomed` bleibt false).
- **Minimap ohne Waveform-Balken** — nur Bereichs-Fuellung, zwei Marken-Ticks, Playhead-Tick, Sage-Fensterrahmen (wie Prototyp, Hoehe 26 pt).
- **Playhead-Grabber und Marken-Griffe sind nur sichtbar, wenn ihre Zeit im Fenster liegt** (`inWin` mit 0,5 s Toleranz). Off-window Marke → Edge-Chip am naeheren Rand; off-window Playhead → Lane ohne Grabber (Linie ausgeblendet).
- **Hit-Testing mit ungeclampten x-Positionen**: Der Prototyp rechnet `pxOf` ohne Clamping — eine Marke ausserhalb des Fensters liegt dann automatisch ausserhalb des 22-pt-Grab-Radius. `TrimHitTesting` bleibt dadurch **unveraendert**; nur der Aufrufer liefert fensterbasierte, ungeclampte Positionen. (Eine knapp ausserhalb liegende Marke bleibt damit wie im Prototyp greifbar — akzeptiert.)
- **Pure Fenster-Funktionen leben in `Application/Models/TrimZoomWindow.swift`** (Praezedenz: `MeditationPhase.swift`). Der ViewModel braucht sie fuer Recentering — Presentation waere von Application aus eine Layer-Verletzung, und das Ticket haelt das Zoom-Fenster bewusst aus der Domain heraus.
- **Layout-Shift beim Zoomen akzeptiert**: Minimap und Chip-Reihe erscheinen/verschwinden mit Transition; kein Platz reserviert (beim Zoomen aendert sich das Layout ohnehin sichtbar).
- **A11y-Umsetzung**: kontextabhaengiger Hinweistext (eigene Keys), Minimap als adjustable Element (Label „Uebersicht", Value = Fensterbereich, increment/decrement = Pan um ZS/2), Edge-Chips als Buttons mit Label + Zeit, Karten-Hint erwaehnt das Heranzoomen.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Application/Models/TrimZoomWindow.swift` | Application | **Neu** | Pure Fenster-Mathematik: `zoomSpan(duration:)` (= `min(dauer, max(120, dauer·0.18))`), `frame(around:point:duration:)`, `pan(toCenter:duration:)` — alle liefern `ClosedRange<TimeInterval>` |
| `Application/ViewModels/TrimEditorViewModel.swift` | Application | Erweitern | `@Published window`, `isZoomed`, neue Intents `focusPoint(_:)` (Karte/Edge-Chip), `zoomOut()`, `panWindow(toCenter:)`; Recentering in `nudgeActivePoint`/`markDragEnded`; Fenster-Reset in `useWholeFile` |
| `Presentation/.../TrimEditor/TrimGeometry.swift` | Presentation | Erweitern | Fenster-Overloads: `x(for:window:width:)` (geclampt, fuers Rendern), `time(forX:window:width:)` (geclampt in Fenstergrenzen), `unclampedX(for:window:width:)` (fuers Hit-Testing) |
| `Presentation/.../TrimEditor/TrimHitTesting.swift` | Presentation | Unveraendert | Bekommt ueber `TrimTrackGeometry` ungeclampte fensterbasierte Positionen — Logik bleibt identisch |
| `Domain/Models/MeditationWaveform.swift` | Domain | Erweitern | Pure `windowed(fromFraction:toFraction:)` — schneidet den Sample-Bereich des Fensters aus (Zoom zeigt echte Details: 18-%-Fenster ≈ 400 von 2200 Samples → 220 Bars) |
| `Presentation/.../TrimEditor/TrimWaveformView.swift` | Presentation | Erweitern | Fenster-Parameter; rendert `windowed(...).downsampled(to: 220)`; Bar-Zeit, Range-Highlight und Playhead-Linie ueber Fenster gemappt; Highlight an Fenstergrenzen geclampt |
| `Presentation/.../TrimEditor/TrimWaveformSection.swift` | Presentation | Erweitern | Fenster in alle Mappings (Gesture, Marken, Lane, Achse); Achse zeigt `winLo … winHi`; Sichtbarkeits-Logik Marken/Playhead; Minimap- und Edge-Chip-Einbindung |
| `Presentation/.../TrimEditor/TrimPlayheadLane.swift` | Presentation | Erweitern | Fenster-Mapping; Grabber nur wenn Playhead im Fenster |
| `Presentation/.../TrimEditor/TrimMinimapView.swift` | Presentation | **Neu** | Gesamtstreifen (26 pt): Bereichs-Fuellung, Marken-/Playhead-Ticks, Sage-Fensterrahmen; Drag/Tap → `onPan(center)`; adjustable Accessibility-Element |
| `Presentation/.../TrimEditor/TrimEdgeChip.swift` | Presentation | **Neu** | Pille am Spurrand („‹ Anfang 0:42" / „Ende 19:05 ›"); Button → `focusPoint` |
| `Presentation/.../TrimEditor/TrimEditorSheet.swift` | Presentation | Erweitern | Chip „⌕ Ganze Datei" (nur im Zoom), kontextabhaengiger Hinweistext, Karten-Tap → `focusPoint` |
| `Presentation/.../TrimEditor/TrimReadoutCards.swift` | Presentation | Erweitern | Kleines Zoom-Icon auf den Karten, aktualisierter A11y-Hint |
| `Resources/de.lproj/Localizable.strings` + `en.lproj` | Resources | Erweitern | Neue Keys (s. u.), `trim_editor.hint` ersetzt durch Overview-/Zoom-Variante |
| `StillMomentTests/TrimEditorViewModelTests.swift` | Tests | Erweitern | Zoom-Intents, Recentering, Pan, Reset |
| `StillMomentTests/Application/TrimZoomWindowTests.swift` | Tests | **Neu** | frame/pan/span inkl. Clamping |
| `StillMomentTests/Presentation/TrimGeometryTests.swift` | Tests | Erweitern | Fenster-Overloads, unclamped-Variante |
| `StillMomentTests/Domain/MeditationWaveformTests.swift` | Tests | Erweitern | `windowed(fromFraction:toFraction:)` |

SwiftLint-Hinweis: `TrimEditorViewModel.swift` steht bei 319 Zeilen (Warning 400). Die Fenster-Mathematik liegt deshalb komplett in `TrimZoomWindow` — der ViewModel bekommt nur schlanke Intents. Sollte er trotzdem ueber 400 wachsen: Extension-Datei `TrimEditorViewModel+Zoom.swift`, kein Komprimieren.

## API-Recherche

Keine neuen Framework-APIs noetig — alles laeuft ueber bereits im Editor verwendete Bausteine (SwiftUI `Canvas`, `DragGesture(minimumDistance: 0)`, `accessibilityAdjustableAction`, `Environment(\.themeColors)`). iOS-16-Deployment-Target wird nicht beruehrt.

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| — | — | — | Keine neuen externen APIs; bestehende Patterns aus shared-107 werden erweitert |

## Design-Entscheidungen

### 1. Fenster als `ClosedRange<TimeInterval>` im ViewModel, pure Funktionen in Application

**Trade-off:** Ein eigenes `TrimWindow`-Struct in der Domain waere auch pur und testbar — aber das Ticket haelt den Zoom bewusst als UI-State aus der Domain heraus (`TrimEditorState` bleibt unberuehrt). Presentation-Platzierung (neben `TrimGeometry`) scheidet aus, weil der ViewModel (Application) die Funktionen fuer Recentering braucht.
**Entscheidung:** `ClosedRange<TimeInterval>` als `@Published` im ViewModel, statische pure Funktionen in `Application/Models/TrimZoomWindow.swift` — unit-testbar, keine Layer-Verletzung, Domain unberuehrt.

### 2. `TrimHitTesting` unveraendert lassen (ungeclampte Positionen statt Optional-API)

**Trade-off:** Optionale `startX`/`endX` in `TrimTrackGeometry` (nil = ausserhalb des Fensters) waeren expliziter, aendern aber die API und alle bestehenden Tests. Der Prototyp loest es geometrisch: ungeclampte Pixel-Positionen liegen fuer off-window Marken automatisch ausserhalb des Grab-Radius.
**Entscheidung:** Prototyp-Verhalten 1:1 — `TrimGeometry` bekommt eine ungeclampte Fenster-Variante, `TrimHitTesting` bleibt wie es ist. Weniger Aenderungsflaeche, identisches Verhalten zur Referenz.

### 3. Sample-Slicing als Domain-Methode auf `MeditationWaveform`

**Trade-off:** Das Slicing koennte privat in `TrimWaveformView` passieren — dann waere es aber nur ueber View-Tests pruefbar. Als pure Domain-Methode (analog `downsampled(to:)`) ist es direkt unit-testbar; der Doc-Kommentar von `MeditationWaveform` kuendigt die Zoom-Nutzung (shared-108) bereits an.
**Entscheidung:** `windowed(fromFraction:toFraction:)` neben `downsampled(to:)`. Das Ticket-Verbot betrifft nur `TrimEditorState`, nicht die Domain insgesamt.

### 4. Edge-Chips als Overlay NACH dem `highPriorityGesture`

Die Spur faengt alle Touches per `.highPriorityGesture` (gewinnt gegen Sheet-Dismiss). Ein Edge-Chip-Button *innerhalb* dieses Containers wuerde den Tap verlieren. **Entscheidung:** Chips als `.overlay` nach dem Gesture-Modifier anbringen — der Chip liegt in der Hit-Test-Reihenfolge vorn und gewinnt den Tap. Im manuellen Test verifizieren.

## Refactorings

Keine. Alle Aenderungen sind additiv; die von shared-107 vorbereiteten Schnittstellen (pures `TrimGeometry`/`TrimHitTesting`, 2200-Sample-Waveform, `downsampled(to:)`) passen. Bestehende `TrimGeometry`-Signaturen (duration-basiert) bleiben fuer die Mini-Karten-Variante (`PlaybackRangeCard`) erhalten.

## Neue Lokalisierungs-Keys (DE + EN)

| Key | DE (Entwurf) |
|-----|--------------|
| `trim_editor.hint.overview` | „Anfang/Ende antippen = heranzoomen · oben ziehen: Abspielposition" |
| `trim_editor.hint.zoomed` | „Detailansicht — fein ziehen, ±1s für die Sekunde" |
| `trim_editor.zoomOut` | „Ganze Datei" |
| `trim_editor.edgeChip.start` | „‹ Anfang %@" |
| `trim_editor.edgeChip.end` | „Ende %@ ›" |
| `trim_editor.a11y.minimap` | „Übersicht" |
| `trim_editor.a11y.minimapValue` | „Ausschnitt %1$@ bis %2$@" |
| `trim_editor.a11y.zoomOut` | „Ganze Datei anzeigen" |
| `trim_editor.a11y.edgeChip.start` | „Anfangspunkt bei %@ anzeigen" |
| `trim_editor.a11y.edgeChip.end` | „Endpunkt bei %@ anzeigen" |
| `trim_editor.a11y.cardHint` | aktualisieren: „Wählt diesen Punkt aus und zoomt heran" |

(Chevrons/Pfeile im Edge-Chip ggf. als Icon statt Text-Glyphe — beim Implementieren entscheiden, A11y-Label bleibt davon unberuehrt.)

## Fachliche Szenarien

Konstanten am Beispiel 19:05-Datei (1145 s): ZS = max(120, round(1145 · 0.18)) = 206 s.

### AK Fenster-Mapping

- Gegeben: Editor in der Uebersicht (Fenster = ganze Datei)
  Wenn: eine Marke gezogen wird
  Dann: identisches Verhalten wie shared-107 (Mapping ueber `[0, Dauer]`)

- Gegeben: Fenster `[100, 306]` bei 1145 s Dauer, Spurbreite 350 pt
  Wenn: ein Punkt bei x = 175 pt (Mitte) angefasst wird
  Dann: entspricht Sekunde 203 (Fenster-Mitte), nicht Sekunde 572 (Datei-Mitte)

- Gegeben: Zoom-Fenster aktiv
  Wenn: eine Marke an den linken/rechten Spurrand gezogen wird
  Dann: die Zeit clampt an `winLo`/`winHi` (nicht an 0/Dauer)

- Gegeben: Zoom-Fenster `[100, 306]`
  Wenn: die Zeitachse gerendert wird
  Dann: links „1:40", rechts „5:06" (nicht „0:00"/„19:05")

- Gegeben: Waveform mit 2200 Samples
  Wenn: das Fenster 18 % der Datei zeigt
  Dann: werden die ~400 Samples des Fensters auf 220 Bars reduziert — echte Details, keine gestreckten Balken

### AK Auto-Zoom

- Gegeben: Uebersicht, Ende bei 19:05 (1145 s)
  Wenn: Karte *Ende* angetippt wird
  Dann: Ende ist aktiv, Fenster ≈ `[990, 1145]` (Breite 206 s, Marke ~25 % vom rechten Rand, an Dateigrenze geclampt), Playhead auf der Marke

- Gegeben: Uebersicht, Anfang bei 0:30
  Wenn: Karte *Anfang* angetippt wird
  Dann: Fenster `[0, 206]` (Clamping an 0), Marke sichtbar nahe linkem Viertel

- Gegeben: Datei mit 90 s Dauer (< 120 s Mindestfenster)
  Wenn: Karte *Anfang* angetippt wird
  Dann: kein Zoom — Fenster bleibt ganze Datei, keine Minimap, kein Chip

- Gegeben: Zoom aktiv, Marke wird gezogen
  Wenn: der Finger zieht (Drag laeuft)
  Dann: das Fenster bleibt waehrend des gesamten Drags fix

- Gegeben: Zoom aktiv
  Wenn: der Marken-Drag endet
  Dann: Fenster recentert auf die freigegebene Marke; Kurz-Vorschau spielt wie bisher

- Gegeben: Uebersicht (kein Zoom)
  Wenn: ein Marken-Drag endet oder genudgt wird
  Dann: Fenster bleibt ganze Datei (kein ungewolltes Hineinzoomen)

- Gegeben: Zoom aktiv
  Wenn: ±1s-Nudge gedrueckt wird
  Dann: Marke verschiebt sich 1 s, Fenster recentert, 1,4-s-Vorschau spielt

- Gegeben: Zoom aktiv
  Wenn: Chip „Ganze Datei" angetippt wird
  Dann: Fenster = ganze Datei, Marken und Playhead unveraendert, Minimap und Chip verschwinden

- Gegeben: Zoom aktiv
  Wenn: Link „Ganze Datei verwenden" angetippt wird
  Dann: Marken auf 0/Dauer zurueckgesetzt UND Fenster = ganze Datei

- Gegeben: Uebersicht / Zoom
  Wenn: der Hinweistext gerendert wird
  Dann: Uebersicht zeigt den Heranzoomen-Hinweis, Zoom den Detailansicht-Hinweis

- Gegeben: Zoom aktiv, Playhead wird in der Lane gezogen
  Wenn: der Drag endet
  Dann: Fenster unveraendert (Seek recentert nie)

### AK Minimap

- Gegeben: Uebersicht
  Wenn: der Editor gerendert wird
  Dann: keine Minimap sichtbar

- Gegeben: Zoom aktiv
  Wenn: die Minimap gerendert wird
  Dann: Bereichs-Fuellung zwischen den Marken, zwei Marken-Ticks, Playhead-Tick, Fensterrahmen an der Fensterposition

- Gegeben: Zoom mit Fenster `[990, 1145]`
  Wenn: auf der Minimap bei 50 % getippt/gezogen wird
  Dann: Fenster pannt auf Mitte ≈ 572 s → `[469, 675]`; Fensterbreite bleibt 206 s

- Gegeben: Pan an den Dateianfang (Tap bei 0 %)
  Wenn: `panWindow(0)` berechnet wird
  Dann: Fenster clampt zu `[0, 206]` (rutscht nicht ueber den Rand)

- Gegeben: Zoom auf den Anfang, Ende bei 19:05 ausserhalb des Fensters
  Wenn: die Hauptspur gerendert wird
  Dann: am rechten Rand erscheint der Edge-Chip „Ende 19:05 ›" statt des Griffs

- Gegeben: Edge-Chip „Ende 19:05 ›" sichtbar
  Wenn: der Chip angetippt wird
  Dann: Ende wird aktiv, Fenster rahmt das Ende, Chip verschwindet, Griff erscheint

- Gegeben: Zoom, Playhead ausserhalb des Fensters
  Wenn: die Lane gerendert wird
  Dann: kein Grabber/keine Playhead-Linie im Fenster (kein an den Rand geklebter Grabber)

### AK Querschnitt

- Gegeben: Zoom aktiv
  Wenn: Marken-Drag, Playhead-Drag, ▶-Vorschau und ±1s-Nudge benutzt werden
  Dann: identisches Audio-/Playhead-Verhalten wie in der Uebersicht (Vorschau nach Drag-Ende, Pause-bei-Endpunkt, Nudge-Vorschau)

- Gegeben: VoiceOver aktiv
  Wenn: Minimap fokussiert wird
  Dann: Label „Uebersicht", Value nennt den Fensterbereich; Swipe hoch/runter pannt das Fenster

- Gegeben: VoiceOver aktiv
  Wenn: ein Edge-Chip fokussiert wird
  Dann: verstaendliches Label inkl. Zeit („Endpunkt bei 19:05 anzeigen")

## Reihenfolge der Akzeptanzkriterien (TDD)

1. **`TrimZoomWindow` (Application, pure)** — `zoomSpan`, `frame`, `pan` mit Clamping-Faellen und Kurz-Datei-Guard. Grundlage fuer alles.
2. **`TrimGeometry`-Fenster-Overloads + `MeditationWaveform.windowed`** — pures Mapping und Slicing, unabhaengig testbar.
3. **ViewModel-Zoom-State + Intents** — `window`, `isZoomed`, `focusPoint`, `zoomOut`, `panWindow`, Recentering in `nudgeActivePoint`/`markDragEnded`, Reset in `useWholeFile`. Kern-Verhaltenstests.
4. **Fenster-Rendering der Spur** — `TrimWaveformView` (Slicing, Highlight, Playhead), `TrimWaveformSection` (Gesture-Mapping, Achse, Sichtbarkeit), `TrimPlayheadLane`. Ab hier ist der Zoom manuell erlebbar.
5. **Minimap** — neues View + Pan-Anbindung + Accessibility.
6. **Edge-Chips** — neues View + Overlay-Einbindung (Gesture-Reihenfolge beachten, s. Entscheidung 4).
7. **Sheet-Feinschliff** — Chip „Ganze Datei", kontextabhaengiger Hint, Zoom-Icon auf den Karten, Lokalisierung DE+EN, CHANGELOG.

## Manuelle Verifikation

Nach Schritt 7 den manuellen Test aus dem Ticket durchspielen (19-Minuten-Datei, Simulator iPhone 16 Plus) — insbesondere Edge-Chip-Tap (Gesture-Konflikt, Entscheidung 4) und das Drag-Gefuehl im Zoom (~2 pt/s).

## Offene Fragen

Keine — alle Entscheidungen sind im Ticket bzw. Design-Handoff gefallen; Detailannahmen siehe „Annahmen".
