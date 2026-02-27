# Ticket shared-050: Optionale Einleitung fuer Meditationstimer

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~M | Android ~M
**Phase**: 3-Feature

---

## Was

Der Meditationstimer bekommt eine optionale Einleitung (z.B. gefuehrte Atemuebung), die nach dem Start-Gong abgespielt wird. Die Einleitung zaehlt zur Gesamtmeditationszeit. Einleitungen sind fest in der App gebundelt und werden ueber eine Auswahl-Liste in den Timer-Einstellungen konfiguriert.

## Warum

Vor allem Einsteiger profitieren von einer kurzen gefuehrten Einfuehrung (z.B. Atem-Anleitung) bevor die stille Meditation beginnt. Die Einleitung hilft beim Ankommen und erspart den Wechsel zu einer separaten gefuehrten Meditation.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen -->

### Feature (beide Plattformen)

#### Domain-Modell
- [ ] Einleitung ist ein eigenes Value Object (ID, lokalisierter Name, Dauer, Audio-Ressource)
- [ ] Einleitungen haben eine sprachuebergreifend konstante ID (z.B. `breath`)
- [ ] Pro Sprache existieren Audio-Dateien fuer eine ID (oder nicht)
- [ ] In `MeditationSettings` wird nur die Einleitungs-ID gespeichert (nicht die Sprache)
- [ ] `TimerState` bekommt neuen State `.introduction` (State Machine: `idle → preparation → introduction → running → completed`)
- [ ] Verfuegbare Einleitungen werden per Konfigurationsdatei definiert (ID, lokalisierter Name, Dauer, verfuegbare Sprachen, Audio-Dateiname). Umsetzung plattformspezifisch

#### Konfiguration
- [ ] Timer-Settings zeigt neue Section "Einleitung" (zwischen Gong und Intervallklaenge)
- [ ] Auswahl-Liste mit verfuegbaren Einleitungen (gefiltert nach Geraetesprache)
- [ ] Default-Auswahl: "Keine" (keine Einleitung)
- [ ] Erste verfuegbare Einleitung: "Atemuebung" (ID: `breath`, Dauer: 1:35)
- [ ] Einstellung wird persistent gespeichert

```
Einordnung in bestehende Settings (chronologisch nach Meditationsablauf):

┌─────────────────────────────────────┐
│           Einstellungen        Done │
├─────────────────────────────────────┤
│ VORBEREITUNGSZEIT                   │
│ ┌─────────────────────────────────┐ │
│ │ Vorbereitungszeit          [ON] │ │
│ │ Countdown vor dem Start         │ │
│ ├─────────────────────────────────┤ │
│ │   Dauer                   15 s ▾│ │
│ └─────────────────────────────────┘ │
│                                     │
│ GONG                                │
│ ┌─────────────────────────────────┐ │
│ │ Gong-Ton        Tempelglocke  ▾│ │
│ ├─────────────────────────────────┤ │
│ │ 🔈 ━━━━━━━━━●━━━━━━━━━━━━ 🔊  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ EINLEITUNG                     ← NEU
│ ┌─────────────────────────────────┐ │
│ │ Einleitung      Atemuebung   ▾│ │
│ │                        (1:35)   │ │
│ └─────────────────────────────────┘ │
│                                     │
│   Picker-Optionen:                  │
│   ┌───────────────────────┐         │
│   │ ○ Keine               │         │
│   │ ● Atemuebung  (1:35)  │         │
│   └───────────────────────┘         │
│                                     │
│ INTERVALLKLAENGE                    │
│ ┌─────────────────────────────────┐ │
│ │ Intervallklaenge          [OFF] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ KLANGKULISSE                        │
│ ┌─────────────────────────────────┐ │
│ │ Klangkulisse           Stille ▾│ │
│ └─────────────────────────────────┘ │
│                                     │
│ ALLGEMEIN                           │
│ ┌─────────────────────────────────┐ │
│ │ Farbthema / Darstellung         │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Section wird NICHT angezeigt wenn   │
│ keine Einleitungen fuer die         │
│ Geraetesprache verfuegbar sind.     │
└─────────────────────────────────────┘
```

#### Wiedergabe-Verhalten
- [ ] Reihenfolge: Vorbereitungszeit → Start-Gong → (Gong fertig) → Einleitung → stille Meditation → End-Gong
- [ ] Einleitung startet erst nach dem Start-Gong (sequenziell, nicht gleichzeitig)
- [ ] Einleitung zaehlt zur Gesamtmeditationszeit (Beispiel: 10 Min Timer + 1:35 Einleitung = 1:35 Einleitung + 8:25 stille Meditation)
- [ ] Einleitung spielt mit `volume = 0.9` (leicht reduziert gegenueber voller Medienlauststaerke, kein eigener Regler)
- [ ] Kein visueller Unterschied waehrend der Einleitung (normaler Countdown)
- [ ] Einleitung ist nicht ueberspringbar (bewusste Designentscheidung: die konfigurierte Meditation laeuft durch wie zusammengestellt)
- [ ] Abbruch waehrend der Einleitung beendet die Meditation sofort
- [ ] Audio-Unterbrechung (Anruf, Siri): Einleitung setzt nach Unterbrechung fort wo sie war, Timer laeuft weiter
- [ ] Lock Screen: Uebergang Einleitung → stille Meditation (inkl. Start des Hintergrund-Sounds) funktioniert korrekt bei gesperrtem Bildschirm

#### Intervall-Gongs
- [ ] Intervall-Gongs zaehlen ab Ende der Einleitung (erster Gong = Intervall nach Start der stillen Phase)

#### Hintergrund-Sound-Interaktion
- [ ] Hintergrund-Sounds starten nie waehrend Vorbereitungszeit oder Einleitung — immer erst beim Uebergang zu `.running`
- [ ] Ohne Einleitung: Hintergrund-Sound startet nach Start-Gong (bei `preparationFinished`)
- [ ] Mit Einleitung: Hintergrund-Sound startet nach Ende der Einleitung (bei `introductionFinished`)
- [ ] Hintergrund-Sound startet mit 10-Sekunden-Fade-In fuer sanften Uebergang
- [ ] Einleitung haelt die Audio-Session selbst aktiv, gehoert zu `AudioSource.timer`

#### Mindestdauer
- [ ] Wenn eine Einleitung ausgewaehlt ist: Mindestdauer = ceil(Einleitungsdauer / 60) + 1 Minute (z.B. Atemuebung 1:35 → Minimum 3 Minuten)
- [ ] Timer-Dauerauswahl beginnt bei Mindestdauer statt bei 1 Minute
- [ ] Aenderung der Einleitung passt die gewaehlte Dauer automatisch an, falls diese unter der neuen Mindestdauer liegt
- [ ] Ohne Einleitung: Mindestdauer bleibt 1 Minute (unveraendertes Verhalten)

#### Sprachwechsel-Verhalten
- [ ] Einleitungs-Auswahl zeigt nur Einleitungen die fuer die aktuelle Geraetesprache verfuegbar sind
- [ ] Wenn keine Einleitungen fuer die Geraetesprache existieren: Section "Einleitung" wird nicht angezeigt
- [ ] Bei Sprachwechsel: Wenn gespeicherte Einleitungs-ID in neuer Sprache verfuegbar → beibehalten, sonst → auf "Keine" zurueckfallen

### Tests
- [ ] Unit Tests iOS
- [ ] Unit Tests Android
- [ ] Automatisierter Test: Timer-Reducer spielt Einleitung nach Start-Gong, dann Hintergrund-Sound
- [ ] Automatisierter Test: Mindestdauer = ceil(Einleitungsdauer/60) + 1 Minute bei aktiver Einleitung
- [ ] Automatisierter Test: Intervall-Gongs zaehlen ab Ende der Einleitung
- [ ] Automatisierter Test: Ohne Einleitung unveraendertes Verhalten
- [ ] Automatisierter Test: Sprachwechsel-Fallback auf "Keine"

### Dokumentation
- [ ] CHANGELOG.md
- [ ] GLOSSARY.md (neuer Begriff "Einleitung" / Introduction)
- [ ] dev-docs/architecture/ddd.md (TimerReducer/TimerState um Einleitungs-Phase)
- [ ] dev-docs/architecture/audio-system.md (Einleitung im Audio-Flow)
- [ ] dev-docs/release/TEST_PLAN_IOS.md (manuelle Testfaelle)
- [ ] dev-docs/release/TEST_PLAN_ANDROID.md (manuelle Testfaelle)

---

## Manueller Test

### Test 1: Einleitung mit ausreichend Meditationszeit
1. Timer-Settings oeffnen
2. Einleitung "Atemuebung" auswaehlen
3. Meditationszeit auf 10 Minuten setzen
4. Timer starten
5. Erwartung: Start-Gong spielt fertig → dann Einleitung spielt → nach Einleitung laeuft Meditation weiter → Timer zaehlt durchgehend runter

### Test 2: Mindestdauer bei aktiver Einleitung
1. Einleitung "Atemuebung" auswaehlen (Dauer 1:35)
2. Timer-Dauerauswahl pruefen
3. Erwartung: Mindestdauer ist 3 Minuten (Dauerauswahl beginnt bei 3 statt bei 1)
4. Meditationszeit auf 3 Minuten setzen, Timer starten
5. Erwartung: Start-Gong spielt fertig → Einleitung (1:35) → stille Meditation (1:25) → End-Gong

### Test 3: Einleitung mit Hintergrund-Sound
1. Einleitung "Atemuebung" auswaehlen
2. Hintergrund-Sound "Wald" auswaehlen
3. Timer starten
4. Erwartung: Start-Gong spielt fertig → Einleitung spielt (ohne Hintergrund-Sound) → nach Einleitung startet Hintergrund-Sound

### Test 4: Keine Einleitung
1. Einleitung auf "Keine" setzen
2. Timer starten
3. Erwartung: Verhalten wie bisher (keine Aenderung)

### Test 5: Einleitung bei gesperrtem Bildschirm
1. Einleitung "Atemuebung" auswaehlen
2. Hintergrund-Sound "Wald" auswaehlen
3. Meditationszeit auf 10 Minuten setzen
4. Timer starten, sofort Bildschirm sperren
5. Erwartung: Start-Gong spielt fertig → Einleitung spielt im Hintergrund → nach Einleitung startet Hintergrund-Sound → Timer laeuft weiter bis End-Gong

### Test 6: Sprachwechsel
1. Geraetesprache Deutsch, Einleitung "Atemuebung" auswaehlen
2. Geraetesprache auf Englisch wechseln
3. Timer-Settings oeffnen
4. Erwartung: Section "Einleitung" nicht sichtbar (keine englischen Einleitungen vorhanden)
5. Timer starten
6. Erwartung: Keine Einleitung spielt (Fallback auf "Keine")

---

## Hinweise

- Erstes Audio-Asset: `intro-breath-de.mp3` (Atemuebung, Deutsch, 1:35)
- Audio-Dateien werden als App-Bundle-Assets ausgeliefert (nicht user-importierbar)
- Architektur soll erweiterbar sein fuer weitere Einleitungen und Sprachen
- Namenskonvention Audio-Dateien: `intro-{id}-{sprache}.mp3` (z.B. `intro-breath-de.mp3`, `intro-breath-en.mp3`)
- Registry/Konfiguration mit ID, Dauer, verfuegbaren Sprachen, Audio-Dateinamen (Umsetzung plattformspezifisch)
- Einleitung startet sequenziell nach dem Start-Gong (via `startGongFinished` Action / `gongCompletionPublisher`)

---

<!--
WAS NICHT INS TICKET GEHOERT:
- Kein Code (Claude Code schreibt den selbst)
- Keine separaten iOS/Android Subtasks mit Code
- Keine Dateilisten (Claude Code findet die Dateien)

Claude Code arbeitet shared-Tickets so ab:
1. Liest Ticket fuer Kontext
2. Implementiert iOS (oder Android) komplett
3. Portiert auf andere Plattform mit Referenz
-->
