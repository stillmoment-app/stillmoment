# Ticket ios-030: Screenshot-Tests ohne Launch-Arguments

**Status**: [ ] TODO
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
- [ ] Screenshots-Target startet mit deaktivierter Vorbereitungszeit
- [ ] Screenshots-Target startet mit passenden Default-Settings fuer Screenshots
- [ ] Launch-Argument `-CountdownDuration` aus App entfernt
- [ ] Launch-Argument `-PreparationTimeSeconds` aus App entfernt (Legacy)
- [ ] `testScreenshot02_timerRunning` laeuft schneller (Ziel: <15s statt 22s)

### Tests
- [ ] `make screenshots` funktioniert wie bisher
- [ ] Normale App-Starts unveraendert (keine Regression)

### Dokumentation
- [ ] CHANGELOG.md (interne Verbesserung)

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
