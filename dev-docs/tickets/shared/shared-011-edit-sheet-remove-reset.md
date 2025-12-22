# Ticket shared-011: Edit Sheet Reset-Button entfernen

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: iOS ~15min | Android ~15min
**Phase**: 4-Polish

---

## Was

Entfernung des "Zurücksetzen"-Buttons aus der Meditation Edit-View.

## Warum

Der Button ist redundant - der Abbrechen-Button erfüllt denselben Zweck (Änderungen verwerfen). Die Entfernung vereinfacht die UI und reduziert Code-Komplexität.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

- [x] Reset-Button aus UI entfernt (beide Plattformen)
- [x] reset()-Methode aus EditSheetState entfernt
- [x] Lokalisierungs-Keys entfernt (beide Sprachen)
- [x] Unit Tests angepasst
- [x] UX-Konsistenz zwischen iOS und Android

---

## Manueller Test

1. Öffne die Meditationsbibliothek
2. Wähle eine Meditation zum Bearbeiten
3. Erwartung: Nur "Abbrechen" und "Speichern" Buttons sichtbar

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/`
