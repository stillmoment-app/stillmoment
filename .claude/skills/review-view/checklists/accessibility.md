# Accessibility Checkliste (25 Punkte)

## iOS (SwiftUI)

### Interaktive Elemente (10 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| `.accessibilityLabel()` auf allen Buttons | 3 | Grep nach `Button` ohne `.accessibilityLabel` |
| `.accessibilityHint()` für komplexe Aktionen | 2 | Wichtige Buttons haben Hints |
| `.accessibilityIdentifier()` für UI-Tests | 2 | Alle interaktiven Elemente haben IDs |
| Touch-Targets >= 44pt | 3 | Keine zu kleinen Buttons/Tappable Areas |

**Patterns suchen:**
```swift
// KORREKT
Button(action: startTimer) { ... }
    .accessibilityLabel("accessibility.startMeditation")
    .accessibilityHint("accessibility.startMeditation.hint")
    .accessibilityIdentifier("timer.button.start")

// FALSCH - fehlende Labels
Button(action: startTimer) { Image(systemName: "play") }
```

### Dynamische Inhalte (8 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| `.accessibilityValue()` für Statusanzeigen | 3 | Timer, Progress haben Values |
| VoiceOver-Ankündigungen bei Änderungen | 3 | `UIAccessibility.post(notification:)` |
| Sinnvolle Lesereihenfolge | 2 | `.accessibilitySortPriority()` wo nötig |

### Kontrast & Sichtbarkeit (7 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| Kontrast >= 4.5:1 (WCAG AA) | 3 | Semantic Colors nutzen |
| Dynamic Type unterstützt | 2 | Keine festen Schriftgrößen |
| Reduce Motion respektiert | 2 | `@Environment(\.accessibilityReduceMotion)` |

---

## Android (Jetpack Compose)

### Interaktive Elemente (10 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| `contentDescription` auf Icon-Buttons | 3 | Grep nach `IconButton` ohne contentDescription |
| `Modifier.semantics { }` für komplexe Widgets | 3 | Custom Composables haben Semantics |
| Touch-Targets >= 48dp | 2 | `Modifier.minimumInteractiveComponentSize()` |
| Test-Tags vorhanden | 2 | `Modifier.testTag()` für UI-Tests |

**Patterns suchen:**
```kotlin
// KORREKT
IconButton(
    onClick = { onStartClick() },
    modifier = Modifier.semantics {
        contentDescription = stringResource(R.string.start_meditation)
    }
)

// FALSCH - fehlende Semantics
IconButton(onClick = { onStartClick() }) {
    Icon(Icons.Default.PlayArrow, contentDescription = null)
}
```

### Dynamische Inhalte (8 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| `liveRegion` für Timer/Progress | 3 | `LiveRegionMode.Polite` oder `Assertive` |
| `heading()` für Überschriften | 3 | Semantische Struktur |
| `stateDescription` für Zustände | 2 | Toggle-States beschrieben |

**Pattern suchen:**
```kotlin
// Timer mit LiveRegion
Box(
    modifier = Modifier.semantics {
        contentDescription = timerDescription
        liveRegion = LiveRegionMode.Polite
    }
)
```

### Kontrast & Sichtbarkeit (7 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| MaterialTheme.colorScheme nutzen | 3 | Keine direkten Color-Werte |
| Schrift skaliert mit System | 2 | `MaterialTheme.typography` |
| Reduce Motion respektiert | 2 | `LocalReducedMotion.current` |

---

## Bewertungsmatrix

| Score | Bewertung | Aktion |
|-------|-----------|--------|
| 23-25 | Exzellent | Keine |
| 18-22 | Gut | Hinweise dokumentieren |
| 12-17 | Verbesserungswürdig | Ticket erstellen |
| < 12 | Kritisch | Ticket mit Priorität HOCH |

## Typische Findings

### Kritisch (5+ Punkte Abzug)
- Buttons ohne jegliche Accessibility-Labels
- Keine LiveRegion für Timer-Display
- Kontrast unter 3:1

### Mittel (2-4 Punkte Abzug)
- Fehlende Hints bei komplexen Aktionen
- Touch-Targets grenzwertig (40-43pt)
- Unlogische Lesereihenfolge

### Gering (1 Punkt Abzug)
- Fehlende accessibilityIdentifier (nur für Tests)
- Redundante Labels
