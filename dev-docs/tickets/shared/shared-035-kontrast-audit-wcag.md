# Ticket shared-035: Kontrast-Audit WCAG-Validierung

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h | Android ~2h
**Phase**: 5-QA

---

## Was

Alle Farbpaletten (3 Themes x 2 Schemes = 6 Paletten) sollen gegen WCAG 2.1 AA Kontrastvorgaben geprueft werden. Ergebnis ist eine dokumentierte Kontrast-Matrix in `color-system.md`.

## Warum

Accessibility ist Pflicht (siehe Design-Richtlinien). Aktuell sind keine Kontrast-Verhaeltnisse validiert oder dokumentiert. Besonders nach der Finalisierung der Theme-Paletten (shared-033) muss sichergestellt sein, dass alle Farbkombinationen fuer alle User lesbar sind. Apple und Google pruefen Accessibility zunehmend im Review-Prozess.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-033    |
| Android   | [ ]    | shared-033    |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

- [ ] Alle Text-auf-Hintergrund-Kombinationen erreichen WCAG 2.1 AA Kontrast (4.5:1 fuer normalen Text, 3:1 fuer grossen Text)
- [ ] Kontrast-Matrix fuer alle 10 Paletten in `color-system.md` dokumentiert
- [ ] Farbkombinationen mit Farbenblindheits-Simulation geprueft (Protanopie, Deuteranopie, Tritanopie)
- [ ] Keine Information wird ausschliesslich ueber Farbe vermittelt (z.B. Error-State hat auch Icon/Text)
- [ ] Falls Paletten angepasst werden muessen: Anpassungen auf beiden Plattformen identisch

### Zu pruefende Kombinationen (pro Palette)

- [ ] `textPrimary` auf `backgroundPrimary` / `backgroundSecondary`
- [ ] `textSecondary` auf `backgroundPrimary` / `backgroundSecondary`
- [ ] `textOnInteractive` auf `interactive`
- [ ] `interactive` auf `backgroundPrimary` (als Text/Link)
- [ ] `error` auf `backgroundPrimary`

### Tests

- [ ] Unit Tests iOS: Kontrast-Berechnung fuer alle Paletten
- [ ] Unit Tests Android: Kontrast-Berechnung fuer alle Paletten

### Dokumentation

- [ ] `color-system.md` um Kontrast-Abschnitt erweitert

---

## Manueller Test

1. App mit jedem der 3 Themes oeffnen (Light + Dark)
2. Alle Screens durchgehen: Timer, Settings, Library, Player, Edit Sheet
3. Erwartung: Alle Texte sind gut lesbar, kein Text verschwindet im Hintergrund
4. Mit Accessibility Inspector (iOS) oder Talkback (Android) pruefen

---

## Referenz

- WCAG 2.1 Kontrast-Anforderungen: Level AA = 4.5:1 (normal), 3:1 (gross/bold)
- iOS: `color-system.md`, `ThemeColors+Palettes.swift`
- Android: `Color.kt`, `Theme.kt`
- Tools: WebAIM Contrast Checker, Xcode Accessibility Inspector, Color Oracle

---

## Hinweise

- Kontrast-Berechnung basiert auf relative Luminanz nach WCAG-Formel
- "Grosser Text" = 18pt regular oder 14pt bold (entspricht ca. `.title3` / `headlineMedium`)
- Falls Paletten angepasst werden muessen, ist das ein Follow-up zu shared-033 — die Audit-Ergebnisse fliessen in die Palette-Finalisierung ein
