# Ticket ios-013: Player Stop-Button entfernen

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Stop-Button aus dem Guided Meditation Player entfernen.

## Warum

Moderne Audio Player (Spotify, Apple Music, Headspace, Calm) haben keinen separaten Stop-Button. Pause + Schliessen ist ausreichend - der Close-Button beendet bereits die Wiedergabe (ruft `cleanup()` auf). Weniger visueller Clutter, passt besser zur ruhigen Meditations-Aesthetik. Android hat ebenfalls keinen Stop-Button.

---

## Akzeptanzkriterien

- [x] Stop-Button aus PlayerView entfernt
- [x] `stop()` Funktion im ViewModel bleibt erhalten (wird von `cleanup()` aufgerufen)
- [x] Layout bleibt visuell ausgewogen
- [x] UI Tests angepasst falls vorhanden (keine vorhanden)

---

## Manueller Test

1. Guided Meditation abspielen
2. Player-Screen oeffnen
3. Erwartung: Nur Play/Pause und Skip-Buttons sichtbar, kein Stop-Button
4. Close-Button antippen
5. Erwartung: Wiedergabe stoppt, Player schliesst sich

---

## Referenz

- Android Player (als Vorlage ohne Stop): `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationPlayerScreen.kt`
- iOS Player: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift`

---

## Hinweise

- Stop-Button ist aktuell in Zeile ~131-140 der PlayerView
- `cleanup()` wird bereits bei `onDisappear` und Close-Button aufgerufen
- Der vertikale Platz kann fuer besseres Spacing genutzt werden oder einfach als Spacer verbleiben
