# Implementierungsplan: shared-114 (Android)

Ticket: [shared-114](../shared/shared-114-topbar-navigation-boilerplate.md)
Erstellt: 2026-06-14

## Ziel

Das in 5 Screens identisch duplizierte `navigationIcon`-Lambda (Standard-Zurück-Icon `Icons.AutoMirrored.Filled.ArrowBack` + `button_back`-contentDescription + `onSurfaceVariant`-Tint) zentral in `StillMomentTopAppBar` rendern. Aufrufer übergeben nur noch die Zurück-Aktion. Sichtbares Verhalten bleibt exakt gleich.

## Annahmen

- Das Standard-Zurück-Icon wird über einen neuen optionalen Callback-Parameter `onNavigateBack: (() -> Unit)? = null` aktiviert: ist er nicht-null, rendert die Bar das Standard-Icon selbst.
- Der bestehende `navigationIcon`-Parameter bleibt erhalten und hat **Vorrang**, falls beide gesetzt sind. Damit bleiben die zwei Close-Icon-Aufrufer (TimerFocusScreen, GuidedMeditationPlayerScreen) unverändert — sie nutzen weiterhin `navigationIcon` mit `Icons.Default.Close`.
- `button_back` (= "Back") und `MaterialTheme.colorScheme.onSurfaceVariant` bleiben die Quelle für Label und Tint — exakt wie in den heutigen Lambdas.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `presentation/ui/components/StillMomentTopAppBar.kt` | Presentation | Erweitern | Neuer Param `onNavigateBack: (() -> Unit)? = null`; rendert Standard-Zurück-Icon wenn gesetzt und `navigationIcon == null` |
| `presentation/.../SelectBackgroundSoundScreen.kt` | Presentation | Ersetzen | `navigationIcon`-Lambda (Z. 218–229) durch `onNavigateBack = onBack` |
| `presentation/.../SelectGongScreen.kt` | Presentation | Ersetzen | `navigationIcon`-Lambda (Z. 83–94) durch `onNavigateBack = onBack` |
| `presentation/.../IntervalGongsEditorScreen.kt` | Presentation | Ersetzen | `navigationIcon`-Lambda (Z. 101–112) durch `onNavigateBack = onBack` |
| `presentation/.../PreparationTimeSelectionScreen.kt` | Presentation | Ersetzen | `navigationIcon`-Lambda (Z. 65–76) durch `onNavigateBack = onBack` |
| `presentation/.../SoundAttributionsScreen.kt` | Presentation | Ersetzen | `navigationIcon`-Lambda (Z. 55–66) durch `onNavigateBack = onBack` |

> Exakte Pfade/Zeilen während der Implementierung per Glob/Read bestätigen.

## Bestehende Komponente (vor Änderung)

```kotlin
@Composable
fun StillMomentTopAppBar(
    modifier: Modifier = Modifier,
    title: String = "",
    navigationIcon: @Composable (() -> Unit)? = null,
    actions: @Composable RowScope.() -> Unit = {}
)
```

Der `navigationIcon` wird in einem Row links via `navigationIcon?.invoke()` (Z. 78) gerendert.

## Bestehendes Lambda (Vorlage, in allen 5 Screens identisch)

```kotlin
navigationIcon = {
    IconButton(onClick = onBack) {
        Icon(
            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
            contentDescription = stringResource(R.string.button_back),
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
```

## Geplante API

```kotlin
@Composable
fun StillMomentTopAppBar(
    modifier: Modifier = Modifier,
    title: String = "",
    navigationIcon: @Composable (() -> Unit)? = null,
    onNavigateBack: (() -> Unit)? = null,   // NEU
    actions: @Composable RowScope.() -> Unit = {}
)
```

Render-Logik im linken Nav-Slot:
```kotlin
when {
    navigationIcon != null -> navigationIcon()
    onNavigateBack != null -> DefaultBackButton(onClick = onNavigateBack)
    else -> {} // nichts
}
```

`DefaultBackButton` als private Composable im selben File (kapselt das obige Lambda 1:1). Vermeidet detekt `LongMethod`/`MultipleEmitters` im Haupt-Composable.

## Design-Entscheidungen

### Ein Callback-Parameter statt `showBackButton: Boolean` + separatem Handler

**Trade-off:** Ein Boolean-Flag + separater `onBack`-Param erlaubt theoretisch „Icon ohne Aktion"; ein nullable Callback verbindet Sichtbarkeit und Aktion untrennbar.
**Entscheidung:** `onNavigateBack: (() -> Unit)? = null`. Ein Zurück-Icon ohne Aktion ergibt keinen Sinn — der nullable Callback ist die minimalere, ausdrucksstärkere API.

### `navigationIcon` behalten + Vorrang

**Trade-off:** Man könnte `navigationIcon` ganz durch `onNavigateBack` ersetzen.
**Entscheidung:** Behalten. Die Close-Icon-Fälle (TimerFocusScreen, GuidedMeditationPlayerScreen) brauchen ein anderes Icon + andere contentDescription — sie liegen bewusst außerhalb des Ticket-Scopes und bleiben über `navigationIcon` unangetastet.

## Refactorings

Keine. Additiver Parameter + Auslagern des Standard-Lambdas in eine private Composable.

## Fachliche Szenarien

### AK: Zurück-Icon unverändert
- Gegeben: Nutzer öffnet die Gong-Auswahl
  Wenn: der Screen erscheint
  Dann: links steht das Standard-Zurück-Icon (ArrowBack) mit „Back"-Label und `onSurfaceVariant`-Tint — identisch zu vorher.

### AK: Zurück-Aktion funktioniert
- Gegeben: Nutzer ist in einem der 5 Screens
  Wenn: er auf das Zurück-Icon tippt
  Dann: `onBack` wird ausgelöst, Navigation zurück — wie vorher.

### AK: Close-Icon-Screens unverändert
- Gegeben: TimerFocusScreen / GuidedMeditationPlayerScreen
  Wenn: geöffnet
  Dann: links steht weiterhin das Close-Icon mit der jeweiligen contentDescription (nicht ArrowBack).

### AK: Screens ohne Nav-Icon unverändert
- Gegeben: AppSettingsScreen / TimerScreen (kein navigationIcon, kein onNavigateBack)
  Wenn: geöffnet
  Dann: kein Nav-Icon links — wie vorher.

## Reihenfolge

1. `StillMomentTopAppBar` um `onNavigateBack` + `DefaultBackButton` erweitern (additiv, bricht nichts).
2. Einen Screen (SelectGongScreen) umstellen, Build + visuell verifizieren.
3. Übrige 4 Screens mechanisch umstellen.
4. `make check` (detekt) + bestehende Tests grün.

## Offene Fragen

- Keine.
