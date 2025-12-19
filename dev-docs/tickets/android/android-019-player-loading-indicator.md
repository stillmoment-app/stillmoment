# Ticket android-019: Player Loading-Indikator hinzufuegen

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Dezenten Loading-Indikator beim initialen Laden einer Meditation anzeigen.

## Warum

User braucht visuelles Feedback dass etwas passiert. iOS hat bereits einen Loading-Overlay. Ohne Indikator wirkt die App "eingefroren" wenn das Audio noch laedt. Der Indikator sollte dezent sein um die ruhige Meditations-Aesthetik zu bewahren.

---

## Akzeptanzkriterien

- [ ] CircularProgressIndicator anzeigen waehrend Audio laedt
- [ ] Dezent gestaltet (nicht zu prominent, passend zur Meditations-App)
- [ ] Verschwindet sobald Audio bereit ist
- [ ] `isLoading` State im ViewModel/UiState hinzufuegen falls nicht vorhanden

---

## Manueller Test

1. Guided Meditation importieren
2. Meditation antippen um Player zu oeffnen
3. Erwartung: Kurz Loading-Indikator sichtbar, dann Player-Controls

---

## Referenz

- iOS Loading-Overlay: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift` (Zeile ~147-152)
- Android Player: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationPlayerScreen.kt`
- Android ViewModel: `android/app/src/main/kotlin/com/stillmoment/presentation/viewmodel/GuidedMeditationPlayerViewModel.kt`

---

## Hinweise

- iOS nutzt `ProgressView()` mit semi-transparentem Overlay
- Material3 bietet `CircularProgressIndicator` - auf Theme-Farben achten (Terracotta)
- Loading-State sollte nur beim initialen Laden true sein, nicht bei Seek/Skip
