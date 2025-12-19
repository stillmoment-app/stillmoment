# Ticket ios-022: Library View accessibilityIdentifier und Hints

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: Klein (~1h)
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

accessibilityIdentifier und accessibilityHint auf alle interaktiven Elemente in GuidedMeditationsListView hinzufuegen, um UI-Test-Automatisierung zu ermoeglichen.

## Warum

Aktuell fehlen accessibilityIdentifiers komplett, wodurch UI-Tests (Ticket ios-012) nicht geschrieben werden koennen. Zusaetzlich fehlen accessibilityHints, die VoiceOver-Nutzern erklaeren, was bei Aktivierung passiert.

---

## Akzeptanzkriterien

- [ ] Add-Button (Toolbar) hat accessibilityIdentifier + accessibilityHint
- [ ] Meditation Rows haben accessibilityIdentifier (mit ID)
- [ ] Edit-Button hat accessibilityIdentifier + accessibilityHint
- [ ] Empty State Import-Button hat accessibilityIdentifier + accessibilityHint
- [ ] Lokalisierte Hints in DE + EN

---

## Manueller Test

1. VoiceOver aktivieren (Settings > Accessibility > VoiceOver)
2. Library Tab oeffnen
3. Durch alle Elemente navigieren
4. Erwartung: Hints werden vorgelesen ("Oeffnet Dateiauswahl...", "Oeffnet Player...", etc.)

---

## Referenz

Bestehende accessibilityIdentifiers als Vorlage:
- `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationEditSheet.swift`
- Pattern: `"editSheet.button.save"`, `"editSheet.field.teacher"`

Empfohlenes Pattern fuer Library:
- `"library.button.add"`
- `"library.button.import.emptyState"`
- `"library.row.meditation.{id}"`
- `"library.button.edit.{id}"`

---

## Hinweise

- accessibilityIdentifier ist fuer UI-Tests (nicht fuer VoiceOver)
- accessibilityHint erklaert die Aktion (fuer VoiceOver)
- Meditation-Row-IDs sollten die UUID enthalten fuer eindeutige Identifikation

---

*Generiert mit `/review-view Library`*
