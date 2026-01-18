# Ticket ios-030: Screenshot-Tests ohne Launch-Arguments

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Was

Screenshot-Tests sollen ohne Launch-Arguments (`-CountdownDuration`) funktionieren. Stattdessen soll das Screenshots-Target die Settings direkt vorkonfigurieren.

## Warum

- Weniger Code in der Haupt-App (Launch-Argument-Parsing entfernen)
- Konsistenter Ansatz: TestFixtureSeeder konfiguriert bereits Meditations-Fixtures
- Einfachere Wartung: Settings-Logik an einem Ort im Screenshots-Target
- Screenshot-Test `testScreenshot02_timerRunning` dauert aktuell 22 Sekunden - Optimierung moeglich

---

## Akzeptanzkriterien

### Feature
- [x] Screenshots-Target startet mit deaktivierter Vorbereitungszeit
- [x] Screenshots-Target startet mit passenden Default-Settings fuer Screenshots
- [x] Launch-Argument `-CountdownDuration` aus App entfernt
- [x] Launch-Argument `-PreparationTimeSeconds` aus App entfernt (Legacy)
- [x] `testScreenshot02_timerRunning` laeuft schneller (Ziel: <15s statt 22s)

### Tests
- [x] `make screenshots` funktioniert wie bisher
- [x] Normale App-Starts unveraendert (keine Regression)

### Dokumentation
- [x] Fastlane-Guide aktualisiert (dev-docs/guides/fastlane-ios.md)

---

## Manueller Test

1. `cd ios && make screenshots`
2. Screenshots werden generiert
3. Timer-Screenshot zeigt laufenden Timer ohne Vorbereitungsphase

---

## Referenz

- iOS: `ios/StillMoment-Screenshots/TestFixtureSeeder.swift` - Bestehender Fixture-Seeder
- iOS: `ios/StillMomentUITests/ScreenshotTests.swift` - Screenshot-Tests

---

## Hinweise

- Settings koennen via UserDefaults im Screenshots-Target vorkonfiguriert werden
- Der Hauptzeitfresser ist das Warten auf Timer-Label `'00:5[0-9]'` - kann durch `Thread.sleep` oder direktes Snapshot ersetzt werden
