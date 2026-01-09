# Ticket android-058: Settings sofort speichern

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Settings-Aenderungen im SettingsSheet sollen sofort uebernommen werden, nicht erst beim Druecken von "Done".

## Warum

iOS uebernimmt Settings-Aenderungen sofort via Binding. Android wartet auf explizites Bestaetigen. Diese Inkonsistenz kann User verwirren, die beide Plattformen nutzen.

---

## Akzeptanzkriterien

- [x] Jede Aenderung (Toggle, Dropdown) wird sofort an das ViewModel weitergegeben
- [x] Done-Button schliesst nur noch das Sheet (kein Speichern mehr noetig)
- [x] Verhalten identisch zu iOS SettingsView
- [x] Unit Tests aktualisiert (4 neue Tests in TimerScreenTest)

---

## Manueller Test

1. Settings-Sheet oeffnen
2. Interval Gongs Toggle aendern
3. Erwartung: Aenderung wird sofort uebernommen (nicht erst bei Done)
4. Sheet durch Wischen nach unten schliessen (ohne Done)
5. Settings erneut oeffnen
6. Erwartung: Aenderung ist gespeichert

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/Timer/SettingsView.swift` - Nutzt @Binding
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/SettingsSheet.kt` - Aktuelle Implementierung mit lokalen States

---

## Hinweise

**Wichtige Klarstellung iOS vs. Android:**

iOS nutzt `@Binding` - Aenderungen sind sofort im ViewModel sichtbar, aber die Persistierung (UserDefaults) erfolgt erst beim Sheet-Dismiss. Bei App-Crash waehrend offener Settings gehen ungespeicherte Aenderungen verloren.

**Android soll es robuster machen:** Jede Aenderung wird sofort in den DataStore persistiert. Das ist benutzerfreundlicher und verhindert Datenverlust.

**Implementierung:**
- Callback `onSettingsChange: (MeditationSettings) -> Unit` bei jeder Aenderung aufrufen
- ViewModel persistiert sofort in SettingsDataStore
- Done-Button schliesst nur noch das Sheet
