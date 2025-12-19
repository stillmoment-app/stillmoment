# Ticket android-018: Player "Now Playing" und Minus-Praefix entfernen

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

"Now Playing" Label und Minus-Praefix bei der verbleibenden Zeit aus dem Player-Screen entfernen.

## Warum

Meditation-Apps wie Headspace und Calm verzichten auf "Now Playing" - Teacher + Name sind selbsterklaerend. Das Minus-Praefix bei der verbleibenden Zeit ist ein veraltetes CD-Player-Relikt. iOS zeigt auch keins. Weniger visueller Clutter fuer eine ruhige Meditations-Aesthetik.

---

## Akzeptanzkriterien

- [ ] "Now Playing" Text entfernt
- [ ] Verbleibende Zeit ohne Minus anzeigen (`4:37` statt `-4:37`)
- [ ] Layout bleibt visuell ausgewogen
- [ ] UI Tests angepasst falls vorhanden

---

## Manueller Test

1. Guided Meditation importieren und abspielen
2. Player-Screen oeffnen
3. Erwartung: Kein "Now Playing" Label sichtbar, verbleibende Zeit ohne Minus-Praefix

---

## Referenz

- iOS Player (als Vorlage): `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift`
- Android Player: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationPlayerScreen.kt`

---

## Hinweise

- `MeditationInfoHeader` Composable enthaelt das "Now Playing" Label
- `PlayerControls` Composable zeigt die Zeit mit `-$formattedRemaining` an (Zeile ~314)
