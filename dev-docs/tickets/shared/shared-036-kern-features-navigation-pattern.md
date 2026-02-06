# Ticket shared-036: Kern-Features Navigation Pattern

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h | Android ~0h (bereits korrekt)
**Phase**: 2-Architektur

---

## Was

Timer-Meditation und Meditations-Player nutzen Navigation-Screens (Push) statt Sheets fuer ihre Kern-Features. Konsistentes X-Icon oben links zum Beenden beider Screens.

## Warum

Sheets sind fuer temporaere Aufgaben (Einstellungen, Bearbeitung), nicht fuer Kern-Features. Die Sheet-basierte TimerFocusView auf iOS verursachte UX-Probleme: Swipe-Dismiss ohne Timer-Reset, inkonsistente Praesentation zwischen Timer und Player. Android hatte das korrekte Pattern (Navigation-Destination) bereits seit shared-013. Dieses Ticket korrigiert die iOS-Implementierung auf das Android-Pattern.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | Fertig (Sheet → Navigation korrigiert) |
| Android   | [x]    | Bereits korrekt seit shared-013 |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Timer-Start zeigt Fokus-Ansicht als Navigation-Screen (nicht Sheet)
- [x] Player oeffnet per Navigation-Push (nicht Sheet)
- [x] X-Icon oben links bei Timer-Fokus und Player
- [x] Keine Disclosure-Indicators (Chevrons) in der Bibliothek-Liste
- [x] Visuell konsistent zwischen iOS und Android

### Tests
- [x] UI Tests iOS (TimerFlowUITests, LibraryFlowUITests)
- [x] Unit Tests Android (bereits vorhanden)

---

## Manueller Test

1. App oeffnen, Timer-Tab
2. Timer starten
3. Erwartung: Fokus-Ansicht erscheint als Vollbild-Navigation (kein Sheet, kein Swipe-Dismiss)
4. X-Icon oben links druecken → zurueck zur Timer-Auswahl
5. Bibliothek-Tab oeffnen, Meditation auswaehlen
6. Erwartung: Player erscheint als Navigation-Push, X-Icon oben links
7. Keine Chevrons (>) in der Meditationsliste sichtbar

---

## UX-Konsistenz

| Verhalten | iOS (vorher) | iOS (nachher) | Android |
|-----------|-------------|---------------|---------|
| Timer-Fokus | Sheet (TimerFocusView) | Navigation in TimerView | Navigation (TimerFocusScreen) |
| Player | Sheet (.sheet(item:)) | navigationDestination(for:) | Navigation (composable) |
| Schliessen-Icon | Text "Schliessen" | X-Icon links | X-Icon links |
| Disclosure-Indicator | Sichtbar | Versteckt | Nicht vorhanden |

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/Timer/TimerView.swift`
- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift`
- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/TimerFocusScreen.kt`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationPlayerScreen.kt`

---

## Hinweise

- iOS: `TimerFocusView.swift` wurde eliminiert - Timer-States (countdown, running, paused, completed) sind jetzt direkt in `TimerView` integriert
- iOS: `.navigationDestination(for:)` ersetzt `.sheet(item:)` fuer den Player
- iOS: Disclosure-Indicators via `.listRowSeparator(.hidden)` und custom Row-Style versteckt
- Korrigiert die iOS-Implementierung von shared-013 auf das Android-Pattern
