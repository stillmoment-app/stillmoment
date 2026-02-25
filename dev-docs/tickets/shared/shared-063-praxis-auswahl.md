# Ticket shared-063: Praxis-Auswahl (Pill-Button & Bottom Sheet)

**Status**: [-] WONTFIX
**Prioritaet**: HOCH
**Aufwand**: iOS ~4 | Android ~4
**Phase**: 3-Feature
**Ursprung**: shared-051 (aufgeteilt)

---

## WONTFIX

Vereinfachung auf Einzelkonfiguration macht Auswahl-UI ueberfluessig. Stattdessen: tappbare Konfigurationsbeschreibung direkt auf dem Timer Screen (shared-068).

## Was

Auf dem Timer Screen einen Pill-Button "Praxis: [Name]" einfuehren, der ein Bottom Sheet mit allen gespeicherten Praxis-Presets oeffnet. Kontextmenue pro Preset fuer Bearbeiten und Loeschen.

## Warum

User soll schnell zwischen vordefinierten Timer-Konfigurationen wechseln koennen, ohne jedes Mal alle Einstellungen einzeln anzupassen. Der Pill-Button ersetzt langfristig das Settings-Zahnrad als primaeren Einstiegspunkt.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | shared-062    |
| Android   | [ ]    | shared-062    |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Pill-Button oben auf dem Timer Screen zeigt "Praxis: [Name der aktiven Praxis]"
- [x] Tap auf Pill oeffnet Bottom Sheet mit Liste aller gespeicherten Praxis-Presets
- [x] Jeder Eintrag zeigt Name und Kurzbeschreibung (aus Praxis-Modell)
- [x] Aktive Praxis ist mit Checkmark markiert
- [x] Kontextmenue (...) pro Eintrag mit "Bearbeiten" und "Loeschen"
- [x] "Loeschen" in Rot, mit Bestaetigungsdialog
- [x] Letzte Praxis kann nicht geloescht werden
- [x] "Neue Praxis erstellen" Button am Ende der Liste (gestrichelte Umrandung)
- [x] Auswahl einer Praxis laedt deren Konfiguration und schliesst das Sheet
- [x] "Bearbeiten" oeffnet den Praxis-Editor (shared-064) — solange dieser nicht existiert, oeffnet es das bestehende Timer-Settings-Sheet als Ueberbrueckung
- [x] "Neue Praxis erstellen" legt eine Praxis mit Default-Werten an und oeffnet den Editor
- [x] Pill-Button wird bei laufender Meditation ausgeblendet (zusammen mit Zen-Modus shared-066)
- [x] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [x] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [x] CHANGELOG.md

---

## Manueller Test

1. Timer Screen → Pill "Praxis: Standard" sichtbar oben am Screen
2. Tap auf Pill → Bottom Sheet oeffnet sich
3. "Standard" mit Checkmark in der Liste
4. "Neue Praxis erstellen" → neue Praxis erscheint in der Liste
5. Neue Praxis auswaehlen → Pill zeigt neuen Namen, Sheet schliesst sich
6. Pill erneut oeffnen → Checkmark bei neuer Praxis
7. Kontextmenue (...) bei "Standard" → "Bearbeiten" und "Loeschen" sichtbar
8. "Loeschen" → Bestaetigungsdialog → Praxis wird entfernt
9. Versuch die letzte Praxis zu loeschen → wird verhindert

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Bottom Sheet | .sheet oder .presentationDetents | ModalBottomSheet |
| Kontextmenue | UIMenu / .contextMenu | DropdownMenu |
| Pill-Button | Custom View (Capsule Shape) | Custom Composable (RoundedCorner) |

---

## Referenz

- UI-Prototype: `dev-docs/ui-prototype.html` (TimerIdleScreen Pill-Button, PresetsBottomSheet)
- Bestehende Patterns: Overflow-Menue in der Bibliothek (shared-008) als Referenz fuer Kontextmenue

---

## Hinweise

- Der Pill-Button ersetzt NOCH NICHT das Settings-Zahnrad in diesem Ticket. Beide koexistieren voruebergehend. Erst shared-064 entfernt das Zahnrad.
- Bottom Sheet soll als Half-Sheet erscheinen (nicht Fullscreen), mit Drag-Indikator oben.
- Beim Wechsel der Praxis aendern sich alle Timer-Einstellungen sofort (Gong, Background, Dauer etc.). Die Dauer kann danach auf dem Timer Screen vor Start angepasst werden (session-only).
