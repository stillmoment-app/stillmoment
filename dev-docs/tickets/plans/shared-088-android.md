# Implementierungsplan: shared-088 (Android)

Ticket: [shared-088](../shared/shared-088-einstimmung-feature-entfernen.md)
Erstellt: 2026-05-05
Plattform: Android
Voraussetzung: iOS-Plan ([shared-088-ios.md](shared-088-ios.md)) als Referenz fuer die fachlichen Entscheidungen.

---

## Ziel

Das Einstimmung-Feature (Attunement) wird vollstaendig aus dem Android-Timer entfernt:
Domain-Phase, ViewModel-Logik, Compose-Screens, AudioService, ForegroundService,
Persistenz, gebuendelte Audio-Dateien, Lokalisierung. Bestehende Settings/Imports
werden bei der ersten Migration stillschweigend bereinigt.

Architekturziel-State-Machine nach Entfernung:
```
Idle → Preparation → StartGong → Running → EndGong → Completed
```
(`Attunement` als optionale Phase entfaellt komplett.)

---

## Betroffene Codestellen

### Domain (entfernen oder reduzieren)

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `domain/models/Attunement.kt` | Loeschen | Einziger gebauter Typ (`breath`), Begleit-Helper. |
| `domain/models/ResolvedAttunement.kt` | Loeschen | Built-in + Custom Abstraktion. |
| `domain/services/AttunementResolverProtocol.kt` | Loeschen | Resolver-Protocol. |
| `domain/models/TimerState.kt` | Edit | `data object Attunement` und kompletten ASCII-State-Chart-Kommentar inkl. Tabellen anpassen. |
| `domain/models/TimerAction.kt` | Edit | `AttunementFinished` entfernen. |
| `domain/models/TimerEffect.kt` | Edit | `PlayAttunement`, `StopAttunement`, `StartAttunementPhase`, `EndAttunementPhase` entfernen. `StartTimer.attunementDurationSeconds`-Parameter entfernen. |
| `domain/models/MeditationTimer.kt` | Edit | `attunementDurationSeconds`, `silentPhaseStartRemaining`, `tickAttunement`, `startAttunement`, `endAttunement`, `effectiveStartRemaining` entfernen. `tick()`-when-Branch fuer `Attunement` entfernen. `tickRunningWithEvents` arbeitet immer mit Baseline `totalSeconds`. `create()`-Parameter und `reset()`-Reset-Felder reduzieren. |
| `domain/models/MeditationSettings.kt` | Edit | `attunementId`, `attunementEnabled`, `customAttunementDurationSeconds`, `activeAttunementId`, `hasActiveAttunement`, `effectiveAttunementDurationSeconds`, `minimumDurationMinutes`, `withAttunementEnabled`, `validateDuration`-Overloads mit Attunement-Parametern, `minimumDuration`-Helper entfernen. `validateDuration(_:)` reduziert sich auf `coerceIn(1, 60)`. `MeditationSettingsKeys.ATTUNEMENT_ID`/`ATTUNEMENT_ENABLED` entfernen. |
| `domain/models/Praxis.kt` | Edit | `attunementId`, `attunementEnabled`, `activeAttunementId`, `withAttunementId`, `withAttunementEnabled`, `init`/`create`-Parameter, `fromMeditationSettings`-Mapping, `toMeditationSettings(customAttunementDurationSeconds:)`-Parameter, beide `@SerialName`-Annotationen entfernen. |
| `domain/models/CustomAudioType.kt` | Edit | `ATTUNEMENT`-Wert entfernen. Enum behaelt nur `SOUNDSCAPE`. |
| `domain/models/CustomAudioFile.kt` | Behalten | `type`-Feld bleibt fuer Persistenz-Format-Kompatibilitaet — Migration entfernt nur die ATTUNEMENT-Eintraege aus dem JSON. |
| `domain/models/ImportAudioType.kt` | Edit | `ATTUNEMENT`-Wert entfernen. |
| `domain/services/AudioServiceProtocol.kt` | Edit | `attunementCompletionFlow`, `playAttunementPreview`, `stopAttunementPreview` entfernen. |
| `domain/services/TimerForegroundServiceProtocol.kt` | Edit | `playAttunement`, `stopAttunement` entfernen. |
| `domain/services/TimerReducer.kt` | Edit | `attunementResolver`-Parameter, `AttunementFinished`-Branch (`reduceAttunementFinished`), Attunement-Pfad in `reduceStartGongFinished`, Attunement-Branches in `reduceResetPressed`/`reduceTimerCompleted`, `attunementDurationSeconds`-Helper entfernen. `reduceStartGongFinished` reduziert sich auf den No-Attunement-Pfad (TransitionToRunning + StartBackgroundAudio). `reduceStartPressed` ruft `StartTimer` ohne Attunement-Parameter. |
| `domain/repositories/TimerRepository.kt` | Edit | `startAttunement`, `endAttunement` entfernen. `start(...)`-Signatur ohne `attunementDurationSeconds`. |

### Application/Presentation (vereinfachen)

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `presentation/viewmodel/TimerViewModel.kt` | Edit | `attunementResolver` Constructor-Param und gespeicherte Property, `resolveAttunementDurationSeconds`, `resolveAttunementName`, `attunementCompletionFlow`-Subscription, `minutesBeforeAttunement`-Property + Restoration in `updateSettings`, Attunement-Branches in `updateSettings`/`applyPraxisUpdate`/`observePraxis`, `TimerState.Attunement` aus `activeStates` in `processTimerTick` entfernen. `TimerReducer.reduce`-Aufruf ohne `attunementResolver`-Parameter. |
| `presentation/viewmodel/TimerUiState.kt` | Edit | `resolvedAttunementName` entfernen. `minimumDurationMinutes` ist konstant 1 (kann ggf. komplett entfernt werden, wenn keine Aufrufer mehr; sonst auf `1` reduzieren). |
| `presentation/viewmodel/PraxisEditorViewModel.kt` | Edit | `attunementResolver`-Constructor-Param, `setAttunementId`, `setAttunementEnabled`, `playAttunementPreview`, `audioService.stopAttunementPreview()`-Aufruf in `stopPreviews`, Attunement-Branch in `deleteCustomAudio`, `loadCustomAudio` reduziert auf `SOUNDSCAPE`, `customAttunements` aus State entfernen, `resolveAttunementName` entfernen. |
| `presentation/viewmodel/PraxisEditorViewModel.kt` (PraxisEditorUiState) | Edit | `attunementId`, `attunementEnabled`, `customAttunements`, `resolvedAttunementName` aus State entfernen; `withPraxis`-Parameter `resolvedAttunementName` entfernen. |
| `presentation/ui/timer/SelectAttunementScreen.kt` | Loeschen | Komplette Datei. |
| `presentation/ui/timer/PraxisEditorScreen.kt` | Edit | `onNavigateToAttunement`-Lambda-Parameter entfernen, `AudioSection`-Composable: `attunementEnabled`/`resolvedAttunementName`-Parameter und Attunement-NavigationRow entfernen — bleibt nur Background-Row. |
| `presentation/ui/timer/SettingsSheet.kt` | Edit | `AttunementSection`, `AttunementToggle`, `AttunementContentDropdown`-Composables entfernen; `Attunement.hasAvailableAttunements`-Branch in der Section-Liste entfernen. (Hinweis: SettingsSheet ist im NavGraph nicht mehr verdrahtet, wird aber von `TimerScreenTest` referenziert — Datei beibehalten, nur Attunement-Code raus. Eine spaetere Aufraeum-Aktion kann SettingsSheet.kt komplett entfernen — out of scope hier.) |
| `presentation/ui/timer/TimerScreen.kt` | Edit | `attunementLabel`/`SettingPill` mit `Headphones`-Icon in `ConfigurationPills` entfernen. Pill-FlowRow zeigt nur noch Preparation, Gong, Background, Interval. Import von `Icons.Outlined.Headphones` entfernen. |
| `presentation/ui/timer/TimerFocusScreen.kt` | Edit | `TimerState.Attunement` aus `activeStates`-Set in `LaunchedEffect` und `getStateText`-when-Verzweigung entfernen. |
| `presentation/ui/common/ImportTypeSelectionSheet.kt` | Edit | `ImportTypeRow` fuer Attunement-Variante entfernen. Sheet zeigt nur noch zwei Optionen + System-Dismiss. |
| `presentation/navigation/NavGraph.kt` | Edit | `Screen.SelectAttunement` data object und Routing entfernen. `praxisEditorSubScreens`: SelectAttunement-`composable` entfernen. `praxisEditorComposable`: `onNavigateToAttunement`-Lambda entfernen. `NavHostScaffold.showBottomBar`-Check ohne `SelectAttunement.route`. `handleImportTypeSelection`: `ATTUNEMENT`-when-Branch entfernen. `pendingImportedCustomAudio`-Filter `it.type == CustomAudioType.ATTUNEMENT` entfernen (unused after removal). |

### Infrastructure (entfernen oder reduzieren)

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `infrastructure/audio/AttunementResolver.kt` | Loeschen | Komplette Datei. |
| `infrastructure/audio/AudioService.kt` | Edit | `attunementPlayer`, `attunementPreviewPlayer`, `_attunementCompletionFlow`/`attunementCompletionFlow`, `playAttunement(resourceName, volume)`, `playAttunementFromFile(filePath, volume)`, `stopAttunement()`, `playAttunementPreview(attunementId)`, `playBuiltInAttunementPreview`, `playCustomAttunementPreview`, `stopAttunementPreview()` entfernen. Cleanup-Verweise (`stopAttunement()`, `stopAttunementPreview()`) in `release()` und `cleanupPreviewPlayers()` entfernen. `ATTUNEMENT_VOLUME`-Konstante entfernen. `resolveRawResourceId`: `intro_breath_de`/`intro_breath_en` aus when-Branch entfernen. Import von `Attunement` entfernen. |
| `infrastructure/audio/TimerForegroundService.kt` | Edit | `ACTION_PLAY_ATTUNEMENT`, `ACTION_STOP_ATTUNEMENT`, `EXTRA_ATTUNEMENT_ID` Companion-Konstanten entfernen. `playAttunement`/`stopAttunement` Companion-Methoden entfernen. `handleAction`-Branch `ACTION_PLAY_ATTUNEMENT`/`ACTION_STOP_ATTUNEMENT`, `handlePlayAttunement` Methode entfernen. `stopTimer()`: `audioService.stopAttunement()`-Aufruf entfernen. Imports von `Attunement` entfernen. |
| `infrastructure/audio/TimerForegroundServiceWrapper.kt` | Edit | `playAttunement`, `stopAttunement` entfernen. |
| `data/repositories/TimerRepositoryImpl.kt` | Edit | `startAttunement()`, `endAttunement()` entfernen. `start(...)`: `attunementDurationSeconds`-Parameter aus Signatur und `MeditationTimer.create`-Aufruf entfernen. |
| `infrastructure/di/AppModule.kt` | Edit | `provideAttunementResolver(impl: AttunementResolver): AttunementResolverProtocol` und Imports `AttunementResolver`, `AttunementResolverProtocol` entfernen. |

### Persistenz / Migration

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `data/local/PraxisDataStore.kt` | Edit | `decodeOrNull` nutzt `Json { ignoreUnknownKeys = true }` (analog `CustomAudioDataStore`), damit alte JSON mit `introductionId`/`introductionEnabled` ohne Crash dekodiert werden. Beim naechsten `save()` werden die Felder automatisch nicht mehr serialisiert (sie existieren im `Praxis`-Datentyp nicht mehr). |
| `data/migration/AttunementCleanupMigration.kt` | Neu | Singleton, in Hilt registriert. `runIfNeeded()`: prueft Marker in `SettingsDataStore`, fuehrt Bereinigung idempotent aus, setzt Marker. Schritte siehe Migration-Abschnitt unten. |
| `data/local/SettingsDataStore.kt` | Edit | Marker-Key `migration_attunement_removed_v1: Boolean` und Getter/Setter ergaenzen (nicht zwingend ein eigener Setter; einmaliges `edit` reicht — in Migration selbst). |
| `StillMomentApp.kt` | Edit | `@Inject lateinit var migration: AttunementCleanupMigration`. In `onCreate()` `runBlocking { migration.runIfNeeded() }` synchron aufrufen, damit alle Repository-Reads danach passieren. |

### Resources

| Pfad | Aktion |
|------|--------|
| `app/src/main/res/raw/intro_breath_de.mp3` | Loeschen |
| `app/src/main/res/raw/intro_breath_en.mp3` | Loeschen |

### Lokalisierung

`app/src/main/res/values/strings.xml` und `values-de/strings.xml` —
folgende Keys entfernen (DE+EN identisch):

- `settings_attunement`
- `settings_attunement_content`
- `accessibility_attunement_picker`
- `accessibility_attunement_toggle`
- `accessibility_attunement_enabled`
- `accessibility_attunement_enabled_no_selection`
- `accessibility_attunement_disabled`
- `praxis_editor_attunement_row`
- `praxis_editor_attunement_none`
- `praxis_editor_attunement_title`
- `accessibility_praxis_editor_attunement`
- `accessibility_praxis_editor_attunement_toggle`
- `custom_audio_section_my_attunements`
- `custom_audio_empty_attunements`
- `import_type_attunement`
- `import_type_attunement_description`

### Tests

| Datei | Aktion |
|-------|--------|
| `domain/models/AttunementTest.kt` | Loeschen |
| `domain/models/MeditationSettingsAttunementTest.kt` | Loeschen |
| `infrastructure/audio/AttunementResolverTest.kt` | Loeschen |
| `presentation/viewmodel/TimerViewModelAttunementTest.kt` | Loeschen |
| `testutil/MockAttunementResolver.kt` | Loeschen |
| `domain/services/TimerReducerTest.kt` | Edit — `MockAttunementResolver`-Felder, `@Nested AttunementFinished`/`CustomAttunement`/`StartGongFinished` Attunement-Branches, `attunementResolver`-Parameter aus allen `reduce`-Aufrufen entfernen. |
| `domain/models/PraxisTest.kt` | Edit — Attunement-Felder/Builder-Tests (`withAttunementId`, `withAttunementEnabled`) entfernen. Migration-Test fuer alte JSON mit `introductionId`/`introductionEnabled` als Fixture ergaenzen (mit `ignoreUnknownKeys`-Json sollte Decode keine Exception werfen). |
| `domain/models/MeditationTimerTest.kt` | Edit — `startAttunement()`, `endAttunement()`, `tickAttunement`-Tests entfernen, `attunementDurationSeconds`-Parameter aus `create()`-Aufrufen entfernen. |
| `domain/models/MeditationTimerEventTest.kt` | Edit — Attunement-bezogene Test-Setups entfernen. |
| `domain/models/MeditationTimerEndGongTest.kt` | Edit — `Attunement`-State-Setups entfernen. |
| `domain/models/CustomAudioFileTest.kt` | Edit — `CustomAudioType.ATTUNEMENT`-Test entfernen. |
| `domain/models/ImportAudioTypeTest.kt` | Edit — `ATTUNEMENT`-Case-Test entfernen. |
| `data/repositories/TimerRepositoryImplTest.kt` | Edit — `startAttunement`/`endAttunement`/`attunementDurationSeconds`-Tests entfernen. |
| `data/local/PraxisDataStoreTest.kt` | Edit — Attunement-Felder aus Test-Setup/Round-Trip-Tests entfernen. **Neue Tests** fuer Migration-Verhalten: (1) `Json { ignoreUnknownKeys = true }` dekodiert alte Praxis-JSON-Fixture mit `introductionId`/`introductionEnabled`; (2) Nach Re-Save erscheinen die Felder nicht mehr im Output. |
| `presentation/viewmodel/PraxisEditorViewModelTest.kt` | Edit — Attunement-Setter, `setAttunementEnabled`/`setAttunementId`/`setupViewModel(attunementResolver=...)`-Tests entfernen. |
| `presentation/viewmodel/PraxisEditorViewModelCustomAudioTest.kt` | Edit — Attunement-Branch in `deleteCustomAudio`-Tests, `loadAll(ATTUNEMENT)`-Erwartungen entfernen. |
| `presentation/viewmodel/TimerViewModelRegressionTest.kt` | Edit — Attunement-Regression-Tests (Min-Duration-Clamp, Restoration, Phase-Transitions) entfernen. |
| `presentation/viewmodel/TimerViewModelForegroundServiceTest.kt` | Edit — Attunement-bezogene Foreground-Service-Aufrufe entfernen. |
| `presentation/viewmodel/TimerViewModelPreviewTest.kt` | Edit — `playAttunementPreview`-Tests entfernen. |
| `presentation/viewmodel/TimerViewModelTestFakes.kt` | Edit — `attunementCompletionFlow`-Stub aus Fake-AudioService, `playAttunement`/`stopAttunement` aus Fake-ForegroundService entfernen. `attunementResolver`-Parameter in TestFake-Builder entfernen. |
| `infrastructure/audio/SoundscapeResolverTest.kt` | Edit — Test `returns null for custom attunement ID` und `Attunement.languageOverride`-Helper entfernen. Test pruefte explizit, dass SoundscapeResolver Attunements ignoriert; nach Removal der Enum entfaellt der Test-Case komplett. |

Hinweis: `androidTest/.../TimerScreenTest.kt` referenziert `SettingsSheet`, aber **keine** Attunement-Strings/States. Aenderung im SettingsSheet (Attunement-Section entfernen) bricht die UI-Tests nur, wenn die Tests den Sheet komplett rendern und Attunement-Compose-Funktionen durchlaufen — pruefen, ggf. Test-Setup anpassen.

### Dokumentation

| Datei | Aktion |
|-------|--------|
| `dev-docs/architecture/timer-state-machine.md` | Edit — Attunement-Knoten + Transitionen aus Mermaid-Chart und Tabellen entfernen. |
| `dev-docs/architecture/ddd.md` | Edit — Attunement-Beispiele entfernen. |
| `dev-docs/reference/glossary.md` | Edit — Eintraege fuer "Attunement", "AttunementResolver", "Attunement"-State entfernen. |
| `dev-docs/architecture/audio-system.md` | Pruefen — Attunement-Audio-Pfade ggf. anpassen. |
| `android/CLAUDE.md` | Edit — `data object Introduction : TimerState()` (Zeile 111), `AttunementResolver`-Erwaehnung im Reducer-Pattern (Zeilen 171, 182, 185, 214), `MockAttunementResolver`-Beispiel (Zeilen 319, 330) entfernen oder ersetzen. |
| `CHANGELOG.md` | Schon eingetragen (Zeile 15) — bestehender Eintrag bleibt; bei Bedarf um Android-Spezifika ergaenzen, wenn iOS und Android in einer Release zusammen gehen. |

---

## API-Recherche

Keine neuen Frameworks/APIs noetig. Alle Operationen sind Reduktionen bestehender Strukturen.

Migration arbeitet mit:
- **DataStore Preferences** (`androidx.datastore.preferences`): `edit { remove(key) }`, `data.first()`. Etabliert.
- **kotlinx.serialization.json**: `Json { ignoreUnknownKeys = true }`, `JsonElement`/`JsonArray` fuer manuelle JSON-Filterung der Custom-Audio-Liste. `Json` ist Multiplatform und Standard-Lib in diesem Projekt.
- **`java.io.File.deleteRecursively()`**: Loescht das Verzeichnis `filesDir/custom_audio/attunements/` rekursiv. Standard-Java-API, kein Permission-Check noetig fuer App-internen Storage.
- **Hilt `@Singleton` + `@Inject`**: Bestehende Patterns; keine neuen Abhaengigkeiten.

Bestehende `Json`-Konfiguration in `PraxisDataStore` ist `Json` (default) — strikt, wirft bei unbekannten Keys. `CustomAudioDataStore` nutzt bereits `Json { ignoreUnknownKeys = true }`. Anpassung in `PraxisDataStore` ist eine 1-Zeilen-Aenderung.

---

## Design-Entscheidungen

### 1. Persistenz-Format: Enum-Case `CustomAudioType.ATTUNEMENT` ganz loeschen?

**Trade-off:**
- Loeschen: konsistenter, kein toter Pfad.
  Risiko: `CustomAudioDataStore` haelt **eine** JSON-Liste mit allen Custom-Audio-Eintraegen. Wenn dort noch Eintraege mit `"type":"ATTUNEMENT"` stehen, schlaegt die kotlinx-Deserialisierung fehl (kein gueltiger Enum-Wert). `getAllFiles` faengt die Exception zwar ab und gibt `emptyList()` zurueck — das wuerde aber **alle Soundscapes ebenfalls verlieren**.
- Behalten: Enum-Case bleibt, kein UI-Pfad — toter Code im Domain-Modell.

**Entscheidung:** Komplett loeschen. **Dafuer muss die Migration die JSON-Liste manuell filtern, BEVOR irgendein Codepfad versucht, sie mit dem reduzierten Enum zu dekodieren.** Vorgehen: `JsonArray`-Parsing der Raw-Strings, Filter `it["type"]?.jsonPrimitive?.content != "ATTUNEMENT"`, danach Re-Encode. Erst wenn das durch ist, koennen `CustomAudioRepository.loadAll` und Co. lesen.

### 2. Wo laeuft die Migration?

**Trade-off:**
- In `StillMomentApp.onCreate()` synchron via `runBlocking`: einfach, garantiert vor allem anderen, blockiert den Main-Thread (nur einmal nach Update — akzeptabel, ms-Bereich).
- In `MainActivity.onCreate()` vor Compose-Setup: Activity-Lifecycle, aber nicht garantiert "vor allen DataStore-Reads", da Hilt-injizierte Services parallel initialisiert werden koennen.
- Lazy in den Repositories pruefen: invasiv, jedes Repo muesste den Marker pruefen.

**Entscheidung:** `StillMomentApp.onCreate()` mit `runBlocking { migration.runIfNeeded() }`. Die Migration ist idempotent und auf einem Idle-DataStore-Read+Write begrenzt — Worst Case ein paar hundert ms beim ersten App-Start nach Update. Saubere Garantie: alle Hilt-Singletons werden lazy bei Bedarf instantiiert, dann ist der Marker schon gesetzt.

### 3. Praxis-JSON-Migration: `ignoreUnknownKeys = true`

**Trade-off:**
- `ignoreUnknownKeys = true`: alte Felder werden ignoriert, Decode klappt, naechstes `save()` schreibt sauber.
- Manuelle JSON-Filterung in PraxisDataStore: Aufwendiger, aber explizit.

**Entscheidung:** `ignoreUnknownKeys = true`. Konsistent mit `CustomAudioDataStore`, minimal-invasiv, robust gegen weitere zukuenftige Feld-Removals.

### 4. SettingsSheet.kt — komplett loeschen oder nur Attunement-Section entfernen?

**Beobachtung:** SettingsSheet wird im Production-NavGraph nicht mehr referenziert. Es wird nur in `androidTest/.../TimerScreenTest.kt` instanziiert.

**Entscheidung:** Nur die Attunement-Section entfernen. Komplettes Loeschen ist eine separate Aufraeum-Aufgabe, die nicht zu shared-088 gehoert.

### 5. Card-Layout der ConfigurationPills

**Entscheidung:** Pills im `TimerScreen.ConfigurationPills` zeigen nach Removal: Preparation (optional), Gong, Background, Interval (optional). Kein eigenes Layout-Refactoring; nur Removal des `attunementLabel`/`SettingPill(Headphones, ...)`-Blocks. Folgt dem iOS-Hinweis, dass das Layout im Folge-Ticket ohnehin ueberarbeitet wird.

### 6. State-Machine-Vereinfachung in `MeditationTimer`

**Beobachtung:** `silentPhaseStartRemaining` existiert nur, damit Interval-Gongs ihre Baseline ab Start der stillen Phase berechnen — nach Wegfall der Attunement-Phase startet die stille Phase mit `totalSeconds`. `effectiveStartRemaining = silentPhaseStartRemaining ?: totalSeconds` reduziert sich auf `totalSeconds`.

**Entscheidung:** `silentPhaseStartRemaining` und `effectiveStartRemaining` komplett entfernen. Interval-Gong-Berechnungen nutzen direkt `totalSeconds`. `endAttunement()` entfaellt vollstaendig. Konsistent mit dem iOS-Plan.

---

## Migration

**Ziel:** Beim ersten App-Start nach Update wird der Attunement-Datenbestand stillschweigend, einmalig und idempotent bereinigt. Kein Dialog, kein Hinweis.

**Wo:** `data/migration/AttunementCleanupMigration` (neu, `@Singleton`), aufgerufen einmalig in `StillMomentApp.onCreate()` via `runBlocking { migration.runIfNeeded() }`.

**Was migriert werden muss:**

1. **Idempotenz-Marker pruefen** — `SettingsDataStore`-Key `migration_attunement_removed_v1`. Wenn `true` → return.
2. **CustomAudioDataStore (Custom-Audio-JSON)**:
   - `praxisDataStore` ist nicht betroffen — nur die Custom-Audio-Liste.
   - Raw-Preferences lesen, `Keys.FILES`-String holen.
   - Mit `Json { ignoreUnknownKeys = true; isLenient = true }` als `JsonArray` parsen (NICHT als `List<CustomAudioFile>`, weil ATTUNEMENT-Enum-Wert nicht mehr existiert).
   - Liste filtern: `it.jsonObject["type"]?.jsonPrimitive?.content != "ATTUNEMENT"`.
   - Gefilterte JsonArray-Form per `Json.encodeToString(JsonArray.serializer(), ...)` zurueckschreiben.
3. **Custom-Attunement-Dateien**:
   - Verzeichnis `context.filesDir/custom_audio/attunements/` rekursiv loeschen via `File.deleteRecursively()`. Idempotent: kein Fehler wenn das Verzeichnis nicht existiert.
4. **Praxis-JSON**:
   - Keine explizite Migration noetig — `PraxisDataStore.decodeOrNull` mit `ignoreUnknownKeys = true` ueberlaedt alte JSON sauber, der naechste `save()` (z.B. wenn der User in den Editor geht) schreibt ohne `introductionId`/`introductionEnabled`. Falls saubere Migration sofort gewuenscht: nach `runIfNeeded()` einmal `praxisRepository.load()` + `praxisRepository.save()` erzwingen, damit die JSON-Datei sofort sauber ist. **Optional.**
5. **MeditationSettings-Legacy-Keys** (falls noch vorhanden): `MeditationSettingsKeys.ATTUNEMENT_ID`/`ATTUNEMENT_ENABLED` aus `SettingsDataStore` entfernen via `prefs.edit { remove(stringPreferencesKey("introductionId")); remove(booleanPreferencesKey("introductionEnabled")) }`. Hinweis: SettingsDataStore-Migration kann optional sein, da `MeditationSettings` heute aus Praxis aufgebaut wird, nicht aus SettingsDataStore. **Vorsorglich entfernen, falls historische Eintraege bestehen.**
6. **Marker setzen**: `prefs.edit { it[booleanPreferencesKey("migration_attunement_removed_v1")] = true }`.

**Logging**: `logger.d(TAG, "Attunement cleanup migration completed: filesRemoved=$N, audioEntriesFiltered=$M")`. `LoggerProtocol` ist bereits in DI verfuegbar.

**Failure-Mode**: Jeder Schritt nutzt `try { ... } catch (e: ...) { logger.e(...) }`-Wrapping. Ein Teil-Fehler verhindert nicht das Setzen des Markers — die App startet sauber, ggf. bleibt eine fremdartige Datei liegen. Akzeptabel, da Custom-Attunements ohnehin nicht mehr referenzierbar sind.

---

## Refactorings (nicht-trivial)

1. **`TimerReducer.reduce`-Signaturaenderung** — `attunementResolver`-Parameter entfaellt. Aufrufer: `TimerViewModel.dispatch` + 5+ Test-Dateien. Risiko: mittel. Compiler erzwingt Anpassung.
2. **`MeditationTimer` State-Machine-Reduktion** — `silentPhaseStartRemaining` + `attunementDurationSeconds` + `tickAttunement` weg. Risiko: mittel. `MeditationTimerEventTest` fuer Interval-Gongs muss vor und nach Refactor gruen sein. Baseline-Aenderung von `effectiveStartRemaining` auf `totalSeconds` ist verhaltensneutral fuer den No-Attunement-Pfad — und das ist der einzige verbleibende Pfad.
3. **`MeditationSettings.validateDuration` und `minimumDuration`** — Reduktion auf `coerceIn(1, 60)`. Risiko: niedrig. Tests in `MeditationSettingsTest` decken den Bereich ab.
4. **`Praxis` Codable-Compat** — Aenderung von `decodeOrNull` auf `Json { ignoreUnknownKeys = true }`. Risiko: mittel — produktive Daten betroffen. Test: `PraxisDataStoreTest` mit Fixtures alter Form ergaenzen.
5. **`AudioService` Cleanup** — entfernt 4 Player-Properties + zugehoerige Methoden. Risiko: niedrig, da Properties nicht mehr aufgerufen werden, sobald Aufrufer geloescht sind.
6. **`PraxisEditorViewModel.deleteCustomAudio`** — Attunement-Branch entfernen. `current.attunementId == id` Check entfaellt. Trivial.

---

## Fachliche Szenarien

### AK-1: Timer-Konfiguration zeigt keine Einstimmung mehr

- Gegeben: Frische Installation, App-Start
  Wenn: User oeffnet Timer-Tab und tippt auf den ConfigurationPills-Bereich → Praxis-Editor
  Dann: Editor zeigt Sektionen `Vorbereitung`, `Audio & Klangkulisse` (nur Klangkulisse-Row, kein Einstimmung-Row), `Gongs` — keine Einstimmungs-Auswahl

- Gegeben: ConfigurationPills im Idle-Zustand
  Wenn: User scannt die Pills
  Dann: Pills zeigen nur Preparation, Gong, Background, Interval — keine `Headphones`-Pill

### AK-2: Datei-Import bietet keine Einstimmung mehr

- Gegeben: User teilt eine MP3-Datei mit der App (Share-Sheet, Chrome-Download)
  Wenn: `ImportTypeSelectionSheet` erscheint
  Dann: Sheet zeigt nur "Gefuehrte Meditation" und "Klangkulisse" — keine `Air`-Icon-Reihe fuer "Einstimmung"

### AK-3: Timer-State-Machine hat keine Attunement-Phase

- Gegeben: Timer wird mit beliebiger Konfiguration gestartet
  Wenn: Vorbereitung endet → Start-Gong endet
  Dann: `MeditationTimer.state` wechselt direkt zu `TimerState.Running`, kein `TimerState.Attunement`-Durchlauf, keine `PlayAttunement`-Effekte

- Gegeben: Timer wird waehrend `Running` per Reset-Button beendet
  Wenn: User drueckt Close im FocusScreen
  Dann: Effekte enthalten `StopForegroundService` und `ResetTimer`, kein `StopAttunement`

### AK-4: Timer-Zeitberechnung ohne Attunement

- Gegeben: User waehlt 1 Minute im WheelPicker
  Wenn: Vor dem Update war die 1 wegen Attunement im Picker nicht waehlbar
  Dann: `TimerUiState.minimumDurationMinutes` ist konstant 1, der WheelPicker-`range` startet bei 1

- Gegeben: Interval-Gongs alle 2 Min, 10 Min Timer ohne Attunement
  Wenn: Timer laeuft
  Dann: Gongs feuern bei 2:00, 4:00, 6:00, 8:00 Verbleibend-Sekunden — Baseline ist `totalSeconds`, identisch zum bisherigen No-Attunement-Verhalten

### AK-5: Update mit konfigurierter Einstimmung crasht nicht

- Gegeben: Vorgaengerversion hat `Praxis`-JSON mit `"introductionId":"breath"` und `"introductionEnabled":true` in DataStore plus eine importierte Custom-Einstimmung in `custom_audio_files`
  Wenn: User aktualisiert auf neue Version und startet die App
  Dann: App startet ohne Crash. Migration laeuft. Attunement-Eintrag aus Custom-Audio-Liste verschwunden, Datei aus `filesDir/custom_audio/attunements/` geloescht. Kein Dialog. Praxis-Editor zeigt keine Einstimmung-Option mehr. Soundscapes bleiben unveraendert.

- Gegeben: Praxis-JSON enthaelt `introductionId` und `introductionEnabled`
  Wenn: `PraxisDataStore.load()` aufgerufen wird
  Dann: Decode mit `ignoreUnknownKeys = true` wirft keine Exception, neue Praxis-Felder fehlen einfach, nach erstem `save()` ist das JSON sauber

### AK-6: Custom-Attunement-Dateien werden geloescht

- Gegeben: `filesDir/custom_audio/attunements/` enthaelt drei MP3s und `custom_audio_files`-DataStore-Liste enthaelt drei Eintraege mit `"type":"ATTUNEMENT"`
  Wenn: Migration laeuft beim ersten Start
  Dann: Verzeichnis ist geloescht, Liste enthaelt keine ATTUNEMENT-Eintraege mehr (nur SOUNDSCAPE), `migration_attunement_removed_v1`-Marker ist `true`

- Gegeben: Migration wurde bereits einmal ausgefuehrt (Marker gesetzt)
  Wenn: User startet App erneut
  Dann: Migration laeuft nicht erneut (idempotent, return early am Marker-Check)

### AK-7: Lokalisierungs-Keys sind weg

- Gegeben: Build mit `make check`
  Wenn: Lint laeuft
  Dann: Keine `*_attunement*`-, `*introduction*`-, `*einstimmung*`-Keys mehr in DE und EN strings.xml. Keine `R.string.settings_attunement` etc. Referenzen mehr im Kotlin-Code.

### AK-8: Bundle-Audio-Dateien sind weg

- Gegeben: Build-Output (`make assembleDebug` oder `assembleRelease`)
  Wenn: APK inspiziert wird
  Dann: Kein `intro_breath_de.mp3`, kein `intro_breath_en.mp3` in `res/raw/`. `R.raw.intro_breath_de`/`intro_breath_en`-Konstanten existieren nicht mehr (Compiler-Fehler waere die Folge — Indikator dass kein Code sie noch referenziert).

---

## Reihenfolge der Implementierung

Strategie: Bottom-up vom Domain-Layer zum UI, Tests vor Production-Code (TDD-Loop pro Schicht).
**Migration als zweiten Schritt** (nicht zuletzt) — sie muss ausgerollt sein, bevor der Enum-Case `CustomAudioType.ATTUNEMENT` entfernt wird, sonst crasht die Deserialisierung im DataStore. In einem einzigen Commit-Set ist das egal, aber bei der Implementierung lohnt sich die fruehere Migration, damit `make test` waehrend der Arbeit weiter laeuft.

1. **Migration zuerst aufsetzen** (AK-5, AK-6)
   - `data/migration/AttunementCleanupMigration.kt` schreiben mit Tests (Custom-Audio-JSON-Filterung, Datei-Loeschung, Marker-Idempotenz)
   - `SettingsDataStore` Marker-Helper ergaenzen
   - `StillMomentApp` mit `@AndroidEntryPoint` + `runBlocking`-Aufruf erweitern
   - Tests gegen Fixture-JSON mit gemischten Soundscape/Attunement-Eintraegen

2. **`PraxisDataStore.decodeOrNull` auf `ignoreUnknownKeys = true`** (AK-5)
   - Test fuer alte Praxis-JSON in `PraxisDataStoreTest` ergaenzen
   - 1-Zeilen-Aenderung im Production-Code

3. **Domain — Modelle** (AK-3, AK-4)
   - Tests in `MeditationSettingsAttunementTest` (loeschen), `MeditationTimerTest`, `MeditationTimerEventTest`, `PraxisTest`, `AttunementTest` (loeschen) — Tests rot machen durch Entfernung der Attunement-Faelle
   - `TimerState`, `TimerAction`, `TimerEffect` reduzieren
   - `MeditationSettings` Felder + Validierung reduzieren
   - `Praxis` Felder + `@SerialName` + Builder reduzieren
   - `MeditationTimer` `silentPhaseStartRemaining` + Helper entfernen
   - `CustomAudioType.ATTUNEMENT` und `ImportAudioType.ATTUNEMENT` entfernen
   - `Attunement.kt`, `ResolvedAttunement.kt` loeschen

4. **Domain — Services** (AK-3)
   - `AudioServiceProtocol`, `TimerForegroundServiceProtocol` reduzieren
   - `AttunementResolverProtocol.kt` loeschen
   - `TimerRepository`-Interface reduzieren
   - `TimerReducer` Attunement-Branch entfernen — Aufrufer-Signatur aendert sich

5. **Infrastructure** (AK-3)
   - `AttunementResolver.kt` loeschen
   - `AudioService` Properties/Cleanup/Methoden reduzieren, `intro_breath_*` aus `resolveRawResourceId`
   - `TimerForegroundService`, `TimerForegroundServiceWrapper` reduzieren
   - `TimerRepositoryImpl` reduzieren
   - `AppModule.provideAttunementResolver` entfernen

6. **Application** (AK-1)
   - `TimerViewModel` Attunement entfernen
   - `TimerUiState` reduzieren
   - `PraxisEditorViewModel` + UiState reduzieren

7. **Presentation** (AK-1, AK-2)
   - `SelectAttunementScreen.kt` loeschen
   - `NavGraph`: Route + Composable entfernen, ImportType-Branch reduzieren
   - `PraxisEditorScreen`: AudioSection + Lambda-Param reduzieren
   - `TimerScreen`: ConfigurationPills reduzieren
   - `TimerFocusScreen`: `TimerState.Attunement` aus Sets/when entfernen
   - `ImportTypeSelectionSheet`: Reihe entfernen
   - `SettingsSheet`: Attunement-Section entfernen

8. **Resources & Lokalisierung** (AK-7, AK-8)
   - `res/raw/intro_breath_*.mp3` loeschen
   - 16 String-Keys in DE+EN entfernen

9. **Mocks + Tests** (parallel, nach jedem Schritt rot/gruen ueberpruefen)
   - `MockAttunementResolver.kt` loeschen
   - `TimerViewModelTestFakes.kt` reduzieren
   - Test-Dateien loeschen oder anpassen (siehe Liste oben)

10. **Dokumentation** (Pflicht-Akzeptanzkriterien)
    - Glossary, State-Chart-MD, DDD-Doku, android/CLAUDE.md
    - CHANGELOG-Eintrag bereits vorhanden

11. **Manueller Test** auf Pixel-Emulator laut Ticket-Manual-Test (frische Install + Update-Pfad)

---

## Vorbereitung

Keine externen Schritte. Reine Code-Reduktion + Migration.

- Vor dem Start `make check` und `make test-unit-agent` einmal laufen lassen, um Baseline gruen zu haben.
- Zwischen Schritt 1 und 2 (Migration + Praxis-Decode) sollten alle Tests noch gruen sein, bevor der Domain-Umbau startet.

---

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| `CustomAudioDataStore` Deserialisierung crasht, weil JSON noch `ATTUNEMENT`-Enum-Werte enthaelt → **Soundscapes wuerden ebenfalls verloren gehen** | Migration laeuft VOR allen DataStore-Reads via `runBlocking` in `StillMomentApp.onCreate()`. Migration nutzt `JsonArray`-Parsing ohne Enum-Constraint. Test mit Fixture-JSON `[{"type":"SOUNDSCAPE",...},{"type":"ATTUNEMENT",...}]` muss zeigen, dass nach Migration nur Soundscape uebrig bleibt UND vom neuen Enum dekodierbar ist. |
| `PraxisDataStore.decodeOrNull` crasht ohne `ignoreUnknownKeys` bei alter JSON mit `introductionId` | `Json { ignoreUnknownKeys = true }` einsetzen. Test mit alter JSON-Fixture in `PraxisDataStoreTest` ergaenzen. |
| `silentPhaseStartRemaining`-Removal bricht Interval-Gong-Berechnung | `MeditationTimerEventTest` muss vor und nach Refactor gruen sein. Baseline-Aenderung verhaltensneutral fuer No-Attunement-Pfad. |
| `Custom-Attunement`-Verzeichnis `filesDir/custom_audio/attunements/` ist auf manchen Geraeten nicht loeschbar (Permissions, Schreibsperre) | `File.deleteRecursively()` gibt `false` zurueck, Migration loggt das, Marker wird trotzdem gesetzt. Akzeptabel — Datei ist nicht mehr referenzierbar. |
| `TimerReducer.reduce`-Signaturaenderung uebersieht Test-Aufrufer | Compiler erzwingt Anpassung. Vor Commit `make test-unit-agent` durchlaufen lassen. |
| `validateDuration` ohne Attunement-Parameter bricht UI-Picker-Range | `WheelPicker.range = minimumMinutes..60` mit `minimumDurationMinutes = 1`. `MeditationSettingsTest` deckt Min-Duration ab. |
| `SettingsSheet` referenziert `Attunement` direkt — nach Removal des Domain-Models compile fail in `androidTest` | `SettingsSheet`-Datei mit Attunement-Section reduzieren. `TimerScreenTest` pruefen — vermutlich nutzt es nur Settings-Felder, nicht `attunementEnabled`. |
| Synchroner `runBlocking` in `Application.onCreate()` blockiert App-Start spuerbar auf Geraeten mit langsamem Storage | Migration nur einmalig, idempotent. Bei mehreren MB-Files: Datei-Loeschung kann ein paar hundert ms dauern, ist aber One-Shot beim Update. Marker verhindert Re-Run. |
| `intro_breath_*.mp3`-Removal: noch offene Code-Pfade in `AudioService.resolveRawResourceId` referenzieren `R.raw.intro_breath_*` → Compile-Fehler | Beabsichtigt: Compile-Fehler indiziert vergessene Codestelle. Reihenfolge: ERST Code reduzieren, DANN Resources loeschen. |

---

## Geklaerte Entscheidungen

- **Card-Layout (Pills):** ConfigurationPills minimal-invasiv reduzieren. Folge-Ticket ueberarbeitet das Layout.
- **ImportTypeSelectionSheet:** Sheet bleibt mit zwei Optionen.
- **CustomAudioType.ATTUNEMENT:** Enum-Wert wird komplett geloescht. Migration filtert die JSON vor dem ersten Decode.
- **PraxisDataStore Json-Config:** `ignoreUnknownKeys = true`.
- **Migration-Marker:** `migration_attunement_removed_v1` in `SettingsDataStore`.
- **Migration-Aufruf:** `StillMomentApp.onCreate()` synchron via `runBlocking`.
- **SettingsSheet.kt:** beibehalten, nur Attunement-Section raus. Komplette Entfernung in einem Folge-Ticket.
- **iOS-Reihenfolge:** iOS-Plan zuerst implementieren, Android danach (laut iOS-Plan-Hinweis). Plan hier ist trotzdem unabhaengig nutzbar.
