# Ticket shared-034: Theme-Vorschau im Picker

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: iOS ~1h | Android ~1h
**Phase**: 4-Polish

---

## Was

Die Theme-Auswahl in den Settings soll neben dem Theme-Namen eine Farbpaletten-Vorschau (Farbkreise/Swatches) anzeigen, damit der User vor dem Wechsel sieht wie das Theme aussieht.

## Warum

Aktuell zeigt der Picker nur den Namen ("Warmer Sand", "Kerzenschein"). Der User muss blind wechseln um das Ergebnis zu sehen. Eine kleine Farbvorschau macht die Entscheidung einfacher und die Auswahl ansprechender.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-032    |
| Android   | [ ]    | shared-032    |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Jede Theme-Option zeigt 3-4 repraesentative Farbkreise neben dem Namen
- [ ] Farbkreise zeigen die Hauptfarben des jeweiligen Themes (z.B. Background, Interactive, Accent)
- [ ] Vorschau zeigt die zum aktuellen System-Setting passende Variante (Light/Dark)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Keine neuen Unit Tests noetig (reine UI-Anpassung)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Settings oeffnen (Timer-Tab oder Library-Tab)
2. Erwartung: Theme-Auswahl zeigt Farbkreise neben jedem Theme-Namen
3. Erwartung: Farben entsprechen dem tatsaechlichen Theme
4. System Dark Mode wechseln
5. Erwartung: Farbkreise zeigen die Dark-Variante

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Vorschau-Position | Neben Theme-Name im Picker | Neben Theme-Name im Dropdown |
| Farbkreise | Kleine runde Swatches | Kleine runde Swatches |

---
