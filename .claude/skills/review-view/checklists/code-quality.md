# Code-Qualität Checkliste (25 Punkte)

## iOS (SwiftUI)

### Semantic Colors (6 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| Nur semantische Farben | 4 | Kein `.warmBlack`, `.terracotta` direkt |
| Color+Theme.swift Rollen nutzen | 2 | `.textPrimary`, `.interactive`, `.progress` |

**Verboten:**
```swift
.foregroundColor(.warmBlack)      // FALSCH
.foregroundColor(.terracotta)     // FALSCH
```

**Korrekt:**
```swift
.foregroundColor(.textPrimary)    // RICHTIG
.foregroundColor(.interactive)    // RICHTIG
```

### Lokalisierung (6 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| Keine hardcoded UI-Strings | 4 | Kein `Text("Start")` |
| NSLocalizedString für dynamische Texte | 2 | `String(format: NSLocalizedString(...))` |

**Verboten:**
```swift
Text("Start meditation")          // FALSCH
```

**Korrekt:**
```swift
Text("button.start", bundle: .main)
NSLocalizedString("button.start", comment: "")
```

### View Composition (5 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| Private computed properties | 3 | `private var timerDisplay: some View` |
| Keine Monster-Body | 2 | Body < 50 Zeilen |

### State Management (5 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| @StateObject für ViewModels | 2 | Nicht @ObservedObject für owned VMs |
| Optional init für Testbarkeit | 2 | `init(viewModel: VM? = nil)` |
| @MainActor auf ViewModels | 1 | Thread-Safety |

### Error Handling (3 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| Keine Force Unwraps | 2 | Kein `!` außer IBOutlets |
| OSLog statt print | 1 | `Logger.timer`, `Logger.audio` |

---

## Android (Jetpack Compose)

### Semantic Colors (6 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| MaterialTheme.colorScheme nutzen | 4 | Kein `Color.Blue`, `Color(0xFF...)` |
| Theme/Color.kt Definitionen | 2 | Projekt-Farbschema |

**Verboten:**
```kotlin
color = Color.Blue                 // FALSCH
color = Color(0xFFE57373)          // FALSCH
```

**Korrekt:**
```kotlin
color = MaterialTheme.colorScheme.primary
color = MaterialTheme.colorScheme.onSurface
```

### Lokalisierung (6 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| stringResource() für alle Texte | 4 | Kein `Text("Start")` |
| Plurals korrekt | 2 | `pluralStringResource()` |

**Verboten:**
```kotlin
Text("Start meditation")           // FALSCH
```

**Korrekt:**
```kotlin
Text(stringResource(R.string.button_start))
```

### Screen Composition (5 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| Container + Content Pattern | 3 | Screen vs ScreenContent getrennt |
| Content nimmt nur Data + Callbacks | 2 | Kein ViewModel in Content |

**Korrekt:**
```kotlin
@Composable
fun TimerScreen(viewModel: TimerViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()
    TimerScreenContent(uiState = uiState, onStartClick = viewModel::start)
}

@Composable
internal fun TimerScreenContent(uiState: UiState, onStartClick: () -> Unit)
```

### State Management (5 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| StateFlow für UiState | 2 | `val uiState: StateFlow<UiState>` |
| Immutable UiState data class | 2 | Keine `var` Properties |
| Hilt-injected ViewModels | 1 | `@HiltViewModel` |

### Error Handling (3 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| Keine !! Operator | 2 | Null-Safety |
| Logging mit Timber/Log | 1 | Kein `println()` |

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
- Direkte Farbwerte statt semantischer Colors
- Hardcoded UI-Strings (keine Lokalisierung)
- Force Unwraps in Produktionscode

### Mittel (2-4 Punkte Abzug)
- Monster-Body (>100 Zeilen)
- ViewModel nicht testbar
- Mutable UiState

### Gering (1 Punkt Abzug)
- print() statt OSLog/Timber
- Fehlende @MainActor
