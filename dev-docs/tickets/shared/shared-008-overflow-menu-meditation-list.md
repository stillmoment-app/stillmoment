# Ticket shared-008: Overflow-Menü statt Edit-Icon in Meditationsliste

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2 | Android ~2
**Phase**: 4-Polish

---

## Was

Das sichtbare Edit-Icon (Stift) in jeder Zeile der Meditationsliste durch ein Overflow-Menü (⋮) ersetzen, das Edit und Delete als Aktionen enthaelt.

## Warum

- Sauberere UI: Weniger visuelle Ablenkung, nur ein Icon statt separatem Stift pro Zeile
- Gruppiert zusammengehoerige Aktionen (Edit + Delete) logisch
- Konsistentes Cross-Platform-Pattern (Material Design + iOS Human Interface Guidelines)
- Fokus liegt auf dem Inhalt, nicht auf den Aktionen

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

- [ ] Edit-Icon (Stift) aus MeditationListItem entfernt
- [ ] Overflow-Icon (⋮ / ellipsis.vertical) hinzugefuegt
- [ ] Tap auf Overflow oeffnet Menue mit "Bearbeiten" und "Loeschen"
- [ ] "Bearbeiten" oeffnet bestehenden Edit-Sheet
- [ ] "Loeschen" zeigt bestehenden Confirmation-Dialog
- [ ] Swipe-to-Delete bleibt erhalten (Android hat es bereits, iOS optional)
- [ ] Accessibility: Menue ist mit VoiceOver/TalkBack bedienbar
- [ ] Lokalisiert (DE + EN)
- [ ] UX-Konsistenz zwischen iOS und Android

---

## Manueller Test

1. Bibliothek oeffnen mit mindestens einer Meditation
2. Overflow-Icon (⋮) antippen
3. Menue erscheint mit "Bearbeiten" und "Loeschen"
4. "Bearbeiten" antippen → Edit-Sheet oeffnet sich
5. Menue erneut oeffnen, "Loeschen" antippen → Confirmation-Dialog erscheint

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Icon | `ellipsis.vertical` (SF Symbol) | `Icons.Default.MoreVert` (Material) |
| Menue | `.contextMenu` oder `Menu` | `DropdownMenu` |
| Swipe-to-Delete | Optional (bereits via swipeActions moeglich) | Bereits implementiert |

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/MeditationListItem.kt`

---

## Hinweise

- Android hat bereits `SwipeToDismissBox` fuer Delete - das Overflow-Menue ist eine Alternative/Ergaenzung
- iOS koennte zusaetzlich `swipeActions` nutzen, aber das Overflow-Menue sollte die primaere Interaktion sein
- Das Play-Icon links bleibt unveraendert

---
