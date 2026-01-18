# Ticket android-061: Timer Settings Repository Abstraktion

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: shared-024
**Phase**: 2-Architektur

---

## Was

TimerViewModel soll alle Settings-Zugriffe über das bestehende SettingsRepository abwickeln, statt direkt auf SettingsDataStore zuzugreifen.

## Warum

Clean Architecture Verletzung: ViewModels (Application Layer) sollen keine direkten Infrastructure-Zugriffe haben. Das `TimerViewModel` importiert und verwendet aktuell direkt `SettingsDataStore` fuer `hasSeenSettingsHint`.

Gefunden im Clean Architecture Review (shared-024).

---

## Akzeptanzkriterien

### Feature
- [ ] TimerViewModel importiert kein `SettingsDataStore` mehr
- [ ] `hasSeenSettingsHint` wird ueber SettingsRepository abgewickelt
- [ ] Bestehende Funktionalität bleibt erhalten (Onboarding-Hint)
- [ ] Keine Regression bei Settings-Handling

### Tests
- [ ] SettingsRepository Tests fuer neue Methoden
- [ ] TimerViewModel Tests mit Mock-Repository
- [ ] Bestehende Tests bleiben gruen

### Dokumentation
- [ ] Keine (interne Refaktorierung)

---

## Manueller Test

1. App frisch installieren (oder Daten loeschen)
2. Timer-Screen oeffnen
3. Erwartung: Settings-Hint Tooltip erscheint
4. Settings-Icon antippen
5. App beenden und neu starten
6. Erwartung: Settings-Hint erscheint nicht mehr

---

## Referenz

- Review-Ticket: shared-024 (Clean Architecture Layer-Review)
- iOS-Pendant: ios-032
- Bestehendes Repository: `SettingsRepository` / `SettingsDataStore`

---

## Hinweise

Das SettingsRepository-Protokoll im Domain Layer muss um die Methoden fuer `hasSeenSettingsHint` erweitert werden. Die Implementierung in SettingsDataStore existiert bereits - es fehlt nur die Abstraktion im Protokoll.
