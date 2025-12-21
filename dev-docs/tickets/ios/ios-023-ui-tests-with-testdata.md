# Ticket ios-023: UI Tests mit Testdaten (Library/Player)

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: shared-007, ios-012
**Phase**: 5-QA

---

## Was

UI Tests fuer befuellte Library, Player-Ansicht und Edit-Sheet ergaenzen. Dafuer muss ein Mechanismus geschaffen werden, um Testdaten (Mock-Meditationen) in die App zu injizieren.

## Warum

Aktuell testen die UI Tests nur den Empty State der Library. Die wichtigsten User-Flows (Meditation abspielen, bearbeiten, loeschen) sind nicht automatisiert getestet. Das sind zentrale Features der App.

---

## Akzeptanzkriterien

- [ ] Testdaten-Injection via Launch Arguments oder Test-Bundle
- [ ] UI Test: Befuellte Library mit gruppierten Meditationen
- [ ] UI Test: Player oeffnen und Play/Pause/Skip bedienen
- [ ] UI Test: Edit-Sheet oeffnen, Felder bearbeiten, speichern
- [ ] UI Test: Meditation loeschen mit Confirmation Dialog
- [ ] Alle Tests laufen stabil im CI

---

## Manueller Test

1. `make test-ui` ausfuehren
2. Im Simulator beobachten: Befuellte Library, Player, Edit-Sheet sichtbar
3. Erwartung: Alle neuen Tests bestehen, keine Flakiness

---

## Referenz

- Existierende UI Tests: `ios/StillMomentUITests/LibraryFlowUITests.swift`
- Launch Arguments Pattern: `app.launchArguments = ["-TestMode", "withData"]`
- Models: `ios/StillMoment/Domain/Models/GuidedMeditation.swift`

---

## Hinweise

Moegliche Ansaetze fuer Testdaten-Injection:

1. **Launch Arguments + In-Memory Repository**: App erkennt `-TestMode` und verwendet Mock-Repository
2. **Test-Bundle mit Audio-Datei**: Kleine MP3 im Test-Target, wird beim Test-Start importiert
3. **UserDefaults Reset + Seed**: Simulator zuruecksetzen, dann feste Testdaten schreiben

Empfehlung: Option 1 (Launch Arguments) ist am saubersten und schnellsten.

---
