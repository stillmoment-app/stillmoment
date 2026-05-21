# Ticket shared-100: Idle-Ring in Running-Sprache duenn (Android-Sync)

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Komplexitaet**: Klein — visuelle Anpassung einer bestehenden Compose-Komponente, Drag-Logik und TalkBack-Verhalten bleiben unveraendert.
**Phase**: 4-Polish

---

## Was

Der Dauer-Picker im Timer-Idle-Screen soll dieselbe Ring-Sprache sprechen wie der laufende Timer: duenner Ring, duenner Fortschritts-Bogen, kleine Lichtperle (Bead) als Indikator. Geometrie und Interaktion (Drag um den Ring, Bereich 1–60 Minuten, TalkBack als Slider mit Increment/Decrement) bleiben gleich — nur die Ring-Erscheinung aendert sich.

## Warum

Idle und Running wirken auf Android aktuell wie zwei verschiedene Apps: Idle hat einen dickeren Ring mit auffaelligem Tropfen-Halo, Running einen feinen Ring mit kleinem Punkt. Der Uebergang vom Auswahl- in den Sitzungs-Screen wirkt dadurch wie ein Bruch. Eine einheitliche Ring-Sprache laesst Idle und Running als denselben Ort wahrnehmen — die Sitzung beginnt visuell ruhiger.

---

## Plattform-Status

| Plattform | Status | Anmerkung |
|-----------|--------|-----------|
| iOS       | [x]    | Bereits umgesetzt via `ios-045` |
| Android   | [x]    | -                               |

---

## Akzeptanzkriterien

### Visuell

- [ ] Idle-Ring und laufender Timer-Ring nutzen identische Strichstaerke, Track-Farbe und Bogen-Farbe (gleiche Werte wie in `BreathingCircle` aus `shared-090`)
- [ ] Bead am Ring ist ein kleiner gefuellter Punkt in Akzentfarbe — kein umrahmter Tropfen, kein Halo, kein pulsierendes Leuchten
- [ ] Bead vergroessert sich sichtbar waehrend des aktiven Drag und kehrt nach Loslassen zur Ruhegroesse zurueck (greifbares Feedback, weil der Ruhe-Bead klein ist)
- [ ] Touch-Area des Rings reicht spuerbar ueber den sichtbaren Ring hinaus, sodass der duenne Bead bequem getroffen wird
- [ ] Idle-Ring ist statisch — keine Atem-Animation, kein pulsierender Glow (der Atem startet erst mit der Sitzung)

### Funktion

- [ ] Drag-Geste, Winkelberechnung, Klemmung auf 1–60 Minuten und die Zentral-Anzeige (Zahl + "Minuten") bleiben unveraendert
- [ ] TalkBack-Slider-Rolle und Increment/Decrement-Actions (±1) funktionieren unveraendert

### Reduce Motion

- [ ] Verhalten unveraendert sichtbar (entfaellt faktisch, weil keine Animation mehr stattfindet im Idle)

### Tests

- [ ] Bestehende Tests fuer den Dauer-Picker laufen weiterhin (Drag, Klemmung, Accessibility-Wert)

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare visuelle Aenderung)

---

## Manueller Test

1. Timer-Tab oeffnen — Idle-Screen wird angezeigt
2. Ring beobachten ohne Interaktion: duenner Track + duenner Bogen + kleiner Bead, keine Bewegung
3. Bead anfassen und um den Ring ziehen: Bead vergroessert sich, Wert in der Mitte folgt
4. Knapp neben den sichtbaren Ring tippen und ziehen: Drag startet trotzdem (Hit-Area)
5. Timer mit "Beginnen" starten: Uebergang zum laufenden Ring fuehlt sich visuell ruhig an, beide Ringe wirken aus derselben Familie
6. TalkBack einschalten, Dial fokussieren, mit Wischen nach oben/unten ±1 anpassen
7. System-Reduce-Motion aktivieren und Schritte 1–3 wiederholen — keine sichtbare Aenderung im Idle

---

## Referenz

- iOS-Pendant: [ios-045](../ios/ios-045-idle-ring-thin.md)
- iOS-Komponente: `ios/StillMoment/Presentation/Views/Timer/Components/BreathDial.swift`
- iOS-Design-Handoff: `handoffs/handoff_idle_thin_ring/`
- Android-Pendant: Dauer-Picker im Timer-Idle (`BreathDial`-aequivalente Compose-Komponente)
- Running-Ring Referenz: `BreathingCircle` aus `shared-090` — Strichstaerke, Bead-Groesse, Farben sollen identisch sein

---

## Hinweise

- **Werte zentralisieren**, wenn die Running-Komponente diese bereits exponiert — dann ziehen Idle und Running automatisch zusammen, wenn der Spec sich aendert.
- **Bead waehrend Drag** soll spuerbar groesser werden (Greifbarkeit). Begruendung: der Bead ist im Ruhezustand klein, ohne Vergroesserung waere das Drag-Feedback duenn.
- **Hit-Area** muss groesser sein als der sichtbare Ring, damit das Anfassen nicht zur Praezisionsuebung wird.
- **Atem im Idle bewusst weggelassen** — der Idle-Screen ist eine Auswahl-Phase. Atmende Geometrie wirkt dort unruhig.
- **Settings-Liste, +/−-Buttons, Pre-Roll** ausserhalb des Scopes (`shared-089` hat das bereits konsolidiert).
