# Ticket shared-049: Flexible Intervallklaenge

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~6h | Android ~6h
**Phase**: 3-Feature

---

## Was

Intervallklaenge sollen flexibel konfigurierbar werden: frei waehlbares Intervall (1-60 Minuten), optionales Wiederholen, Richtung (vom Anfang oder Ende), und ein eigener Sound unabhaengig vom Start/Ende-Gong.

## Warum

Aktuell sind nur 3 feste Intervall-Optionen (3, 5, 10 Minuten) verfuegbar, die immer wiederholend vom Start zaehlen. User wuenschen sich mehr Kontrolle, insbesondere einen einzelnen Klang X Minuten vor Ende als Erinnerung -- der haeufigste Usecase.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

**Datenmodell**
- [ ] Intervall frei waehlbar von 1 bis 60 Minuten (statt fest 3/5/10)
- [ ] Wiederholen an/aus (Default: an = bisheriges Verhalten)
- [ ] Richtung "vom Ende zaehlen" an/aus (Default: aus = bisheriges Verhalten)
- [ ] Eigener Sound fuer Intervallklaenge, unabhaengig vom Start/Ende-Gong
- [ ] Bestehende Einstellungen migrieren sauber (keine Datenverluste)

**Intervall-Logik**
- [ ] Wiederholend + vom Anfang: Klaenge bei jedem vollen Intervall vom Start (5:00, 10:00, 15:00, ...)
- [ ] Wiederholend + vom Ende: Klaenge rueckwaerts vom Ende, letzter Klang exakt X Min. vor Ende
- [ ] Einmalig: Genau 1 Klang X Minuten vor Ende (Richtungswahl nicht sichtbar)
- [ ] Kein Klang wenn Intervall >= Meditation (kein Fehler, kein Warning)
- [ ] Kein Intervall-Klang in den letzten 5 Sekunden (Kollision mit Ende-Gong vermeiden)

**Settings-UI**
- [ ] Intervallklaenge bekommen eine eigene Section (getrennt von Gong-Section)
- [ ] Stepper fuer Intervall 1-60 Min. (statt Dropdown)
- [ ] Toggle fuer "Wiederholen"
- [ ] Toggle fuer "Vom Ende zaehlen" -- nur sichtbar wenn Wiederholen an
- [ ] Sound-Picker fuer Intervall-Sound (5 Optionen: bisherige 4 + "Sanfter Intervallton")
- [ ] Lautstaerkeregler fuer Intervall-Sound
- [ ] Dynamische Beschreibung unter dem Intervall-Toggle zeigt aktuelle Konfiguration

**Dynamische Beschreibung**

| Konfiguration | DE | EN |
|---------------|----|----|
| Wiederholen AN, vom Anfang | "Alle X Min., {Soundname}" | "Every X min, {Soundname}" |
| Wiederholen AN, vom Ende | "Alle X Min. vom Ende, {Soundname}" | "Every X min from end, {Soundname}" |
| Wiederholen AUS | "X Min. vor Ende, {Soundname}" | "X min before end, {Soundname}" |
| Toggle AUS | Statische Beschreibung (wie bisher) | Statische Beschreibung (wie bisher) |

**Sound-Optionen**
- [ ] 5. Sound "Sanfter Intervallton" / "Soft Interval Tone" (bestehende `interval.mp3`)
- [ ] Sound-Vorhoeren bei Auswahl

**Zustaende der UI**

| Zustand | Sichtbar |
|---------|----------|
| Intervallklaenge AUS | Nur Toggle + statische Beschreibung |
| Wiederholend, vom Anfang (Default) | Toggle, Stepper, Wiederholen-Toggle, Vom-Ende-Toggle (aus), Sound-Picker, Volume |
| Wiederholend, vom Ende | Toggle, Stepper, Wiederholen-Toggle, Vom-Ende-Toggle (an), Sound-Picker, Volume |
| Einmalig | Toggle, Stepper, Wiederholen-Toggle (aus), Sound-Picker, Volume (kein Vom-Ende-Toggle) |

- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android
- [ ] Accessibility-Labels auf allen interaktiven Elementen

### Edge Cases
- [ ] Intervall > Meditation: Kein Klang, kein Fehler
- [ ] Einmalig + Intervall > Meditation: Kein Klang
- [ ] Intervall = Meditation: Kein Klang (wuerde mit Ende-Gong kollidieren)
- [ ] Vom Ende, nicht teilbar (z.B. 23 Min., 5 Min. Intervall): Erster Klang bei 3:00, dann 8:00, 13:00, 18:00

### Migration
- [ ] Bestehende intervalMinutes (3/5/10) bleiben gueltig im neuen 1-60 Bereich
- [ ] Neue Felder bekommen Defaults die bisheriges Verhalten beibehalten (repeating=true, fromEnd=false, soundId=bisheriger Gong-Sound)
- [ ] Alte Validierung (Snap zu 3/5/10) wird durch Clamping 1-60 ersetzt

### Tests
- [ ] Unit Tests fuer neue Intervall-Logik (alle 3 Modi, Edge Cases)
- [ ] Unit Tests fuer Settings-Persistenz (neue Felder, Migration)
- [ ] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

### Wiederholend vom Anfang (Default)
1. Settings oeffnen, Intervallklaenge aktivieren
2. Intervall auf 5 Min. stellen, Wiederholen an, Vom Ende aus
3. 20-Min-Meditation starten
4. Erwartung: Klaenge bei 5:00, 10:00, 15:00 verstrichener Zeit

### Wiederholend vom Ende
1. Intervall 5 Min., Wiederholen an, Vom Ende an
2. 23-Min-Meditation starten
3. Erwartung: Klaenge bei 3:00, 8:00, 13:00, 18:00 (= 20, 15, 10, 5 Min. vor Ende)

### Einmalig (vor Ende)
1. Intervall 5 Min., Wiederholen aus
2. 20-Min-Meditation starten
3. Erwartung: Genau 1 Klang bei 15:00 (= 5 Min. vor Ende)

### Eigener Sound
1. Intervall-Sound auf "Sanfter Intervallton" aendern
2. Meditation starten
3. Erwartung: Intervallklang klingt anders als Start/Ende-Gong

### Edge Case
1. Intervall auf 30 Min., Meditation auf 20 Min.
2. Meditation starten
3. Erwartung: Kein Intervallklang waehrend der gesamten Meditation

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Stepper | Nativer `Stepper(value:in:)` | Custom Row mit -/+ Buttons (Material3) |
| Sound-Picker | Nativer Picker | ExposedDropdownMenuBox |
| Section-Trennung | Eigene List-Section | Eigene Card |

---

## Referenz

- Bestehende Intervall-Gong-Logik als Ausgangspunkt
- Bestehende `interval.mp3` wird als 5. Sound-Option wiederverwendet

---

## Hinweise

- **Regel bei Einmalig**: `intervalFromEnd` wird automatisch true und das Toggle ist nicht sichtbar. Der haeufigste Einzelklang-Usecase ist "X Min. vor Ende".
- **Verhaltensmatrix**:

| Wiederholen | Vom Ende | Beispiel (20 Min., 5 Min. Intervall) |
|-------------|----------|---------------------------------------|
| AN          | AUS      | Klaenge bei 5:00, 10:00, 15:00       |
| AN          | AN       | Klaenge bei 5:00, 10:00, 15:00 vor Ende |
| AUS         | (immer vom Ende) | 1 Klang bei 15:00 (= 5 vor Ende) |

- **Vom-Ende-Rechnung**: 23 Min., 5 Min. Intervall → Klaenge bei 3:00, 8:00, 13:00, 18:00. Erster Klang ist der "Rest" (23 mod 5 = 3), danach regelmaessig.
- **5-Sekunden-Schutz**: Bestehende Logik `remainingSeconds > 0` auf `remainingSeconds > 5` erhoehen, um Kollision mit Ende-Gong zu vermeiden.
