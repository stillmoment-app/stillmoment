# Ticket shared-005: Empty State vereinfachen

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: iOS ~2min | Android ~2min
**Phase**: 4-Polish

---

## Was

Das Icon/Emoji im Empty State der Library entfernen. Minimalistischer Ansatz: nur Text + Import-Button.

**Aktuell:**
- iOS: SF Symbol `music.note.list`
- Android: Emoji 🧘

**Neu:**
- Beide: Kein Icon, nur Text + Button

## Warum

"Einfach > Feature-reich" - Weniger ist mehr. Ein leerer Zustand braucht kein dekoratives Icon. Der Fokus liegt auf der Aktion (Import). Zusaetzlich erreichen wir 100% Konsistenz durch Weglassen.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

- [x] iOS: SF Symbol aus emptyStateView entfernt
- [x] Android: Emoji aus EmptyLibraryState entfernt
- [x] Beide Plattformen zeigen nur Text (Titel + Beschreibung) + Import-Button
- [x] Layout bleibt zentriert und ansprechend

---

## Manueller Test

1. Alle Meditationen loeschen (oder frische Installation)
2. Library-Tab oeffnen
3. Erwartung: Nur "Keine Meditationen" Text + Import-Button, kein Icon
4. iOS und Android sehen identisch aus

---

## Referenz

- iOS: `GuidedMeditationsListView.swift` - `emptyStateView`
- Android: `EmptyLibraryState.kt`
