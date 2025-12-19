# Ticket ios-014: Play-Icon in Library List Items

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Die Meditations-Eintraege in der Library sollen ein Play-Icon auf der linken Seite erhalten, um die Tap-Aktion (Wiedergabe starten) visuell zu signalisieren.

## Warum

Aktuell sind die List Items reine Text-Elemente ohne visuelle Affordanz. Android zeigt bereits ein Play-Icon, was sofort signalisiert "tippe hier um abzuspielen". Dies verbessert die Discoverability und UX-Konsistenz zwischen den Plattformen.

---

## Akzeptanzkriterien

- [ ] Play-Icon (`play.fill`) links im List Item
- [ ] Icon in `Color.interactive` (Terracotta)
- [ ] Icon-Groesse passend zur Texthoehe (~24pt)
- [ ] Layout: [Play-Icon] [Name + Duration] [Edit-Button]
- [ ] Accessibility: Icon ist dekorativ (Teil des tappable Items)
- [ ] Konsistenz mit Android-Darstellung

---

## Manueller Test

1. Library mit Meditationen oeffnen
2. Erwartung: Jeder Eintrag zeigt links ein Play-Icon
3. Tippen auf Eintrag oeffnet Player (unveraendertes Verhalten)
4. VoiceOver: Eintrag wird als eine Einheit gelesen (nicht Icon separat)

---

## Referenz

- Android-Implementierung: `MeditationListItem.kt` - `Icons.Default.PlayArrow`
- iOS aktuell: `GuidedMeditationsListView.swift` - `meditationRow(for:)` Funktion
- iOS-Pattern: SF Symbol `play.fill` oder `play.circle.fill`

---

## Hinweise

Das Play-Icon sollte NICHT einzeln tappbar sein - es ist Teil des gesamten List Items. Der Edit-Button rechts bleibt separat tappbar.
