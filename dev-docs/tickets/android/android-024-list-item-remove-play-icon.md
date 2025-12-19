# Ticket android-024: Play-Icon aus List Items entfernen

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Das Play-Icon links in den Meditations-List-Items entfernen. Die Items bleiben tappbar, aber ohne redundantes Icon.

## Warum

Das Play-Icon ist redundant - das gesamte List Item ist bereits tappbar und das Tap-to-Play-Verhalten ist in Library-UIs gelernt (Spotify, Apple Music, Podcasts). Weniger visuelle Elemente = ruhigeres UI, passender fuer eine Meditations-App.

Bonus: Konsistenz mit iOS, das keine Play-Icons in der Liste zeigt.

---

## Akzeptanzkriterien

- [ ] Play-Icon (`Icons.Default.PlayArrow`) aus `MeditationListItem` entfernt
- [ ] Layout angepasst: [Name + Duration] [Edit-Button]
- [ ] Card bleibt vollstaendig tappbar
- [ ] Visuell cleaner als vorher
- [ ] Accessibility: Item-Description bleibt vollstaendig

---

## Manueller Test

1. Library mit Meditationen oeffnen
2. Erwartung: Kein Play-Icon links in den Eintraegen
3. Tap auf Eintrag oeffnet weiterhin den Player

---

## Referenz

- Aktuell: `MeditationListItem.kt` - `Icons.Default.PlayArrow`
- iOS-Referenz: `GuidedMeditationsListView.swift` - `meditationRow` (kein Play-Icon)
