# Ticket shared-006: Timer-Texte anpassen

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: iOS ~15min | Android ~15min
**Phase**: 4-Polish

---

## Was

Drei Text-Anpassungen in der Timer View:
1. `timer.lockscreen.hint` entfernen (UI + Strings)
2. `state.completed` aendern zu "danke dir" / "thank you"
3. `affirmation.running.5` auf iOS ergaenzen (Android hat bereits Text)

## Warum

Vereinfachung der UI und konsistentere Texte zwischen den Plattformen. Der Lockscreen-Hinweis ist ueberfluessig, die Completion-Nachricht soll persoenlicher werden.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

- [x] `timer.lockscreen.hint` wird nicht mehr angezeigt (Code + Strings entfernt)
- [x] `state.completed` zeigt "danke dir" (DE) / "thank you" (EN)
- [x] `affirmation.running.5` zeigt "Du machst das wunderbar" (DE) / "You are doing wonderfully" (EN)
- [x] Lokalisiert (DE + EN)
- [x] UX-Konsistenz zwischen iOS und Android

---

## Manueller Test

1. Timer starten und laufen lassen
2. Beobachten: Kein Lockscreen-Hinweis mehr sichtbar
3. Timer bis zum Ende laufen lassen
4. Erwartung: "danke dir" / "thank you" wird angezeigt
5. Mehrere Sessions starten, Affirmationen beobachten
6. Erwartung: Alle 5 Running-Affirmationen haben Text

---

## Referenz

- iOS: `ios/StillMoment/Resources/{de|en}.lproj/Localizable.strings`
- iOS: `ios/StillMoment/Presentation/Views/Timer/TimerView.swift`
- Android: `android/app/src/main/res/values{-de}/strings.xml`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/TimerScreen.kt`

---

## Hinweise

- iOS `affirmation.running.5` ist aktuell leer (""), Android hat bereits den Text
- Android-Text uebernehmen: "Du machst das wunderbar" / "You are doing wonderfully"
