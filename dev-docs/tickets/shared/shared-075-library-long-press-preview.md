# Ticket shared-075: Long-Press Preview in der Meditations-Bibliothek

**Status**: [x] DONE
**Plan**: [Implementierungsplan](../plans/shared-075.md)
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h (Rework) | Android ~3h
**Phase**: 3-Feature

---

## Was

Redesign der Meditations-Row in der Bibliothek:

**Row-Layout:**
- Titel + Dauer links, Play-Button rechts
- Kein Overflow-Menu (⋮) mehr — Edit und Loeschen ueber Swipe-Actions

**Play-Button (rechts):**
- **Tap** → Meditation starten (Navigation zum Full Player)
- **Long-Press** (~0.5s) → Preview starten (laeuft bis Stop gedrueckt wird)
- Waehrend Preview: Icon wechselt von ▶ zu ■, Tap auf ■ stoppt Preview

**Swipe-Actions (links wischen):**
- Bearbeiten (blau) + Loeschen (rot)

**Row-Text** (Titel, Dauer) ist nicht tappbar — nur scrollbar.

## Warum

Aktuell muss man eine Meditation komplett oeffnen (Fullscreen-Player), um reinzuhoeren. Bei einer laengeren Liste ist das muehsam, wenn man eine bestimmte Meditation sucht. Long-Press-Preview ermoeglicht schnelles Reinhoren, ohne die Liste zu verlassen.

**Use Cases:**
- Meditation kurz vorhoeren ("Ist das die richtige?")
- Lautstaerke pruefen bevor man eine Session startet

## UI-Konzept-Aenderung (2026-03-14)

Die urspruengliche Implementierung (DragGesture "solange Finger drauf") war instabil — `DragGesture.onEnded` feuert nicht zuverlaessig in einer List (Scroll-Konflikt), was zu unkontrolliert weiterlaufenden Previews fuehrte. SwiftUI bietet keine robuste "press-and-hold-then-release"-Geste.

Neues Konzept: Long-Press startet Preview, Preview laeuft bis expliziter Stop-Tap. Kein Gesture-Tracking waehrend der Wiedergabe noetig. Overflow-Menu entfernt zugunsten von Swipe-Actions.

```
Idle:                          Preview laeuft:
┌────────────────────────┐     ┌────────────────────────┐
│  Bodyscan    25:00  ▶  │     │  Bodyscan    25:00  ■  │
└────────────────────────┘     └────────────────────────┘
                Tap→Start       Tap→Stop
           Long Press→Preview

Swipe links:
┌────────────────────────┬────────────┬─────────┐
│  Bodyscan    25:00  ▶  │ Bearbeiten │ Loeschen│
└────────────────────────┴────────────┴─────────┘
                            (blau)      (rot)
```

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Row-Layout (beide Plattformen)
- [x] Play-Button rechts in der Row
- [x] Kein Overflow-Menu — Edit und Loeschen ueber Swipe-Actions (links wischen)
- [x] Swipe-Links: Bearbeiten (blau) + Loeschen (rot)
- [x] Row-Text (Titel, Dauer) ist nicht tappbar — nur scrollbar

### Preview (beide Plattformen)
- [x] Tap auf Play-Button startet die Meditation (Navigation zum Full Player)
- [x] Long-Press (~0.5s) auf Play-Button startet Preview ab Anfang
- [x] Waehrend Preview: Play-Icon (play.circle.fill) wechselt zu Stop-Icon (stop.circle.fill)
- [x] Tap auf Stop-Icon stoppt die Preview (mit kurzem Fade-out ~0.3s)
- [x] Nur eine Preview gleichzeitig (neuer Long-Press stoppt vorherige Preview)
- [x] Haptisches Feedback beim Start der Preview
- [x] Preview nutzt die Audio-Session-Source `.preview` (nicht `.guidedMeditation`)
- [x] Preview blockiert nicht den Start einer vollstaendigen Meditation (Navigation zum Player stoppt Preview automatisch)

### Tests
- [x] Unit Tests iOS
- [x] Unit Tests Android

### Dokumentation
- [x] CHANGELOG.md aktualisieren

---

## Manueller Test

### Preview
1. Meditations-Bibliothek oeffnen (mindestens 2 Meditationen vorhanden)
2. Auf den Play-Button (▶, rechts) einer Meditation **lang druecken** (~0.5s)
3. Erwartung: Haptisches Feedback, Icon wechselt zu ■, Audio startet ab Anfang
4. Auf den Stop-Button (■) **tippen**
5. Erwartung: Audio stoppt mit kurzem Fade-out, Icon wechselt zurueck zu ▶
6. Auf den Play-Button **kurz tippen**
7. Erwartung: Navigation zum Full Player (Meditation starten)
8. Auf den Meditations-Titel oder die Dauer tippen
9. Erwartung: Nichts passiert (kein Tap-Handler, nur Scroll)
10. Preview starten, dann auf Play-Button einer anderen Meditation lang druecken
11. Erwartung: Erste Preview stoppt, zweite startet

### Swipe-Actions
12. Auf einer Meditation-Row **nach links wischen**
13. Erwartung: Zwei Buttons erscheinen — "Bearbeiten" (blau) + "Loeschen" (rot)
14. Auf "Bearbeiten" tippen
15. Erwartung: Edit-Sheet oeffnet sich
16. Auf einer anderen Row nach links wischen, "Loeschen" tippen
17. Erwartung: Loeschen-Bestaetigungsdialog erscheint

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/guidedmeditations/`
- Preview-Pattern (Vorlage): `ios/StillMoment/Infrastructure/Services/AudioService.swift` (playGongPreview, playBackgroundPreview)

---

## Hinweise

### iOS (implementiert)
- Play-Button: `Image` mit `.onTapGesture` + `.onLongPressGesture(minimumDuration: 0.5)`. Kein `Button` (Tap und Long-Press kollidieren bei `Button`). Kein `DragGesture` (instabil in List).
- Swipe-Actions: `.swipeActions(edge: .trailing)` auf der Row. Zwei separate `.swipeActions`-Modifier (Loeschen + Bearbeiten).
- AudioService: `playMeditationPreview(fileURL:)` / `stopMeditationPreview()` unveraendert.
- Preview-Zustand: Ausschliesslich ueber `viewModel.previewingMeditationId` — kein lokaler View-State.

### Android (offen)
- Play-Button: `combinedClickable(onLongClick = ..., onClick = ...)` auf dem Play-Icon, `HapticFeedback` beim Start.
- Swipe-Actions: `SwipeToDismissBox` oder `material3` Swipe-to-Reveal Pattern.
- Row-Text: Kein `clickable()` auf der Row — nur Play-Button ist interaktiv.

---
