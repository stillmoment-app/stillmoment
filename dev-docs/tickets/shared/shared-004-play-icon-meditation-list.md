# Ticket shared-004: Play-Icon in Meditationsliste

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~15min | Android ~15min
**Phase**: 4-Polish

---

## Was

Dezentes Play-Icon links vom Meditationstitel anzeigen, um visuell zu signalisieren, dass die Zeile tappbar ist und eine Meditation abspielt.

## Warum

Aktuell fehlt jeder visuelle Hinweis, dass Meditationszeilen tappbar sind. Das einzige sichtbare Icon ist der Edit-Stift rechts, was suggeriert, dass Bearbeiten die primaere Aktion ist. Ein Play-Icon verbessert die Affordance und macht die Haupt-Interaktion intuitiv klar.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

- [ ] Play-Icon links vom Meditationstitel (iOS)
- [ ] Play-Icon links vom Meditationstitel (Android)
- [ ] Icon nutzt sekundaere Textfarbe (dezent, nicht dominant)
- [ ] Icon-Groesse: 20pt/20dp
- [ ] Accessibility: Icon ist dekorativ (contentDescription = null), Zeile hat bereits Hint
- [ ] Screenshots aktualisiert (beide Plattformen)
- [ ] UX-Konsistenz zwischen iOS und Android

---

## Manueller Test

1. App oeffnen, zur Bibliothek wechseln
2. Meditationsliste betrachten
3. Erwartung: Jede Zeile zeigt links ein dezentes Play-Icon, das klar macht dass Tippen die Meditation abspielt

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Icon | SF Symbol `play.circle` | Material Icon `PlayCircle` |
| Farbe | `.textSecondary` | `onSurfaceVariant` |
| Groesse | 20pt | 20dp |

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/MeditationListItem.kt`

---

## Hinweise

- Android hatte fruher ein Play-Icon (entfernt in android-024) - dieses Ticket fuehrt es mit besserem Design zurueck
- Position links vom Titel (nicht rechts), um nicht mit Edit-Button zu konkurrieren
- Farbe bewusst dezent (textSecondary), damit Icon nicht mit interaktiven Elementen konkurriert

---
