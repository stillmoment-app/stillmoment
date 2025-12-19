# Ticket android-011: Accessibility Audit

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein (~1-2h)
**Abhaengigkeiten**: android-009
**Phase**: 5-QA

---

## Beschreibung

Accessibility-Audit aller UI-Komponenten durchfuehren und fehlende Labels hinzufuegen. Sicherstellen, dass die App mit TalkBack vollstaendig nutzbar ist.

---

## Akzeptanzkriterien

- [x] Alle interaktiven Elemente haben contentDescription
- [x] Custom Components haben semantics{} Block
- [x] Timer-Fortschritt ist als Text verfuegbar
- [x] Slider haben valueRange beschrieben
- [x] TalkBack-Navigation funktioniert auf allen Screens
- [x] Focus-Reihenfolge ist logisch
- [x] Live-Regions fuer dynamische Updates

---

## Betroffene Dateien

### Zu pruefen und ggf. aendern:
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/TimerScreen.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/MinutePicker.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/SettingsSheet.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationsListScreen.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationPlayerScreen.kt`

### Strings hinzufuegen:
- `android/app/src/main/res/values/strings.xml`
- `android/app/src/main/res/values-de/strings.xml`

---

## Checkliste

### Timer Screen
- [x] Duration Picker: `stateDescription` fuer ausgewaehlte Minuten (bereits in WheelPicker.kt)
- [x] Start Button: `contentDescription` (bereits vorhanden)
- [x] Pause Button: `contentDescription` (bereits vorhanden)
- [x] Resume Button: `contentDescription` (bereits vorhanden)
- [x] Reset Button: `contentDescription` (bereits vorhanden)
- [x] Settings Button: `contentDescription` (korrigiert - hardcoded entfernt)
- [x] Timer Progress Ring: `stateDescription` fuer verbleibende Zeit (bereits vorhanden)
- [x] Countdown-Zahl: Live Region fuer Updates (hinzugefuegt)
- [x] Affirmation Text: (Teil des Timer-Bereichs)

### Settings Sheet
- [x] Background Sound Picker: `stateDescription` (hinzugefuegt)
- [x] Interval Toggle: `stateDescription` on/off (hinzugefuegt)
- [x] Interval Picker: `stateDescription` (hinzugefuegt)
- [x] Done Button: `contentDescription` (hinzugefuegt)

### Library Screen
- [x] Import FAB: `contentDescription` (bereits vorhanden)
- [x] Meditation Item: `contentDescription` mit Name und Dauer (bereits in MeditationListItem.kt)
- [x] Edit Button: `contentDescription` (bereits vorhanden)
- [x] Delete Action: `contentDescription` (bereits vorhanden)
- [x] Section Headers: Heading semantics (hinzugefuegt)

### Player Screen
- [x] Back Button: `contentDescription` (bereits vorhanden)
- [x] Play/Pause Button: `contentDescription` (state-dependent, bereits vorhanden)
- [x] Seek Slider: `valueRange` und `contentDescription` (bereits vorhanden)
- [x] Progress: `stateDescription` (hinzugefuegt)
- [x] Current Time: (nicht als Live Region - wuerde zu viel vorlesen)

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

### Beispiel: Live Region fuer Timer
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

# 3. Pruefen:
# - Werden alle Elemente vorgelesen?
# - Sind die Beschreibungen verstaendlich?
# - Ist die Reihenfolge logisch?
# - Werden Aenderungen angekuendigt?
```

---

## Tools

- **Accessibility Scanner**: Google Play Store App
- **TalkBack**: Built-in Screen Reader
- **Layout Inspector**: Android Studio Tool
