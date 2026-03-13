# Ticket shared-075: Long-Press Preview in der Meditations-Bibliothek

**Status**: [~] IN PROGRESS
**Plan**: [Implementierungsplan](../plans/shared-075.md)
**Prioritaet**: MITTEL
**Aufwand**: iOS ~3h | Android ~3h
**Phase**: 3-Feature

---

## Was

In der Meditations-Liste soll ein Long-Press auf die Row eine Audio-Preview der Meditation abspielen — solange der Finger gedrueckt bleibt. Loslassen stoppt die Wiedergabe. Ein kurzer Tap navigiert wie bisher zum Full Player.

## Warum

Aktuell muss man eine Meditation komplett oeffnen (Fullscreen-Player), um reinzuhoeren. Bei einer laengeren Liste ist das muehsam, wenn man eine bestimmte Meditation sucht. Long-Press-Preview ermoeglicht schnelles Reinhoren, ohne die Liste zu verlassen.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Long-Press auf die Row startet die Meditation ab Anfang als Preview (Overflow-Menu ausgenommen)
- [ ] Loslassen stoppt die Preview sofort (mit kurzem Fade-out ~0.3s)
- [ ] Kurzer Tap auf die Row navigiert zum Full Player
- [ ] Nur eine Preview gleichzeitig (neuer Long-Press stoppt vorherige Preview)
- [ ] Haptisches Feedback beim Start der Preview
- [ ] Subtiler Scale-Effekt auf dem Icon waehrend des Drueckens (visuelles Feedback)
- [ ] Preview nutzt die Audio-Session-Source `.preview` (nicht `.guidedMeditation`)
- [ ] Preview blockiert nicht den Start einer vollstaendigen Meditation (Navigation zum Player stoppt Preview automatisch)

### Tests
- [ ] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Meditations-Bibliothek oeffnen (mindestens 2 Meditationen vorhanden)
2. Auf eine Meditation-Row lang druecken (egal ob Icon oder Text)
3. Erwartung: Haptisches Feedback, Play-Icon wird leicht groesser, Audio startet ab Anfang
4. Finger loslassen
5. Erwartung: Audio stoppt mit kurzem Fade-out
6. Auf die Row (Name/Dauer) tippen
7. Erwartung: Navigation zum Full Player wie bisher
8. Waehrend Preview laeuft: auf anderes Play-Icon druecken
9. Erwartung: Erste Preview stoppt, neue startet

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/guidedmeditations/`
- Preview-Pattern (Vorlage): `ios/StillMoment/Infrastructure/Services/AudioService.swift` (playGongPreview, playBackgroundPreview)

---

## Hinweise

- iOS: `DragGesture(minimumDistance: 0)` oder `.onLongPressGesture(minimumDuration:)` mit `pressing:`-Callback auf dem Play-Icon. Der umgebende NavigationLink muss den Tap auf das Icon nicht abfangen.
- AudioService braucht eine neue Methode `playMeditationPreview(filePath:)` / `stopMeditationPreview()` analog zu den bestehenden Preview-Methoden.
- Android: Kombination aus `pointerInput` mit `detectTapGestures(onPress = ...)` auf dem Icon, `HapticFeedback` beim Start.

---
