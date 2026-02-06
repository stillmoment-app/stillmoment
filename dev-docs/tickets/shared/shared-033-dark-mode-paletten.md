# Ticket shared-033: Theme-Paletten finalisieren

**Status**: [~] IN PROGRESS
**Prioritaet**: MITTEL
**Aufwand**: iOS erledigt | Android ~1h (Paletten von iOS uebernehmen)
**Phase**: 4-Polish

---

## Was

Alle 6 Farbpaletten (3 Themes x Light/Dark) sollen echte, abgestimmte Farbwerte haben. Iterativ mit MCP-Screenshots entwickelt.

## Warum

User mit System Dark Mode sehen aktuell Placeholder-Farben, die nicht bewusst gestaltet wurden. Ein Theme-Wechsel muss einen sichtbaren Unterschied machen, sonst ist die Funktion wertlos.

**Update:** iOS hat mittlerweile alle 6 Paletten mit echten Farbwerten finalisiert. Android muss diese 1:1 uebernehmen.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | Fertig - alle 6 Paletten mit echten Farbwerten |
| Android   | [ ]    | shared-032 (Android-Angleichung auf 3 Themes) |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Candlelight Light: Morning Glow - warmer Sonnenaufgang
- [x] Candlelight Dark: Evening Cocoa - gedaempftes Terrakotta auf Kakao
- [x] Forest Light: Misty Pine - kuehler Wald-Gradient
- [x] Forest Dark: Ancient Woods - tiefer Wald auf dunklem Grund
- [x] Moon Light: Pure Silver - neutraler Silber-Gradient
- [x] Moon Dark: Midnight Shimmer - tiefstes Schwarz mit Indigo-Schimmer
- [x] Alle 6 Paletten sind visuell unterscheidbar
- [x] Gradient, Buttons, Text, TabBar, Timer-Ring sehen in jeder Palette stimmig aus
- [ ] Kontrast-Verhaeltnisse fuer Lesbarkeit eingehalten (WCAG AA) → shared-035
- [ ] Visuell konsistent zwischen iOS und Android (Android muss Paletten uebernehmen)

### Tests
- [x] Bestehende Tests bleiben gruen (Paletten-Uniqueness-Test)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. System Dark Mode aktivieren
2. App starten mit Candlelight Theme
3. Erwartung: Evening Cocoa - dunkle Variante sieht durchdacht und stimmig aus
4. Zu Forest wechseln
5. Erwartung: Ancient Woods - deutlich andere Farbstimmung, kuehle Gruentoene
6. Zu Moon wechseln
7. Erwartung: Midnight Shimmer - tiefstes Schwarz mit Indigo-Akzent
8. System Dark Mode deaktivieren
9. Alle 3 Themes durchschalten: jedes hat eine eigene, unterscheidbare Stimmung
10. Alle Screens pruefen: Timer, Settings, Library, Player, Edit Sheet

---

## Hinweise

- iOS-Farbwerte liegen in `ThemeColors+Palettes.swift` — diese sind die Referenz fuer Android
- Android muss die RGB-Werte 1:1 uebernehmen (nach Angleichung auf 3 Themes in shared-032)

---
