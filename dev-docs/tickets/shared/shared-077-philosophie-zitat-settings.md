# Ticket shared-077: Philosophie-Zitat in den Einstellungen

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: iOS ~1h | Android ~1h
**Phase**: 4-Polish

---

## Was

Das App-Philosophie-Zitat ("Meditiere nicht, um dich zu verbessern oder zu erlösen. Tue es als Akt der Liebe — der tiefen, warmen Freundschaft mit dir selbst.") wird als stiller Abschluss ganz unten in den Einstellungen angezeigt.

## Warum

Das Zitat beschreibt den Geist der App besser als jede Featureliste. Es gehört nicht ins Onboarding (wird weggeklickt) und nicht in leere Zustände (dort braucht der User Orientierung). Wer bis ans Ende der Einstellungen scrollt, bekommt einen Moment des Erkennens: "Ah, darum geht es hier."

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Das Zitat erscheint ganz unten in den Einstellungen, nach allen funktionalen Sektionen (inkl. Version)
- [ ] Es ist kein interaktives Element (kein Link, kein Button, keine Navigation)
- [ ] Es verschiebt keine bestehenden Settings nach unten — es ist der letzte Inhalt der Seite
- [ ] Schriftbild ist dezent (kleiner, gedämpfte Farbe) — es soll nicht dominieren
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Kein Unit Test notwendig (rein visuell/statisch)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Einstellungen öffnen
2. Bis ans Ende scrollen
3. Erwartung: Das Zitat steht ganz unten, ruhig und dezent — alle anderen Settings sind unverändert erreichbar

---

## UX-Konsistenz

Das Zitat selbst ist plattformübergreifend identisch. Die visuelle Gestaltung folgt dem jeweiligen Design-System (iOS: `.themeFont`, Android: `MaterialTheme.typography`).

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/AppSettings/AppSettingsView.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/` (Settings-Screen)

---

## Zitat-Text

> Meditiere nicht, um dich zu verbessern oder zu erlösen.\
> Tue es als Akt der Liebe —\
> der tiefen, warmen Freundschaft mit dir selbst.

DE und EN müssen lokalisiert sein.
