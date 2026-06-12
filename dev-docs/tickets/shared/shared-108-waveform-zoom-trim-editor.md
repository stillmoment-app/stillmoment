# Ticket shared-108: Zoom in die Waveform des Trim-Editors

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Mittel — die Voraussetzung (hoeher aufgeloeste Waveform-Daten, 2200 Peaks) ist mit shared-107 erledigt. Kern ist das Fenster-Mapping `[winLo, winHi]` fuer alle Spur-Interaktionen, der Auto-Zoom per Karten-Tap und die Minimap mit Pan und Edge-Chips.
**Phase**: 3-Feature

---

## Was

Der Waveform-Trim-Editor (shared-107) bekommt eine Detail-Ansicht: Tippen auf die Karte *Anfang* bzw. *Ende* zoomt auf ein Fenster um die Marke (~18 % der Dateidauer, min. 120 s), in dem sich die Marke sekundengenau ziehen laesst. Eine Minimap zeigt die Gesamtdatei mit Fensterrahmen und erlaubt Verschieben des Ausschnitts; „Ganze Datei" zoomt zurueck zur Uebersicht.

Massgebliche Design-Referenz: `handoffs/design_handoff_trim_zoom/README.md`, Abschnitt „Praezises Zuschneiden an den Raendern" (Fenster-Mapping, `frameWindow`, Minimap, Edge-Chips, Recentering).

## Warum

Bei einer 19-Minuten-Datei entspricht eine Sekunde ~0,3 pt auf der Spur — sekundengenaues Ziehen ist physisch unmoeglich, aktuell kompensiert nur der ±1s-Nudge. Im Zoom-Fenster (~2 pt/s) trifft der Finger die Sekunde direkt; die hoeher aufgeloesten Waveform-Daten zeigen dabei echte Details statt breit gezogener Balken.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-107 (iOS done) |
| Android   | [ ]    | shared-107 (Android offen) |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

**Fenster-Mapping:**
- [ ] Alle Spur-Interaktionen (Marken-Drag, Playhead-Drag, Hit-Testing) mappen ueber ein Fenster `[winLo, winHi]` statt fest ueber `[0, Dauer]`; in der Uebersicht ist das Fenster die ganze Datei
- [ ] Die Zeitachse unter der Spur zeigt die Fenstergrenzen (nicht 0 … Dauer)
- [ ] Im Zoom zeigt die Waveform echte zusaetzliche Details (hoeher aufgeloeste Daten, nicht nur breitere Balken)

**Auto-Zoom:**
- [ ] Tippen auf die Karte *Anfang*/*Ende* waehlt die Marke und rahmt sie in einem Fenster (~18 % der Dauer, min. 120 s, Marke ~25 % vom nahen Rand)
- [ ] Nach Drag-Ende, Nudge und Karten-Tap wird das Fenster auf die Marke recentert; waehrend des Ziehens bleibt es fix
- [ ] „Ganze Datei"-Aktion zoomt zurueck zur Uebersicht; die Karten signalisieren die Zoom-Moeglichkeit (Zoom-Icon)
- [ ] Kontextabhaengiger Hinweistext (Uebersicht vs. Detailansicht)

**Minimap (nur im Zoom sichtbar):**
- [ ] Dünner Gesamtstreifen mit Bereichs-Fuellung, Marken-Ticks, Playhead-Tick und Fensterrahmen
- [ ] Ziehen/Tippen auf der Minimap verschiebt das Fenster (Pan)
- [ ] Liegt eine Marke ausserhalb des Fensters, zeigt die Hauptspur am naeheren Rand einen Edge-Chip („Ende 19:05 ›"); Tippen waehlt und rahmt diese Marke

**Querschnitt:**
- [ ] Marken, Playhead, Vorschau und ±1s-Nudge funktionieren im Zoom unveraendert
- [ ] Accessibility: Minimap und Edge-Chips beschriftet; Zoom-Zustand fuer VoiceOver/TalkBack nachvollziehbar
- [ ] Farben ueber semantische Theme-Rollen, Typografie ueber bestehende Tokens
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [ ] CHANGELOG.md (bei user-sichtbaren Aenderungen)

---

## Manueller Test

1. Lange Meditation (≥ 15 Minuten) im Trim-Editor oeffnen
2. Karte *Anfang* antippen — Editor zoomt auf die Umgebung des Anfangspunkts, Minimap erscheint
3. Anfangspunkt im Zoom ziehen — sekundengenaues Treffen ist moeglich, Zeitachse zeigt die Fenstergrenzen
4. Minimap ziehen — der Ausschnitt verschiebt sich; liegt das Ende ausserhalb, erscheint der Edge-Chip, Tippen springt dorthin
5. „Ganze Datei" — zurueck zur Uebersicht, Marken und Playhead unveraendert korrekt

---

## Referenz

- Design-Handoff: `handoffs/design_handoff_trim_zoom/` (README Abschnitt „Praezises Zuschneiden an den Raendern" + lauffaehiger Prototyp)
- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/TrimEditor/` (`TrimGeometry`, `TrimHitTesting` sind pure und bekommen das Fenster als Parameter)
- Android: folgt mit der Android-Umsetzung von shared-107

---

## Hinweise

- Voraussetzung erledigt: Die gecachte Waveform hat seit shared-107 2200 Peaks (`MeditationWaveform.sampleCount`); Uebersichten rendern per `downsampled(to:)`. Der Provider regeneriert Alt-Caches mit abweichender Aufloesung automatisch.
- Bewusst NICHT in Scope: Snap-Chips („Intro ueberspringen / Ausklang kuerzen") aus dem Handoff — sie braeuchten echte Stille-/Onset-Erkennung; die Handoff-Werte sind Platzhalter. Zoom + Nudge loesen das Praezisionsproblem; Chips nur aufgreifen, falls sich der Editor danach noch zaeh anfuehlt.
- Kein Pinch-Zoom: Der Karten-Tap-Auto-Zoom aus dem Handoff ersetzt die urspruengliche Pinch-Idee — einfacher bedienbar und einfacher umzusetzen. Das Zoom-Fenster ist UI-State (ViewModel), `TrimEditorState` (Domain) bleibt unberuehrt; `frameWindow`/`panWindow` als pure Funktionen (unit-testbar).

---
