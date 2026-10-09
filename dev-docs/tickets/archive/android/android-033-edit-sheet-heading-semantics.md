---
id: android-033
title: Edit Sheet heading() Titel
status: done
phase: 4-Polish
priority: mittel
---

# Ticket android-033: Edit Sheet heading() fuer Titel

**Aufwand**: Klein
**Abhaengigkeiten**: Keine

---

## Was

Titel "Edit Meditation" als heading markieren fuer Screen Reader Navigation.

## Warum

Screen Reader Nutzer koennen mit heading-Navigation schnell durch Sektionen springen. Der Titel sollte als heading markiert sein.

---

## Akzeptanzkriterien

- [x] Titel hat `Modifier.semantics { heading() }`
- [ ] TalkBack kuendigt "Heading" an beim Titel (manuell testen)

---

## Manueller Test

1. TalkBack aktivieren
2. Edit Sheet oeffnen
3. Zum Titel navigieren
4. Erwartung: TalkBack sagt "Edit Meditation, Heading"

---

## Referenz

```kotlin
Text(
    text = stringResource(R.string.edit_meditation_title),
    modifier = Modifier.semantics { heading() }
)
```

---

<!-- Erstellt via View Quality Review -->
