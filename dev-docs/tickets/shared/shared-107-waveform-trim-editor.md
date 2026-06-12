# Ticket shared-107: Waveform-Trim-Editor fuer den Wiedergabe-Bereich

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Mittel-Hoch. Die Trim-Logik (Domain, Persistenz, Player-Verhalten) existiert aus shared-105 — Risiken liegen in der Waveform-Berechnung (Decode-Dauer bei 1h-Dateien, Caching, Lazy-Fallback) und in der Gesten-Praezision des Editors (Drag-Griffe, Clamping, Vorhoeren).
**Phase**: 3-Feature

---

## Was

Das Setzen der Trim-Punkte (shared-105) bekommt ein visuelles UI: Eine Karte "Wiedergabe-Bereich" im Edit-Sheet ersetzt die mm:ss-Textfelder und oeffnet einen Vollbild-Editor mit Wellenform-Darstellung. Zwei ziehbare Griffe setzen Start- und Endpunkt; Vorhoeren ab dem aktiven Punkt prueft die Wahl.

## Warum

Mit mm:ss-Eingabe muss man sich zur richtigen Stelle durchhoeren. In der Wellenform heben sich dichte Sprach-Bloecke (Einleitung, Schlussworte) sichtbar von der stillen Meditation ab — der User zieht die Griffe direkt an die Kante.

Design-Handoff (massgeblich fuer Layout, Masse, Interaktionen): `handoffs/design_handoff_trim_waveform/README.md`

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-105 (iOS done) |
| Android   | [ ]    | shared-105 (Android offen) |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

**Formular-Zeile (Edit-Sheet):**
- [ ] Karte "Wiedergabe-Bereich" ersetzt die mm:ss-Textfelder aus shared-105
- [ ] Ungetrimmt: "Ganze Datei · {Dauer}" + "Bereich waehlen"; Tippen oeffnet den Editor
- [ ] Getrimmt: statische Mini-Wellenform mit hervorgehobenem Bereich, Zeitraum "{start} – {end}", hoerbare Dauer, Textlink "Zuschnitt entfernen" (setzt auf ungetrimmt zurueck)

**Vollbild-Editor:**
- [ ] Wellenform mit zwei ziehbaren Griffen (Touch-Target >= 44 pt), Bereichs-Highlight, Playhead
- [ ] Aktiver Punkt (Anfang/Ende) waehlbar ueber Readout-Karten; grosser Zeit-Readout zeigt den aktiven Punkt
- [ ] Griff ziehen setzt den Punkt live (Zeit-Blase folgt); Loslassen spielt eine kurze Vorschau
- [ ] −1s/+1s verschieben den aktiven Punkt exakt; kurze Vorschau folgt
- [ ] Play/Pause: durchgehende Wiedergabe ab aktivem Punkt; kurze Vorschauen veraendern das Play-Icon nicht
- [ ] Mindestabstand zwischen Anfang und Ende: 25 s
- [ ] "Ganze Datei verwenden" setzt auf den vollen Bereich zurueck
- [ ] "Fertig" uebernimmt die Werte; ist der Bereich praktisch die ganze Datei (start <= 1 s und end >= Dauer − 1 s), wird kein Zuschnitt gespeichert
- [ ] "Zurueck" schliesst ohne zu speichern

**Waveform-Daten:**
- [ ] Werden beim initialen Import im Hintergrund vorberechnet und gecacht (Import wird nicht blockiert)
- [ ] Fehlen die Daten beim Laden (Bestands-Meditationen nach Versions-Upgrade), werden sie zu diesem Zeitpunkt berechnet und gecacht; der Editor zeigt solange einen Ladezustand
- [ ] Schlaegt die Dekodierung fehl, zeigt der Editor statt Balken eine schlichte Linie — die Funktion bleibt voll erhalten
- [ ] Die Audiodatei selbst bleibt unveraendert (nicht-destruktiv, wie shared-105)

**Querschnitt:**
- [ ] Accessibility: Griffe als anpassbare Elemente (Slider-Semantik, Werte in Worten), Transport-Buttons beschriftet
- [ ] Reduced Motion: Griff-Puls und Sheet-Animation reduziert/abgeschaltet
- [ ] Farben ueber semantische Theme-Rollen, Typografie ueber bestehende Tokens (Handoff-Hexwerte sind Referenz, nicht Vorgabe)
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [ ] CHANGELOG.md
- [ ] GLOSSARY.md (Begriff "Wiedergabe-Bereich" / "Wellenform")

---

## Manueller Test

1. Meditation (laengere Datei, mit Einleitung) importieren — Import fuehlt sich unveraendert schnell an
2. Edit-Sheet oeffnen, Karte "Wiedergabe-Bereich" antippen — Editor oeffnet, Wellenform ist da (oder erscheint nach kurzem Ladezustand)
3. Anfangs-Griff an das Ende der Einleitung ziehen — Vorschau spielt automatisch, Punkt per −1s/+1s feinjustieren
4. Ende-Karte antippen, End-Griff vor die Schlussworte ziehen, "Fertig"
5. Formular zeigt Mini-Wellenform + Zeitraum; Meditation abspielen: startet/endet an den Punkten (Verhalten aus shared-105)
6. "Zuschnitt entfernen" — Wiedergabe laeuft wieder ueber die ganze Datei
7. App-Update-Szenario: Meditation aus Bestand ohne Cache oeffnen — Editor zeigt Ladezustand, danach Wellenform (einmalig)

---

## Referenz

- Design-Handoff: `handoffs/design_handoff_trim_waveform/` (README + Screenshots + lauffaehiger Prototyp)
- shared-105 (Trim-Punkte: Domain, Persistenz, Player-Verhalten — bereits vorhanden)
- shared-098 (Library-Preview: Vorhoer-Infrastruktur)

---

## Hinweise

- Decode-Performance: 1h-Dateien brauchen auf aelteren Geraeten (iPhone 8-Klasse) geschaetzt 10–25 s — deshalb Vorberechnung beim Import im Hintergrund plus Cache; Berechnung nie auf dem Main Thread.
- Cache-Daten sind klein (~220 normalisierte Peak-Werte pro Meditation); Invalidierung ist unkritisch, da Dateien nie veraendert werden (nicht-destruktive Invariante).
- Die mm:ss-Felder aus shared-105 entfallen ersatzlos; die Validierungsregeln (innerhalb Dateidauer, Start < Ende) wandern in den Editor (Clamping statt Fehlermeldung).
- Kein Zoom in der Wellenform (bewusst nicht in Scope dieser Version).
- Android: shared-105 ist dort noch offen — Android-Umsetzung dieses Tickets setzt shared-105-Android voraus.
