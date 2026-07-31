# Implementierungsplan: shared-081 (Android)

Ticket: [shared-081](../shared/shared-081-library-filter-nach-dauer.md)
Erstellt: 2026-07-31

> Der iOS-Plan liegt daneben: [shared-081-ios.md](shared-081-ios.md). Die fachlichen Szenarien sind identisch — dieser Plan wiederholt sie nicht, sondern beschreibt die Android-spezifische Umsetzung und die eine Stelle, an der Android echte Zusatzarbeit hat (Filter-Reset am Tab-Wechsel).

## Annahmen

Identisch zu iOS, mit Android-Bezug:

- **Gefiltert wird `effectiveDurationMs`** (mit Trim), nicht die Dateilänge. Das ist die Zahl, die `formattedDuration` in der Liste anzeigt.
- **„Suchmodus" = `isSearchFocused || searchQuery.isNotBlank()`.** Das Ticket sagt „sobald das Suchfeld den Fokus hat", aber iOS verliert den Fokus beim Scrollen (`scrollDismissesKeyboard`), Android nicht (`SearchResultsList` ruft nur `keyboard?.hide()`). Ohne die Query-Bedingung verhielten sich die Plattformen unterschiedlich.
- **Reihenfolge der flachen Liste ohne Suchtext:** `groups.flatMap { it.meditations }` — Lehrer:in alphabetisch, innerhalb nach Titel (macht `groupByTeacher()` bereits). Keine neue Sortierung. Mit Suchtext bleibt die Relevanz-Rangfolge der `LibrarySearchEngine`.
- **Reset-Button im „Kein Treffer"-Zustand nur bei gesetztem Filter.** Reine Such-Nulltreffer bleiben wie heute.
- **`Alle` ist nie blass** — die Filterzeile erscheint nur bei nicht-leerer Bibliothek.
- **Ein gewählter Schritt bleibt gewählt, auch wenn ein Suchtext ihn leer macht** → „Kein Treffer" mit beiden Ursachen.
- **Die Filterzeile gehört zum fixierten Header** (`Column { Header; Body }` in `LibraryWithHeader`), scrollt also nicht mit.

## Betroffene Codestellen

> Der Ticket-Verweis auf `presentation/ui/library/` geht ins Leere — die Library liegt unter **`presentation/ui/meditations/`**.

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `domain/models/DurationFilter.kt` | Domain | **Neu** | Enum mit fünf Stufen, `matches(durationMs: Long)`, `apply(list)`, `availableSteps(list)`. Grenzen als **`Long`**-Konstanten in Millisekunden. |
| `domain/models/LibrarySearchState.kt` | Domain | Erweitern | Neues `data object Filtered` (kein Suchtext, aber Filter gesetzt → flache Liste). |
| `presentation/viewmodel/GuidedMeditationsListViewModel.kt` | Application | Erweitern | `durationFilter` im UiState; abgeleitete `visibleMeditations`, `availableDurationSteps`, `isFilterActive`, `isSearchModeActive`; `searchState` um den Filter erweitern; `selectDurationFilter()`, `resetDurationFilter()`, `resetSearchAndFilter()`. `resetSearch()` bleibt filterfrei. |
| `presentation/ui/meditations/LibraryDurationFilterRow.kt` | Presentation | **Neu** | `Row` mit `horizontalScroll` + `DurationFilterChip` (private). |
| `presentation/ui/meditations/LibraryActiveFilterChip.kt` | Presentation | **Neu** | Einzelner Chip mit ✕ für den Suchmodus. |
| `presentation/ui/meditations/DurationFilterLabels.kt` | Presentation | **Neu** | `DurationFilter.labelRes(): Int` — hält das Domain-Modell frei von Android-Ressourcen (Pattern wie `SoundExtensions.kt`). |
| `presentation/ui/meditations/LibraryHeaderBar.kt` | Presentation | Erweitern | Aus `Row` wird `Column { Row{Suche+Aktion}; Filterzeile ODER Chip ODER nichts }`. |
| `presentation/ui/meditations/GuidedMeditationsListScreen.kt` | Presentation | Erweitern | `LibraryWithHeader`: `LibrarySearchState.Filtered` → `SearchResultsList`; neue Callbacks durchreichen. |
| `presentation/ui/meditations/SearchResultsList.kt` | Presentation | Erweitern | Neuer Parameter `totalCount`; `ResultsHeader` auf das neue Plural mit zwei Argumenten. |
| `presentation/ui/meditations/SearchEmptyState.kt` | Presentation | Erweitern | Neue Parameter `activeFilter: DurationFilter?`, `onReset: (() -> Unit)?`; drei Textvarianten + Reset-Button. |
| `presentation/navigation/NavGraph.kt` | Presentation | Erweitern | `libraryFilterResetSignal` als `MutableStateFlow<Boolean>`, gesetzt in `onTabSelect`, konsumiert in der Library-`composable`. Siehe Design-Entscheidung 3. |
| `res/values/strings.xml`, `res/values-de/strings.xml` | Resources | Erweitern | Stufen-Labels, Empty-Texte, Reset-Button, Accessibility; `library_search_result_count` ersetzen. |
| `test/.../domain/models/DurationFilterTest.kt` | Test | **Neu** | Grenzwerte + Stufen-Belegung. |
| `test/.../presentation/viewmodel/GuidedMeditationsListViewModelTest.kt` | Test | Erweitern | Zusammenspiel Suche/Filter, Zustände, Reset-Semantik (`@Nested class DurationFilter`). |
| `CHANGELOG.md` | Docs | Erweitern | Eintrag unter Unreleased (gemeinsam mit iOS). |

## API-Recherche

Keine neuen Libraries. Alles Compose-Bordmittel, die im Projekt bereits vorkommen:

| API | Min. Version | Hinweis |
|-----|--------------|---------|
| `Modifier.horizontalScroll(rememberScrollState())` | Compose 1.0 | Fünf feste Chips — kein `LazyRow` nötig, spart Key-Handling. |
| `Modifier.semantics { selected = true }` | Compose 1.0 | TalkBack sagt „ausgewählt". |
| `Modifier.semantics { disabled() }` | Compose 1.0 | TalkBack sagt „deaktiviert"; zusätzlich `stateDescription` mit „nicht verfügbar". |
| `pluralStringResource(id, quantity, vararg formatArgs)` | Compose 1.0 | Bereits in `SearchResultsList` genutzt. **`quantity` = Gesamtbestand**, `formatArgs` = (Anzahl, Gesamt). |
| `Modifier.sizeIn(minHeight = 48.dp)` | Compose 1.0 | Material-Mindest-Tapfläche. |

`minSdk = 26` — keine Verfügbarkeits-Einschränkung bei irgendeinem der obigen Aufrufe.

## Design-Entscheidungen

### 1. `DurationFilter` als Enum mit eigener Logik statt neuem Domain-Service

Wie iOS: `matches()`, `apply()`, `availableSteps()` am Enum. Kein Gegenstück zur `LibrarySearchEngine` nötig — der Dauerfilter ist ein Bereichsvergleich, keine Ranking-Maschine.

**Kotlin-spezifisch:** Grenzen als `Long`-Konstanten (`300_000L`, `900_000L`, `1_800_000L`). Kotlin-`Int` ist 32-bit; Dauern in Millisekunden gehören konsequent in `Long` — das Modell führt `duration` bereits als `Long`.

### 2. Fünfter Zustand `Filtered` statt Umbenennung des Zustandsmodells

Additives `data object Filtered` in `LibrarySearchState`. Im `when` von `LibraryWithHeader` teilen sich `Filtered` und `Results` einen Zweig (`SearchResultsList` mit `query = uiState.searchQuery`, das bei leerem Query kein Highlight zeichnet). Eine Umbenennung auf `LibraryBodyState` wäre sauberer, verlangt aber kein Akzeptanzkriterium — als Follow-up notiert.

### 3. Filter-Reset am Tab-Wechsel: expliziter Signal-Flow (Android-spezifisch)

**Das Problem:** Auf iOS gibt es mit `StillMomentApp.onChange(of: selectedTab)` bereits einen sauberen Tab-Hook. Android hat den nicht.

Der bestehende `ResetLibrarySearchOnPause` (NavGraph.kt:455) hängt an `Lifecycle.Event.ON_PAUSE` des Library-`NavBackStackEntry`. Dieses Event feuert **in beiden Fällen** — beim Tab-Wechsel *und* beim Öffnen des Players. Genau die Unterscheidung, die das Ticket verlangt („Ein Ausflug in den Player und zurück lässt ihn bestehen"), kann `ON_PAUSE` also nicht leisten.

**Warum es keine bequemere Stelle gibt:**
- `ON_DESTROY` hilft nicht: Der Tab-Wechsel nutzt `popUpTo(startDestination) { saveState = true }` + `restoreState = true`. Der Eintrag wird mit gesichertem Zustand gepoppt, sein `ViewModelStore` bleibt erhalten und die Lifecycle landet bei `CREATED`, nicht bei `DESTROYED`.
- `rememberSaveable` hilft nicht: Genau dieses `saveState = true` konserviert den gespeicherten Zustand ebenfalls über den Tab-Wechsel.
- `settingsDataStore.selectedTabFlow` hilft nicht: Der Schreibvorgang ist asynchron, das Library-Composable verlässt die Komposition währenddessen; beim Zurückkommen steht der Wert längst wieder auf `LIBRARY` — das Reset-Fenster ist verpasst.

**Entscheidung:** Ein `MutableStateFlow<Boolean>` `libraryFilterResetSignal`, gehalten in `StillMomentNavHost`, gesetzt in `onTabSelect`, wenn das Ziel-Tab **nicht** Library ist. Das Library-`composable` konsumiert es per `LaunchedEffect` und ruft `resetDurationFilter()`. Das spiegelt exakt das im NavGraph bereits etablierte `stopMeditationSignal`-Muster (gleiche Datei, gleiche Durchreichung über `NavHostScaffold` → `StillMomentNavContent`).

Das Signal überlebt die Disposition des Composables, deshalb ist die Reihenfolge unkritisch: Feuert der Effekt noch vor dem Verlassen, ist der Filter sofort weg; feuert er erst beim Zurückkommen, ist er ebenfalls weg. Beide Wege enden im geforderten Zustand.

`ResetLibrarySearchOnPause` bleibt **unverändert** — die Suche soll ihr heutiges Verhalten behalten (Ticket-Hinweis: nur der Filter bekommt die neue Semantik).

### 4. Stufen-Belegung gegen die *such*-gefilterte Menge, nicht gegen die gefilterte

`availableDurationSteps` wird aus der Menge berechnet, auf die nur der Suchtext wirkt. Sonst schaltete das Setzen einer Stufe alle anderen blass und der Filter wäre eine Einbahnstrasse.

## Fachliche Szenarien

Identisch zu [shared-081-ios.md](shared-081-ios.md), Abschnitt „Fachliche Szenarien" (AK-1 bis AK-8) — dieselben Grenzwerte, dieselben Zustände, dieselben Reset-Regeln. Das Ticket verlangt „Unit Tests Android: identische Fälle".

Zwei Szenarien mit Android-eigener Mechanik, die iOS nicht hat:

### AK-6 (Android): Filter überlebt den Player, fällt beim Tab-Wechsel

- Gegeben: `bis 5 Min` gesetzt
  Wenn: eine Meditation antippen (Player öffnet), dann Zurück-Geste
  Dann: `bis 5 Min` ist weiterhin gesetzt — obwohl `ON_PAUSE` gefeuert und die Suche zurückgesetzt hat
- Gegeben: `bis 5 Min` gesetzt
  Wenn: unten auf „Timer" tippen und dann zurück auf „Meditationen"
  Dann: `Alle` ist aktiv, die Liste ist gruppiert

### AK-3 (Android): Zeilenbreite bleibt stabil

- Gegeben: Schriftgrösse auf Maximum, `bis 5 Min` blass
  Wenn: horizontal wischen
  Dann: alle fünf Stufen sind erreichbar, keine verschwindet, die Zeile bricht nicht um

## Reihenfolge der Akzeptanzkriterien

1. **AK-1 (Grenzwerte)** — `DurationFilter` im Domain. Reine Funktion, `@Nested`-JUnit-5-Tests, schnellster Zyklus.
2. **AK-3 (Stufen-Belegung)** — `availableSteps()`, ebenfalls Domain.
3. **AK-2 + AK-5 (Zustandslogik)** — `GuidedMeditationsListUiState` + ViewModel: `durationFilter`, `visibleMeditations`, `searchState` mit `Filtered`, Toggle- und Reset-Semantik. Kern des Tickets.
4. **AK-4 (Zählzeile)** — Plural in beiden `strings.xml` + `SearchResultsList`.
5. **AK-7 (Kein Treffer)** — `SearchEmptyState` mit drei Textvarianten und Reset-Button.
6. **AK-2/AK-3 visuell + AK-8** — `LibraryDurationFilterRow`, `LibraryActiveFilterChip`, Einbau in `LibraryHeaderBar`, Semantics.
7. **AK-6 (Tab-Reset)** — Signal-Flow im `NavGraph`. Zuletzt, weil er nur den in Schritt 3 gebauten Reset auslöst.
8. **CHANGELOG**

## Lokalisierung

| Key | DE | EN |
|-----|----|----|
| `library_filter_all` | Alle | All |
| `library_filter_up_to_5` | bis 5 Min | Up to 5 min |
| `library_filter_5_to_15` | 5–15 Min | 5–15 min |
| `library_filter_15_to_30` | 15–30 Min | 15–30 min |
| `library_filter_over_30` | über 30 Min | Over 30 min |
| `library_list_count_of_total` (plurals) | one: `%1$d von %2$d Meditation` / other: `%1$d von %2$d Meditationen` | one: `%1$d of %2$d meditation` / other: `%1$d of %2$d meditations` |
| `library_filter_empty_message` | Keine Meditation mit der Dauer „%1$s". | No meditation with duration “%1$s”. |
| `library_search_filter_empty_message` | Keine Treffer für „%1$s" mit der Dauer „%2$s". | No matches for “%1$s” with duration “%2$s”. |
| `library_filter_reset` | Filter zurücksetzen | Reset filter |
| `accessibility_library_filter_unavailable` | Nicht verfügbar | Unavailable |
| `accessibility_library_filter_chip_hint` | Antippen entfernt den Filter | Tap to remove the filter |

**Entfällt:** `library_search_result_count` („%d Treffer") in beiden `strings.xml` — ersetzt durch `library_list_count_of_total`. Ein zweiter Key daneben würde Suche und Filter auseinanderdriften lassen (Ticket-Hinweis).

**Plural-Fallstrick:** Der `quantity`-Parameter muss der **Gesamtbestand** sein, nicht die Trefferzahl — „2 von 1 Meditation" gibt es nicht. Also `pluralStringResource(R.plurals.library_list_count_of_total, total, count, total)`.

## Design-Tokens

| Zustand | Füllung | Text | Rand |
|---------|---------|------|------|
| Stufe aktiv | `theme.accentBubbleBackground` | `theme.interactive` | `theme.accentBannerBorder` |
| Stufe inaktiv | `theme.cardBackground` | `MaterialTheme.colorScheme.onSurfaceVariant` | `theme.cardBorder` |
| Stufe blass | wie inaktiv, `Modifier.alpha(0.4f)` | — | — |
| Chip (Suchmodus) | wie „aktiv", plus ✕-Icon in `theme.interactive` | | |

Form: `RoundedCornerShape(50)`, sichtbare Höhe 32 dp, Trefferfläche über `sizeIn(minHeight = 48.dp)`. Textstil `TextStyle.caption`. Keine direkten Farbwerte, alles über `LocalStillMomentColors`.

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| detekt `LongMethod` (60 Zeilen) bei `LibraryHeaderBar` und `LibraryWithHeader` | Filterzeile und Chip als eigene Composables in eigenen Dateien; der Header bekommt nur den `Column`-Wrapper. `LibraryWithHeader` hat schon 14 Parameter — neue Callbacks nicht einzeln durchreichen, sondern das ohnehin vorhandene `uiState` nutzen und nur `onSelectDurationFilter` + `onResetSearchAndFilter` ergänzen. |
| detekt `MultipleEmitters` | `LibraryDurationFilterRow` emittiert genau eine `Row`; `LibraryHeaderBar` genau eine `Column`. |
| detekt `LongParameterList` wächst weiter | Die betroffenen Composables tragen bereits `@Suppress("LongParameterList")` mit Begründung — Kommentar entsprechend erweitern statt neu unterdrücken. |
| Signal-Flow im NavGraph wird beim Tab-Wechsel *zur* Library fälschlich gefeuert | Bedingung ist `tabItem.tab != AppTab.LIBRARY`. Der Share-Import-Pfad (`MeditationImportNavigationEffect`) navigiert direkt per `navController.navigate` und geht gar nicht durch `onTabSelect` — der Filter bleibt dort unberührt, was richtig ist. |
| Recomposition-Kosten: `visibleMeditations` und `availableDurationSteps` sind berechnete Properties am UiState | Gleiche Bauart wie das bestehende `searchResults` — bei einer persönlichen Bibliothek (Dutzende Einträge) unkritisch. Falls die Liste je gross wird, ist das ein Thema für Suche *und* Filter gemeinsam, nicht für dieses Ticket. |
| `rememberScrollState()` verliert die Scrollposition der Filterzeile bei Recomposition | `remember`-Aufruf ausserhalb des `when`-Zweigs, damit er nicht mit dem Zustandswechsel neu erzeugt wird. |

## Offene Fragen

- Keine. Die beiden Mehrdeutigkeiten (Suchmodus-Definition, Sortierung der flachen Liste) sind unter **Annahmen** entschieden — identisch zu iOS, damit die Plattformen nicht auseinanderlaufen.
