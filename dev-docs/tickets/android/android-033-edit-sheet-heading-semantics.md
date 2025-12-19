# Ticket android-033: Edit Sheet heading() fuer Titel

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Titel "Edit Meditation" als heading markieren fuer Screen Reader Navigation.

## Warum

Screen Reader Nutzer koennen mit heading-Navigation schnell durch Sektionen springen. Der Titel sollte als heading markiert sein.

---

## Akzeptanzkriterien

- [ ] Titel hat `Modifier.semantics { heading() }`
- [ ] TalkBack kuendigt "Heading" an beim Titel

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
