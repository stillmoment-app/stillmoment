# UX/Layout Checkliste (25 Punkte)

## Responsiveness (8 Punkte)

### iOS

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| Funktioniert auf iPhone SE | 3 | Kleinster Screen |
| Funktioniert auf iPhone Pro Max | 2 | Größter Screen |
| GeometryReader für adaptive Layouts | 2 | Wo nötig eingesetzt |
| Safe Area respektiert | 1 | `.ignoresSafeArea()` nur für Background |

**Prüfen:**
- Previews für verschiedene Geräte vorhanden?
- Keine abgeschnittenen Elemente?
- Scrollbar wenn Inhalt nicht passt?

### Android

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| Funktioniert auf kleinen Screens | 3 | ~360dp Breite |
| Funktioniert auf Tablets | 2 | Falls relevant |
| Constraint-basiertes Layout | 2 | `fillMaxWidth()`, `weight()` |
| WindowInsets respektiert | 1 | System Bars, Cutouts |

---

## Layout-Qualität (8 Punkte)

### Abstände & Padding

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| Konsistente Padding-Werte | 3 | 8pt/16pt/24pt Grid |
| Elemente gut zentriert | 2 | VStack/HStack alignment |
| Kein visuelles Crowding | 2 | Genug Whitespace |
| Symmetrie wo angemessen | 1 | Balanced Layout |

### Visuelle Hierarchie

**Prüfen:**
- Ist klar, was das Wichtigste ist?
- Sind Aktionen gut erkennbar?
- Ist die Leserichtung logisch?

---

## States (5 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| Loading State vorhanden | 1 | Falls Daten geladen werden |
| Empty State vorhanden | 2 | Leere Listen haben Message |
| Error State vorhanden | 2 | Fehler werden angezeigt |

**Pattern suchen:**
```swift
// iOS
if viewModel.isLoading {
    ProgressView()
} else if viewModel.items.isEmpty {
    EmptyStateView()
} else {
    ContentView()
}
```

```kotlin
// Android
when {
    uiState.isLoading -> LoadingIndicator()
    uiState.items.isEmpty() -> EmptyState()
    else -> ContentList(uiState.items)
}
```

---

## Cross-Platform Konsistenz (4 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| Gleiche Features | 2 | Feature-Parity |
| Platform-native Patterns | 2 | iOS: NavigationStack, Android: TopAppBar |

**Vergleichen:**
- Sind die gleichen Aktionen verfügbar?
- Ist das visuelle Erscheinungsbild konsistent?
- Werden Platform-Idiome respektiert?

**Erlaubte Unterschiede:**
- Navigation Patterns (iOS: Bottom Tab, Android: Navigation Drawer)
- System UI Integration (iOS: SF Symbols, Android: Material Icons)
- Gestures (iOS: Swipe Back, Android: System Back)

---

## Background & Theme (Bonus)

### iOS

| Kriterium | Status |
|-----------|--------|
| `Color.warmGradient.ignoresSafeArea()` als Background | Check |
| Form mit `.scrollContentBackground(.hidden)` | Check |
| Light Mode enforced | Check |

### Android

| Kriterium | Status |
|-----------|--------|
| `WarmGradientBackground()` als Background | Check |
| `StillMomentTheme {}` wrapper | Check |
| Theme consistent | Check |

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
- Layout bricht auf kleinen Screens
- Fehlende Error/Empty States
- Massive Feature-Parity-Lücken

### Mittel (2-4 Punkte Abzug)
- Inkonsistente Abstände
- Unzentrierte Elemente
- Fehlende Previews für Device-Größen

### Gering (1 Punkt Abzug)
- Leichte Asymmetrie
- Suboptimale Whitespace-Nutzung
