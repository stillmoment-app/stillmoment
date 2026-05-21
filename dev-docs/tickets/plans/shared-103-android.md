# Implementierungsplan: shared-103 (Android)

Ticket: [shared-103 — Share-Import-Verbesserungen (Android-Sync)](../shared/shared-103-share-import-verbesserungen-android.md)
Erstellt: 2026-05-21
Branch: `feature/shared-103-android`

iOS-Pendants (alle DONE):
- [ios-042](../ios/ios-042-share-import-immer-meditation.md) — Share-Import immer als Meditation
- [ios-043](../ios/ios-043-import-prefill-service.md) — Prefill-Service (Sanitize + Kaskaden)
- [ios-044](../ios/ios-044-import-prefill-edit-sheet-ui.md) — Edit-Sheet Prefill-UI

iOS-Plaene zur Referenz:
- [ios-043.md](ios-043.md)
- [ios-044.md](ios-044.md)

---

## Kernidee

shared-103 buendelt drei aufeinander aufbauende Schritte zu einem Android-Ticket. Reihenfolge ist nicht beliebig: **Teil 1 → 2 → 3**, weil

1. Ohne den entfernten Typ-Auswahl-Sheet (Teil 1) bleibt der alte direkte-Persistenz-Pfad im NavGraph stehen und blockiert den Pending-Import-Lifecycle in Teil 2.
2. Ohne `ImportPrefill` (Teil 2) hat der Edit-Sheet im Import-Modus in Teil 3 keine sinnvollen Default-Werte.
3. Der Domain-Cleanup (`customTeacher`/`customName` raus) gehoert in Teil 3, weil er die Edit-Sheet-Save-Semantik vereinfacht — derselbe Override-Bug aus iOS-043 (Save liefert Prefill statt User-Wert via `customTeacher`) existiert auf Android im selben Konstrukt (`EditSheetState.applyChanges()` setzt `customTeacher`).

Die Prefill-Pipeline (Sanitize, Filename-Preprocessing, Garbage-Detection, Teacher-/Title-Kaskade) wird **1:1 aus iOS portiert**, idiomatisch in Kotlin:
- `Regex` statt `NSRegularExpression`
- `Char.isUpperCase()`/`isDigit()` statt `Character.isUppercase`
- `Set<String>` Blacklist als `companion object`-Konstante
- `data class ImportPrefill(val teacher: String?, val name: String?)`

Edit-Sheet bleibt **eine** Composable in zwei Modi (Import / Edit). Modus-Parameter steuert Autofocus, Save-Button-Text und Persistenz-Closure beim Caller. Persistenz-Lifecycle: **Pending-Import-State im ViewModel**, Datei-Kopie + DataStore-Eintrag erst nach Save.

---

## Annahmen

- **Persistenz**: `GuidedMeditation` ist `@Serializable`-`data class`, persistiert via `kotlinx.serialization.Json` als Liste in `GuidedMeditationDataStore`. `Json { ignoreUnknownKeys = true }` ist bereits gesetzt — fehlende Felder beim Decoden sind also kein Problem, alte Felder beim Re-Encode landen aber nicht mehr im JSON. Migration: einmaliger Sweep beim Load, `customTeacher` → `teacher`, dann Liste mit neuem Schema zurueckschreiben.
- **Soundscape-Import via Settings** laeuft komplett ueber `CustomAudioRepository.importFile(...)` (siehe `NavGraph.kt:handleCustomAudioImport`). Dieser Pfad ist **unabhaengig** von `FileOpenHandler.handleFileOpen` (der den Meditation-Pfad bedient) — Entfernen der Typ-Auswahl im Share-Pfad beruehrt ihn nicht.
- **MediaMetadataRetriever** liefert `METADATA_KEY_ARTIST` und `METADATA_KEY_TITLE`. Das ist die Android-Entsprechung zu `AVAsset.metadata` mit ID3-Tags. Bleibt in der Infrastructure-Schicht (`GuidedMeditationRepositoryImpl.extractMetadata`).
- **`AudioMetadata` als Domain-Wert**: iOS hat einen expliziten `AudioMetadata`-Typ. Android hat heute `MediaMetadata` (private im Repository). Wir ziehen ihn in die Domain (`com.stillmoment.domain.models.AudioMetadata`), damit `ImportPrefill.compute(metadata, fileName, knownTeachers)` einen Domain-Typ als Input hat.
- **Security-Scope-Aequivalent**: Android hat kein `startAccessingSecurityScopedResource`. Stattdessen wird per `ContentResolver.takePersistableUriPermission(...)` gearbeitet — wird im aktuellen Code nicht persistent gehalten, weil die Datei sofort in den App-Container kopiert wird. Im neuen Pending-Flow: **Die Datei wird erst bei Save kopiert**. Bis dahin muss der `Uri` (z. B. `content://...`) zumindest waehrend der Sheet-Lebensdauer abrufbar bleiben. Die `Intent.FLAG_GRANT_READ_URI_PERMISSION`-Permission gilt fuer die Lebenszeit der Activity — solange die App im Vordergrund bleibt (Edit-Sheet offen), funktioniert das. Falls die App in den Hintergrund geht und der OS-Prozess stirbt, ist der Pending-Import verloren — akzeptabel, weil der User die Datei einfach neu shared.
- **Compose-`mode`-Parameter**: pragmatisch — `enum class EditSheetMode { IMPORT, EDIT }` als Composable-Parameter. Default-Wert `EDIT` fuer Backward-Compatibility.
- **`@SerialName`-Annotation** nicht noetig, weil die alten Feldnamen (`customTeacher`, `customName`) bei der Migration aus dem persistierten JSON gelesen werden ueber den **Tolerant-Decode**-Trick: alte JSON-Strings haben die Felder, neue nicht. Beim Decode laeuft die Migration vorgezogen ueber einen separaten Schritt im Repository (`migrateLegacyOverrides`), der das JSON parsed, Custom-Felder faltet und neu schreibt — **bevor** die normale Deserialisierung auf das neue Schema trifft.

---

## Betroffene Codestellen (Schaetzung: ~18 Dateien)

### Teil 1: Share-Import immer als Meditation

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `presentation/ui/common/ImportTypeSelectionSheet.kt` | Presentation | **Loeschen** | Vollstaendig entfernt; nicht mehr referenziert. |
| `presentation/navigation/NavGraph.kt` | Presentation | Aendern | `ImportTypeSheetEffect`, `handleImportTypeSelection`, `handleGuidedMeditationImport` zusammenfaltbar zu einem direkten `FileOpenEffect` → `viewModel.beginImport(uri)`. `showImportTypeSheet`, `pendingImportUri` States entfernen. Soundscape-Pfad ueber Settings bleibt — `handleCustomAudioImport` bleibt unveraendert, wird aber nicht mehr von Share-Pfad aufgerufen. |
| `domain/models/ImportAudioType.kt` | Domain | **Loeschen** | War nur fuer die Typ-Auswahl. Nach Entfernen aller Aufrufer obsolet. |
| `res/values/strings.xml` + `res/values-de/strings.xml` | Resources | Aendern | `import_type_title`, `import_type_guided`, `import_type_guided_description`, `import_type_soundscape`, `import_type_soundscape_description` entfernen (5 Keys × 2 Sprachen). |
| Tests: NavGraph-Verzweigung | Tests | Aendern | `handleImportTypeSelection`-Tests entfernen oder auf den neuen direkten Pfad ziehen. |

### Teil 2: Prefill-Service (Domain-rein)

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `domain/models/AudioMetadata.kt` | Domain | **Neu** | `data class AudioMetadata(val duration: Long, val artist: String?, val title: String?)`. Reines Kotlin. Ersetzt das private `MediaMetadata` im Repository. |
| `domain/models/ImportPrefill.kt` | Domain | **Neu** | `data class ImportPrefill(val teacher: String?, val name: String?)` + `companion object` mit: `sanitize`, `preprocessFilename`, `isGarbageFilename`, `compute(metadata, fileName, knownTeachers)`. Kein Android-Framework-Import. 1:1-Port der iOS-Implementierung. |
| `domain/services/AudioMetadataService.kt` | Domain | **Neu** (Interface) | `interface AudioMetadataService { suspend fun extract(uri: Uri): AudioMetadata }`. `Uri` ist Android-Framework — Trade-off: entweder Service-Interface mit `String` (Uri-toString) im Domain, oder `Uri` im Interface aber realer Wert in Domain bleibt frei. Wir nehmen **`String`** (URI-String) — dann ist das Domain-Interface plattformneutral. Infrastructure-Impl wandelt `String → Uri`. |
| `infrastructure/services/AndroidAudioMetadataService.kt` | Infrastructure | **Neu** | Implementierung mit `MediaMetadataRetriever`. Liefert `AudioMetadata`. Wird via Hilt provided. |
| `data/repositories/GuidedMeditationRepositoryImpl.kt` | Data | Refactor | `extractMetadata` Methode → an `AudioMetadataService` ausgelagert. `importMeditation(uri)` wird zu `addMeditation(uri, metadata, teacher, name)`. Default `DEFAULT_TEACHER = "Unknown"` faellt weg. `metadata.title ?: fileNameWithoutExtension(...)` Default faellt weg — Caller gibt explizit `name` durch. **Migration**: neue Methode `migrateLegacyOverridesIfNeeded()` (one-shot bei erstem Repository-Init), liest rohes JSON via `meditationsDataStore.data.first()`, parsed gegen `LegacyGuidedMeditation`-Helper (mit `customTeacher`/`customName`), faltet die Custom-Felder, schreibt neues JSON. Flag in `SettingsDataStore` (`guidedMeditationsOverrideMigratedV1`). |
| `domain/repositories/GuidedMeditationRepository.kt` | Domain | Aendern | `importMeditation(uri)` → `addMeditation(uri, metadata, teacher, name)`. |
| `data/FileOpenHandler.kt` | Data | Aendern | `handleFileOpen(uri)` → `validateAndPrepareImport(uri)`: liefert `Result<PendingImport>` mit `(uri, metadata, fileName)`. Persistiert **nicht** mehr selbst — kein `repository.importMeditation`-Aufruf hier. Duplicate-Check bleibt vor dem Pending-Setup. |
| `domain/models/PendingImport.kt` | Domain | **Neu** | `data class PendingImport(val uri: String, val fileName: String, val metadata: AudioMetadata, val prefill: ImportPrefill)`. Im ViewModel-State. |
| `presentation/viewmodel/GuidedMeditationsListViewModel.kt` | Application | Aendern | `importMeditation(uri)` Logik: 1) `fileOpenHandler.validateAndPrepareImport(uri)` 2) `ImportPrefill.compute(metadata, fileName, knownTeachers)` 3) `PendingImport` setzen, Edit-Sheet im Import-Modus oeffnen. Neue Methoden: `saveImportedMeditation(teacher, name)` → ruft `repository.addMeditation(uri, metadata, teacher, name)`; `cancelImport()` → resetet State; `knownTeachers` aus `groups.map { it.teacher }.distinct()`. Override-Methoden `updateCustomTeacher`/`updateCustomName` werden geloescht (Override-Mechanismus weg). |
| Tests: `ImportPrefillTest.kt` | Tests | **Neu** | Pro Akzeptanzkriterium ein Test (Sanitize, Preprocess, Garbage, Teacher-Kaskade, Title-Kaskade). JUnit 5 mit `@Nested`. ~25-30 Tests. |
| Tests: `GuidedMeditationRepositoryImplTest.kt` | Tests | Aendern | `addMeditation`-Signatur nachziehen. Migration-Test ergaenzen (Eintrag mit `customTeacher="X"` im DataStore → nach Init `teacher="X"`, kein Override mehr). |
| Tests: `GuidedMeditationsListViewModelTest.kt` | Tests | Aendern | Tests fuer `importMeditation`-Pfad: Pending-State, Cancel, Save. Bestehende Tests fuer `updateCustomTeacher`/`updateCustomName` loeschen (Methoden weg). |
| Tests: `FileOpenHandlerTest.kt` | Tests | Aendern | `handleFileOpen` → `validateAndPrepareImport`. Persistenz-Assertion entfernt (passiert erst bei Save). |

### Teil 3: Edit-Sheet-UI mit Pflichtfeldern + Modes

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `domain/models/GuidedMeditation.kt` | Domain | Aendern | `customTeacher`/`customName` Properties entfernen. `effectiveTeacher`/`effectiveName` computed properties entfernen. `withCustomTeacher`/`withCustomName` Builder entfernen. `teacher`/`name` sind die einzige Wahrheit. |
| `domain/models/EditSheetState.kt` | Domain | Vereinfachen | `applyChanges()` setzt `teacher`/`name` direkt via `copy()`. `fromMeditation` nutzt `meditation.teacher`/`.name` direkt. `hasChanges`-Semantik unveraendert. |
| `domain/models/GuidedMeditationGroup.kt` | Domain | Aendern | `groupByTeacher`: `effectiveTeacher` → `teacher`, `effectiveName` → `name`. |
| `domain/services/LibrarySearchEngine.kt` | Domain | Aendern | Z35 Doc-Kommentar + Z95-96: `effectiveName`/`effectiveTeacher` → `name`/`teacher`. |
| `infrastructure/audio/MeditationNotificationManager.kt` | Infrastructure | Aendern | Z103-104: `effective*` → `teacher`/`name`. |
| `infrastructure/audio/MediaSessionManager.kt` | Infrastructure | Aendern | Z99-100: `effective*` → `teacher`/`name`. |
| `presentation/ui/meditations/MeditationListItem.kt` | Presentation | Aendern | Z79, Z153, Z161, Z172, Z180: `effective*` → `teacher`/`name`. |
| `presentation/ui/meditations/GuidedMeditationPlayerScreen.kt` | Presentation | Aendern | Z311-330: `effective*` → `teacher`/`name`. |
| `presentation/ui/meditations/GuidedMeditationsListScreen.kt` | Presentation | Aendern | Z222: `effective*` → `name`. Sheet-Aufruf bekommt `mode` und neue Closures. |
| `presentation/ui/meditations/MeditationEditSheet.kt` | Presentation | **Refactor** | Neuer `mode: EditSheetMode`-Parameter (Default `EDIT`). Autofocus-Regel: `mode == IMPORT && initialName.isBlank()` → Name-Feld autofocus via `FocusRequester`+`LaunchedEffect`. Toolbar-Vereinfachung: kein Sheet-Titel, Cancel als X-IconButton, Save als prominentes Pill. Name-Feld via `OutlinedTextField` mit `singleLine = false, maxLines = 3`. File-Info als kompakter zweizeiliger Footer mit Doc-Icon. Save-Button-Text: `import_action` (Import-Modus) / `common_save` (Edit-Modus). Pflichtfeld-Validation bleibt (`isValid`). |
| `presentation/ui/components/ClearableTextField.kt` | Presentation | **Neu** | `OutlinedTextField`-Wrapper + X-Icon-`TrailingIcon` mit Sichtbarkeitsregel "focused AND text not empty". X-Tap setzt Text leer. `accessibilityLabel` "Feld leeren" (lokalisiert). Style: 20dp Kreis, `theme.textSecondary` Tint. |
| `presentation/ui/components/AutocompleteTextField.kt` | Presentation | Erweitern | Nutzt intern `ClearableTextField` statt `OutlinedTextField`. `SuggestionItem` rendert via `HighlightedText` (Akzent-Highlight des Match-Substrings, ohne Background-Tint). `SuggestionsList`: Card mit Shadow → transparent + `HorizontalDivider` zwischen Eintraegen + duenne Divider ueber dem ersten Eintrag (Plain-Look). Dropdown bleibt bei leerem Feld zu (entspricht bereits `filterSuggestions`-Verhalten). |
| `domain/models/EditSheetMode.kt` | Domain | **Neu** | `enum class EditSheetMode { IMPORT, EDIT }`. |
| `presentation/viewmodel/GuidedMeditationsListViewModel.kt` | Application | Aendern | Methoden `updateCustomTeacher`/`updateCustomName` entfernen (existieren nicht mehr). `availableTeachers` schon vorhanden (`groups.map { it.teacher }.distinct()`). Aufruf-Pfad fuer Edit-Sheet: `mode` aus `uiState.pendingImport != null ? IMPORT : EDIT` ableiten. |
| `res/values/strings.xml` + `res/values-de/strings.xml` | Resources | Aendern | Neue Keys: `guided_meditations_import_action` ("Importieren"/"Import"), `accessibility_clear_field` ("Feld leeren"/"Clear field"), `guided_meditations_edit_teacher_placeholder` ("Wer leitet die Meditation an?"/"Who is leading this meditation?"), `guided_meditations_edit_name_placeholder` ("Wie heisst diese Meditation?"/"What is this meditation called?"). |
| Tests: `EditSheetStateTest.kt` | Tests | Aendern | `applyChanges()` produziert jetzt `teacher`/`name` direkt — Tests vereinfachen. Override-Spezifika entfernen. |
| Tests: `GuidedMeditationTest.kt` | Tests | Aendern | `effective*`/`customTeacher`/`customName`/`withCustomTeacher`/`withCustomName` Tests entfernen. |
| `CHANGELOG.md` | Docs | Aendern | Eintrag fuer Android: keine Typ-Auswahl mehr, bessere Vorschlaege, X-Button, Pflichtfelder, Match-Highlight, schlankere Toolbar. |

**Geschaetzte Datei-Anzahl gesamt**: 18 Dateien beruehrt + 6 Neue + 2 Geloescht ≈ **26 betroffene Dateien**.

---

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `MediaMetadataRetriever` | API 10+ | Android Docs | Bereits in Code. `METADATA_KEY_ARTIST` und `METADATA_KEY_TITLE` aequivalent zu ID3 `TPE1`/`TIT2`. |
| `FocusRequester` + `Modifier.focusRequester` | Compose 1.0+ | Compose Docs | Standard fuer Autofocus. `LaunchedEffect(Unit) { focusRequester.requestFocus() }`. |
| `kotlinx.serialization.Json` mit `ignoreUnknownKeys = true` | bereits konfiguriert | Bestand | Erlaubt das Lesen alter JSONs mit Custom-Feldern, ohne Decode-Fehler. |
| `OutlinedTextField` mit `singleLine = false, maxLines = 3` | Compose 1.4+ | Compose Docs | Vertikales Wachsen mit Limit. |
| `Regex` (Kotlin stdlib) | seit Anfang | Kotlin Docs | UUID-Pattern: `Regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", RegexOption.IGNORE_CASE)`. Track-Prefix: `Regex("^\\d{1,3}[-_.\\s]+")`. |

Keine externen Bibliotheken noetig.

---

## Design-Entscheidungen

### 1. Sanitize-/Preprocessing-Pipeline 1:1 aus iOS portieren

**Trade-off:** Eigene Heuristiken neu erfinden waere riskant — Inkonsistenz zur iOS-Logik. Identischer Output pro Filename auf beiden Plattformen ist erwuenscht (gleiche User-Erwartung, gleiche Library-Konsistenz nach Cross-Plattform-Switch).
**Entscheidung:** Wort-fuer-Wort-Port der iOS-Implementierung. Blacklist identisch, Regex-Pattern identisch, CamelCase/Akronym/Zahl-Boundary-Regeln identisch. Sprache: Kotlin-idiomatisch (Regex statt NSRegularExpression, `Char.isUpperCase()` statt `Character.isUppercase`, `data class` statt `struct`). **Genau dieselben Tests** wie iOS-043 — beide Akzeptanzkriterien-Listen sind kongruent. Plan-Stelle "Filename-Preprocessing-Tests" → Port der iOS-Tests aus `ImportPrefillTests.swift`.

### 2. Persistenz-Lifecycle: Pending-Import-State im ViewModel

**Trade-off:** Heutiger Pfad ist simpel ("import = copy + persist"). Neuer Pfad braucht einen State (`pendingImport`) und Branching im Save-Closure. Mehr Komplexitaet im ViewModel.
**Entscheidung:** Pending-Import-State ist die saubere Loesung. Alternative "Dummy-Eintrag persistieren, dann editieren oder loeschen" haette das Risiko von Datei-Leichen bei App-Crash. Pending-State im ViewModel ist process-local — Crash = State weg = sauber. Datei wird erst bei Save in den App-Container kopiert (genau wie iOS).

### 3. `kotlinx.serialization`-Migration via Pre-Decode-Sweep

**Trade-off:** `@Serializable`-`data class` mit `customTeacher`-Feld behalten + `init {}` mit Falten-Logik waere einfacher. Aber: Liest man ohne Custom-Felder im Schema das alte JSON, fallen die Felder einfach weg (`ignoreUnknownKeys = true`) — die alte User-Anpassung waere verloren.
**Entscheidung:** Vor der ersten regulaeren Deserialisierung laeuft `migrateLegacyOverridesIfNeeded()`: liest rohes JSON, parsed gegen ein **transientes** `LegacyGuidedMeditation`-Schema (mit `customTeacher`/`customName`), faltet die Felder in `teacher`/`name`, schreibt neues JSON. Flag in `SettingsDataStore` (boolean `guided_meditations_override_migrated_v1`). Beim zweiten App-Start macht die Migration nichts. Idempotent.

### 4. `mode`-Parameter als Enum statt Boolean

**Trade-off:** `isImportMode: Boolean` ist kompakter. Aber `EditSheetMode` ist erweiterbar (z. B. spaeter ein `DUPLICATE_RENAME`-Modus) und liest sich am Call-Site klarer.
**Entscheidung:** `enum class EditSheetMode { IMPORT, EDIT }`. Default `EDIT` fuer alle bestehenden Call-Sites — Backward-Compatibility, kein Risiko.

### 5. `Uri`-String im Domain-Layer

**Trade-off:** Echte `android.net.Uri` in Domain-Modell waere Android-Framework-Coupling im Domain. Aber: Repository und ViewModel arbeiten heute schon mit `String` (`fileUri: String` in `GuidedMeditation`). Konsistent.
**Entscheidung:** `PendingImport.uri: String` (URI-String). Service-Interfaces (`AudioMetadataService.extract`) nehmen `String`, Infrastructure-Impl wandelt zu `Uri.parse(...)`. Domain bleibt Android-frei.

### 6. ID3-Extraktion in eigenes Domain-Service-Interface ziehen

**Trade-off:** Heute extrahiert das Repository selbst die Metadaten (`extractMetadata`-Methode). Ein extra Service waere Overengineering, wenn der Code nur an einer Stelle laeuft.
**Entscheidung:** `AudioMetadataService` als Domain-Interface, Infrastructure-Impl mit `MediaMetadataRetriever`. Vorteile: testbar isoliert (Mock-Service in ViewModel-Tests), das Repository-Interface bleibt simpler, und der Service ist die Android-Spiegelung von `AudioMetadataService` auf iOS — strukturelle Parallelitaet zwischen den Plattformen.

### 7. Autocomplete-Dropdown: Card-Shadow weg, Plain-Look

**Trade-off:** Aenderung an einer bestehenden Komponente, die ggf. an anderen Stellen genutzt wird.
**Entscheidung:** `AutocompleteTextField` wird heute nur im Edit-Sheet genutzt (Grep-Verifikation). Aenderung ist isoliert — kein Side-Effect-Risiko.

### 8. Beim Cancel im Import-Modus passiert nichts mit der Quelle

**Trade-off:** Wir koennten beim Cancel proaktiv den temporaeren Pre-Import-`Uri` "freigeben" (z. B. `revokeUriPermission`).
**Entscheidung:** Auf Android nicht noetig — der Share-`Uri` lebt mit der Activity-Permission. Cancel = `pendingImport = null` + Sheet zu. Beim nächsten Share-Versuch passiert der Read-Permission-Grant neu. Identisches Verhalten wie iOS-`startAccessingSecurityScopedResource`-Aequivalent ist NICHT noetig.

---

## Refactorings

1. **`MediaMetadata` (private im Repository) → `AudioMetadata` (Domain).** Verschiebung des Typs in den Domain-Layer. Eine Code-Stelle (Repository) bleibt Konsumentin, eine neue (ViewModel) kommt dazu. Risiko: niedrig.

2. **`GuidedMeditationRepository.importMeditation(uri)` → `addMeditation(uri, metadata, teacher, name)`.** Signatur-Aenderung. Alle Aufrufstellen (heute: ViewModel, NavGraph indirekt) muessen mitziehen. Risiko: niedrig (Compiler-gefangen).

3. **`FileOpenHandler.handleFileOpen` → `validateAndPrepareImport`.** Persistenz-Aufruf raus, Pending-Daten zurueckgeben. Aufrufer im NavGraph muss umgebaut werden. Risiko: niedrig.

4. **Override-Mechanismus aus `GuidedMeditation` entfernen.** ~15 Aufrufstellen (siehe Codestellen-Tabelle). Compiler hilft — `effectiveTeacher` weg = Compile-Fehler an jedem Aufrufer. Kein silent fail. Risiko: niedrig.

5. **`AutocompleteTextField` intern auf `ClearableTextField` + `HighlightedText` umstellen.** Oeffentliche API unveraendert (`(value, onValueChange, suggestions, ...)`). Pruefen ob Caller `OutlinedTextField`-Style erwarten — er bleibt strukturell gleich, nur mit X-Overlay und Highlight im Dropdown. Risiko: niedrig.

6. **`ImportTypeSelectionSheet` + `ImportAudioType` loeschen.** Vor dem Loeschen Grep nach Imports — sollte nur in `NavGraph.kt` referenziert werden. Risiko: niedrig.

---

## Fachliche Szenarien

### Sanitize (1:1 aus iOS-043)

- Gegeben: `null`. Wenn: `sanitize(null)`. Dann: `null`.
- Gegeben: `"   "`. Wenn: `sanitize`. Dann: `null`.
- Gegeben: Blacklist-Treffer (`"Unknown Artist"`, `"unknown_artist"`, `"unknown-artist"`, `"UNKNOWN ARTIST"`, `"Unknown   Artist"`). Wenn: `sanitize`. Dann: `null`.
- Gegeben: weitere Blacklist-Worte (`"Untitled"`, `"audio"`, `"recording"`, `"voice memo"`, `"voice_memo"`). Wenn: `sanitize`. Dann: `null`.
- Gegeben: reine Track-Nummerierung (`"Track 01"`, `"01"`, `"1"`, `"track 03"`, `"track03"`). Wenn: `sanitize`. Dann: `null`.
- Gegeben: sauberer Wert `"Tara Brach"`. Wenn: `sanitize`. Dann: `"Tara Brach"`.
- Gegeben: `"  Body Scan  "`. Wenn: `sanitize`. Dann: `"Body Scan"` (Trim, Inhalt unveraendert).

### Filename-Preprocessing (1:1 aus iOS-043 + Filename-Boundaries aus iOS-044)

- Gegeben: `"01-body-scan.mp3"`. Wenn: `preprocessFilename`. Dann: `"body scan"`.
- Gegeben: `"Bodyscan.mp3"`. Wenn: `preprocessFilename`. Dann: `"Bodyscan"`.
- Gegeben: `"meditation-im-sitzen.mp3"`. Wenn: `preprocessFilename`. Dann: `"meditation im sitzen"`.
- Gegeben: `"Anleitung-Bodyscan-Deutsch-MBSR.mp3"`. Wenn: `preprocessFilename`. Dann: `"Anleitung Bodyscan Deutsch MBSR"`.
- Gegeben: `"MomentMal.mp3"`. Wenn: `preprocessFilename`. Dann: `"Moment Mal"` (CamelCase).
- Gegeben: `"MBSRBodyscan.mp3"`. Wenn: `preprocessFilename`. Dann: `"MBSR Bodyscan"` (Akronym-Ende).
- Gegeben: `"04Fuesse.mp3"`. Wenn: `preprocessFilename`. Dann: `"04 Fuesse"` (Zahl/Wort).
- Gegeben: `"Moment-mal-04Fuesse.mp3"`. Wenn: `preprocessFilename`. Dann: `"Moment mal 04 Fuesse"`.

### Garbage-Detection

- Gegeben: `"d067c0ea-2c04-b934-1e04-94b2dc2f13dd"`. Wenn: `isGarbageFilename`. Dann: `true` (UUID).
- Gegeben: `"thisistheverylongunbrokenfilename"` (>= 24 Zeichen, ohne Trenner). Wenn: `isGarbageFilename`. Dann: `true`.
- Gegeben: leerer String. Wenn: `isGarbageFilename`. Dann: `true`.
- Gegeben: `"bodyscan"` (kurz, kein UUID). Wenn: `isGarbageFilename`. Dann: `false`.

### Teacher-Kaskade (1:1 aus iOS)

- Gegeben: `metadata.artist = "Tara Brach"`. Wenn: `compute`. Dann: `teacher = "Tara Brach"`.
- Gegeben: `metadata.artist = "Unknown Artist"`, `knownTeachers = []`. Wenn: `compute`. Dann: `teacher = null`.
- Gegeben: `metadata.artist = null`, Filename `"bodyscan-tara_brach.mp3"`, `knownTeachers = ["Tara Brach"]`. Wenn: `compute`. Dann: `teacher = "Tara Brach"`.
- Gegeben: `knownTeachers` enthaelt `"Unknown Artist"`. Wenn: Filename match-Versuch. Dann: nicht gematched (sanitize filtert).
- Gegeben: `knownTeachers = ["Tara", "Tara Brach"]`, Filename enthaelt `"tara brach"`. Wenn: `compute`. Dann: `teacher = "Tara Brach"` (laengster Match).
- Gegeben: `knownTeachers = ["Tara"]` (3 Zeichen, 1 Wort). Wenn: Filename `"tara-bodyscan.mp3"`. Dann: `teacher = null` (Mindestlaenge nicht erreicht).
- Gegeben: `knownTeachers = []`. Wenn: `compute`. Dann: Stufe 2 inaktiv, `teacher = null`.

### Title-Kaskade

- Gegeben: `metadata.title = "Body Scan"`. Wenn: `compute`. Dann: `name = "Body Scan"`.
- Gegeben: `metadata.title = "Untitled"`, Filename `"Anleitung-Bodyscan-Deutsch-MBSR.mp3"`. Wenn: `compute`. Dann: `name = "Anleitung Bodyscan Deutsch MBSR"`.
- Gegeben: `metadata.title = null`, Filename `"meditation-im-sitzen.mp3"`. Wenn: `compute`. Dann: `name = "meditation im sitzen"` (verbatim).
- Gegeben: `metadata.title = null`, Filename `"bodyscan-tara_brach.mp3"`, Teacher matched Stufe 2. Wenn: `compute`. Dann: `name = "bodyscan"`.
- Gegeben: `metadata.artist = "Tara Brach"`, `metadata.title = null`, Filename `"bodyscan-tara_brach.mp3"`. Wenn: `compute`. Dann: `name = "bodyscan"` (Teacher aus ID3, trotzdem aus Filename entfernt).
- Gegeben: `metadata.artist = "Tara Brach"`, `metadata.title = null`, Filename `"morning-meditation.mp3"`. Wenn: `compute`. Dann: `name = "morning meditation"`.
- Gegeben: Filename UUID, kein ID3. Wenn: `compute`. Dann: `name = null` (Garbage).
- Gegeben: Filename `"audio.mp3"`. Wenn: `compute`. Dann: `name = null` (Sanitize).
- Gegeben: Filename `"01-body-scan.mp3"`. Wenn: `compute`. Dann: `name = "body scan"`.

### Migration (Override-Cleanup)

- Gegeben: DataStore mit JSON-Liste, ein Eintrag `{"teacher":"Tara Brach","customTeacher":"Jon Kabat-Zinn",...}`. Wenn: App-Start, Migration laeuft. Dann: DataStore enthaelt `{"teacher":"Jon Kabat-Zinn",...}` (customTeacher gefaltet, Feld weg). Flag `override_migrated_v1 = true`.
- Gegeben: Eintrag `{"teacher":"Unknown Artist","customTeacher":null,...}`. Wenn: Migration. Dann: Eintrag bleibt `teacher="Unknown Artist"` (Wert nicht migriert, nur Mechanismus).
- Gegeben: Flag bereits gesetzt. Wenn: zweiter App-Start. Dann: Migration uebersprungen. Idempotent.

### Share-Import-Flow (Teil 1)

- Gegeben: User shared MP3, kein Duplikat, gueltiges Format. Wenn: `FileOpenEffect` triggert. Dann: `viewModel.importMeditation(uri)` direkt — kein Auswahl-Sheet. Library-Tab vorne. Edit-Sheet im Import-Modus auf.
- Gegeben: User shared PDF. Wenn: `validateFileFormat`. Dann: Snackbar "nicht unterstuetztes Format". Kein Sheet.
- Gegeben: User shared bereits importierte MP3. Wenn: Duplicate-Check. Dann: Snackbar "bereits importiert". Kein Sheet.

### Edit-Sheet Import-Modus (Teil 3)

- Gegeben: `prefill.teacher = "Tara Brach"`, `prefill.name = "bodyscan"`. Wenn: Sheet oeffnet. Dann: Felder gefuellt, kein Autofocus, Save enabled.
- Gegeben: `prefill.teacher = null`, `prefill.name = null` (Garbage). Wenn: Sheet oeffnet. Dann: Felder leer, Name-Feld autofocus, Save disabled.
- Gegeben: gefuelltes Lehrer-Feld, User tippt X. Wenn: Tap. Dann: Feld leer, Save disabled, Dropdown bleibt zu.
- Gegeben: leeres Lehrer-Feld, User tippt "T". Wenn: Tippen. Dann: Dropdown oeffnet mit "Tara Brach", "T" akzent-hervorgehoben.
- Gegeben: Sheet offen, User tippt Cancel. Wenn: Tap. Dann: `cancelImport()`, Library unveraendert, keine Datei kopiert.
- Gegeben: Sheet offen, User swipt nach unten. Wenn: Dismiss. Dann: gleicher Effekt wie Cancel.
- Gegeben: Sheet offen, beide Felder gefuellt, User tippt Save. Wenn: Tap. Dann: `addMeditation(uri, metadata, teacher, name)` aufgerufen, Library zeigt neue Meditation.

### Edit-Sheet Edit-Modus (Teil 3)

- Gegeben: bestehende Meditation `teacher = "Unknown Artist"`. Wenn: Edit-Sheet oeffnet. Dann: Wert sichtbar, nicht migriert.
- Gegeben: bestehende Meditation. Wenn: User aendert nichts, tippt Save. Dann: `updateMeditation` mit unveraendertem Eintrag.
- Gegeben: User leert Lehrer-Feld via X. Wenn: Save-Pruefung. Dann: Save disabled.

---

## Reihenfolge der Akzeptanzkriterien (TDD)

Strikt sequenziell ueber drei Teile. Jeder Teil endet mit `make check` + `make test-unit-agent` als Quality Gate.

### Teil 1 — Share-Import immer als Meditation

1. **Test schreiben (RED)**: NavGraph-Verzweigung bei valid file → direkter ViewModel-Pfad (Mock-VM erhaelt `importMeditation(uri)`-Aufruf).
2. **`ImportTypeSheetEffect` ausbauen (GREEN)**: NavGraph triggert direkt `viewModel.importMeditation(uri)` aus `FileOpenEffect`. `showImportTypeSheet`/`pendingImportUri`-States raus.
3. **`ImportTypeSelectionSheet.kt` + `ImportAudioType.kt` loeschen**.
4. **Strings (5 Keys × 2 Sprachen) entfernen**.
5. **Quality Gate**: `make check`, `make test-unit-agent`.

### Teil 2 — Prefill-Service

6. **`AudioMetadata` Domain-Modell anlegen**.
7. **Sanitize-Tests schreiben (RED)** → `ImportPrefill.sanitize` implementieren (GREEN). Reihenfolge der Akzeptanzkriterien wie in iOS-043-Plan.
8. **Preprocessing-Tests (RED)** → `preprocessFilename` (GREEN). Inkl. CamelCase/Akronym/Zahl-Boundaries.
9. **Garbage-Detection-Tests (RED)** → `isGarbageFilename` (GREEN).
10. **Teacher-Kaskade-Tests (RED)** → `computeTeacher` (GREEN).
11. **Title-Kaskade-Tests (RED)** → `computeName` + `compute` (GREEN).
12. **`AudioMetadataService` Domain-Interface + Impl mit `MediaMetadataRetriever`**.
13. **`GuidedMeditationRepository.addMeditation`-Signatur aendern** (Tests-Updates).
14. **`FileOpenHandler.validateAndPrepareImport` Refactor** (Tests-Updates).
15. **`PendingImport` Domain-Modell**.
16. **ViewModel `importMeditation` → Pending-Flow** (Tests-Updates).
17. **Migration**: `migrateLegacyOverridesIfNeeded()` im Repository (RED → GREEN).
18. **Quality Gate**: `make check`, `make test-unit-agent`.

### Teil 3 — Edit-Sheet-UI + Domain-Cleanup

19. **`GuidedMeditation`: Override-Felder entfernen** (Compile-Fehler an Aufrufstellen).
20. **15 Aufrufstellen `effective*` → `teacher`/`name` umstellen** (Group, Search, Notifications, MediaSession, ListItem, Player, ListScreen, ViewModel).
21. **`EditSheetState.applyChanges()` vereinfachen** (Tests-Updates).
22. **Override-Migration-Test (RED) → GREEN** (siehe Teil 2 Schritt 17 — kombinierbar).
23. **`EditSheetMode`-Enum + Sheet-Refactor**: `mode` Parameter, Autofocus-Regel, Save-Button-Text.
24. **`ClearableTextField` (RED → GREEN)**: View-Test fuer Sichtbarkeitsregel.
25. **`AutocompleteTextField` intern auf `ClearableTextField` + `HighlightedText`**.
26. **Plain-Look Dropdown** (Shadow weg, Divider rein).
27. **Save-Button-Pflichtfeld + Pill-Style**.
28. **File-Info-Footer (Doc-Icon, Filename, Duration, 2-zeilig)**.
29. **Toolbar-Vereinfachung**: Cancel als X-IconButton, kein Sheet-Titel.
30. **Name-Feld mit `maxLines = 3`**.
31. **Modal-Swipe-Down → `cancelImport()`** (im Import-Modus).
32. **Manueller Test im Simulator** (15 Szenarien aus dem Ticket).
33. **CHANGELOG.md**.
34. **Quality Gate**: `make check`, `make test-unit-agent`, `make test` (Full-Suite mit Coverage).

---

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| Migration laeuft auf grossen Libraries (Hunderte Eintraege) waehrend App-Init → spuerbarer Delay. | Realistisch maximal ~50 Eintraege (Single-User-Library). Migration laeuft asynchron auf `Dispatchers.IO`, blockiert nicht den Main-Thread. Falls Latenz spuerbar wird, Loading-State im UI ergaenzen — aktuell nicht noetig. |
| `Json { ignoreUnknownKeys = true }` ist bereits aktiv → alte `customTeacher`-Werte koennten beim ersten Decode (vor Migration!) verloren gehen. | Migration laeuft VOR der ersten regulaeren `meditationsFlow`-Emission. Repository-Init lockt den Flow bis Migration durch ist. Alternativ: Migration laeuft synchron beim ersten `meditationsFlow.collect` — vor der ersten Emission an Subscribers. Praezedenzfall: iOS-044 Plan, Schritt "Migration beim Load". |
| `MediaMetadataRetriever` schlaegt bei manchen content://-Uris fehl (`IllegalArgumentException`). | Bestehende Try/Catch-Logik bleibt erhalten — leeres `AudioMetadata(0L, null, null)` als Fallback. Prefill kommt dann ausschliesslich aus Filename. Ist akzeptabel. |
| User schliesst App waehrend Edit-Sheet im Import-Modus offen — `pendingImport`-State weg, Datei nicht kopiert. | Akzeptiert: User muss erneut sharen. Iden­tisches Verhalten wie iOS (`startAccessingSecurityScopedResource` waere mit `defer` freigegeben, App-Restart loescht den State). |
| URI-Permission expired bevor Save tippt (z. B. User wartet 10 Min). | Beim Save schlaegt `ContentResolver.openInputStream(uri)` mit `SecurityException` fehl → Error-Pfad in `addMeditation`, Snackbar "Import fehlgeschlagen". Library bleibt unveraendert. Akzeptabel. |
| `AutocompleteTextField`-API-Aenderung bricht Tests/Caller, die Plain-`OutlinedTextField`-Verhalten erwarten. | Grep zeigt: nur `MeditationEditSheet` ruft das auf. Andere Stellen? `LibrarySearchBar` nutzt eigenen `BasicTextField`. Sicher. |
| Track-Praefix-Regex frisst echte Titel wie "3 Schritte zur Ruhe.mp3" zu "Schritte zur Ruhe". | Wie iOS-043 dokumentiert: bewusst akzeptiert. User kann via Edit-Sheet korrigieren. |
| Detekt `LongMethod`/`MultipleEmitters`-Violations im neuen Edit-Sheet-Composable. | Proaktiv aufsplitten: `EditSheetTeacherField`, `EditSheetNameField`, `EditSheetFileInfoFooter`, `EditSheetToolbar`. |
| `kotlinx.serialization` braucht beim Migration-Pfad einen separaten `LegacyGuidedMeditation`-Typ. | Lokal als `private @Serializable data class` in `GuidedMeditationRepositoryImpl`. Nur fuer den Migration-Schritt. Keine Domain-Verschmutzung. |

---

## Offene Fragen

Keine — alle Entscheidungen durch iOS-Pendants vorgeklaert.

- iOS-042 / iOS-043 / iOS-044 sind DONE und in Code review-tauglich.
- Android-Sync uebernimmt Akzeptanzkriterien 1:1 und Spielregeln (`customTeacher`-Migration ja, `"Unknown Artist"`-Wert-Migration nein).

Falls beim Implementieren Inkonsistenzen zur iOS-Implementierung auffallen (z. B. Regex-Pattern liefert in Java-Regex anderes Resultat als Swift-Regex), pivotieren auf identisches Verhalten — Tests pruefen das.
