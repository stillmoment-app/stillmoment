# Ticket android-032: Edit Sheet Accessibility Semantics

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Accessibility-Semantics fuer alle interaktiven Elemente im MeditationEditSheet.

## Warum

Aktuell fehlen explizite contentDescription und semantics auf Buttons. TalkBack-Nutzer bekommen moeglicherweise unklare Ansagen.

---

## Akzeptanzkriterien

- [ ] Save-Button hat contentDescription
- [ ] Cancel-Button hat contentDescription
- [ ] TextFields haben explizite semantics (ueber label hinaus)
- [ ] TalkBack liest alle Elemente korrekt vor
- [ ] Lokalisiert (DE + EN)

---

## Manueller Test

1. TalkBack aktivieren
2. Edit Sheet oeffnen
3. Durch alle Elemente navigieren
4. Erwartung: Jedes Element wird klar und verstaendlich angesagt

---

## Referenz

- iOS: accessibilityLabel Pattern in `GuidedMeditationEditSheet.swift`
- Android: `Modifier.semantics { contentDescription = ... }`

---

<!-- Erstellt via View Quality Review -->
