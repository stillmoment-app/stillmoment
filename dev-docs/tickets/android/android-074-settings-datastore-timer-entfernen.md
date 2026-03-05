# Ticket android-074: SettingsDataStore als Timer-Quelle entfernen

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 1-Quick Fix

---

## Was

Custom Introduction (Einstimmung) wird im Timer als "No introduction" angezeigt, obwohl der User eine Datei ausgewaehlt hat. TimerViewModel soll nur noch PraxisDataStore als Quelle fuer Timer-Settings nutzen, nicht mehr den Legacy-SettingsDataStore.

## Warum

TimerViewModel sammelt parallel von zwei DataStores: `loadSettings()` (SettingsDataStore) und `observePraxis()` (PraxisDataStore). Wer zuletzt emittiert, gewinnt. Der SettingsDataStore filtert custom Attunement-IDs heraus (`Introduction.isAvailableForCurrentLanguage()` gibt false fuer UUIDs), setzt die ID auf null und damit `introductionEnabled` auf false. Das ueberschreibt die korrekte Auswahl aus dem PraxisDataStore.

Zusaetzlich: `hasSeenSettingsHint` und `SettingsHintTooltip` sind toter Code — der Tooltip wird in keinem Screen eingebunden.

---

## Akzeptanzkriterien

### Feature
- [ ] Custom Attunement bleibt nach Auswahl im PraxisEditor als Introduction sichtbar
- [ ] Built-in Introductions funktionieren weiterhin korrekt
- [ ] Timer-Settings werden nur noch aus PraxisDataStore gelesen und geschrieben
- [ ] `SaveSettings`-Effect speichert in PraxisDataStore statt SettingsDataStore
- [ ] TimerViewModel hat keine `settingsRepository`-Dependency mehr

### Aufraeum-Arbeiten
- [ ] `loadSettings()` und `saveSettings()` aus TimerViewModel entfernen
- [ ] `SettingsRepository`-Interface: `settingsFlow`, `updateSettings`, `getSettings` entfernen
- [ ] SettingsDataStore: Timer-Settings-Keys und Methoden entfernen (nur App-Settings bleiben: Tab, Theme, Appearance)
- [ ] Toter Code entfernen: `showSettingsHint` aus UiState, `hasSeenSettingsHint` aus SettingsRepository, `SettingsHintTooltip` Composable
- [ ] Zugehoerige Tests anpassen

### Tests
- [ ] Bestehende Timer-Tests laufen gruen
- [ ] Neuer Test: Custom Attunement-ID wird korrekt aus Praxis geladen

### Dokumentation
- [ ] CHANGELOG.md (Bug Fix: Custom Introduction)

---

## Manueller Test

1. PraxisEditor oeffnen → Einstimmung → eigene Datei auswaehlen
2. Zurueck zum Timer
3. Erwartung: Timer-Settings zeigen den Namen der ausgewaehlten Datei, nicht "Ohne Einstimmung"
4. App beenden und neu starten
5. Erwartung: Auswahl ist weiterhin gespeichert

---

## Referenz

- SettingsDataStore enthaelt neben Timer-Settings auch App-Settings (Tab, Theme, Appearance) — diese bleiben
- PraxisDataStore ist seit shared-062 die primaere Quelle fuer Timer-Konfiguration
- `TimerReducer` erzeugt `SaveSettings`-Effects die aktuell in SettingsDataStore schreiben

---

## Hinweise

- Die `Introduction.isAvailableForCurrentLanguage()`-Pruefung im SettingsDataStore ist der eigentliche Bug-Trigger: sie erkennt custom UUIDs nicht als gueltig
- SettingsDataStore wird weiterhin gebraucht fuer App-Level-Settings (Tab, Theme, Appearance) — nur die Timer-Settings-Teile werden entfernt
- Einzelne Setter im SettingsDataStore (`setIntervalMinutes`, `setGongVolume` etc.) werden nicht mehr vom Timer verwendet und koennen entfernt werden
