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
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

**Datenmodell**
- [ ] Intervall frei waehlbar von 1 bis 60 Minuten (statt fest 3/5/10)
- [ ] IntervalMode Enum: REPEATING (Default), AFTER_START, BEFORE_END
- [ ] Eigener Sound fuer Intervallklaenge, unabhaengig vom Start/Ende-Gong
- [ ] Bestehende Einstellungen migrieren sauber (keine Datenverluste)

**Intervall-Logik**
- [ ] REPEATING: Klaenge bei jedem vollen Intervall vom Start (5:00, 10:00, 15:00, ...)
- [ ] AFTER_START: Genau 1 Klang X Minuten nach Start
- [ ] BEFORE_END: Genau 1 Klang X Minuten vor Ende
- [ ] Kein Klang wenn Intervall >= Meditation (kein Fehler, kein Warning)
- [ ] Kein Intervall-Klang in den letzten 5 Sekunden (Kollision mit Ende-Gong vermeiden)

**Settings-UI**
- [ ] Intervallklaenge bekommen eine eigene Section (getrennt von Gong-Section)
- [ ] Stepper fuer Intervall 1-60 Min. (statt Dropdown)
- [ ] IntervalMode-Auswahl: Segmented Button (Android) / Picker(.menu) (iOS) mit 3 Optionen
- [ ] Sound-Picker fuer Intervall-Sound (5 Optionen: bisherige 4 + "Sanfter Intervallton")
- [ ] Lautstaerkeregler fuer Intervall-Sound
- [ ] Dynamische Beschreibung unter dem Intervall-Toggle zeigt aktuelle Konfiguration

**Dynamische Beschreibung**

| IntervalMode | DE | EN |
|--------------|----|----|
| REPEATING | "Alle X Min., {Soundname}" | "Every X min, {Soundname}" |
| AFTER_START | "X Min. nach Start, {Soundname}" | "X min after start, {Soundname}" |
| BEFORE_END | "X Min. vor Ende, {Soundname}" | "X min before end, {Soundname}" |
| Toggle AUS | Statische Beschreibung (wie bisher) | Statische Beschreibung (wie bisher) |

**Sound-Optionen**
- [ ] 5. Sound "Sanfter Intervallton" / "Soft Interval Tone" (bestehende `interval.mp3`)
- [ ] Sound-Vorhoeren bei Auswahl

**Zustaende der UI**

| Zustand | Sichtbar |
|---------|----------|
| Intervallklaenge AUS | Nur Toggle + statische Beschreibung |
| REPEATING (Default) | Toggle, Stepper, IntervalMode-Selector, Sound-Picker, Volume |
| AFTER_START | Toggle, Stepper, IntervalMode-Selector, Sound-Picker, Volume |
| BEFORE_END | Toggle, Stepper, IntervalMode-Selector, Sound-Picker, Volume |

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
- [ ] `dev-docs/reference/glossary.md` — `intervalMinutes` Range 3/5/10 → 1-60, neue Felder (`repeating`, `fromEnd`, `intervalSoundId`), `validateInterval()` aktualisieren
- [ ] `dev-docs/architecture/ddd.md` — "Intervall-Gong-Zyklus" Section: 3 Modi dokumentieren, `shouldPlayIntervalGong()` Logik, 5-Sekunden-Schutz
- [ ] `dev-docs/architecture/audio-system.md` — "alle 3/5/10 Minuten" → flexibel 1-60, drei Abspielmodi, separater Sound
- [ ] `dev-docs/concepts/timer-presets.md` — `TimerPreset` Datenmodell um neue Felder erweitern
- [ ] `dev-docs/release/STORE_CONTENT_IOS.md` — Feature-Beschreibung "3/5/10" → "1-60 min"

---

## UI-Mockup: Settings Sheet

### Gesamte Settings-Sheet Struktur (Soll-Zustand)

Die Section-Reihenfolge bleibt gleich, nur "Gong" wird aufgeteilt:

```
┌──────────────────────────────────────────────┐
│  Einstellungen                      [Fertig] │
└──────────────────────────────────────────────┘

  VORBEREITUNGSZEIT
┌──────────────────────────────────────────────┐
│  Zeit zum Ankommen vor         ┌────┐        │
│  der Meditation                │ ON │        │
│                                └────┘        │
│  Dauer              [ 15 Sekunden  ▾]        │
└──────────────────────────────────────────────┘

  GONG
┌──────────────────────────────────────────────┐
│  Gong-Ton           [ Tempelglocke   ▾]      │
│                                              │
│  🔉━━━━━━━━━━━●━━━━━━🔊                     │
└──────────────────────────────────────────────┘

  INTERVALLKLAENGE                    ← NEU: eigene Section
┌──────────────────────────────────────────────┐
│                                              │
│    (Inhalt je nach Zustand — siehe unten)     │
│                                              │
└──────────────────────────────────────────────┘

  KLANGKULISSE
┌──────────────────────────────────────────────┐
│  Klang              [ Stille         ▾]      │
└──────────────────────────────────────────────┘

  ERSCHEINUNGSBILD
┌──────────────────────────────────────────────┐
│  Farbthema   [Kerzenschein] [Wald] [Mond]    │
│  Darstellung [System] [Hell] [Dunkel]        │
└──────────────────────────────────────────────┘
```

### Intervallklaenge Section — 3 Zustaende (+ AUS)

#### Zustand: AUS (collapsed)

```
  INTERVALLKLAENGE
┌──────────────────────────────────────────────┐
│  Ein Gong-Klang in             ┌─────┐       │
│  regelmaessigen Abstaenden     │ OFF │       │
│  waehrend der Meditation       └─────┘       │
└──────────────────────────────────────────────┘
```

#### Zustand: AN — REPEATING (Default)

```
  INTERVALLKLAENGE
┌──────────────────────────────────────────────┐
│  Alle 5 Min., Tempelglocke    ┌─────┐       │
│                                │  ON │       │
│                                └─────┘       │
│                                              │
│  ──────────────────────────────────────────  │
│                                              │
│  Intervall       [ - ]   5 Min.   [ + ]      │
│                                              │
│  [Regelmaessig] [Nach Start] [Vor Ende]      │
│                                              │
│  ──────────────────────────────────────────  │
│                                              │
│  Klang              [ Tempelglocke   ▾]      │
│                                              │
│  🔉━━━━━━━━●━━━━━━━━🔊                      │
└──────────────────────────────────────────────┘
  → Ergebnis (20 Min.): Klaenge bei 5:00, 10:00, 15:00
```

#### Zustand: AN — AFTER_START

```
  INTERVALLKLAENGE
┌──────────────────────────────────────────────┐
│  5 Min. nach Start,            ┌─────┐       │
│  Tempelglocke                  │  ON │       │
│                                └─────┘       │
│                                              │
│  ──────────────────────────────────────────  │
│                                              │
│  Intervall       [ - ]   5 Min.   [ + ]      │
│                                              │
│  [Regelmaessig] [Nach Start] [Vor Ende]      │
│                                              │
│  ──────────────────────────────────────────  │
│                                              │
│  Klang              [ Tempelglocke   ▾]      │
│                                              │
│  🔉━━━━━━━━●━━━━━━━━🔊                      │
└──────────────────────────────────────────────┘
  → Ergebnis (20 Min.): 1 Klang bei 5:00
```

#### Zustand: AN — BEFORE_END

```
  INTERVALLKLAENGE
┌──────────────────────────────────────────────┐
│  5 Min. vor Ende,              ┌─────┐       │
│  Tempelglocke                  │  ON │       │
│                                └─────┘       │
│                                              │
│  ──────────────────────────────────────────  │
│                                              │
│  Intervall       [ - ]   5 Min.   [ + ]      │
│                                              │
│  [Regelmaessig] [Nach Start] [Vor Ende]      │
│                                              │
│  ──────────────────────────────────────────  │
│                                              │
│  Klang              [ Tempelglocke   ▾]      │
│                                              │
│  🔉━━━━━━━━●━━━━━━━━🔊                      │
└──────────────────────────────────────────────┘
  → Ergebnis (20 Min.): 1 Klang bei 15:00
```

### Stepper-Verhalten

```
  Minimum:        [ - ]   1 Min.   [ + ]     ← [-] disabled/grau
  Normal:         [ - ]   5 Min.   [ + ]
  Maximum:        [ - ]  60 Min.   [ + ]     ← [+] disabled/grau
```

- Tap auf [-]/[+]: Aendert um 1 Minute
- Long-Press: Beschleunigtes Aendern (Plattform-nativ)
- Haptic Feedback bei Tap

### Sound-Picker Dropdown (geoeffnet)

```
  Klang              [ Tempelglocke   ▾]
                     ┌─────────────────────┐
                     │  Tempelglocke    ✓  │
                     │  Klassisch          │
                     │  Tiefe Resonanz     │
                     │  Klarer Anschlag    │
                     │  Sanfter Intervall- │
                     │  ton                │
                     └─────────────────────┘
```

Sound-Vorhoeren: Bei Tap auf einen Eintrag wird der Sound kurz abgespielt.

### Vergleich: Vorher → Nachher

#### VORHER (Ist-Zustand)
```
  GONG
┌──────────────────────────────────────────────┐
│  Gong-Ton           [ Tempelglocke   ▾]      │
│  🔉━━━━━━━━━━━●━━━━━━🔊                     │
│                                              │
│  ──────────────────────────────────────────  │
│                                              │
│  Ein Gong-Klang in             ┌─────┐       │
│  regelmaessigen Abstaenden     │  ON │       │
│  waehrend der Meditation       └─────┘       │
│                                              │
│  🔉━━━━━━━━●━━━━━━━━🔊                      │
│                                              │
│  Intervall          [  5 Minuten     ▾]      │
└──────────────────────────────────────────────┘
```

#### NACHHER (Soll-Zustand)
```
  GONG
┌──────────────────────────────────────────────┐
│  Gong-Ton           [ Tempelglocke   ▾]      │
│  🔉━━━━━━━━━━━●━━━━━━🔊                     │
└──────────────────────────────────────────────┘

  INTERVALLKLAENGE
┌──────────────────────────────────────────────┐
│  Alle 5 Min., Tempelglocke    ┌─────┐       │
│                                │  ON │       │
│                                └─────┘       │
│                                              │
│  ──────────────────────────────────────────  │
│                                              │
│  Intervall       [ - ]   5 Min.   [ + ]      │
│                                              │
│  [Regelmaessig] [Nach Start] [Vor Ende]      │
│                                              │
│  ──────────────────────────────────────────  │
│                                              │
│  Klang              [ Tempelglocke   ▾]      │
│                                              │
│  🔉━━━━━━━━●━━━━━━━━🔊                      │
└──────────────────────────────────────────────┘
```

---

## Manueller Test

### REPEATING (Default)
1. Settings oeffnen, Intervallklaenge aktivieren
2. Intervall auf 5 Min. stellen, Modus "Regelmaessig"
3. 20-Min-Meditation starten
4. Erwartung: Klaenge bei 5:00, 10:00, 15:00 verstrichener Zeit

### AFTER_START
1. Intervall 5 Min., Modus "Nach Start"
2. 20-Min-Meditation starten
3. Erwartung: Genau 1 Klang bei 5:00 verstrichener Zeit

### BEFORE_END
1. Intervall 5 Min., Modus "Vor Ende"
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
| IntervalMode-Auswahl | Picker(.menu) | SingleChoiceSegmentedButtonRow (Material3) |
| Stepper | Nativer `Stepper(value:in:)` | Custom Row mit -/+ Buttons (Material3) |
| Sound-Picker | Nativer Picker | ExposedDropdownMenuBox |
| Section-Trennung | Eigene List-Section | Eigene Card |

---

## Referenz

- Bestehende Intervall-Gong-Logik als Ausgangspunkt
- Bestehende `interval.mp3` wird als 5. Sound-Option wiederverwendet

---

## Hinweise

- **IntervalMode Enum**: Ersetzt das fruehere Boolean-Paar (`intervalRepeating` + `intervalFromEnd`). 3 selbsterklaerende Werte statt 4 Boolean-Kombinationen (davon 1 sinnlos).
- **Verhaltensmatrix**:

| IntervalMode | Beispiel (20 Min., 5 Min. Intervall) |
|--------------|---------------------------------------|
| REPEATING    | Klaenge bei 5:00, 10:00, 15:00       |
| AFTER_START  | 1 Klang bei 5:00                     |
| BEFORE_END   | 1 Klang bei 15:00 (= 5 vor Ende)    |

- **5-Sekunden-Schutz**: Bestehende Logik `remainingSeconds > 0` auf `remainingSeconds > 5` erhoehen, um Kollision mit Ende-Gong zu vermeiden.
