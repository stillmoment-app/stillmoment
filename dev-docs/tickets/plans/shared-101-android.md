# Implementierungsplan: shared-101 (Android)

Ticket: [shared-101](../shared/shared-101-library-search-android.md)
iOS-Pendant: [ios-041](../ios/ios-041-library-search.md) — bereits umgesetzt
iOS-Plan-Vorbild: [ios-041 Plan](ios-041.md)
Erstellt: 2026-05-21
Branch: `feature/shared-101-android`

---

## Ziel in einem Satz

Die Library bekommt eine Volltextsuche ueber Titel + Lehrer mit Live-Filter, persistenter
Suchhistorie (max 6) und Match-Highlight in der Akzentfarbe — verhaltens- und such-engine-identisch
zu iOS, visuell konsistent zur warmen Card-Sprache aus shared-094.

---

## Annahmen

Bewusste Festlegungen, die in den Plan eingeflossen sind. Bitte beim Review pruefen.

- **Such-Engine ist eine 1:1-Portierung der iOS-Implementation.** Pure Kotlin im Domain-Layer,
  keine Android-Framework-Imports. Token-Splitting per Whitespace, Multi-Token-UND, Substring-Match,
  vier Ranking-Buckets, "best-match-wins" bei Multi-Token (siehe iOS-Plan Design-Entscheidung 1),
  Tiebreaker nach `dateAdded`.
- **Diakritika-Normalisierung via `java.text.Normalizer`** (NFD + Strip-Combining-Marks). Java-API,
  ab API 24 verfuegbar, keine externe Library noetig. Folding pro Substring-Vergleich auf beiden
  Seiten, damit Original-`String.indices` fuer das Highlighting erhalten bleiben.
- **`MatchBucket` als interner `enum class` (mit `Comparable`-Implementierung).** Nicht als
  `sealed class` — wir brauchen nur die Sortierung nach Rawvalue, kein Polymorphismus.
- **Suchhistorie in eigenem DataStore-File `search_history`** (nicht in `settings.preferences_pb`).
  Trennung verhindert die DataStore-Singleton-Falle aus dem MEMORY-Eintrag — ein File, eine
  `preferencesDataStore`-Property, im `presentation.viewmodel.searchhistory`-Package abgelegt
  (`internal` Visibility, damit Tests via FakePreferences arbeiten koennen).
- **Persistenz als JSON-Liste in einem `stringPreferencesKey("history")`.** Eine Liste hat max
  6 kurze Strings — `kotlinx.serialization.encodeToString(ListSerializer(String.serializer()), ...)`
  reicht. Alternative `stringSetPreferencesKey` haette die Reihenfolge zerstoert und ist deshalb
  ausgeschlossen.
- **`SearchHistoryRepositoryProtocol` im Domain-Layer**, `DataStoreSearchHistoryRepository` im
  `data/local/` — gleicher Architektur-Layer wie die anderen DataStores (`PraxisDataStore`,
  `SettingsDataStore`). Bewusst kein Hilt-Constructor-Inject im ViewModel ohne Wrapper — das
  Domain-Protokoll bleibt frei von Android-Imports.
- **State-Machine via `LibrarySearchState` Sealed-Class im Domain-Layer**: `Idle | History | Results | Empty`.
  Wird im ViewModel aus `searchQuery` + `isSearching` + `searchResults` abgeleitet (computed
  property, kein eigener StateFlow).
- **Suchfeld als `OutlinedTextField` in einem Card-Container**, nicht als Material-3
  `SearchBar`. Begruendung in Design-Entscheidung 1.
- **Live-Suche ab Zeichen 1, kein Debounce.** Bibliotheken sind klein (typisch <100, oberer
  Rand <500 Eintraege). Die Such-Engine ist eine reine In-Memory-Filteroperation auf einer
  bereits ge-collecteten Liste — fuer diese Groessenordnung deutlich unter 16 ms pro Tick.
- **Tab-Wechsel-Reset und Treffer-Tap-Reset werden im ViewModel implementiert.** Der
  Tab-Wechsel-Reset wird via `LaunchedEffect(currentRoute)` im `NavGraph` getriggert, sobald
  die Library-Route den Fokus verliert. Treffer-Tap-Reset passiert direkt im
  `onMeditationClick`-Handler vor der Navigation.
- **Suchfeld erscheint zwischen `StillMomentTopAppBar` und `MeditationsList`** — unter dem Titel,
  ueber der Liste. Bei leerer Bibliothek (`uiState.isEmpty`) bleibt der bestehende
  `EmptyLibraryState` unveraendert ohne Suchfeld.
- **Long-Press Preview, Swipe-Edit/Delete und Tap-zum-Player bleiben identisch** zur normalen
  Liste — die neue `SearchResultsList` ruft die gleichen Handler auf wie `MeditationsList`.
- **TalkBack-Live-Region fuer Empty-Treffer-State** via `Modifier.semantics { liveRegion = LiveRegionMode.Polite }`.
  Headline + Subline werden gemeinsam angesagt.
- **Tastatur einklappen beim Scrollen**: `LazyListState.isScrollInProgress` beobachten und
  `LocalSoftwareKeyboardController.current?.hide()` triggern. Sauberer als ein zusaetzlicher
  `nestedScroll`-Connector und konsistent zu iOS `.scrollDismissesKeyboard(.immediately)`.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `domain/services/LibrarySearchEngine.kt` | Domain | **Neu** | Pure Object-Singleton mit `tokens(query)`, `search(meditations, query)`, `highlightRanges(text, query)`. 1:1-Port der iOS-Logik. |
| `domain/services/SearchHistory.kt` | Domain | **Neu** | Pure Object-Singleton mit `prepend(history, term, limit)`, `normalize(value)`. Diakritika via `Normalizer.normalize(NFD)` + Combining-Mark-Strip. |
| `domain/repositories/SearchHistoryRepository.kt` | Domain | **Neu** | Interface: `historyFlow: Flow<List<String>>`, `suspend fun save(history: List<String>)`, `suspend fun clear()`. |
| `domain/models/LibrarySearchState.kt` | Domain | **Neu** | `sealed class LibrarySearchState { Idle | History | Results | Empty }` — abgeleiteter UI-State. |
| `data/local/SearchHistoryDataStore.kt` | Data | **Neu** | `internal val Context.searchHistoryDataStore by preferencesDataStore(name = "search_history")`. `@Singleton`-Klasse implementiert `SearchHistoryRepository`. Persistiert via `stringPreferencesKey("history")` als JSON-`List<String>`. |
| `presentation/viewmodel/GuidedMeditationsListViewModel.kt` | Presentation | Erweitern | Neue Felder im UiState (`searchQuery`, `searchHistory`, `isSearchFocused`, `searchResults`, `searchState`). Methoden: `updateSearchQuery`, `setSearchFocused`, `submitSearch`, `recordSearchCommittedByOpening`, `selectHistoryEntry`, `clearHistory`, `resetSearch`. Konstruktor erhaelt `SearchHistoryRepository`. |
| `presentation/ui/meditations/GuidedMeditationsListScreen.kt` | Presentation | Erweitern | Rendert ueber der `MeditationsList` ein `LibrarySearchBar`. Switched per `uiState.searchState` zwischen 4 Body-Bereichen. Reicht `onMeditationClick` durch die `resetSearch()`-Bruecke. |
| `presentation/ui/meditations/LibrarySearchBar.kt` | Presentation | **Neu** | `OutlinedTextField` in Card, Lupen-Icon, Clear-X, Akzent-Border bei Fokus. `accessibilityLabel = "library.search.field"`. |
| `presentation/ui/meditations/SearchHistoryList.kt` | Presentation | **Neu** | LazyColumn mit "Zuletzt gesucht"-Header und "Leeren"-Button, Uhr-Icon + Suchbegriff + Diagonalpfeil pro Zeile. |
| `presentation/ui/meditations/SearchResultsList.kt` | Presentation | **Neu** | Flache `LazyColumn` mit "{N} Treffer"-Header, `MeditationListItem`-Reuse pro Zeile + `HighlightedText` fuer Titel und Lehrer. Swipe-Actions identisch zur normalen Liste. Tastatur via `lazyListState.isScrollInProgress` ausblenden. |
| `presentation/ui/meditations/SearchEmptyState.kt` | Presentation | **Neu** | Zentriert: Lupen-Kreis, "Nichts gefunden", "Keine Treffer für „{q}"". `liveRegion = Polite`. |
| `presentation/ui/meditations/HighlightedText.kt` | Presentation | **Neu** | Composable wrapper: nimmt `text`, `query`, faerbt alle Vorkommen ueber `buildAnnotatedString` + `SpanStyle(color = theme.interactive, fontWeight = SemiBold)`. Delegiert an `LibrarySearchEngine.highlightRanges`. |
| `presentation/ui/meditations/MeditationListItem.kt` | Presentation | Aendern (kleiner) | Optionalen `query: String?`-Parameter aufnehmen, der bei Nicht-Null an `HighlightedText` durchgereicht wird. Default `null` → unveraenderter Pfad fuer die normale Liste. |
| `presentation/navigation/NavGraph.kt` | Presentation | Aendern (klein) | `LaunchedEffect(currentRoute)`-Bruecke: wenn die Library-Route den Fokus verliert, `viewModel.resetSearch()` aufrufen. |
| `infrastructure/di/AppModule.kt` | Infrastructure | Aendern | `provideSearchHistoryRepository(impl: SearchHistoryDataStore): SearchHistoryRepository`. |
| `res/values/strings.xml` | Resources | Erweitern | 6 neue Keys + 3 Accessibility-Keys (EN). |
| `res/values-de/strings.xml` | Resources | Erweitern | gleiche Keys (DE). |
| `CHANGELOG.md` | Doc | Eintrag | "Suchfunktion in der Bibliothek" unter `Unreleased` → `Added (Android)`. |

### Neue Tests

| Datei | Inhalt |
|---|---|
| `test/.../domain/services/LibrarySearchEngineTest.kt` | Token-Splitting; Normalisierung (Case, Diakritika); Single-Token-Bucket-Sortierung (4 Buckets); Multi-Token-UND mit best-match-wins; Tiebreaker `dateAdded`; `highlightRanges` mehrfach + ueberlappend; leere Eingabe → leere Trefferliste. |
| `test/.../domain/services/SearchHistoryTest.kt` | `prepend` neuer Begriff, Dedup case+diakritika-insensitiv, FIFO-Cap 6, Trimming, leerer Term laesst unveraendert; `normalize` lowercase + diakritika-frei. |
| `test/.../data/local/SearchHistoryDataStoreTest.kt` | Roundtrip Save → Flow gibt aktualisierte Liste; `clear()` leert; FakePreferencesDataStore via `PreferenceDataStoreFactory.create` mit tmp-File. |
| `test/.../presentation/viewmodel/GuidedMeditationsListViewModelSearchTest.kt` | State-Uebergaenge idle ↔ history ↔ results ↔ empty; `submitSearch` commitet nur bei Treffern; `recordSearchCommittedByOpening` commitet + resettet; `clearHistory`; `resetSearch` setzt Query und `isSearchFocused` zurueck; `selectHistoryEntry` setzt Query. |
| `androidTest/.../presentation/ui/meditations/LibrarySearchScreenTest.kt` | Suchfeld nur sichtbar wenn Library nicht leer; Eingabe von "tara" zeigt Trefferliste; Tap auf Treffer triggert `resetSearch`; Tap auf "Leeren" loescht Historie; Empty-State erscheint bei keinen Treffern. (Nur 1-2 zentrale UI-Tests, der Rest ist Unit-Test-Coverage.) |

Geschaetzte Anzahl betroffener Produktiv-Dateien: **15 neu/geaendert** (8 neu, 7 geaendert) + 4 Test-Dateien neu + 2 Resource-Dateien + CHANGELOG.

---

## API-Recherche

Alle benoetigten APIs sind ab `minSdk = 26` verfuegbar:

| API | Min. Version | Quelle | Hinweis |
|---|---|---|---|
| `java.text.Normalizer.normalize(text, Form.NFD)` | API 1 / Java | JDK | Diakritika-Stripping. Folgt mit `Regex("\\p{Mn}+").replace(it, "")`. |
| `String.lowercase(locale = Locale.ROOT)` | Kotlin 1.5+ | Kotlin | Bewusst `Locale.ROOT`, sonst Tuerkisch-Falle (`i`/`I`-Mapping). |
| `androidx.datastore.preferences.preferencesDataStore` | DataStore 1.0+ | bereits genutzt | Eigene Property fuer `search_history`-File. |
| `androidx.compose.material3.OutlinedTextField` | M3 1.0+ | Compose Docs | Suchfeld-Container. Nutzt theme-Tokens via `colors = ...` Argument. |
| `androidx.compose.ui.text.buildAnnotatedString` + `SpanStyle` | Compose 1.0+ | Compose Docs | Match-Highlight in einem Text-Node. |
| `androidx.compose.foundation.lazy.LazyListState.isScrollInProgress` | Compose 1.0+ | Compose Docs | Tastatur beim Scrollen einklappen. |
| `androidx.compose.ui.platform.LocalSoftwareKeyboardController` | Compose 1.2+ | Compose Docs | Manuelles Verstecken der Tastatur. |
| `androidx.compose.ui.focus.FocusRequester` + `FocusManager.clearFocus()` | Compose 1.0+ | Compose Docs | Fokus aus dem Suchfeld bei `resetSearch` raussetzen. |
| `Modifier.semantics { liveRegion = LiveRegionMode.Polite }` | Compose 1.3+ | Compose Docs | Empty-State von TalkBack ansagen lassen. |
| `androidx.compose.material3.SwipeToDismissBox` | M3 1.0+ | bereits genutzt | Swipe-Actions in Trefferliste. |
| `kotlinx.serialization.encodeToString` mit `ListSerializer(String.serializer())` | bereits Dep | Kotlin Serialization | Persistenz der Historie als JSON-String. |

**Hinweis zu Material 3 `SearchBar`:** Verworfen. Die Material-3-`SearchBar` ist ein
Top-App-Bar-Ersatz mit aufklappbarem Voll-Overlay und festem Layout-Verhalten — passt nicht
zur "Suchfeld unter dem Titel, Liste darunter wechselt"-Form, die wir fuer Cross-Platform-Konsistenz
brauchen. Siehe Design-Entscheidung 1.

**Hinweis zu Java `Collator`:** Verworfen. `Collator` kann diakritika-insensitiv vergleichen,
aber nicht "Substring von a in b" liefern. Wir brauchen Positions-Information fuers Highlighting,
deshalb `Normalizer`-basiertes Folding + Indizes auf dem Original-String.

---

## Design-Entscheidungen

### 1. `OutlinedTextField` + Card-Container statt `SearchBar`

**Trade-off:** Material 3 `SearchBar` ist idiomatischer und bringt Tastatur-/Fokus-Verhalten
mit, ist aber ein Vollbild-aufklappbarer Top-App-Bar-Ersatz. Das Ticket fordert ein "Suchfeld
unter dem Titel" mit darunter wechselndem Content — nicht ein aufklappendes Overlay.

**Entscheidung:** `OutlinedTextField` in einem schmalen `Card`-Container (gleiche Card-Sprache
wie `MeditationListItem` aus shared-094), zwischen `StillMomentTopAppBar` und Content.

**Warum:**
- Visuelle Konsistenz mit iOS: dort rendert `.searchable(placement: .automatic)` ebenfalls ein
  unauffaelliges Feld unter dem Titel, nicht ein Vollbild-Overlay.
- Cross-Platform-Konsistenz hat laut Ticket Vorrang vor Material-3-Defaults.
- Wir kontrollieren das 4-State-Body-Switching selbst — `SearchBar` will den Body uebernehmen.
- Card-Sprache (Border 0.5 dp / Shadow im Light Mode, Border-only im Dark Mode) ist bereits
  etabliert via `liftedCardShadow` aus shared-094.

### 2. Such-Engine im Domain-Layer

**Trade-off:** ViewModel-internal vs. Domain-Service.

**Entscheidung:** Domain-Service als Kotlin `object` (entspricht `TimerReducer`).

**Warum:**
- Pure Funktionen, keine Dependencies, leicht testbar, kein State.
- Folgt der existierenden Reducer-Pattern-Konvention (`TimerReducer`).
- 1:1-Port der iOS-Implementation moeglich — gleicher Layer dort.

### 3. Eigenes DataStore-File `search_history` statt Wiederverwendung von `settings`

**Trade-off:** Wiederverwendung von `appSettingsDataStore` (Key-Erweiterung) vs. eigenes File.

**Entscheidung:** Eigenes `search_history`-File mit `internal val Context.searchHistoryDataStore`
im `data/local/`-Package.

**Warum:**
- MEMORY-Warnung `feedback_android_datastore_singleton.md`: mehrere `preferencesDataStore(name)`
  auf das gleiche File crashen. Trennung schliesst die Falle automatisch aus.
- Klare semantische Trennung: App-Settings vs. User-Suchverlauf.
- Privacy-konform — Datei laesst sich ggf. separat loeschen (Wipe-Feature spaeter).

### 4. JSON-String statt `stringSetPreferencesKey`

**Trade-off:** Set vs. Liste-als-JSON.

**Entscheidung:** JSON-`List<String>` in einem `stringPreferencesKey`.

**Warum:**
- `stringSetPreferencesKey` garantiert keine Reihenfolge → FIFO-Cap nicht umsetzbar.
- Liste ist klein (max 6 Strings), JSON-Overhead vernachlaessigbar.
- `kotlinx.serialization` ist bereits Dependency (`@Serializable` in `GuidedMeditation`).

### 5. Highlight nur Foreground + Weight, kein Background-Tint

**Trade-off:** Foreground+Background wie im Design-Handoff vs. nur Foreground+Weight.

**Entscheidung:** Foreground = `theme.interactive`, `fontWeight = SemiBold`. **Kein** Background.

**Warum:** Konsistent zur iOS-Entscheidung (siehe `HighlightedText.swift`): auf der warmen
Card-Background-Farbe (`#FFF6E6` light / `#2E211A` dark) verschwimmt ein zusaetzlicher
semi-transparenter Akzent-Tint. iOS hat aus genau diesem Grund den Tint aus dem Handoff
weggelassen — gleiche Begruendung auf Android. Cross-Platform-Konsistenz hat Vorrang.

### 6. Tab-Wechsel-Reset in `NavGraph` per `LaunchedEffect(currentRoute)`

**Trade-off:** `DisposableEffect` in Library-Screen vs. zentral im `NavGraph`.

**Entscheidung:** Zentral im `NavGraph` via `LaunchedEffect(currentRoute)`.

**Warum:**
- `DisposableEffect.onDispose` feuert auf Compose nicht zuverlaessig beim Tab-Wechsel (Screen
  bleibt im Memory).
- Der `currentRoute` ist im `NavGraph` bereits verfuegbar — direkte Bruecke.
- Explizit und testbar (UI-Test simuliert Tab-Wechsel).

### 7. `MatchBucket` als `enum class`, nicht als `sealed class`

**Trade-off:** Sealed-Class (idiomatisch fuer State) vs. Enum (Comparable, ordinal).

**Entscheidung:** `enum class MatchBucket : Comparable<MatchBucket>` mit eigenem `compareTo`
auf `ordinal`.

**Warum:** Es gibt keine assoziierten Daten pro Bucket, nur Ordnung. Enum ist hier idiomatischer
Kotlin-Style; `sealed class` waere Over-Engineering.

---

## Fachliche Szenarien

### Suchfeld-Sichtbarkeit

- **Gegeben:** Bibliothek ist leer
  **Wenn:** Nutzer oeffnet den Library-Tab
  **Dann:** Kein Suchfeld sichtbar; bestehender `EmptyLibraryState` unveraendert.

- **Gegeben:** Mindestens eine Meditation importiert
  **Wenn:** Nutzer oeffnet den Library-Tab
  **Dann:** Suchfeld erscheint unter dem Titel, leer, unfokussiert; Liste darunter wie bisher.

### Live-Filter & Tastatur

- **Gegeben:** Library mit Meditationen, Suchfeld leer
  **Wenn:** Nutzer tippt das Suchfeld an
  **Dann:** Fokus + Tastatur erscheinen; Liste verschwindet; "Zuletzt gesucht"-Liste wird gezeigt
  (zunaechst leer).

- **Gegeben:** Suchfeld leer und fokussiert
  **Wenn:** Nutzer tippt ein einzelnes Zeichen
  **Dann:** Trefferliste erscheint sofort (kein Debounce).

- **Gegeben:** Trefferliste sichtbar
  **Wenn:** Nutzer scrollt die Trefferliste
  **Dann:** Tastatur klappt ein (`SoftwareKeyboardController.hide()` getriggert durch
  `isScrollInProgress`).

### Such-Verhalten

- **Gegeben:** Meditation "Atemmeditation" / "Tara Brach", Eingabe `"ATEM"` → Treffer
  (case-insensitiv).
- **Gegeben:** Meditation "Übung im Loslassen", Eingabe `"ubung"` → Treffer
  (diakritika-insensitiv via `Normalizer`).
- **Gegeben:** Meditation "Tara Brach — Atemmeditation", Eingabe `"ata"` → Treffer
  (Substring).
- **Gegeben:** Meditationen "Body Scan" / "Tara Brach" und "Atemmeditation" / "Tara Brach",
  Eingabe `"tara body"` → nur "Body Scan" (UND-Verknuepfung).
- **Gegeben:** Vier Meditationen mit Treffern in den Buckets 1–4 (siehe iOS-Plan) → Sortierung
  1 → 2 → 3 → 4.
- **Gegeben:** Zwei Meditationen im selben Bucket, unterschiedliches `dateAdded` → neuere zuerst.

### Trefferliste

- **Gegeben:** Query `"tara"`, drei Treffer
  **Dann:** Header "3 Treffer"; flache LazyColumn ohne Lehrer-Gruppen; jede Zeile mit Titel +
  Lehrer-Untertitel + Dauer + Play-Button; alle Vorkommen von `"tara"` in Titel und Lehrer in
  Akzentfarbe + SemiBold (mehrfach pro Zeile moeglich).

- **Gegeben:** Trefferzeile sichtbar
  **Wenn:** Nutzer tippt auf den Play-Button
  **Dann:** Player oeffnet sich (`onMeditationClick`); Suchquery wird zurueckgesetzt
  (`resetSearch`); Historie erhaelt den Begriff (falls Treffer vorhanden); bei Rueckkehr ist
  die Library im Idle-Zustand.

- **Gegeben:** Trefferzeile sichtbar
  **Wenn:** Nutzer haelt lange auf den Play-Button
  **Dann:** Preview startet wie bisher (`onPreviewStart`); Query bleibt.

- **Gegeben:** Trefferzeile sichtbar
  **Wenn:** Nutzer swiped (Edit / Delete)
  **Dann:** Wie heute (Edit-Sheet / Delete-Dialog).

### Empty-Treffer-State

- **Gegeben:** Eingabe `"xyz123"`, keine Treffer
  **Dann:** Lupen-Symbol (56 dp Kreis) + "Nichts gefunden" + "Keine Treffer für „xyz123""
  zentriert; `liveRegion = Polite` sorgt fuer automatische TalkBack-Ansage.

### Historie

- **Gegeben:** Leere Historie, Eingabe `"tara"`, Treffer vorhanden
  **Wenn:** Nutzer drueckt IME-Done
  **Dann:** `"tara"` steht oben in der Historie.

- **Gegeben:** Leere Historie, Eingabe `"tara"`, Treffer vorhanden
  **Wenn:** Nutzer tippt auf einen Treffer (Play-Button)
  **Dann:** `"tara"` steht oben in der Historie.

- **Gegeben:** Eingabe `"xyz123"`, keine Treffer
  **Wenn:** Nutzer drueckt IME-Done oder verlaesst den Tab
  **Dann:** `"xyz123"` ist NICHT in der Historie.

- **Gegeben:** Historie enthaelt `["Atem", "Tara", "Body"]`, Eingabe `"atem"`, Submit
  **Dann:** Historie → `["Atem", "Tara", "Body"]` (Duplikat nach oben; neue Schreibweise gewinnt
  bei verschiedener Capitalisation).

- **Gegeben:** Historie enthaelt 6 Eintraege, neuer Begriff
  **Dann:** Aeltester Eintrag faellt heraus; Laenge bleibt 6; Neuer Eintrag steht oben.

- **Gegeben:** Historie enthaelt `["Tara"]`
  **Wenn:** Nutzer tippt auf "Tara" in der Historie
  **Dann:** Suchfeld zeigt "Tara"; Trefferliste erscheint sofort.

- **Gegeben:** Historie hat 3 Eintraege
  **Wenn:** Nutzer tippt "Leeren"
  **Dann:** Historie ist sofort leer; UI zeigt leeren Historie-Body (nur Header).

- **Gegeben:** Historie enthaelt `["Atem"]`, App wird komplett beendet
  **Wenn:** App neu gestartet, Library-Tab fokussiert, Suchfeld angetippt
  **Dann:** Historie zeigt `["Atem"]`.

### Reset-Verhalten

- **Gegeben:** Trefferliste sichtbar mit Query `"tara"`
  **Wenn:** Nutzer wechselt auf den Timer-Tab und wieder zurueck
  **Dann:** Suchfeld leer; Library im Idle-Zustand; Historie unveraendert.

### Accessibility

- **Gegeben:** TalkBack aktiv, Suchfeld erscheint
  **Dann:** `contentDescription = "Bibliothek durchsuchen"`.

- **Gegeben:** Suchfeld mit Inhalt, Clear-X sichtbar
  **Dann:** `contentDescription = "Suche leeren"`.

- **Gegeben:** Historie-Eintrag `"Tara"`
  **Dann:** `contentDescription = "Erneut suchen: Tara"`.

- **Gegeben:** Trefferzeile
  **Dann:** Mindestens 48 dp hoch (bestehende `MeditationListItem`-Hoehe).

---

## Reihenfolge der Akzeptanzkriterien (TDD)

Reihenfolge Domain → Data → ViewModel → UI. Pro Schritt RED → GREEN → REFACTOR.

1. **Domain: `LibrarySearchEngine.tokens(query)` + `normalize`-Hilfsfunktionen** — Grundlage.
2. **Domain: `LibrarySearchEngine.search(meditations, query)` — Single-Token-Cases** (case,
   diakritika, substring) und Bucket-Sortierung.
3. **Domain: Multi-Token-UND + Tiebreaker `dateAdded`** — alle Such-AKs gruen.
4. **Domain: `LibrarySearchEngine.highlightRanges(text, query)`** — pure Funktion mit ueberlappenden
   Ranges-Merge.
5. **Domain: `SearchHistory.prepend(history, term, limit)` pure Funktion** — Dedup, FIFO,
   case-/diakritika-insensitiv via `normalize`.
6. **Domain: `LibrarySearchState` Sealed-Class** + Modell-Tests (Idle/History/Results/Empty).
7. **Data: `SearchHistoryDataStore` + Repository-Roundtrip-Test** mit Fake-DataStore.
8. **DI: `AppModule.provideSearchHistoryRepository(...)`** + Build-Smoketest.
9. **ViewModel: UiState-Felder + `updateSearchQuery`/`setSearchFocused`** — State-Uebergaenge
   idle → history → results → empty mit Test (`runTest`).
10. **ViewModel: `submitSearch` / `recordSearchCommittedByOpening` / `clearHistory` /
    `resetSearch` / `selectHistoryEntry`** — Historie-Persistenz + Reset.
11. **Presentation: `HighlightedText`-Composable** + Preview-Snapshot.
12. **Presentation: `LibrarySearchBar`-Composable** — Card-Container, Lupen-Icon, Clear-X,
    Fokus-Akzent.
13. **Presentation: `SearchHistoryList` + `SearchResultsList` + `SearchEmptyState`** —
    Subviews pro State.
14. **Presentation: `GuidedMeditationsListScreen` Body-Switch** auf `uiState.searchState`;
    `MeditationsList` bleibt der Idle-Pfad.
15. **Presentation: Reset bei Tab-Wechsel** (`LaunchedEffect(currentRoute)` in `NavGraph`) +
    Reset beim Oeffnen eines Treffers (im `onMeditationClick`-Handler).
16. **Presentation: Tastatur-Ausblendung beim Scrollen** via `isScrollInProgress`.
17. **Accessibility-Labels + Strings (DE+EN)** — alle 6 + 3 Keys.
18. **Manueller Test gemaess Ticket-Checkliste** (14 Schritte).
19. **CHANGELOG-Eintrag.**

---

## Vorbereitung

Keine manuellen Schritte noetig:
- Keine neuen Dependencies (alle benoetigten Libraries sind bereits im Catalog).
- Keine Manifest-Aenderungen.
- Keine neuen Hilt-Module — nur eine `@Provides`-Funktion ergaenzen.

---

## Risiken

| Risiko | Mitigation |
|---|---|
| `Normalizer`-NFD-Folding ist auf bestimmten Geraeten langsam fuer Tausende Strings | Library-Groesse ist klein (<500). Profiling im manuellen Test mit dem Apex-Set. Bei Bedarf normalisierte Strings am Meditation-Modell cachen (`val normalizedSearchableText: String by lazy { ... }`) — Follow-up, nicht in diesem Ticket. |
| `OutlinedTextField`-Fokus-State kollidiert mit `LocalSoftwareKeyboardController.hide()` | `FocusManager.clearFocus()` zusaetzlich aufrufen bevor `hide()` — verhindert Re-Open der Tastatur. |
| Empty-State-`liveRegion` feuert zu oft (z.B. bei jedem Tastendruck nach leerem Treffer) | `liveRegion` nur am Headline-Element, nicht auf dem Container. Compose dedupliziert identische Ansagen automatisch. Bei Bedarf `mergeDescendants = true` + State-Schluessel "no-results-{q}". |
| Tab-Wechsel-Reset feuert beim ersten Launch | `LaunchedEffect(currentRoute)` feuert beim initialen Wert nicht als "Wechsel", da kein Vor-Wert vorhanden ist. Test: `MainActivityTest` bestaetigt Idle-State beim ersten Tab-Anzeigen. |
| `kotlinx.serialization` Deserialize-Fehler bei korruptem Storage | `runCatching { Json.decodeFromString<List<String>>(...) }.getOrDefault(emptyList())`. Test mit Garbage-Payload. |
| `MeditationListItem` `query`-Parameter laesst Aufrufer aus normaler Liste vergessen | Default `query: String? = null` — Standard-Pfad bleibt unveraendert. Nur die neue `SearchResultsList` reicht einen Wert ungleich `null` durch. |
| Detekt `LongMethod` in `GuidedMeditationsListScreenContent` (bereits `@Suppress`ed) | Body-Switch in eigene private Composable `LibrarySearchContent(uiState, ...)` extrahieren. |
| Doppelte Aufnahme in Historie bei IME-Done + Tap auf Treffer kurz hintereinander | `commitCurrentQueryToHistory` ist idempotent (Normalize + Dedup), kein Doppel-Eintrag moeglich. |

---

## Offene Fragen

- [ ] Sollen Treffer aus der Historie beim Tap die Reihenfolge der Historie aendern (nach oben
  springen) oder erst beim erneuten Submit/Treffer-Tap? **Vorschlag:** unveraendert bis Submit
  oder Treffer-Tap (sonst springt der Eintrag unter dem Finger weg). Konsistent zu iOS-Plan.
- [ ] Sollen Historien-Eintraege im Edit-Modus geloescht werden koennen (z.B. Long-Press auf
  Eintrag)? **Vorschlag:** Nein — "Leeren" reicht. Konsistent zu iOS, nicht im Ticket
  gefordert.
- [ ] Soll die Suchhistorie beim Loeschen der Library (kuenftiges Feature) ebenfalls geloescht
  werden? **Vorschlag:** Ja — eigener Cleanup-Step im Migrations/Wipe-Handler. Aber das ist
  nicht Teil dieses Tickets — Follow-up wenn Library-Wipe kommt.
- [ ] IME-Action: `Search` (Lupe) oder `Done` (Haken) auf der Tastatur? **Vorschlag:**
  `ImeAction.Search`, da semantisch klar.

---

## Referenzen

- iOS-Pendant: [ios-041](../ios/ios-041-library-search.md) — DONE
- iOS-Plan: [ios-041 Plan](ios-041.md)
- iOS-Implementation:
  - `ios/StillMoment/Domain/Services/LibrarySearchEngine.swift` (1:1 Port)
  - `ios/StillMoment/Domain/Services/SearchHistoryStore.swift` (Protokoll + `SearchHistory.prepend`)
  - `ios/StillMoment/Domain/Services/LibrarySearchState.swift`
  - `ios/StillMoment/Infrastructure/Services/UserDefaultsSearchHistoryStore.swift`
  - `ios/StillMoment/Application/ViewModels/GuidedMeditationsListViewModel.swift` (Search-Bereich)
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/HighlightedText.swift`
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/SearchResultsListView.swift`
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/SearchHistoryListView.swift`
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/LibrarySearchContentView.swift`
- Design-Handoff: `handoffs/library_search/README.md`
- Aktuelle Android-Library:
  - `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationsListScreen.kt`
  - `android/app/src/main/kotlin/com/stillmoment/presentation/viewmodel/GuidedMeditationsListViewModel.kt`
  - `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/MeditationListItem.kt`
- DataStore-Singleton-Falle: MEMORY-Eintrag `feedback_android_datastore_singleton.md`
- Theme-Tokens shared-094: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/theme/{Color,Theme}.kt`
- Out-of-Scope (Folge-Tickets):
  - shared-102: Header-Bar mit immer sichtbarem Suchfeld
  - shared-098: Library-Preview-Scrub-Slider
