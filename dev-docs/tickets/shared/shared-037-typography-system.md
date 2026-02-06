# Ticket shared-037: Zentrales Typography System

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS erledigt | Android erledigt
**Phase**: 2-Architektur

---

## Was

Alle Schriftarten, -groessen und -farben sollen ueber semantische Rollen definiert werden statt durch manuelle Font/Color-Kombination in jeder View. Das System kompensiert automatisch Dark Mode Halation (duenne helle Schrift auf dunklem Grund wirkt zu duenn).

## Warum

Konsistente Typografie ueber alle Screens hinweg. Aenderungen an Schriftgroessen oder -farben muessen nur an einer Stelle gemacht werden. Die Dark Mode Halation-Kompensation verhindert, dass helle Schrift auf dunklem Hintergrund optisch duenner wirkt als beabsichtigt — ein haeufiges Problem bei Meditations-Apps mit dunklen Themes.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | Fertig (20 TypographyRoles, alle Views migriert, Unit Tests) |
| Android   | [x]    | Fertig (20 TypographyRoles, Nunito Font, alle 14 Views migriert, Unit Tests) |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Semantische Rollen fuer alle Text-Verwendungen (Timer, Headings, Body, Settings, Player, List, Edit)
- [x] Einzelner Aufruf pro Text-Element statt separate Font + Color-Angaben
- [x] Dark Mode Halation-Kompensation: Font Weight automatisch eine Stufe schwerer im Dark Mode
- [x] Feste Groessen fuer dekorative Elemente (Timer-Display, Headings), Dynamic Type fuer Lesetext
- [x] Visuell konsistent zwischen iOS und Android

### Tests
- [x] Unit Tests: Halation-Kompensation liefert korrektes Weight pro Light/Dark
- [x] Unit Tests: Jede Rolle hat eindeutige Font/Size/Color-Kombination

### Dokumentation
- [x] CHANGELOG.md

---

## Manueller Test

1. App starten mit Candlelight Theme, Light Mode
2. Alle Screens durchgehen: Timer-Display, Headings, Body-Text, Settings-Labels, Player, Liste
3. Erwartung: Konsistente Schriftgroessen und -farben
4. System Dark Mode aktivieren
5. Erwartung: Schrift wirkt optisch gleich dick wie im Light Mode (nicht duenner)
6. Verschiedene Themes durchschalten
7. Erwartung: Textfarben passen sich dem Theme an

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Aufruf | `.themeFont(.screenTitle)` ViewModifier | `TypographyRole.ScreenTitle.textStyle()` Composable |
| Halation | Font Weight +1 Stufe in Dark Mode | Font Weight +1 Stufe in Dark Mode |
| Dynamic Type | Body/List-Rollen skalieren | Body/List-Rollen skalieren |

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/Shared/Font+Theme.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/theme/Type.kt`

---

## Hinweise

- iOS nutzt `TypographyRole` Enum mit 20 Rollen und `ThemeTypographyModifier`
- Dark Mode Halation-Kompensation: ultraLight→thin, thin→light, light→regular, regular→medium
- SF Symbol Icons sind NICHT Teil des Typography Systems (eigene Sizing-Logik)
- Android muss MaterialTheme Typography erweitern, nicht ersetzen

---
