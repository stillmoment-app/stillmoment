# Accessibility-Konsistenz - Checklist

Prueft ob Accessibility-Labels und sichtbare UI-Labels konsistent sind.

## Grundprinzip

Accessibility-Labels sollten:
1. **Existieren** fuer alle interaktiven Elemente
2. **Lokalisiert sein** (nicht hardcoded)
3. **Konsistent sein** mit dem sichtbaren Text (oder sinnvoll erweitert)

## iOS Pruefung

### Interaktive Elemente ohne Accessibility

Suche nach Buttons/Controls ohne accessibilityLabel:

```swift
// FALSCH - Fehlendes Label
Button(action: { ... }) {
    Image(systemName: "gear")
}

// RICHTIG - Mit Label
Button(action: { ... }) {
    Image(systemName: "gear")
}
.accessibilityLabel("accessibility.settings")
```

### Lokalisierung der Labels

```swift
// FALSCH - Hardcoded
.accessibilityLabel("Settings")

// RICHTIG - Lokalisiert
.accessibilityLabel("accessibility.settings")
```

### Label vs. AccessibilityLabel Konsistenz

| Sichtbar | AccessibilityLabel | Bewertung |
|----------|-------------------|-----------|
| "Start" | "Start meditation" | OK (erweitert) |
| "Start" | "Begin session" | Warnung (anderes Wort) |
| "Start" | "Pause" | Fehler (widerspruch) |

## Android Pruefung

### Interaktive Elemente ohne contentDescription

```kotlin
// FALSCH - Fehlendes Label
IconButton(onClick = { ... }) {
    Icon(Icons.Default.Settings, contentDescription = null)
}

// RICHTIG - Mit Label
IconButton(onClick = { ... }) {
    Icon(
        Icons.Default.Settings,
        contentDescription = stringResource(R.string.accessibility_settings)
    )
}
```

### Semantics fuer komplexe Controls

```kotlin
// Fuer Slider, Checkboxen, etc.
Modifier.semantics {
    contentDescription = stringResource(R.string.accessibility_volume)
    stateDescription = "$volume%"
}
```

## Konsistenz-Matrix

### Buttons mit Text

| Element | Sichtbarer Text | AccessibilityLabel | Pruefung |
|---------|-----------------|-------------------|----------|
| Start Button | "Start" | "accessibility.startMeditation" | Label sollte "Start" enthalten oder sinnvoll erweitern |
| Pause Button | "Pause" | "accessibility.pauseMeditation" | OK |
| Settings Icon | (kein Text) | "accessibility.settings" | Muss beschreibend sein |

### Icon-Only Buttons

Diese benoetigen **immer** ein AccessibilityLabel:
- Settings (Zahnrad)
- Close (X)
- Play/Pause
- Navigation Icons

### Slider und Picker

Benoetigen:
- `accessibilityLabel` - Was wird eingestellt
- `accessibilityValue` - Aktueller Wert (iOS) / `stateDescription` (Android)

## Haeufige Fehler

### 1. Redundante Labels
```swift
// SCHLECHT - "Button" ist redundant
.accessibilityLabel("Start button")

// GUT - VoiceOver sagt automatisch "Button"
.accessibilityLabel("Start meditation")
```

### 2. Fehlende Hints
```swift
// Fuer komplexe Aktionen: Hint hinzufuegen
.accessibilityLabel("accessibility.timer")
.accessibilityHint("accessibility.timer.hint")  // "Doppeltippen zum Starten"
```

### 3. Dynamische Werte nicht aktualisiert
```swift
// FALSCH - Statischer Text
.accessibilityLabel("Timer")

// RICHTIG - Dynamischer Wert
.accessibilityLabel(Text("accessibility.remainingTime"))
.accessibilityValue(Text(timeString))
```

## Bewertung

| Finding | Schwere |
|---------|---------|
| Interaktives Element ohne AccessibilityLabel | Kritisch |
| Hardcoded AccessibilityLabel | Kritisch |
| Label und AccessibilityLabel widersprechen sich | Mittel |
| Fehlender Hint fuer komplexe Aktion | Gering |
| Redundante Begriffe im Label | Gering |

## Referenzen

- Apple Human Interface Guidelines: Accessibility
- Android Accessibility Guidelines
- `dev-docs/ACCESSIBILITY.md` (falls vorhanden)
