# Ticket android-035: Edit Sheet State Extraktion + Unit Tests

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Was

1. Edit-Logik aus `MeditationEditSheet` Composable in separaten `EditSheetState` extrahieren
2. Unit Tests fuer die extrahierte Logik

## Warum

Aktuell ist die Edit-Logik (hasChanges, customTeacher/customName Handling) direkt im Composable eingebettet. Das macht Tests schwierig und erfordert die schwerfaellige Compose Testing API.

Durch Extraktion der Logik in ein separates State-Objekt:
- Einfache Unit-Tests ohne Compose-Dependencies
- Konsistenz mit iOS-Architektur (`EditSheetState.swift`)
- Bessere Separation of Concerns
- Schnellere, stabilere Tests

---

## Akzeptanzkriterien

### Refactoring
- [x] `EditSheetState` data class in Domain/Models erstellen
- [x] Logik aus Composable extrahieren: hasChanges, isValid, applyChanges(), reset()
- [x] `MeditationEditSheet` verwendet `EditSheetState`

### Unit Tests (EditSheetStateTest.kt)
- [x] Test: hasChanges ist false bei unveraenderten Werten
- [x] Test: hasChanges ist true bei geaenderten Werten
- [x] Test: isValid ist false bei leerem Teacher oder Name
- [x] Test: isValid ist true bei ausgefuellten Feldern
- [x] Test: applyChanges() setzt customTeacher/customName nur wenn geaendert
- [x] Test: applyChanges() setzt keine custom-Werte bei unveraenderten Feldern
- [x] Test: reset() setzt Werte auf Original zurueck

---

## Manueller Test

1. `./gradlew test` ausfuehren
2. Erwartung: EditSheetStateTest Tests passen
3. Edit Sheet im Emulator testen - Verhalten unveraendert

---

## Referenz

- iOS: `EditSheetState.swift` (Domain/Models) - Vorlage fuer Extraktion
- iOS Tests: `ios-018-edit-sheet-tests.md` (IN PROGRESS)

---

## Hinweise

Die Compose Testing API ist fuer UI-Integration-Tests gedacht, nicht fuer Logik-Tests. Durch die Extraktion werden die Tests:
- Schneller (keine UI-Rendering)
- Stabiler (keine Timing-Issues)
- Einfacher zu schreiben und zu warten

---

<!-- Erstellt via View Quality Review, aktualisiert fuer Architektur-Konsistenz -->
