# Implementierungsplan: shared-067 (Android)

Ticket: [shared-067](../shared/shared-067-rename-introduction-attunement.md)
Erstellt: 2026-03-22

## Uebersicht

Rein mechanischer Rename: `Introduction` → `Attunement` / `Einleitung` → `Einstimmung` in Code, UI-Texten und Lokalisierung. Keine Logik-Aenderungen. **33 Source-Dateien, 17 Test-Dateien, 2 Lokalisierungs-Dateien** betroffen.

## Betroffene Codestellen

### Domain Layer — Models

| Datei | Aktion | Beschreibung |
|-------|--------|--------------|
| `domain/models/Introduction.kt` | **Rename → `Attunement.kt`** | Klasse `Introduction` → `Attunement`, `allIntroductions` → `allAttunements`, `hasAvailableIntroductions` → `hasAvailableAttunements`, `availableForCurrentLanguage()` Rueckgabetyp, Doc-Comments |
| `domain/models/TimerState.kt` | Rename Case | `data object Introduction` → `data object Attunement`, Doc-Comments + ASCII-Diagramm |
| `domain/models/TimerAction.kt` | Rename Case | `IntroductionFinished` → `AttunementFinished` |
| `domain/models/TimerEffect.kt` | Rename Cases | `PlayIntroduction(introductionId)` → `PlayAttunement(attunementId)`, `StopIntroduction` → `StopAttunement`, `BeginIntroductionPhase` → `BeginAttunementPhase`, `EndIntroductionPhase` → `EndAttunementPhase`. Parameter: `introductionDurationSeconds` → `attunementDurationSeconds` in `StartTimer`. `StartRunningWithoutIntroduction` → `StartRunningWithoutAttunement` |
| `domain/models/MeditationTimer.kt` | Rename | `introductionDurationSeconds` Property → `attunementDurationSeconds`, `silentPhaseStartRemaining` Doc-Comment, `tickIntroduction()` bleibt intern (pruefen), `beginIntroduction()` → `beginAttunement()`, `endIntroduction()` → `endAttunement()`, `create()` Parameter |
| `domain/models/MeditationSettings.kt` | Rename Properties | `introductionId` → `attunementId`, `introductionEnabled` → `attunementEnabled`, `activeIntroductionId` → `activeAttunementId`, `hasActiveIntroduction` → `hasActiveAttunement`, `activeIntroductionDurationSeconds` → `activeAttunementDurationSeconds`, `withIntroductionEnabled()` → `withAttunementEnabled()`. **`Keys.INTRODUCTION_ID` und `Keys.INTRODUCTION_ENABLED`: Swift-Name umbenennen, String-Werte `"introductionId"` / `"introductionEnabled"` NICHT aendern** (Legacy-Persistenz) |
| `domain/models/Praxis.kt` | Rename Properties | `introductionId` → `attunementId`, `introductionEnabled` → `attunementEnabled`, `activeIntroductionId` → `activeAttunementId`, `withIntroductionId()` → `withAttunementId()`, `withIntroductionEnabled()` → `withAttunementEnabled()`. **Serialisierung pruefen** — falls `@Serializable` mit Key-Mapping, String-Werte NICHT aendern |
| `domain/models/ResolvedAttunement.kt` | Pruefen | Evtl. Doc-Comment-Referenzen auf "introduction" |
| `domain/models/ImportAudioType.kt` | Pruefen | Referenzen auf "introduction" |
| `domain/models/CustomAudioFile.kt` | Pruefen | Referenzen auf "introduction" |
| `domain/models/CustomAudioType.kt` | Pruefen | Referenzen auf "introduction" |
| `domain/models/TimerEvent.kt` | Pruefen | Doc-Comment-Referenzen |

### Domain Layer — Services / Repositories

| Datei | Aktion | Beschreibung |
|-------|--------|--------------|
| `domain/services/AudioServiceProtocol.kt` | Rename | `introductionCompletionFlow` → `attunementCompletionFlow`, `playIntroduction()` → `playAttunement()`, `stopIntroduction()` → `stopAttunement()`, `playIntroductionPreview()` → `playAttunementPreview()`, `stopIntroductionPreview()` → `stopAttunementPreview()` |
| `domain/services/TimerReducer.kt` | Rename | Alle `.Introduction`/`.IntroductionFinished`/`.PlayIntroduction` Referenzen, `introductionDurationSeconds()` → `attunementDurationSeconds()`, lokale Variablen `introDuration`/`introId` |
| `domain/services/AttunementResolverProtocol.kt` | Pruefen | Evtl. Doc-Comment-Referenzen |
| `domain/services/TimerForegroundServiceProtocol.kt` | Rename | `playIntroduction()` → `playAttunement()` |
| `domain/repositories/CustomAudioRepository.kt` | Pruefen | Referenzen |
| `domain/repositories/TimerRepository.kt` | Pruefen | Referenzen |

### Infrastructure Layer

| Datei | Aktion | Beschreibung |
|-------|--------|--------------|
| `infrastructure/audio/AudioService.kt` | Rename | Alle introduction-Properties und -Methoden |
| `infrastructure/audio/AttunementResolver.kt` | Pruefen | Doc-Comment-Referenzen |
| `infrastructure/audio/SoundscapeResolver.kt` | Pruefen | Doc-Comment-Referenzen |
| `infrastructure/audio/TimerForegroundService.kt` | Rename | `playIntroduction()` → `playAttunement()` |
| `infrastructure/audio/TimerForegroundServiceWrapper.kt` | Rename | `playIntroduction()` → `playAttunement()` |
| `data/repositories/TimerRepositoryImpl.kt` | Pruefen | Referenzen |

### Application / ViewModel Layer

| Datei | Aktion | Beschreibung |
|-------|--------|--------------|
| `presentation/viewmodel/TimerViewModel.kt` | Rename | `resolveIntroDurationSeconds(introductionId)` → `resolveAttunementDurationSeconds(attunementId)`, `introductionCompletionFlow`, alle `introductionId`-Referenzen, Duration-Tracking-Kommentare |
| `presentation/viewmodel/PraxisEditorViewModel.kt` | Rename | `PraxisEditorUiState.introductionId` → `.attunementId`, `.introductionEnabled` → `.attunementEnabled`, `setIntroductionId()` → `setAttunementId()`, `setIntroductionEnabled()` → `setAttunementEnabled()`, `resolveIntroductionName()` → `resolveAttunementName()`, `playIntroductionPreview()` → `playAttunementPreview()` |
| `presentation/viewmodel/TimerUiState.kt` | Rename | Doc-Comment "introduction display name" → "attunement display name" |

### Presentation Layer

| Datei | Aktion | Beschreibung |
|-------|--------|--------------|
| `presentation/ui/timer/SelectIntroductionScreen.kt` | **Rename → `SelectAttunementScreen.kt`** | Dateiname + Composable `SelectIntroductionScreen` → `SelectAttunementScreen`, alle internen Composables: `IntroductionTopBar` → `AttunementTopBar`, `IntroductionContent` → `AttunementContent`, `IntroductionToggleCard` → `AttunementToggleCard`, `IntroductionSelectionCard` → `AttunementSelectionCard`, `IntroductionRow` → `AttunementRow`, `IntroductionDialogs` → `AttunementDialogs`, Parameter-Namen |
| `presentation/ui/timer/SettingsSheet.kt` | Rename | Introduction-Sektions-Referenzen |
| `presentation/ui/timer/PraxisEditorScreen.kt` | Rename | Introduction-Row-Referenzen, Navigation zu `SelectIntroductionScreen` |
| `presentation/ui/timer/TimerScreen.kt` | Pruefen | Referenzen |
| `presentation/ui/timer/TimerFocusScreen.kt` | Pruefen | Doc-Comment-Referenzen |
| `presentation/navigation/NavGraph.kt` | Rename | Route-Name und Composable-Referenz fuer `SelectIntroductionScreen` |

### Lokalisierung

| Datei | Aktion |
|-------|--------|
| `res/values/strings.xml` | Keys: `settings_introduction` → `settings_attunement`, `settings_introduction_content` → `settings_attunement_content`, `accessibility_introduction_*` → `accessibility_attunement_*`, `praxis_editor_introduction_*` → `praxis_editor_attunement_*`, `import_type_attunement_description` Text aendern. Texte: "Introduction" → "Attunement", "Select introduction" → "Select attunement" |
| `res/values-de/strings.xml` | Gleiche Key-Renames. Texte: "Einleitung" → "Einstimmung" (wo noch "Einleitung"). **Achtung:** Accessibility-Labels sagen teilweise schon "Einstimmung" — nach Rename alles konsistent "Einstimmung" |

### Tests (17 Dateien)

Datei-Renames:
- `IntroductionTest.kt` → `AttunementTest.kt`
- `MeditationSettingsIntroductionTest.kt` → `MeditationSettingsAttunementTest.kt`
- `TimerViewModelIntroductionTest.kt` → `TimerViewModelAttunementTest.kt`

Mechanischer Rename in allen 17 Test-Dateien — gleiche Patterns wie Source.

| Test-Datei | Erwartete Aenderungen |
|------------|----------------------|
| `domain/models/IntroductionTest.kt` | Klasse + alle Referenzen |
| `domain/models/MeditationSettingsIntroductionTest.kt` | Klasse + Properties |
| `domain/models/MeditationSettingsTest.kt` | Introduction-Properties |
| `domain/models/PraxisTest.kt` | Introduction-Properties |
| `domain/models/MeditationTimerTest.kt` | Introduction-Referenzen |
| `domain/models/MeditationTimerEventTest.kt` | Introduction-Referenzen |
| `domain/models/MeditationTimerEndGongTest.kt` | Introduction-Referenzen |
| `domain/services/TimerReducerTest.kt` | Alle Effect/Action/State-Referenzen |
| `infrastructure/audio/AttunementResolverTest.kt` | Referenzen |
| `infrastructure/audio/SoundscapeResolverTest.kt` | Referenzen |
| `data/local/PraxisDataStoreTest.kt` | Introduction-Properties |
| `data/repositories/TimerRepositoryImplTest.kt` | Referenzen |
| `presentation/viewmodel/TimerViewModelIntroductionTest.kt` | Klasse + alle Referenzen |
| `presentation/viewmodel/TimerViewModelRegressionTest.kt` | Introduction-Referenzen |
| `presentation/viewmodel/TimerViewModelTestFakes.kt` | Fake-Methoden |
| `presentation/viewmodel/PraxisEditorViewModelTest.kt` | Introduction-Properties |
| `presentation/viewmodel/PraxisEditorViewModelCustomAudioTest.kt` | Introduction-Properties |

## Design-Entscheidungen

### 1. Persistenz-Stabilitaet durch stabile Keys

**Entscheidung:** `MeditationSettings.Keys` behalten ihre String-Werte. `Praxis`-Serialisierung (falls JSON/DataStore) behaelt ebenfalls die alten String-Keys.

```kotlin
// MeditationSettings.Keys
const val ATTUNEMENT_ID = "introductionId"           // alter DataStore-Key bleibt
const val ATTUNEMENT_ENABLED = "introductionEnabled"  // alter DataStore-Key bleibt
```

**Warum:** Identisch zur iOS-Strategie. Kein Migrations-Code noetig, kein Datenverlust. Bestehende User-Einstellungen werden weiterhin korrekt gelesen.

### 2. Bundle-Asset-Pfade bleiben

Audio-Dateinamen (`intro_breath_de`, `intro_breath_en`) und Asset-Verzeichnisse werden NICHT umbenannt. Nur Code-Identifier und UI-Texte.

### 3. Lokalisierungs-Keys komplett umbenennen

Android String-Resources sind nicht persistiert — sie werden zur Laufzeit aufgeloest. Keys koennen bedenkenlos umbenannt werden.

### 4. TestTag-Strings

`testTag("selectIntroduction.toggle.enabled")` → `testTag("selectAttunement.toggle.enabled")`. Test-Tags sind nicht persistiert und koennen frei umbenannt werden. Falls UI-Tests diese Tags referenzieren, dort ebenfalls anpassen.

## Reihenfolge

1. **Domain-Models** — `Introduction.kt` → `Attunement.kt`, `TimerState`, `TimerAction`, `TimerEffect`, `MeditationTimer`, `MeditationSettings`, `Praxis` + zugehoerige Tests → `make test-unit-agent`
2. **Domain-Services** — `AudioServiceProtocol`, `TimerReducer`, `AttunementResolverProtocol`, `TimerForegroundServiceProtocol` + Tests → `make test-unit-agent`
3. **Infrastructure** — `AudioService`, `AttunementResolver`, `SoundscapeResolver`, `TimerForegroundService`, `TimerForegroundServiceWrapper`, `TimerRepositoryImpl` + Tests → `make test-unit-agent`
4. **Application/ViewModel** — `TimerViewModel`, `PraxisEditorViewModel`, `TimerUiState` + Tests → `make test-unit-agent`
5. **Presentation** — `SelectIntroductionScreen` → `SelectAttunementScreen`, `SettingsSheet`, `PraxisEditorScreen`, `TimerScreen`, `TimerFocusScreen`, `NavGraph` → `make test-unit-agent`
6. **Lokalisierung** — Keys und Texte in `strings.xml` (EN) und `strings.xml` (DE)
7. **Dokumentation** — Ticket-Status aktualisieren, Glossar/Audio-System/Timer-State-Machine/DDD/ADR-004 (falls noch nicht in iOS erledigt)
8. **`make check`** — Finaler Durchlauf

## Fachliche Szenarien

Rein mechanischer Rename — keine neuen Szenarien. Alle bestehenden Tests muessen nach Rename weiterhin gruen sein.

### Persistenz-Szenario (implizit durch stabile Keys)

- Gegeben: User hat eine Einstimmung konfiguriert (gespeicherte Praxis mit `introductionId = "breath"`)
  Wenn: App-Update mit Rename installiert wird
  Dann: Einstimmung ist weiterhin konfiguriert (DataStore liest ueber stabile Key-Strings)

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| Vergessene Referenz → Compile-Error | `make check` am Ende. Kotlin-Compiler findet alle Referenzen. |
| Lokalisierungs-Key vergessen → leerer Text / Crash | Grep nach alten Keys (`introduction`) nach Rename — darf keine Treffer in `.kt`-Dateien geben |
| Asset-Pfade versehentlich umbenannt → Audio bricht | Plan explizit: `intro_breath_*` Asset-Namen bleiben |
| NavGraph-Route vergessen → Navigation bricht | Compile-Error wenn Composable-Funktion nicht gefunden |
| detekt LongMethod nach Rename | Composable-Grenzwerte pruefen — Rename aendert keine Zeilenanzahl |

## Offene Fragen

Keine — Ticket, iOS-Plan und Android-Code sind eindeutig. Rein mechanischer Rename.
