# Ticket android-066: Footer-Text "Du verdienst diese Pause" entfernen

**Status**: [x] DONE
**Prioritaet**: HOCH
**Aufwand**: Trivial
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Den kursiven Footer-Text "Du verdienst diese Pause" / "You deserve this pause" unter dem Dauer-WheelPicker auf dem Timer-Hauptscreen entfernen.

## Warum

Der Text ist wertend und wirbt. Das widerspricht der Still-Moment-Philosophie: "No gamification, no streaks, no social." Der App soll sich wie eine Pause anfuehlen, nicht wie ein Produkt das den Nutzer umschmeichelt. iOS hat diesen Text nicht.

---

## Akzeptanzkriterien

### Feature
- [x] `Text`-Element mit `stringResource(R.string.duration_footer)` aus `TimerScreen.kt` entfernt (Zeile ~197-202)
- [x] Zugehoeriger `Spacer` vor dem Text ebenfalls entfernt
- [x] String-Ressource `duration_footer` aus `values/strings.xml` und `values-de/strings.xml` entfernt
- [x] Kein unerklärter Leerraum an der Stelle des entfernten Textes

### Tests
- [x] `make test` gruen

### Dokumentation
- [ ] Keine

---

## Manueller Test

1. App starten, Timer-Tab oeffnen
2. Erwartung: Kein Text unter dem Dauer-WheelPicker

---

## Referenz

- `android/app/src/main/kotlin/.../timer/TimerScreen.kt` Zeile ~197-202
- `android/app/src/main/res/values/strings.xml`: `duration_footer = "You deserve this pause"`
- `android/app/src/main/res/values-de/strings.xml`: `duration_footer = "Du verdienst diese Pause"`
