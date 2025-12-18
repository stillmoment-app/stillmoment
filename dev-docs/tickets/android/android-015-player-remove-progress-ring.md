# Ticket android-015: Player Progress-Ring entfernen

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: Klein (~1h)
**Abhaengigkeiten**: android-008
**Phase**: 4-Polish

---

## Beschreibung

Der Android Guided Meditation Player zeigt einen grossen Progress-Ring mit verbleibender Zeit, der redundant ist. Der Slider darunter zeigt bereits dieselben Informationen (Fortschritt, Position, Dauer).

**Problem:**
- Progress-Ring zeigt verbleibende Zeit
- Slider zeigt Position und Gesamtdauer
- Doppelte Information, verschwendet Bildschirmplatz

**iOS-Referenz:**
Der iOS Player (`GuidedMeditationPlayerView.swift`) hat keinen Progress-Ring - nur den Slider mit Zeit-Labels. Das ist das bessere Design fuer einen Audio-Player.

**Unterschied zum Timer:**
Der Progress-Ring macht beim Timer-Screen Sinn (Countdown-Visualisierung), aber beim Guided Meditation Player ist ein linearer Slider die bessere Metapher fuer Audio-Wiedergabe.

---

## Akzeptanzkriterien

- [x] Progress-Ring aus `GuidedMeditationPlayerScreen` entfernt
- [x] Layout an iOS-Design angepasst (Slider mit Zeit-Labels)
- [x] Verbleibende Zeit weiterhin sichtbar (als Label, nicht im Ring)
- [x] UI visuell konsistent mit iOS Player

### Tests (PFLICHT)
- [x] Unit Tests geschrieben/aktualisiert
- [x] Bestehende Tests weiterhin gruen
- [ ] Manuelle Tests durchgefuehrt

### Dokumentation
- [x] CHANGELOG.md: Changed Eintrag

---

## Betroffene Dateien

### Zu aendern:
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationPlayerScreen.kt`
  - `PlayerProgressRing` Composable entfernen (Zeile 253-308)
  - Layout anpassen: Mehr Platz fuer Meditation-Info
  - Optional: Verbleibende Zeit als separates Label hinzufuegen

### Tests:
- Manuelle UI-Tests

---

## Technische Details

### Aktuelles Layout (Android):
```
[Header: Teacher + Name]
[Progress Ring mit Zeit]   <-- ENTFERNEN
[Slider]
[Position --- Dauer]
[Controls]
```

### Neues Layout (wie iOS):
```
[Header: Teacher + Name]
[Spacer - mehr Platz]
[Slider]
[Position --- Verbleibend]
[Controls]
```

### Code-Aenderungen:

```kotlin
// ENTFERNEN: PlayerProgressRing Composable (Zeile 253-308)
@Composable
private fun PlayerProgressRing(...) { ... }

// ENTFERNEN: Aufruf in GuidedMeditationPlayerScreenContent
// Progress Ring
PlayerProgressRing(
    progress = uiState.progress,
    formattedTime = uiState.formattedRemaining
)

// ANPASSEN: Zeit-Labels unter Slider
Row(
    modifier = Modifier.fillMaxWidth(),
    horizontalArrangement = Arrangement.SpaceBetween
) {
    Text(text = formattedPosition, ...)
    Text(text = formattedRemaining, ...)  // War: formattedDuration
}
```

### iOS-Referenz (GuidedMeditationPlayerView.swift:74-89):
```swift
// Time labels
HStack {
    Text(self.viewModel.formattedCurrentTime)
        .font(.system(.caption, design: .rounded).monospacedDigit())
        .foregroundColor(.textSecondary)

    Spacer()

    Text(self.viewModel.formattedRemainingTime)
        .font(.system(.caption, design: .rounded).monospacedDigit())
        .foregroundColor(.textSecondary)
}
```

---

## Testanweisungen

```bash
cd android && ./gradlew test
```

### Manueller Test:
1. App starten
2. Library Tab oeffnen
3. Meditation auswaehlen und Player oeffnen
4. Erwartung: Kein Progress-Ring, nur Slider mit Zeit-Labels
5. Play/Pause und Seek testen
6. Vergleich mit iOS Player (sollte aehnlich aussehen)

---

## Referenzen

- iOS Player: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift`
- Android Player: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationPlayerScreen.kt`
