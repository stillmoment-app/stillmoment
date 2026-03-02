# Ticket shared-072: Einstimmung Toggle statt Picker-Option "Ohne Einstimmung"

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: iOS ~S | Android ~S
**Phase**: 4-Polish

---

## Was

Die Einstimmungs-Einstellung im Timer soll statt eines Pickers mit "Keine" als erster Option ein Toggle (an/aus) und einen bedingten Inhalts-Picker (sichtbar nur wenn an) verwenden.

## Warum

Vorbereitungszeit und Einstimmung sind beide optionale Timer-Phasen. Vorbereitungszeit nutzt bereits das Muster Toggle + bedingter Picker. Die Einstimmung weicht davon ab (Picker mit "Keine" als "aus"-Option), was inkonsistent ist. Ein Toggle kommuniziert "an/aus" klarer als eine Picker-Option.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-067 (Rename) |
| Android   | [x]    | shared-067 (Rename) |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

#### Aktuell (wird abgeloest)
```
EINSTIMMUNG
┌─────────────────────────────────┐
│ Einstimmung     Atemuebung   ▾ │
│                       (1:35)    │
└─────────────────────────────────┘
  Picker-Optionen:
  ○ Keine
  ● Atemuebung (1:35)
```

#### Neu (Ziel)
```
EINSTIMMUNG
┌─────────────────────────────────┐
│ Einstimmung             [OFF]   │  ← Toggle aus
└─────────────────────────────────┘

EINSTIMMUNG
┌─────────────────────────────────┐
│ Einstimmung              [ON]   │  ← Toggle an
├─────────────────────────────────┤
│   Inhalt        Atemuebung   ▾ │  ← Inhalts-Picker erscheint
│                       (1:35)    │
└─────────────────────────────────┘
```

#### Verhalten
- [ ] Einstimmungs-Section zeigt Toggle "Einstimmung" an/aus
- [ ] Bei Toggle aus: kein Inhalts-Picker sichtbar, keine Einstimmung wird abgespielt
- [ ] Bei Toggle an: Inhalts-Picker erscheint darunter (wie Dauer-Picker bei Vorbereitungszeit)
- [ ] Default beim ersten Aktivieren: erste verfuegbare Einstimmung vorausgewaehlt
- [ ] Benutzerauswahl bleibt gespeichert, auch wenn Toggle aus ist (beim Wiedereinschalten bleibt die letzte Auswahl erhalten)
- [ ] Visuell konsistent mit dem Vorbereitungszeit-Pattern
- [ ] Lokalisiert (DE + EN)

### Tests
- [ ] Unit Tests iOS (Toggle-Status, persistierte Auswahl bleibt bei Toggle-Wechsel)
- [ ] Unit Tests Android (Toggle-Status, persistierte Auswahl bleibt bei Toggle-Wechsel)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

### Test 1: Toggle aus → an → aus
1. Timer-Einstellungen oeffnen
2. Einstimmung-Toggle ist aus (Inhalts-Picker nicht sichtbar)
3. Toggle einschalten
4. Erwartung: Inhalts-Picker erscheint, "Atemuebung" ist vorausgewaehlt
5. Toggle ausschalten
6. Erwartung: Inhalts-Picker verschwindet

### Test 2: Auswahl bleibt gespeichert
1. Einstimmung aktivieren, "Atemuebung" ausgewaehlt
2. Toggle ausschalten
3. App neu starten, Timer-Einstellungen oeffnen
4. Toggle einschalten
5. Erwartung: "Atemuebung" ist weiterhin ausgewaehlt (nicht zurueckgesetzt)

### Test 3: Konsistenz mit Vorbereitungszeit
1. Vorbereitungszeit-Toggle und Einstimmungs-Toggle vergleichen
2. Erwartung: Identisches visuelles Muster (Toggle + bedingter Picker)

---

## Hinweise

- Analog zu Vorbereitungszeit (shared-023): Toggle ein/aus + bedingter Picker
- Kein Domain-Aenderung noetig — nur UI-Schicht (Picker mit "Keine" vs. Toggle + bedingter Picker)
- Wenn shared-067 (Code-Rename) noch offen: Terms "Einstimmung" / "Attunement" verwenden
- Abhaengigkeit von shared-067 gilt nur fuer die Benennung, nicht fuer die Logik

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
