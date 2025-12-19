# Ticket ios-017: Edit Sheet accessibilityHint hinzufuegen

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

accessibilityHint auf Buttons im GuidedMeditationEditSheet.

## Warum

VoiceOver-Nutzer profitieren von Hints die erklaeren, was passiert wenn ein Button aktiviert wird. Aktuell fehlen diese.

---

## Akzeptanzkriterien

- [ ] Cancel-Button hat accessibilityHint
- [ ] Save-Button hat accessibilityHint
- [ ] Reset-Button hat accessibilityHint
- [ ] Hints sind lokalisiert (DE + EN)

---

## Manueller Test

1. VoiceOver aktivieren
2. Edit Sheet oeffnen
3. Zu Buttons navigieren
4. Erwartung: VoiceOver liest Hint vor (z.B. "Doppeltippen zum Speichern der Aenderungen")

---

## Referenz

- Pattern: `TimerView.swift` - accessibilityHint auf allen Buttons
- Strings: `accessibility.saveChanges.hint`, `accessibility.cancel.hint`, etc.

---

<!-- Erstellt via View Quality Review -->
