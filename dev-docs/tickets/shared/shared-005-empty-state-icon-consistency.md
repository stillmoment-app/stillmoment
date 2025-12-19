# Ticket shared-005: Empty State Icon Konsistenz

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: iOS ~5min | Android ~5min
**Phase**: 4-Polish

---

## Was

Der Empty State in der Library soll auf beiden Plattformen ein konsistentes Icon verwenden. Aktuell: iOS zeigt `music.note.list`, Android zeigt ein Emoji.

## Warum

Kosmetische Inkonsistenz. Emojis wirken weniger professionell als System-Icons und werden je nach OS/Device unterschiedlich gerendert. Ein konsistentes Icon-Design staerkt die App-Identitaet.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

- [ ] Beide Plattformen verwenden ein Symbol statt Emoji
- [ ] iOS: SF Symbol (z.B. `music.note.list` beibehalten oder `person.wave.2`)
- [ ] Android: Material Icon Equivalent
- [ ] Gleiche semantische Bedeutung: "Bibliothek/Sammlung" oder "Meditation"
- [ ] Icon-Farbe: `Color.interactive` / `MaterialTheme.colorScheme.primary`
- [ ] Icon-Groesse: ~60-64dp/pt

---

## Manueller Test

1. Alle Meditationen loeschen (oder frische Installation)
2. Library-Tab oeffnen
3. Erwartung: Grosses Icon ueber dem "Keine Meditationen" Text
4. iOS und Android zeigen aehnliche Icons

---

## UX-Konsistenz

| Element | iOS | Android |
|---------|-----|---------|
| Icon | SF Symbol | Material Icon |
| Vorschlag 1 | `music.note.list` | `LibraryMusic` |
| Vorschlag 2 | `books.vertical` | `CollectionsBookmark` |
| Vorschlag 3 | `leaf` | `SelfImprovement` |

---

## Referenz

- iOS: `GuidedMeditationsListView.swift` - `emptyStateView`
- Android: `EmptyLibraryState.kt` - Text mit Emoji

---

## Hinweise

Am einfachsten waere es, das iOS-Icon (`music.note.list`) als Referenz zu nehmen und ein semantisch aequivalentes Material Icon zu finden. `LibraryMusic` waere ein gutes Equivalent.
