# Ticket shared-071: Tab "Bibliothek" → "Meditationen" + Icon waveform

**Status**: [~] IN PROGRESS
**Prioritaet**: NIEDRIG
**Aufwand**: iOS ~0.5h | Android ~0.5h
**Phase**: 4-Polish

---

## Was

Den Tab-Bezeichner "Bibliothek" (EN: "Library") umbenennen zu "Meditationen" (EN: "Meditations") und das Tab-Icon von `music.note.list` (iOS) / entsprechendem Musik-Icon (Android) auf `waveform` (iOS) / `waveform` (Android) ändern.

## Warum

"Bibliothek" und das Musik-Noten-Icon kommunizieren den Inhalt ungenau: Ersteres evoziert Bücher/Text, Letzteres Musik-Playlists. "Meditationen" ist direkt und klar, das Waveform-Icon signalisiert Audio-Inhalt und passt zur ruhigen Ästhetik der App.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Tab-Label lautet "Meditationen" (DE) / "Meditations" (EN)
- [ ] Tab-Icon ist `waveform` (SF Symbol iOS) / gleichwertiges Waveform-Icon (Android Material)
- [ ] Accessibility-Label ist konsistent mit neuem Namen
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Kein Unit Test erforderlich (reine Lokalisierungs-/Icon-Änderung)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. App starten
2. Tab-Bar prüfen: zweiter Tab zeigt "Meditationen" (DE) / "Meditations" (EN) mit Waveform-Icon
3. Accessibility: VoiceOver liest Tab korrekt vor

---

## Referenz

- iOS: `ios/StillMoment/StillMomentApp.swift` (tabItem Label + systemImage), `ios/StillMoment/Resources/*/Localizable.strings` (key `tab.library`)
- Android: Tab-Definition in Navigation/MainScreen

---
