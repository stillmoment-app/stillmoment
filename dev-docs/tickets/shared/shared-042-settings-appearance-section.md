# Ticket shared-042: Settings Erscheinungsbild-Section verbessern

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: iOS ~15min | Android ~10min
**Phase**: 4-Polish

---

## Was

Die Settings-Section fuer Farbthema und Darstellungsmodus soll bessere Beschriftung erhalten: Section-Header von "Allgemein" zu "Erscheinungsbild" umbenennen und ein sichtbares Label ueber dem System/Hell/Dunkel-Picker anzeigen.

## Warum

Der Header "Allgemein" ist zu generisch fuer eine Section, die ausschliesslich Erscheinungsbild-Optionen enthaelt. Der Darstellungsmodus-Picker (System/Hell/Dunkel) hat kein sichtbares Label - der User sieht drei Segmente ohne zu wissen, was sie steuern.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [ ]    | -             |

---

## Ziel-Layout

```
┌─────────────────────────────────────────┐
│                                         │
│  ERSCHEINUNGSBILD          (Section)    │
│                                         │
│  Farbthema                 Mondlicht ▾  │
│                                         │
│  Darstellung                            │
│  ┌───────────┬───────────┬────────────┐ │
│  │  System   │   Hell    │   Dunkel   │ │
│  └───────────┴───────────┴────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

Vorher:

```
┌─────────────────────────────────────────┐
│                                         │
│  ALLGEMEIN                 (Section)    │
│                                         │
│  Farbthema                 Mondlicht ▾  │
│                                         │
│  ┌───────────┬───────────┬────────────┐ │
│  │  System   │   Hell    │   Dunkel   │ │
│  └───────────┴───────────┴────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Section-Header zeigt "Erscheinungsbild" (DE) / "Appearance" (EN) statt "Allgemein" / "General"
- [ ] Ueber dem segmentierten Picker (System/Hell/Dunkel) steht das Label "Darstellung" (DE) / "Appearance" (EN)
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Einstellungen oeffnen (Timer oder Library)
2. Zur Erscheinungsbild-Section scrollen
3. Erwartung: Section-Header zeigt "ERSCHEINUNGSBILD", Label "Darstellung" steht ueber dem Segmented Picker

---

## Hinweise

- Android zeigt bereits ein Label "Darstellung" ueber dem Segmented Button - dort muss nur der Section-Header geaendert werden.
- iOS: Der Picker hat bereits die Localization-Key `settings.appearance.title`, aber SwiftUI `.segmented` Style versteckt das Label in einer List. Das Label muss separat angezeigt werden.
- Localization-Key `settings.general.header` existiert bereits auf beiden Plattformen.

---
