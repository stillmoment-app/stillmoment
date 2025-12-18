# Ticket 011: Accessibility Audit

**Status**: [ ] TODO
**Priorität**: MITTEL
**Aufwand**: Klein (~1-2h)
**Abhängigkeiten**: 009

---

## Beschreibung

Accessibility-Audit aller UI-Komponenten durchführen und fehlende Labels hinzufügen. Sicherstellen, dass die App mit TalkBack vollständig nutzbar ist.

---

## Akzeptanzkriterien

- [ ] Alle interaktiven Elemente haben contentDescription
- [ ] Custom Components haben semantics{} Block
- [ ] Timer-Fortschritt ist als Text verfügbar
- [ ] Slider haben valueRange beschrieben
- [ ] TalkBack-Navigation funktioniert auf allen Screens
- [ ] Focus-Reihenfolge ist logisch
- [ ] Live-Regions für dynamische Updates

---

## Betroffene Dateien

### Zu prüfen und ggf. ändern:
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/TimerScreen.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/MinutePicker.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/SettingsSheet.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationsListScreen.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationPlayerScreen.kt`

### Strings hinzufügen:
- `android/app/src/main/res/values/strings.xml`
- `android/app/src/main/res/values-de/strings.xml`

---

## Checkliste

### Timer Screen
- [ ] Duration Picker: `stateDescription` für ausgewählte Minuten
- [ ] Start Button: `contentDescription`
- [ ] Pause Button: `contentDescription`
- [ ] Resume Button: `contentDescription`
- [ ] Reset Button: `contentDescription`
- [ ] Settings Button: `contentDescription`
- [ ] Timer Progress Ring: `stateDescription` für verbleibende Zeit
- [ ] Countdown-Zahl: Live Region für Updates
- [ ] Affirmation Text: `liveRegion` für Änderungen

### Settings Sheet
- [ ] Background Sound Picker: `stateDescription`
- [ ] Interval Toggle: `stateDescription` on/off
- [ ] Interval Picker: `stateDescription`
- [ ] Done Button: `contentDescription`

### Library Screen
- [ ] Import FAB: `contentDescription`
- [ ] Meditation Item: `contentDescription` mit Name und Dauer
- [ ] Edit Button: `contentDescription`
- [ ] Delete Action: `contentDescription`
- [ ] Section Headers: Heading semantics

### Player Screen
- [ ] Back Button: `contentDescription`
- [ ] Play/Pause Button: `contentDescription` (state-dependent)
- [ ] Seek Slider: `valueRange` und `contentDescription`
- [ ] Progress: `stateDescription`
- [ ] Current Time: Live Region

---

## Technische Details

### Beispiel: Timer Progress Ring
```kotlin
Box(
    modifier = Modifier
        .semantics {
            contentDescription = "Timer progress"
            stateDescription = "$minutes minutes and $seconds seconds remaining"
            liveRegion = LiveRegionMode.Polite
        }
) {
    CircularProgressIndicator(...)
    Text(formattedTime)
}
```

### Beispiel: Play/Pause Button
```kotlin
FloatingActionButton(
    onClick = onPlayPause,
    modifier = Modifier.semantics {
        contentDescription = if (isPlaying) {
            context.getString(R.string.accessibility_pause_button_player)
        } else {
            context.getString(R.string.accessibility_play_button)
        }
        role = Role.Button
    }
) { ... }
```

### Beispiel: Seek Slider
```kotlin
Slider(
    value = progress,
    onValueChange = onSeek,
    modifier = Modifier.semantics {
        contentDescription = context.getString(R.string.accessibility_seek_slider)
        stateDescription = context.getString(
            R.string.accessibility_player_progress,
            (progress * 100).toInt()
        )
    }
)
```

### Beispiel: Live Region für Timer
```kotlin
Text(
    text = remainingTime,
    modifier = Modifier.semantics {
        liveRegion = LiveRegionMode.Polite
        contentDescription = "$minutes minutes, $seconds seconds remaining"
    }
)
```

---

## Neue Strings

```xml
<!-- values/strings.xml -->
<string name="accessibility_timer_progress_state">%1$d minutes and %2$d seconds remaining</string>
<string name="accessibility_meditation_item">%1$s by %2$s, duration %3$s</string>
<string name="accessibility_sound_selected">%s selected</string>
<string name="accessibility_interval_enabled">Interval gongs enabled, every %d minutes</string>
<string name="accessibility_interval_disabled">Interval gongs disabled</string>
```

---

## Testanweisungen

```bash
# 1. TalkBack aktivieren
# Settings → Accessibility → TalkBack → On

# 2. Jeden Screen durchnavigieren
# - Timer Screen: Picker, Buttons, Progress
# - Settings Sheet: Alle Optionen
# - Library Screen: Liste, FAB, Items
# - Player Screen: Controls, Slider

# 3. Prüfen:
# - Werden alle Elemente vorgelesen?
# - Sind die Beschreibungen verständlich?
# - Ist die Reihenfolge logisch?
# - Werden Änderungen angekündigt?
```

---

## Tools

- **Accessibility Scanner**: Google Play Store App
- **TalkBack**: Built-in Screen Reader
- **Layout Inspector**: Android Studio Tool
