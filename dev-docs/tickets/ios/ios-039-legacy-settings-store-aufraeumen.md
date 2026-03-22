# Ticket ios-039: Legacy Timer-Settings-Store aufraeumen

**Status**: [x] DONE
**Plan**: [Implementierungsplan](../plans/ios-039.md)
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Was

TimerViewModel schreibt noch in den alten `UserDefaultsTimerSettingsRepository`, obwohl seit shared-068 ausschliesslich `PraxisRepository` als Quelle genutzt wird. Ausserdem existieren Tests fuer `hasSeenSettingsHint` — ein Feature das nie in die UI eingebaut wurde.

## Warum

Vestigiale Schreibzugriffe auf einen ungenutzten Store sind verwirrend und erhoehen die Wartungslast. Der tote `hasSeenSettingsHint`-Code suggeriert eine Funktionalitaet die nicht existiert.

---

## Akzeptanzkriterien

### Feature
- [ ] TimerViewModel schreibt nicht mehr in `UserDefaultsTimerSettingsRepository`
- [ ] `TimerSettingsRepository`-Dependency aus TimerViewModel entfernt
- [ ] `hasSeenSettingsHint`-Tests entfernt (Feature nie implementiert, kein UI-Gegenstueck)
- [ ] `UserDefaultsTimerSettingsRepository` kann entfernt werden, sofern keine Migration mehr noetig ist (Migrations-Pfad in `UserDefaultsPraxisRepository.load()` pruefen)

### Tests
- [ ] Bestehende Timer-Tests laufen gruen
- [ ] Keine Regression bei Settings-Persistenz (Praxis bleibt einzige Quelle)

---

## Manueller Test

1. Timer-Settings im PraxisEditor aendern (Gong, Hintergrund, Dauer)
2. App beenden und neu starten
3. Erwartung: Alle Einstellungen sind erhalten

---

## Hinweise

- `UserDefaultsPraxisRepository.load()` hat einen Migrations-Pfad der einmalig aus den alten UserDefaults-Keys liest. Dieser muss erhalten bleiben, solange es User mit alten App-Versionen gibt. Der Repository selbst kann aber als read-only Migration behandelt werden — aktive Schreibzugriffe vom TimerViewModel sind unnoetig.
- Android hat das gleiche Problem plus einen aktiven Bug (android-074). iOS ist nur Aufraeumarbeit.
