# Ticket android-058: Settings sofort speichern

**Status**: [ ] TODO
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

- [ ] Jede Aenderung (Toggle, Dropdown) wird sofort an das ViewModel weitergegeben
- [ ] Done-Button schliesst nur noch das Sheet (kein Speichern mehr noetig)
- [ ] Verhalten identisch zu iOS SettingsView
- [ ] Unit Tests aktualisiert

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

Die iOS-Implementierung nutzt `@Binding` auf `MeditationSettings`. In Compose kann das analog mit einem Callback `onSettingsChange` bei jeder Aenderung erreicht werden, statt nur beim Done-Button.
