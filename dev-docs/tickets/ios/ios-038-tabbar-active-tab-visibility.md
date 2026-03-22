# Ticket ios-038: Tab-Bar aktiver Tab schlecht erkennbar (iOS 18)

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Der aktuell aktive Tab in der Tab-Bar ist unter iOS 18 visuell kaum vom inaktiven Zustand zu unterscheiden.

## Warum

Die Tab-Bar verwendet einen benutzerdefinierten farbigen Hintergrund (theme-abhängig). iOS wählt die Farbe inaktiver Tab-Icons automatisch, was auf den warmen/dunklen Theme-Hintergründen zu unzureichendem Kontrast führt. Nutzer können so nicht auf einen Blick erkennen, wo sie sich gerade befinden.

---

## Akzeptanzkriterien

### Feature
- [ ] Auf allen Themes (Light + Dark) ist der aktive Tab klar erkennbar
- [ ] Inaktive Tabs sind sichtbar gedimmt/zurückgestellt, aber noch lesbar
- [ ] Verhält sich konsistent bei Theme-Wechsel zur Laufzeit

### Tests
- [ ] Kein Unit Test erforderlich (reine visuelle Änderung)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. App starten, alle verfügbaren Themes durchschalten (Einstellungen → Erscheinungsbild)
2. Jeden der drei Tabs antippen
3. Erwartung: Der aktive Tab ist auf jedem Theme — sowohl Light als auch Dark — sofort als solcher erkennbar

---

## Hinweise

Bekanntes iOS 18 Verhalten: SwiftUI `TabView` ist UIKit-gebridged. Der `.tint()`-Modifier steuert nur die aktive Farbe; die inaktive Farbe folgt dem System-Default, der mit benutzerdefinierten Tab-Bar-Hintergründen kollidieren kann. Auch das MEMORY.md-Pattern (UIAppearance + `.id(theme)` für reaktive UIKit-Bridges) ist hier relevant.

---
