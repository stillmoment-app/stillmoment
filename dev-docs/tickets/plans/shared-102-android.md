# Implementierungsplan: shared-102 (Android)

Ticket: [shared-102](../shared/shared-102-library-header-search-android.md)
iOS-Pendant: [ios-051](../ios/ios-051-library-header-suchfeld-sichtbar.md) — bereits umgesetzt
iOS-Plan-Vorbild: [ios-051 Plan](ios-051.md)
Erstellt: 2026-05-21
Branch: `feature/shared-102-android`

---

## Ziel in einem Satz

Im Library-Tab verschwindet der Top-App-Bar-Title "Bibliothek"; an seiner Stelle sitzt eine
eigene, fix verankerte Header-Bar mit zwei Pillen — links die Such-Pille (40 dp, immer
sichtbar), rechts die kombinierte Aktion-Pille `+` / `i`. Bei Fokus wandert die Aktion-Pille
weg, ein "Abbrechen"-Button erscheint, die Such-Pille expandiert. Die komplette Such-Logik
aus shared-101 (Engine, History, ViewModel-Felder, States) bleibt unangetastet.

---

## Annahmen

Bewusste Festlegungen, die in den Plan eingeflossen sind. Bitte beim Review pruefen.

- **`StillMomentTopAppBar` mit Title bleibt fuer andere Screens unveraendert.** Wir loeschen
  ihn nur aus dem `GuidedMeditationsListScreenContent`-Body und ersetzen ihn durch unseren
  neuen `LibraryHeaderBar` direkt unter der StatusBar (gleiche `TopAppBarHeight = 44 dp`
  greift nicht — Header bemisst sich selbst aus Pillen-Hoehe + Padding).
- **Header bei Empty-State ausblenden.** Wenn `uiState.isEmpty`, wird `LibraryHeaderBar`
  nicht gerendert; der bestehende `EmptyLibraryState` (Welcome-Icon + Import + Find-Sources)
  bleibt unveraendert. Verhalten parallel zu iOS.
- **Header bleibt fix beim Scrollen** dadurch, dass er als erster Child in der existierenden
  `Column { Header; LibraryBody }`-Struktur sitzt — der Body darunter scrollt via
  `LazyColumn`, der Header nicht. Kein `TopAppBarScrollBehavior`, kein `nestedScroll`.
- **`LibrarySearchBar` wird umgeschrieben — kein `Card`-Container, kein Material-`TextField`
  mehr.** Stattdessen ein `BasicTextField` in einer `Capsule`-Shape (`RoundedCornerShape(50)`)
  mit `liftedCardShadow` (Light) bzw. `BorderStroke` (Dark). Begruendung siehe
  Design-Entscheidung 1.
- **`LibraryActionPill` als eigenes Composable** im `presentation/ui/meditations/`-Package.
  Kombinierte Capsule, zwei `IconButton`-aehnliche Bereiche, durch eine 1 dp `Box` mit
  `theme.divider.copy(alpha = 0.18f)` getrennt — analog zur iOS-`Rectangle().fill(theme.divider)`.
- **Touch-Target 48 dp via `Modifier.minimumInteractiveComponentSize()`** an den
  `IconButton`-Kindern in `LibraryActionPill`. Die sichtbare Pille bleibt 40 dp hoch.
- **`FocusRequester` + `onFocusChanged` im Header.** `setSearchFocused(focused)` aus dem
  ViewModel wird wie heute getriggert; der Switch zwischen Aktion-Pille und "Abbrechen"
  beobachtet `uiState.isSearchFocused`.
- **Abbrechen-Tap macht zwei Dinge:** ruft `viewModel.resetSearch()` (entfernt Query +
  `isSearchFocused = false`) und `FocusManager.clearFocus()` (entfernt den Compose-Focus
  und schliesst die Tastatur). Konsistent zu iOS (`resetSearch()` + `searchFocused = false`).
- **Sicht-Wechsel Aktion-Pille ↔ Abbrechen** via `AnimatedContent` mit Fade + leichtem Scale
  (Spec aus iOS-Plan, dort `.opacity.combined(with: .scale(scale: 0.95))`). Compose-Pendant:
  `togetherWith` mit `fadeIn() + scaleIn(initialScale = 0.95f)` und `fadeOut() + scaleOut(targetScale = 0.95f)`.
- **Such-Pille bleibt strukturell gleich** — sie hat `Modifier.weight(1f)`, expandiert
  automatisch in den frei gewordenen Aktion-Pillen-Raum, sobald die rechte Seite vom
  schmalen "Abbrechen"-Text statt der breiten Pille belegt ist. Kein explizites Width-Switching.
- **String `library_search_prompt` wird auf "Suchen" / "Search" verkuerzt.** Der lange
  Prompt aus shared-101 ("Search by title or teacher" / "Nach Titel oder Sprecher suchen")
  passt nicht in die 40 dp hohe Pille neben Lupe und Clear-X. Wert wird im String-Catalog
  ueberschrieben — gleiche Loesung wie iOS-051 (kein neuer Key, bestehender Wert geaendert).
- **TalkBack-Fokus-Reihenfolge** im Idle: Such-Pille → "+" → "i". Im aktiven Zustand:
  Such-Pille → "Abbrechen". Compose stellt das natuerlich durch Layout-Reihenfolge sicher,
  wenn die Aktion-Pille via `AnimatedContent` getauscht wird.
- **Existierender `ResetLibrarySearchOnPause`-Effekt bleibt unveraendert** — er sitzt im
  `NavGraph` und triggert via `Lifecycle.ON_PAUSE`. Tab-Wechsel-Reset funktioniert weiter.
- **`recordSearchCommittedByOpening`** im `onMeditationClick` im `NavGraph` bleibt
  unveraendert.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `presentation/ui/meditations/GuidedMeditationsListScreen.kt` | Presentation | Refactor | `StillMomentTopAppBar`-Aufruf entfernen, `LibraryWithSearchBar`-Aufrufstelle so umbauen, dass `LibraryHeaderBar` (statt der heutigen `LibrarySearchBar`-im-Body) fix oben sitzt. `Scaffold`-`topBar`-Slot bleibt leer (Header ist Teil des Bodys, aber durch die `Column { Header; Body }`-Struktur fixiert). |
| `presentation/ui/meditations/LibraryHeaderBar.kt` | Presentation | **Neu** | `Row` mit `LibrarySearchPill(modifier.weight(1f))` und `AnimatedContent`-Switch zwischen `LibraryActionPill` (Idle) und `LibraryCancelButton` (Active). Padding 22 dp horizontal, 12 dp top, 8 dp bottom (analog iOS). |
| `presentation/ui/meditations/LibrarySearchBar.kt` | Presentation | Refactor | Umbenennen in `LibrarySearchPill` (Datei behaelt Name `LibrarySearchBar.kt` aus Stabilitaet, alternative: Datei umbenennen). Card weg, `Capsule`-Shape, 40 dp hoch, `BasicTextField` mit Lupe links und Clear-X rechts. `FocusRequester` Parameter, `onFocusChanged`-Callback bleibt. `liftedCardShadow` (Light) / `BorderStroke` (Dark) wie heute. |
| `presentation/ui/meditations/LibraryActionPill.kt` | Presentation | **Neu** | Kombinierte 40 dp-Capsule mit zwei `IconButton`-aehnlichen Bereichen ("+" / "i"), durch 1 dp-`Box` getrennt. Theme-aware Background (cardBackground), Light-Mode-Shadow / Dark-Mode-Border. `onAdd` und `onInfo` Callbacks. |
| `presentation/ui/meditations/LibraryCancelButton.kt` | Presentation | **Neu** (inline ok) | Schmaler `TextButton` mit "Abbrechen" in `theme.interactive`, Tap ruft `onCancel()`. Akzent-Color, kein eigener Capsule-Background. Kann auch ein `@Composable`-private im `LibraryHeaderBar.kt` sein — siehe Reihenfolge. |
| `presentation/navigation/NavGraph.kt` | Presentation | Pruefen | Keine Aenderung erwartet — `ResetLibrarySearchOnPause` und `recordSearchCommittedByOpening` bleiben. Reset bei Treffer-Tap weiterhin ueber den `ResetLibrarySearchOnPause`-Hook (`ON_PAUSE` triggert beim Navigieren zum Player). |
| `res/values/strings.xml` | Resources | Aendern + Ergaenzen | `library_search_prompt` Wert auf `Search` kuerzen. Neue Keys: `accessibility_library_search_cancel = "Cancel search"`, `accessibility_library_add_hint = "Opens file picker to import a guided meditation"` (optional, falls noch nicht vorhanden — ist bereits vorhanden). Pruefen: `accessibility_library_search_field = "Search library"` bleibt. |
| `res/values-de/strings.xml` | Resources | Aendern + Ergaenzen | `library_search_prompt` Wert auf `Suchen` kuerzen. `accessibility_library_search_cancel = "Suche abbrechen"`. |
| `CHANGELOG.md` | Doc | Eintrag | "Library-Header mit immer sichtbarem Suchfeld" unter `Unreleased` → `Changed (Android)`. |

### Bestehende Tests, die gruen bleiben muessen

| Datei | Pruefung |
|---|---|
| `test/.../domain/services/LibrarySearchEngineTest.kt` | Unbetroffen — Engine wird nicht angefasst. |
| `test/.../presentation/viewmodel/GuidedMeditationsListViewModelTest.kt` | Unbetroffen — VM-API (`updateSearchQuery`, `setSearchFocused`, `submitSearch`, `selectHistoryEntry`, `clearHistory`, `resetSearch`, `recordSearchCommittedByOpening`) bleibt identisch. |

### Neue Tests

| Datei | Inhalt |
|---|---|
| `androidTest/.../presentation/ui/meditations/LibraryHeaderBarTest.kt` | Drei Compose-UI-Tests: (1) Idle-State zeigt Such-Pille + Aktion-Pille; (2) Tap auf Such-Pille → Aktion-Pille verschwindet, "Abbrechen" erscheint, Tastatur waere offen; (3) Tap auf "Abbrechen" entfernt Fokus, leert die Eingabe, Aktion-Pille kommt zurueck. |
| `androidTest/.../presentation/ui/meditations/LibraryActionPillTest.kt` | Zwei Tests: (1) Tap auf "+" triggert `onAdd`; (2) Tap auf "i" triggert `onInfo`. TalkBack-`contentDescription` wird verifiziert (`accessibility_import_meditation`, `guided_meditations_guide_info`). |

Geschaetzte Anzahl betroffener Produktiv-Dateien: **5 neu/geaendert** (2 neu, 3 geaendert) +
2 Test-Dateien neu + 2 Resource-Dateien + CHANGELOG.

---

## API-Recherche

Alle benoetigten APIs sind ab `minSdk = 26` verfuegbar:

| API | Min. Version | Quelle | Hinweis |
|---|---|---|---|
| `androidx.compose.animation.AnimatedContent` | Compose 1.4+ | bereits Dep | Switch Aktion-Pille ↔ Abbrechen. Mit `fadeIn() + scaleIn()` / `fadeOut() + scaleOut()` als `ContentTransform`. |
| `androidx.compose.foundation.text.BasicTextField` | Compose 1.0+ | Compose Docs | Volle Kontrolle ueber Capsule-Container, ohne Material-`TextField`-Defaults (die padden 56 dp und respektieren keine 40 dp Hoehe). |
| `androidx.compose.foundation.text.KeyboardOptions(imeAction = ImeAction.Search)` | Compose 1.0+ | Compose Docs | Bleibt aus shared-101. |
| `androidx.compose.foundation.shape.RoundedCornerShape(percent = 50)` | Compose 1.0+ | Compose Docs | Capsule-Shape (rechteckig + 50 %-Corner = Capsule). |
| `androidx.compose.ui.focus.FocusRequester` + `.focusRequester(...)` | Compose 1.0+ | Compose Docs | Such-Pille-Tap ruft `requester.requestFocus()`. |
| `androidx.compose.foundation.layout.RowScope.weight(1f)` | Compose 1.0+ | Compose Docs | Such-Pille expandiert automatisch. |
| `Modifier.minimumInteractiveComponentSize()` | Material 3 1.1+ | bereits Dep | 48 dp Touch-Target ohne sichtbare Pille zu vergroessern. |
| `LocalSoftwareKeyboardController.current?.hide()` | Compose 1.2+ | bereits genutzt | Tastatur ausblenden bei Cancel (zusaetzlich zu `clearFocus()`). |
| `androidx.compose.ui.platform.LocalFocusManager.current.clearFocus()` | Compose 1.0+ | Compose Docs | Compose-Fokus loeschen. |

**Hinweis zu `Scaffold(topBar = ...)`:** Verworfen fuer den neuen Header. Der heutige
`StillMomentTopAppBar` ist KEIN echter Material-3-`TopAppBar` — es ist ein eigener
`Box` mit fester Hoehe (44 dp). Der neue Header bleibt ebenfalls ein eigenes Composable,
in die existierende `Column { Header; Body }`-Struktur eingehaengt. Damit ist
"Header bleibt fix beim Scrollen" automatisch erfuellt — die `LazyColumn` im Body scrollt,
der Header nicht.

**Hinweis zu Material 3 `SearchBar`:** Verworfen wie schon in shared-101 (siehe dortigen
Plan, Design-Entscheidung 1). Bringt aufklappendes Overlay, blockiert Header-Layout.

---

## Design-Entscheidungen

### 1. `BasicTextField` in `Capsule` statt `OutlinedTextField` in `Card`

**Trade-off:** Material-`TextField` (heute) bringt Tastatur-Wiring, Cursor-Animation und
Theme-Defaults mit, aber padded mindestens 56 dp Hoehe — das Ticket fordert eine 40 dp
hohe Pille. Manuelles Tuning der `TextField`-Defaults bricht das Material-Verhalten.

**Entscheidung:** `BasicTextField` mit eigenem Capsule-Container (`Modifier.background` +
`Modifier.border` auf `RoundedCornerShape(50)`). Lupe und Clear-X als Geschwister im
umschliessenden `Row`, nicht als `leadingIcon`/`trailingIcon`.

**Warum:**
- 40 dp Hoehe ist genau steuerbar (`Modifier.height(40.dp)`).
- Tastatur-Wiring (`KeyboardActions`, `KeyboardOptions`, `LocalSoftwareKeyboardController`)
  funktioniert identisch mit `BasicTextField`.
- Wir kontrollieren die visuelle Sprache (Capsule statt `RoundedCornerShape(12.dp)`).
- iOS macht es genauso: dort sitzt ein `TextField` plus `Image`-Geschwister in einer
  `Capsule`, nicht ein `.searchable()` mit System-Container.

### 2. Such-Pille bleibt strukturell stabil — Aktion-Pille verschwindet, Such-Pille gewinnt Raum durch `weight(1f)`

**Trade-off:** Eigene Width-Animation auf der Such-Pille vs. Layout-Verhalten ueber
`weight(1f)` ausnutzen.

**Entscheidung:** Such-Pille bekommt `Modifier.weight(1f)`. Wenn die Aktion-Pille
schmaler wird (Cancel-Text statt 2-Button-Pille), bekommt die Such-Pille automatisch
mehr Raum. Kein expliziter Width-State, keine `animateContentSize`-Trickserei.

**Warum:** Konsistent zu iOS, wo die Such-Pille `.frame(maxWidth: .infinity)` hat und
durch das Layout-System mitwaechst. Vermeidet Focus-Verlust durch Width-Wechsel
(siehe iOS-Plan-Risiko mit `@FocusState` + dynamischer Width — auf Compose ebenfalls
nicht verlaesslich).

### 3. `LibraryActionPill` als eigenes Composable

**Trade-off:** Inline in `LibraryHeaderBar` waere 30 Zeilen weniger Code; ein eigenes
Composable kostet etwas Boilerplate, ist aber testbar (visuell isoliert) und entlastet
die Header-View.

**Entscheidung:** Eigenes Composable, analog zur iOS-Implementation und zum Ticket-Hinweis.

**Warum:** Header bekommt zwei Verantwortlichkeiten (Suche + Aktionen). Die Aufteilung
macht beide kleiner und vermeidet `LongMethod`-Detekt-Warnungen. Plus: Die Pille hat
eine eigene Theme-Logik (Light-Shadow / Dark-Border), die in einer eigenen Funktion
besser aufgehoben ist.

### 4. Reset bei Treffer-Tap → bestehender `ResetLibrarySearchOnPause`-Hook reicht

**Trade-off:** Eigener Reset im `onMeditationClick` vor `navController.navigate(...)` vs.
Verlassen auf `Lifecycle.ON_PAUSE` aus shared-101.

**Entscheidung:** Bestehender Mechanismus aus shared-101 bleibt — `ON_PAUSE` feuert beim
Navigieren zum Player. `recordSearchCommittedByOpening` schreibt vorher die History.
Reihenfolge im `NavGraph`: erst `recordSearchCommittedByOpening()`, dann `navigate(...)`,
dann triggert `ON_PAUSE` den `resetSearch()`. Das ist die bestehende Verkettung —
nichts daran aendern.

**Warum:** Aenderungen ausserhalb des Header-Scopes sind explizit "Out-of-Scope" laut
Ticket. Bestehende Verkettung funktioniert.

### 5. Animation: `AnimatedContent` mit Fade + Scale 0.95

**Trade-off:** `Crossfade` (einfach, nur Fade) vs. `AnimatedContent` (flexibler,
ContentTransform mit Fade + Scale).

**Entscheidung:** `AnimatedContent` mit `fadeIn(animationSpec = tween(200)) + scaleIn(initialScale = 0.95f) togetherWith fadeOut(animationSpec = tween(200)) + scaleOut(targetScale = 0.95f)`.

**Warum:** Konsistent zur iOS-Animation (`.opacity.combined(with: .scale(scale: 0.95))`).
Crossfade waere visuell leicht abweichend von iOS.

---

## Layout-Skizze

```
┌──────────────────────────────────────────────────────────────────────┐  StatusBar
│ (StatusBar / SafeArea-Top)                                            │
├──────────────────────────────────────────────────────────────────────┤
│ ┌─ LibraryHeaderBar (Row, padding 22.dp / 12.dp / 22.dp / 8.dp) ────┐ │
│ │                                                                    │ │
│ │ ┌─ LibrarySearchPill (Capsule, 40 dp, weight 1f) ─┐  ┌─ Action ─┐ │ │
│ │ │ 🔍  "Suchen"                              [×]   │  │ + │ i  │ │ │
│ │ └─────────────────────────────────────────────────┘  └──────────┘ │ │
│ │                                                                    │ │
│ └────────────────────────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────────────────┤
│ Body (LazyColumn, scrollt)                                            │
│   Idle:    MeditationsList                                            │
│   History: SearchHistoryList                                          │
│   Results: SearchResultsList                                          │
│   Empty:   SearchEmptyState                                           │
│ ...                                                                   │
│ (BottomFadeMask)                                                      │
├──────────────────────────────────────────────────────────────────────┤
│ TabBar                                                                │
└──────────────────────────────────────────────────────────────────────┘
```

**Active-State** (Such-Pille fokussiert):

```
┌─ LibrarySearchPill (Capsule, 40 dp, weight 1f - expandiert) ──┐  Abbrechen
│ 🔍  |Cursor   "tara"                                  [×]      │  (TextButton,
└────────────────────────────────────────────────────────────────┘   theme.interactive)
```

**Komponenten-Hierarchie:**

```
GuidedMeditationsListScreen
└── GuidedMeditationsListScreenContent
    └── Box (root)
        └── Scaffold (snackbarHost)
            └── Box (padding)
                └── LibraryBody  ◄── existierend, kein StillMomentTopAppBar mehr darueber
                    └── (Empty | Loading | LibraryWithHeader)
                        └── Column
                            ├── LibraryHeaderBar  ◄── NEU
                            │   └── Row
                            │       ├── LibrarySearchPill (weight 1f)  ◄── refactored
                            │       └── AnimatedContent
                            │           ├── LibraryActionPill (Idle)  ◄── NEU
                            │           └── LibraryCancelButton (Active)  ◄── NEU
                            └── Box (4 States wie shared-101)
                                ├── MeditationsList
                                ├── SearchHistoryList
                                ├── SearchResultsList
                                └── SearchEmptyState
```

---

## Refactorings

1. **`LibrarySearchBar.kt` → `LibrarySearchPill` umschreiben**
   - Heute: `Card` + `TextField` + `BorderStroke` + `liftedCardShadow` mit
     `RoundedCornerShape(12.dp)`.
   - Neu: kein `Card`-Wrapper, stattdessen `Row` mit `Modifier.height(40.dp)`,
     `RoundedCornerShape(50)`, `background(theme.cardBackground)`, conditional
     `BorderStroke` (Dark / Focus) bzw. `liftedCardShadow` (Light).
   - `BasicTextField` statt `TextField` (Material-`TextField`-Padding ist nicht
     unterdrueckbar auf 40 dp). Lupe und Clear-X als `Icon` und `IconButton`
     Geschwister im Row, nicht via `leadingIcon`/`trailingIcon`.
   - Neuer Pflicht-Parameter: `focusRequester: FocusRequester`. Wird von
     `LibraryHeaderBar` injected, damit der Tap-auf-Pille den Focus an `BasicTextField`
     reichen kann.
   - **Risiko**: Niedrig. Das ViewModel-Interface bleibt identisch.

2. **`GuidedMeditationsListScreenContent` umbauen**
   - `StillMomentTopAppBar`-Block (Lines 172–200) entfernen.
   - `Box(modifier = Modifier.fillMaxSize().padding(top = TopAppBarHeight))` entfernen —
     der Body sitzt direkt unter der StatusBar; der Header (eigene 56 dp Hoehe ca.) ist
     Teil der `LibraryWithSearchBar`-`Column`.
   - `LibraryBody` Aufrufstelle bleibt; nur `LibraryWithSearchBar`-Innenleben wird
     umgebaut: heute `LibrarySearchBar(...)` im Body, neu `LibraryHeaderBar(...)`
     anstelle dessen.
   - `onImportClick` und `onOpenGuide` werden in den `LibraryHeaderBar` durchgereicht
     (sind ohnehin bereits Parameter von `GuidedMeditationsListScreenContent`).
   - **Risiko**: Niedrig. Empty-State-Pfad bleibt unveraendert; nur der non-Empty-Pfad
     bekommt einen neuen Header statt der alten TopBar.

3. **String-Catalog: `library_search_prompt` Wert aendern, neuen Cancel-Key ergaenzen**
   - `library_search_prompt` Wert von "Search by title or teacher" / "Nach Titel oder
     Sprecher suchen" auf "Search" / "Suchen" aendern.
   - Neuer Key `accessibility_library_search_cancel`.
   - **Risiko**: Niedrig. Der Key bleibt; nur der Wert aendert sich. Konsistent zu iOS-051.

4. **Kein Refactoring an Such-Engine, History-Persistenz, ViewModel-API, oder
   `ResetLibrarySearchOnPause`.** Sauberer Cut, wie iOS-051.

---

## Fachliche Szenarien

### Header-Layout

- **Gegeben:** Library mit mind. 1 Meditation, View geoeffnet
  **Wenn:** Nutzer betrachtet die Library
  **Dann:** Kein "Bibliothek"-Title sichtbar. Direkt unter der StatusBar sitzt die
  Header-Bar mit Such-Pille (links, breit) und Aktion-Pille (rechts, schmal).

- **Gegeben:** Library mit 0 Meditationen (Empty-State)
  **Wenn:** Nutzer oeffnet die Library
  **Dann:** Keine Header-Bar sichtbar; `EmptyLibraryState` wie bisher (Welcome-Icon +
  Import-Button + Find-Sources-Link).

- **Gegeben:** Library mit vielen Meditationen
  **Wenn:** Nutzer scrollt in der Liste
  **Dann:** Header-Bar bleibt fixiert am oberen Rand — keine Scroll-Animation, kein
  Verstecken.

### Such-Pille Idle

- **Gegeben:** Library im Idle-Zustand, Such-Pille leer und unfokussiert
  **Wenn:** Nutzer tippt irgendwo auf die Such-Pille (Lupe, Platzhalter, Mitte)
  **Dann:** Tastatur erscheint, `BasicTextField` bekommt Fokus, `setSearchFocused(true)`
  wird gerufen, History-State wird im Body gerendert, Aktion-Pille fadet aus,
  "Abbrechen"-Button fadet ein.

### Such-Pille Active

- **Gegeben:** Such-Pille fokussiert, Eingabe leer
  **Wenn:** Nutzer tippt "ta"
  **Dann:** `updateSearchQuery("ta")` wird gerufen; Trefferliste erscheint live
  (shared-101-Logik unveraendert). Clear-X erscheint rechts in der Pille.

- **Gegeben:** Such-Pille fokussiert mit Eingabe "tara"
  **Wenn:** Nutzer tippt Clear-X
  **Dann:** `updateSearchQuery("")` wird gerufen, Fokus bleibt, History-State.

- **Gegeben:** Such-Pille fokussiert mit Eingabe "tara"
  **Wenn:** Nutzer tippt "Abbrechen"
  **Dann:** `resetSearch()` wird gerufen, `FocusManager.clearFocus()` wird gerufen,
  Tastatur klappt ein, Aktion-Pille fadet wieder ein, Idle-Zustand erreicht.

- **Gegeben:** Such-Pille fokussiert mit "tara", Trefferliste sichtbar
  **Wenn:** Nutzer tippt auf einen Treffer
  **Dann:** `recordSearchCommittedByOpening()` schreibt "tara" in die Historie,
  `navController.navigate(...)` startet, `ON_PAUSE` triggert `resetSearch()`. Bei
  Rueckkehr ist die Library im Idle.

### Aktion-Pille

- **Gegeben:** Library im Idle-Zustand
  **Wenn:** Nutzer tippt "+"
  **Dann:** `onImportClick` triggert SAF-Picker (`OpenDocument`, wie heute).

- **Gegeben:** Library im Idle-Zustand
  **Wenn:** Nutzer tippt "i"
  **Dann:** `onOpenGuide` triggert `ContentGuideSheet` (wie heute).

- **Gegeben:** Such-Pille fokussiert
  **Wenn:** Nutzer schaut auf die rechte Seite
  **Dann:** Aktion-Pille ist nicht sichtbar; "Abbrechen" steht dort.

### Such-Verhalten (unveraendert aus shared-101)

- Tipp-Cycle idle ↔ history ↔ results ↔ empty fuehlt sich identisch an.
- Suchhistorie wird bei Treffer-Tap und IME-Search gespeichert.
- Match-Highlight in Akzentfarbe + SemiBold bleibt.
- Empty-State: `liveRegion = Polite`.

### Theme / Light + Dark

- **Light Mode:** Such-Pille hat `liftedCardShadow`, `BorderStroke(0.5.dp, theme.cardBorder)`,
  `cardBackground`. Bei Fokus: zusaetzlich `interactive.copy(alpha = 0.25f)` als 1 dp
  Border-Overlay (Akzent-Border).
- **Dark Mode:** Kein Shadow, nur `BorderStroke(0.5.dp, theme.cardBorder)` (bzw. bei Fokus
  `interactive.copy(alpha = 0.35f)` mit 1 dp).
- **Aktion-Pille:** gleiche Light/Dark-Strategie ohne Focus-Variation.
- **Trennlinie zwischen + und i:** `theme.divider.copy(alpha = 0.18f)`, 1 dp breit,
  ca. 18 dp hoch.

### Accessibility

- **TalkBack** liest im Idle: "Bibliothek durchsuchen, Suchfeld" → "Meditation
  hinzufuegen" → "Anleitung oeffnen".
- **TalkBack** liest im Active: "Bibliothek durchsuchen, Suchfeld" → "Suche abbrechen".
- **Touch-Targets:** "+", "i", "Abbrechen", Clear-X — jeder mindestens 48 dp via
  `minimumInteractiveComponentSize()`.
- **Font-Scale Largest:** Header darf zweizeilig umbrechen, Pillen duerfen nicht clippen.

---

## Reihenfolge der Akzeptanzkriterien (TDD)

Reihenfolge: kleinste Einheit → groesste. Pro Schritt RED → GREEN → REFACTOR. Da der
Hauptaufwand UI ist und es keine neue Logik gibt, ueberwiegen Compose-UI-Tests gegenueber
Unit-Tests.

1. **`LibraryActionPill`-Composable + Preview** — kleinste Einheit. Compose-Test:
   `onAdd`/`onInfo` Callbacks werden bei Tap getriggert; TalkBack-Labels gesetzt.
2. **`LibrarySearchPill`-Refactor** — alter `LibrarySearchBar` umschreiben. Bestehende
   Funktionalitaet (Tippen aktualisiert Query, Clear-X leert, IME-Search ruft `onSubmit`)
   bleibt erhalten. Compose-Test: Query erscheint im Field, Clear-X leert.
3. **`LibraryHeaderBar`-Composable** — komponiert Such-Pille + AnimatedContent
   (Aktion-Pille ↔ Cancel). Compose-Test: Idle zeigt Aktion-Pille; Tap auf Such-Pille
   blendet auf Cancel; Tap auf Cancel kehrt auf Aktion-Pille zurueck.
4. **`GuidedMeditationsListScreenContent`-Umbau** — `StillMomentTopAppBar` raus,
   `LibraryHeaderBar` in `LibraryWithSearchBar` an Stelle von `LibrarySearchBar`.
   Existierende UI-Tests fuer Library-State (Empty, Loading, With Data) muessen gruen
   bleiben.
5. **String-Catalog kuerzen + Cancel-Key ergaenzen** — DE/EN.
6. **Manueller Test gemaess Ticket-Checkliste** (12 Schritte) inklusive Font-Scale-Check
   in "Large" / "Largest".
7. **CHANGELOG-Eintrag.**

---

## Vorbereitung

Keine manuellen Schritte noetig:
- Keine neuen Dependencies (alle benoetigten APIs sind in Compose 1.4+ verfuegbar).
- Keine Manifest-Aenderungen.
- Keine Datenbank-Migration.
- Keine neuen Hilt-Module.

---

## Risiken

| Risiko | Mitigation |
|---|---|
| Material-`TextField` lieferte heute viele Defaults (Theme, Padding, Cursor-Animation); `BasicTextField` braucht alles explizit | `BasicTextField` mit `cursorBrush = SolidColor(theme.interactive)`, `textStyle = TextStyle.body.toComposeTextStyle().copy(color = theme.textPrimary)`. Cursor-Animation kommt von `BasicTextField` selbst. Tastatur via `KeyboardOptions(imeAction = ImeAction.Search)` und `KeyboardActions(onSearch = ...)` — identisch zu shared-101. |
| `Modifier.height(40.dp)` auf `BasicTextField` kann Cursor verstecken, wenn Text groesser ist | Bei Font-Scale Largest werden Pille und Inhalt mitskalieren. Test bei Font-Scale 1.3x und 1.5x. Falls Text geclippt wird: `Modifier.heightIn(min = 40.dp)` statt `.height(40.dp)` setzen — laesst die Pille mitwachsen. |
| `AnimatedContent` zwischen Aktion-Pille und Cancel-Button mit unterschiedlichen Layout-Breiten kann ruckeln | `AnimatedContent` bekommt `transitionSpec = { ContentTransform(...) }` und `contentAlignment = Alignment.CenterEnd` damit beide Inhalte rechts ankommen. Fallback: `Crossfade` (Fade-only) — visuell minimal weniger lebendig, aber stabil. |
| `FocusRequester` aus `LibraryHeaderBar` an `LibrarySearchPill` durchreichen — wenn die Pille recomposed wird, kann der Requester veralten | `FocusRequester` als `remember { FocusRequester() }` im `LibraryHeaderBar` deklarieren und in `LibrarySearchPill` reinreichen. `remember`-Lebenszyklus deckt den ganzen Header ab. |
| Tap-Geste auf die Pille (statt direkt ins `BasicTextField`) bekommt im Edge-Case keinen Focus | `Modifier.clickable` auf den Pillen-`Row` ruft `focusRequester.requestFocus()`. Compose route propagiert das an das Child-`BasicTextField`. Test: Tap auf Lupe muss Focus geben. |
| Empty-State enthaelt heute Import-Button — Aktion-Pille darf nicht doppelt erscheinen | Header wird nur im non-Empty-Pfad gerendert (im `LibraryBody`-`else`-Branch). Empty-State bleibt 1:1 aus shared-101. |
| `library_search_prompt` wird in shared-101-Tests ausgelesen (`assertHasText("Search by title or teacher")`?) | Vor dem Wert-Wechsel: `androidTest`-Verzeichnis nach dem alten String durchsuchen (`grep -r "Search by title or teacher"`). Falls hardcoded in einem Test, dort auf neuen Wert anpassen oder den Test auf `R.string.library_search_prompt`-Aufloesung umstellen. |
| Detekt-Warnung `LongMethod` in `GuidedMeditationsListScreenContent` (heute bereits `@Suppress`ed) bleibt | Akzeptabel — die Suppression bleibt. Falls die Methode aufgrund des Umbaus weiter waechst: `LibraryHeaderBar`-Aufrufstelle in eigene private `@Composable LibraryContent(...)`-Methode extrahieren. |
| TalkBack-Fokus-Reihenfolge: Aktion-Pille wird als ein Element vorgelesen statt zwei | `IconButton`-Geschwister in der Pille bekommen jeweils ihren eigenen `Modifier.semantics { contentDescription = ... }`. Die Pille selbst hat kein `mergeDescendants = true`, damit TalkBack beide getrennt liest. |
| `BasicTextField`-Cursor-Akzentfarbe ohne Material-Default | `cursorBrush = SolidColor(theme.interactive)` explizit setzen. |

---

## Offene Fragen

- [ ] Soll der Header eine subtile Bottom-Border / Trennlinie bekommen, um sich vom
  Body abzusetzen? **Vorschlag:** Nein — iOS hat keine, der visuelle Abstand zwischen
  Pillen und ListItems reicht. Konsistent zu iOS.
- [ ] Soll die Header-Animation Idle ↔ Active auch ein leichtes Slide enthalten (Cancel
  kommt von rechts rein)? **Vorschlag:** Nein — bei iOS ist es Fade + Scale, konsistent
  belassen.
- [ ] Soll die Such-Pille bei Fokus eine zusaetzliche Hoehen-Aenderung bekommen (z.B.
  44 dp statt 40 dp)? **Vorschlag:** Nein — Hoehe bleibt 40 dp, nur die Akzent-Border
  zeigt den Focus-State an. Konsistent zu iOS.
- [ ] Was passiert bei externer Hardware-Tastatur, wenn der User per Tab durch die
  Header-Buttons navigiert? **Vorschlag:** Compose-Default-Focus-Indikator (helle
  Outline). Keine Sonder-Logik noetig. Manueller Test mit USB-Tastatur am Geraet.

---

## Referenzen

- iOS-Pendant: [ios-051](../ios/ios-051-library-header-suchfeld-sichtbar.md) — DONE
- iOS-Plan: [ios-051 Plan](ios-051.md)
- iOS-Implementation:
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/LibraryHeaderView.swift`
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/LibraryActionPill.swift`
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift`
- Vorgaenger Android: [shared-101 Plan](shared-101-android.md) — DONE
- Aktuelle Android-Library:
  - `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationsListScreen.kt`
  - `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/LibrarySearchBar.kt`
  - `android/app/src/main/kotlin/com/stillmoment/presentation/ui/components/StillMomentTopAppBar.kt`
  - `android/app/src/main/kotlin/com/stillmoment/presentation/navigation/NavGraph.kt` (Reset-Hook)
- Theme-Tokens shared-094: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/theme/{Color,Theme}.kt`
- Card-Lift-Pattern: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/theme/LiftedCardShadow.kt`
- Design-Handoff: `handoffs/Library Header - Mit Suche.html`
