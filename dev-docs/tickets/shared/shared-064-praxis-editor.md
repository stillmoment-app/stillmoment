# Ticket shared-064: Praxis-Editor und Settings-Abloesung

**Status**: [~] IN PROGRESS
**Prioritaet**: HOCH
**Aufwand**: iOS ~6 | Android ~6
**Phase**: 3-Feature
**Ursprung**: shared-051 (aufgeteilt)

---

## Was

Fullscreen-Editor fuer Praxis-Presets mit chronologischer Sektions-Anordnung (Vorbereitung → Audio → Gongs). Ersetzt das bisherige Timer-Settings-Sheet fuer Timer-spezifische Konfiguration. Das Settings-Zahnrad auf dem Timer Screen entfaellt.

## Warum

Die Timer-Konfiguration wird durch die chronologische Anordnung intuitiver — der User konfiguriert seine Meditation in der Reihenfolge, in der sie ablaufen wird. Gleichzeitig wird das ueberladene Settings-Sheet aufgeloest: globale Settings leben im Einstellungen-Tab (shared-061), Timer-Settings im Praxis-Editor.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | shared-061, shared-063 |
| Android   | [ ]    | shared-061, shared-063 |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

#### Editor-Struktur
- [x] Fullscreen-Navigation (Push, nicht Modal) mit Navigation-Bar: "Abbrechen" / Titel "Praxis bearbeiten" / "Fertig"
- [x] Textfeld fuer Praxis-Name (bearbeitbar)
- [x] Dauer-Picker (1-60 Minuten) — Standard-Dauer der Praxis, kann auf dem Timer Screen vor Start angepasst werden
- [x] Sektion "Vorbereitung" mit Sanduhr-Icon: Toggle an/aus + Dauer-Picker (5/10/15/20/30/45s)
- [x] Sektion "Audio & Klaenge" mit Wind-Icon: Row "Einstimmung" (zeigt aktuelle Auswahl, Chevron → Sub-Screen), Row "Hintergrundklang" (zeigt aktuelle Auswahl, Chevron → Sub-Screen)
- [x] Sektion "Gongs" mit Glocken-Icon: Row "Start & Ende" (zeigt aktuelle Auswahl, Chevron → Sub-Screen), Row "Intervall-Gongs" (zeigt aktuelle Auswahl, Chevron → Sub-Screen)
- [x] "Praxis loeschen" Button am Ende (Rot, mit Bestaetigungsdialog)
- [x] Sektions-Icons in gedaempfter Farbe (textSecondary / slate-400)

#### Sub-Screens
- [x] Einstimmung: "Ohne Einstimmung", mitgelieferte Einstimmungen, Checkmark bei aktiver Auswahl
- [x] Hintergrundklang: "Stille (Kein Hintergrund)", mitgelieferte Klaenge, Volume-Slider, Checkmark bei aktiver Auswahl
- [x] Start & Ende Gong: Gong-Auswahl mit Checkmark, Volume-Slider, Vorhoer-Funktion
- [x] Intervall-Gongs: Toggle an/aus, Intervall-Dauer (Stepper), Modus (Repeating/After Start/Before End), Sound-Auswahl, Volume-Slider

#### Settings-Abloesung
- [x] Timer-spezifische Settings (Vorbereitung, Gongs, Audio) aus altem Settings-Sheet entfernt
- [x] Settings-Zahnrad auf Timer Screen entfaellt — Praxis-Pill ist der Einstiegspunkt
- [x] Timer liest Konfiguration aus aktiver Praxis (statt aus globalem MeditationSettings)
- [x] "Fertig" speichert Aenderungen in der Praxis
- [x] "Abbrechen" verwirft Aenderungen

#### Allgemein
- [x] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android
- [x] Accessibility: Labels und Hints auf allen interaktiven Elementen

### Tests
- [x] Unit Tests iOS (Editor-State, Speichern/Abbrechen, Validierung)
- [ ] Unit Tests Android (Editor-State, Speichern/Abbrechen, Validierung)

### Dokumentation
- [x] CHANGELOG.md
- [x] Audio-System Doku aktualisieren (neuer Konfigurationspfad)

---

## Manueller Test

1. Pill "Praxis: Standard" → Kontextmenue → "Bearbeiten"
2. Editor oeffnet sich: Name "Standard", Sektionen Vorbereitung/Audio/Gongs sichtbar
3. Name aendern auf "Abend-Meditation" → "Fertig" → Pill zeigt neuen Namen
4. Editor oeffnen → Vorbereitung deaktivieren → "Fertig" → Meditation starten → keine Vorbereitung
5. Editor oeffnen → Gong aendern → "Fertig" → Meditation starten → neuer Gong
6. Editor oeffnen → "Abbrechen" → Aenderungen verworfen
7. Hintergrundklang-Sub-Screen: Sound auswaehlen, Volume einstellen
8. "Praxis loeschen" → Bestaetigungsdialog → zurueck zur Praxis-Auswahl
9. Timer Screen: kein Settings-Zahnrad mehr sichtbar
10. Meditation starten → laeuft mit Konfiguration der aktiven Praxis

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Editor-Navigation | NavigationStack push | NavHost navigate |
| Sub-Screens | NavigationLink | Navigation composable |
| Sektions-Layout | Grouped List / Form | Cards mit Sections |

---

## Referenz

- UI-Prototype: `dev-docs/ui-prototype.html` (EditPresetScreen, SelectIntroScreen, SelectBackgroundScreen)
- Bestehende Settings-Controls (Picker, Slider, Stepper, Toggle) koennen wiederverwendet werden

---

## Hinweise

- Die bestehenden Settings-Controls (Volume-Slider, Gong-Picker, Interval-Stepper etc.) existieren bereits — sie muessen in den neuen Editor-Kontext umgezogen werden, nicht neu gebaut.
- Die Sub-Screens fuer Einstimmung und Hintergrundklang zeigen in diesem Ticket nur mitgelieferte Sounds. Custom Audio Import kommt in shared-065.
- Vorhoer-Funktion fuer Gongs und Background existiert bereits im alten Settings-Sheet — wiederverwenden.
- "Neue Praxis erstellen" (aus shared-063) oeffnet diesen Editor mit Default-Werten und leerem Namen.
- Nach Loeschen der Praxis: Falls aktive Praxis geloescht wird, automatisch auf die erste verbleibende Praxis wechseln.
