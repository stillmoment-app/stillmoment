# Ticket ios-045: Idle-Ring in Running-Sprache (duenn)

**Status**: [ ] TODO | [~] IN PROGRESS | [x] DONE
**Plan**: [Implementierungsplan](../plans/ios-045.md)
**Prioritaet**: NIEDRIG
**Komplexitaet**: Klein — visuelle Anpassung einer bestehenden Komponente, Drag-Logik und Accessibility bleiben unveraendert
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Der Dauer-Picker im Timer-Idle-Screen soll dieselbe Ring-Sprache sprechen wie der laufende Timer: duenner Ring, duenner Fortschritts-Bogen, kleine Lichtperle als Bead. Geometrie und Interaktion (Drag um den Ring, Bereich 1–60 Minuten, VoiceOver-Slider) bleiben gleich — nur die Ring-Erscheinung aendert sich.

## Warum

Idle und Running wirken aktuell wie zwei verschiedene Apps: Idle hat einen dicken Ring mit grossem Tropfen und animiertem Halo, Running einen feinen Ring mit kleinem Punkt. Der Uebergang vom Auswahl- in den Sitzungs-Screen wirkt dadurch wie ein Bruch. Eine einheitliche Ring-Sprache laesst Idle und Running als denselben Ort wahrnehmen — die Sitzung beginnt visuell ruhiger.

---

## Akzeptanzkriterien

### Feature
- [ ] Idle-Ring und laufender Timer-Ring nutzen identische Strichstaerke, Track-Farbe und Bogen-Farbe
- [ ] Bead am Ring ist ein kleiner gefuellter Punkt in Akzent-Farbe (kein umrahmter Tropfen, kein Halo)
- [ ] Bead vergroessert sich sichtbar waehrend des aktiven Drag und kehrt nach Loslassen zur Ruhegroesse zurueck
- [ ] Touch-Area des Rings reicht spuerbar ueber den sichtbaren Ring hinaus, sodass der duenne Bead bequem getroffen wird
- [ ] Idle-Ring ist statisch — keine Atem-Animation, kein pulsierender Glow (der Atem startet erst mit der Sitzung)
- [ ] Drag, atan2-Winkelberechnung, Klemmung auf 1–60 Minuten und die Zentral-Anzeige (Zahl + "Minuten") bleiben unveraendert
- [ ] VoiceOver-Slider-Rolle und `accessibilityAdjustableAction` (±1) funktionieren unveraendert
- [ ] Reduced Motion: Verhalten unveraendert sichtbar (entfaellt faktisch, weil keine Animation mehr stattfindet)

### Tests
- [ ] Bestehende `BreathDial`-Tests laufen weiterhin (Drag, Klemmung, Accessibility-Wert)

### Dokumentation
- [ ] CHANGELOG.md (user-sichtbare visuelle Aenderung)

---

## Manueller Test

1. Timer-Tab oeffnen — Idle-Screen wird angezeigt
2. Ring beobachten ohne Interaktion: duenner Track + duenner Bogen + kleiner Bead, keine Bewegung
3. Bead anfassen und um den Ring ziehen: Bead vergroessert sich, Wert in der Mitte folgt
4. Knapp neben den sichtbaren Ring tippen und ziehen: Drag startet trotzdem
5. Timer mit "Beginnen" starten: Uebergang zum laufenden Ring fuehlt sich visuell ruhig an, beide Ringe wirken aus derselben Familie
6. VoiceOver einschalten, Dial fokussieren, mit Wischen nach oben/unten ±1 anpassen
7. Reduced Motion in den iOS-Einstellungen aktivieren und Schritte 1–3 wiederholen — keine sichtbare Aenderung im Idle

---

## Referenz

- Vorlage fuer Ring-Werte und Bead: die bereits existierende Komponente, die den laufenden Timer rendert. Ihre Werte (Strichstaerke, Bead-Groesse, Track-/Bogen-Farben, Bead-Shadow) sollen im Idle 1:1 uebernommen werden, damit Idle und Running garantiert identisch sind.
- Aktueller Idle-Ring: `ios/StillMoment/Presentation/Views/Timer/Components/BreathDial.swift`
- Drag-/Winkel-Helper: `BreathDialGeometry` bleibt unveraendert
- Design-Handoff: `handoffs/handoff_idle_thin_ring/` (README + Side-by-Side-HTML, JSX-Referenz)

---

## Hinweise

- **Werte aus dem Handoff vs. existierender Code:** Der Handoff nennt 1 px / 1.5 px Strichstaerken. Verbindlich sind aber die Werte aus der existierenden Running-Komponente — sie sind etwas dicker, dafuer ist die visuelle Identitaet Idle ↔ Running garantiert. Wenn der Code spaeter die Werte zentral aendert, ziehen Idle und Running zusammen mit.
- **Bead waehrend Drag:** Der Bead soll beim aktiven Drag spuerbar groesser werden (Greifbarkeit). Open Question aus dem Handoff bewusst bejaht — Begruendung: der Bead ist im Ruhezustand klein, ohne Vergroesserung waere das Drag-Feedback duenn.
- **Hit-Area:** Erweiterung der Touch-Flaeche nach aussen ist wichtig, weil der Bead jetzt viel kleiner ist als der bisherige Tropfen. Die Hit-Area soll groesser sein als der sichtbare Ring, damit das Anfassen nicht zur Praezisionsuebung wird.
- **Atem im Idle bewusst weggelassen:** Der Idle-Screen ist eine Auswahl-Phase — eine atmende Geometrie wirkt dort unruhig. Atem startet erst, wenn die Sitzung laeuft. (Open Question aus dem Handoff in diese Richtung entschieden.)
- **Settings-Liste, +/−-Buttons, Pre-Roll, Sheet-Picker, Tab-Bar:** ausserhalb des Scopes.

---
