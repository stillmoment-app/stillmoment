# Implementierungsplan: shared-088 (iOS)

Ticket: [shared-088](../shared/shared-088-einstimmung-feature-entfernen.md)
Erstellt: 2026-05-04
Plattform: iOS

---

## Ziel

Das Einstimmung-Feature (Attunement) wird vollstaendig aus dem iOS-Timer entfernt:
Domain-Phase, ViewModel-Logik, UI-Karten/Detail-Views, Audio-Resolver, Persistenz,
gebuendelte Audio-Dateien, Lokalisierung. Bestehende Settings/Imports werden bei
der ersten Migration stillschweigend bereinigt.

Architekturziel-State-Machine nach Entfernung:
```
idle → preparation → startGong → running → endGong → completed
```
(`attunement` als optionale Phase entfaellt komplett.)

---

## Betroffene Codestellen

### Domain (entfernen oder reduzieren)

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `Domain/Models/Attunement.swift` | Loeschen | Einziger gebauter Attunement-Typ (`Attunement.breath`). |
| `Domain/Models/ResolvedAttunement.swift` | Loeschen | Abstraktion built-in + custom — wird nicht mehr gebraucht. |
| `Domain/Services/AttunementResolverProtocol.swift` | Loeschen | Protocol fuer den Resolver. |
| `Domain/Models/TimerState.swift` | Edit | `case attunement` und Doku entfernen. State-Chart-Kommentar anpassen. |
| `Domain/Models/TimerAction.swift` | Edit | `case attunementFinished` entfernen. |
| `Domain/Models/TimerEffect.swift` | Edit | `playAttunement`, `stopAttunement`, `beginAttunementPhase`, `endAttunementPhase` entfernen. |
| `Domain/Models/MeditationTimer.swift` | Edit | `tickAttunement()`, `endAttunement()`, `silentPhaseStartRemaining`-Property entfernen. `tick()`-Switch und `silentPhaseStartSeconds` (Interval-Baseline) auf `totalSeconds` vereinfachen — ohne Attunement-Phase ist `silentPhaseStartRemaining` immer `nil`. |
| `Domain/Models/MeditationSettings.swift` | Edit | `attunementId`, `attunementEnabled`, `customAttunementDurationSeconds`, `activeAttunementId`, `minimumDurationMinutes`, alle `minimumDuration(...)` und `validateDuration(...)`-Overloads mit Attunement-Parametern entfernen. `Keys.attunementId`/`attunementEnabled` entfernen. `validateDuration(_:)` reduziert sich auf `min(max(minutes, 1), 60)`. |
| `Domain/Models/Praxis.swift` | Edit | `attunementId`, `attunementEnabled`, beide CodingKeys, `withAttunementId`, `withAttunementEnabled`, init-Parameter, `init(from:)`-Decodierung, `init(migratingFrom:)`-Mapping und `toMeditationSettings(customAttunementDurationSeconds:)`-Parameter entfernen. |
| `Domain/Models/CustomAudioFile.swift` | Edit | `enum CustomAudioType` ohne `case attunement`. Wenn nur `.soundscape` uebrig bleibt, `type`-Feld trotzdem behalten (Persistenz-Format kompatibel halten). |
| `Domain/Models/ImportAudioType.swift` | Edit | `case attunement` und `customAudioType`-Mapping `.attunement → .attunement` entfernen. |
| `Domain/Services/AudioServiceProtocol.swift` | Edit | `attunementCompletionPublisher`, `playAttunement(filename:)`, `stopAttunement()`, `playAttunementPreview(attunementId:)`, `stopAttunementPreview()` entfernen. |
| `Domain/Services/TimerServiceProtocol.swift` | Edit | `beginAttunementPhase()`, `endAttunementPhase()` entfernen. |
| `Domain/Services/TimerReducer.swift` | Edit | `attunementResolver`-Parameter, `case .attunementFinished`, `reduceAttunementFinished`, Attunement-Pfad in `reduceStartGongFinished`, `hasActiveAttunement`-Helper, `case .attunement` in `reduceResetPressed`/`reduceTimerCompleted` entfernen. `reduceStartGongFinished` reduziert sich auf den No-Attunement-Pfad. |

### Application (vereinfachen)

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `Application/ViewModels/TimerViewModel.swift` | Edit | `attunementResolver`-Parameter (init), gespeicherte Property, `resolveAttunementDurationSeconds`, `executePlayAttunement`, alle attunement-bezogenen `executeEffect`-Cases, `attunementCompletionPublisher`-Subscription, Min-Duration-Bindung auf `\.attunementId`, `minutesBeforeAttunement`-Restoration entfernen. `selectedMinutes`-Clamp wird konstant 1...60. |
| `Application/ViewModels/TimerViewModel+ConfigurationDescription.swift` | Edit | `attunementDescription`, `attunementCardLabel`, `attunementCardIsOff` entfernen. |
| `Application/ViewModels/TimerViewModel+Preview.swift` | Edit | `availableAttunements`-Stub und `case .attunement` aus dem Stub-State entfernen. |
| `Application/ViewModels/PraxisEditorViewModel.swift` | Edit | `attunementId`/`attunementEnabled`-Published Properties, `customAttunements`, `availableAttunements`, `playAttunementPreview`, `setAttunementEnabled`, Attunement-Branch in `onCustomAudioImported` und `deleteCustomAudio`, `usageCount`-Mapping, $attunementId/$attunementEnabled-Bindung, `praxis.attunementId`/`praxis.attunementEnabled`-Lesen/Schreiben entfernen. |
| `Application/FileOpenHandler.swift` | Edit | `case .attunement` in `performTypeBasedImport`, `checkDuplicate`, `pendingCustomAudioImport`-Update entfernen — danach gibt es nur noch `.guidedMeditation` und `.soundscape` als Routen. |

### Infrastructure (entfernen oder reduzieren)

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `Infrastructure/Services/AttunementResolver.swift` | Loeschen | Komplette Datei. |
| `Infrastructure/Services/AudioService+Attunement.swift` | Loeschen | Komplette Datei + `AttunementPlayerDelegate`. |
| `Infrastructure/Services/AudioService.swift` | Edit | `attunementCompletionSubject`, `attunementPlayerDelegate`, `attunementPlayer`, `attunementPreviewPlayer`-Properties, Init-Setup, Cleanup in `deactivateTimerSession()` entfernen. `attunementCompletionPublisher` aus dem Protokoll-Conformance ebenfalls. |
| `Infrastructure/Services/TimerService.swift` | Edit | `beginAttunementPhase()`, `endAttunementPhase()` entfernen. |
| `Infrastructure/Services/UserDefaultsTimerSettingsRepository.swift` | Edit | `loadAttunementEnabled()`, `attunementId/attunementEnabled` aus `load()` entfernen. |
| `Infrastructure/Services/UserDefaultsPraxisRepository.swift` | Edit | Migrations-Punkt fuer Attunement-Bereinigung erweitern (siehe Migration-Abschnitt). |
| `Infrastructure/Services/CustomAudioRepository.swift` | Edit | Falls `CustomAudioType.attunement` ganz entfernt werden soll: `getDirectory(for:)`, `storageKey(for:)`, `delete(id:)`-Loop, `findFile(byId:)` reduzieren. **Alternative (siehe Design-Entscheidung 2):** Enum-Case behalten und nur die Aufrufer entfernen, dann beim ersten Start einmalig den Attunement-Storage-Slot leeren. |

### Presentation (entfernen oder reduzieren)

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `Presentation/Views/Timer/AttunementSelectionView.swift` | Loeschen | Komplette Datei. |
| `Presentation/Views/Timer/SettingDestination.swift` | Edit | `case attunement` entfernen. Verbleibend: `preparation`, `background`, `gong`, `interval`. |
| `Presentation/Views/Timer/SettingDetailRoot.swift` | Edit | Routing-Branch fuer `.attunement` entfernen. |
| `Presentation/Views/Timer/SettingsView.swift` | Edit | `availableAttunements`-Parameter, `attunementSection`, `if !availableAttunements.isEmpty` entfernen. (Diese View wird ueber Detail-Routes nicht mehr direkt zur Attunement-Auswahl aufgerufen.) |
| `Presentation/Views/Timer/TimerView.swift` | Edit | Im `settingCardsGrid`: `attunement`-Item entfernen. Pending-Custom-Audio-Routing (`pending.type == .soundscape ? .background : .attunement`) reduziert sich auf reines `.background`. |
| `Presentation/Views/Timer/Components/SettingCardsGrid.swift` | Edit | `attunement`-Property aus Init und Body entfernen. Layout: 4 Karten — bei 3+1 oder 2+2-Layout entscheiden (siehe Design-Entscheidung 1). |
| `Presentation/Views/Timer/Components/SettingCard.swift` | Edit | Nur Preview-Beispiel mit "Einstimmung" entfernen. |
| `Presentation/Views/Shared/ImportTypeSelectionView.swift` | Edit | `ImportTypeRow` fuer Attunement entfernen. Sheet enthaelt nur noch zwei Optionen + Cancel. |

### Resources

| Pfad | Aktion |
|------|--------|
| `ios/StillMoment/Resources/IntroductionAudio/intro-breath-de.mp3` | Loeschen |
| `ios/StillMoment/Resources/IntroductionAudio/intro-breath-en.mp3` | Loeschen |
| `ios/StillMoment/Resources/IntroductionAudio/` (Ordner) | Loeschen |

### Lokalisierung

`ios/StillMoment/Resources/de.lproj/Localizable.strings` und `en.lproj/Localizable.strings` —
folgende Keys entfernen (DE+EN identisch):

- `attunement.breath.name`
- `settings.attunement.header`
- `settings.attunement.title`
- `settings.attunement.none`
- `settings.attunement.option`
- `settings.attunement.footer`
- `accessibility.attunement`
- `accessibility.attunement.hint`
- `accessibility.attunement.toggle.hint`
- `praxis.editor.attunement.row`
- `praxis.editor.attunement.title`
- `settings.card.value.attunement.off`
- `settings.card.label.attunement`
- `custom.audio.empty.attunements`
- `custom.audio.section.myAttunements`
- `custom.audio.accessibility.importButton.attunement`
- `import.type.attunement`
- `import.type.attunement.description`

### Tests

| Datei | Aktion |
|-------|--------|
| `StillMomentTests/Domain/AttunementTests.swift` | Loeschen |
| `StillMomentTests/Domain/TimerReducerAttunementTests.swift` | Loeschen |
| `StillMomentTests/Domain/MeditationSettingsTests+Attunement.swift` | Loeschen |
| `StillMomentTests/Domain/MeditationTimerAttunementTests.swift` | Loeschen |
| `StillMomentTests/Infrastructure/AttunementResolverTests.swift` | Loeschen |
| `StillMomentTests/AudioServiceAttunementTests.swift` | Loeschen |
| `StillMomentTests/AudioServicePreviewSessionTests.swift` | Pruefen — falls reine Attunement-Preview-Tests, loeschen; sonst entsprechende Faelle entfernen. |
| `StillMomentTests/Mocks/MockAttunementResolver.swift` | Loeschen |
| `StillMomentTests/Mocks/MockTimerService.swift` | Edit — alle attunement-bezogenen Properties/Methoden entfernen. |
| `StillMomentTests/Mocks/MockCustomAudioRepository.swift` | Edit — `stubbedAttunements` entfernen, `loadAll(type:)` reduziert. |
| `StillMomentTests/Domain/TimerReducerTests.swift` | Edit — `MockAttunementResolver`-Init und Attunement-Faelle entfernen. |
| `StillMomentTests/Domain/TimerReducerStateTransitionTests.swift` | Edit — analog. |
| `StillMomentTests/Domain/TimerReducerIntegrationTests.swift` | Edit — analog. |
| `StillMomentTests/Domain/TimerReducerEndGongTests.swift` | Edit — `.stopAttunement`-Erwartungen entfernen. |
| `StillMomentTests/Domain/IntervalModeTests.swift` | Edit — `MockAttunementResolver` entfernen. |
| `StillMomentTests/Domain/PraxisTests.swift` | Edit — Attunement-Felder/Builder-Tests entfernen, Codable-Migration-Tests fuer alte JSON pruefen. |
| `StillMomentTests/PraxisEditor/PraxisEditorViewModelTests.swift` | Edit — Attunement-bezogene Tests loeschen. |
| `StillMomentTests/PraxisEditor/PraxisEditorViewModelCustomAudioTests.swift` | Edit — Attunement-Branch entfernen. |
| `StillMomentTests/TimerViewModel/TimerViewModelRegressionTests.swift` | Edit — Attunement-Regression-Tests entfernen. |
| `StillMomentTests/Infrastructure/TimerSettingsRepositoryTests.swift` | Edit — Attunement-Load-Cases entfernen. |
| `StillMomentTests/Infrastructure/PraxisRepositoryTests.swift` | Edit — Migration-Tests anpassen (alte JSON mit `introductionId` muss ohne Crash geladen werden). |
| `StillMomentUITests/LibraryFlowUITests.swift` | Edit — `"timer.card.attunement"` aus der Card-Liste entfernen. |
| `StillMomentTests/Domain/ImportAudioTypeTests.swift` | Edit — Attunement-Case-Test entfernen. |

### Dokumentation

| Datei | Aktion |
|-------|--------|
| `dev-docs/architecture/timer-state-machine.md` | Edit — Attunement-Knoten + Transitionen aus Mermaid-Chart und Tabellen entfernen. |
| `dev-docs/architecture/ddd.md` | Edit — Beispiel-Code (`playAttunement`, `stopAttunement`, `attunementFinished`) und State-Chart entfernen. |
| `dev-docs/reference/glossary.md` | Edit — `Attunement`, `AttunementResolver`, `attunement`-State-Eintrag entfernen. |
| `dev-docs/architecture/audio-system.md` | Edit pruefen — Attunement-Audio-Pfade beschreiben? Falls ja anpassen. |
| `dev-docs/architecture/timer-incremental-refactoring.md` | Edit — Attunement-Erwaehnung in Zeile 53 entfernen oder neutralisieren. |
| `ios/CLAUDE.md` | Edit — Beispiel `attunementResolver: AttunementResolverProtocol` (Zeile ~143) ersetzen oder entfernen. |
| `CHANGELOG.md` | Edit — Eintrag unter "Unreleased": "Einstimmung-Feature entfernt" mit Verweis auf shared-088. |

---

## API-Recherche

Keine neuen Frameworks/APIs noetig. Alle Operationen sind Reduktionen bestehender Strukturen.

Migration arbeitet mit:
- `UserDefaults.removeObject(forKey:)` — vorhanden seit iOS 2.
- `FileManager.removeItem(at:)` — vorhanden, wirft, ignoriert wenn Datei nicht existiert via `try?`.
- `JSONDecoder` mit `decodeIfPresent` — bereits in `Praxis.init(from:)` etabliert.
- `Bundle.main.url(forResource:)` — Bundle-Files werden ueber das Xcode-Target verwaltet (FileSystemSynchronizedRootGroup), Loeschen aus dem Verzeichnis reicht aus.

---

## Design-Entscheidungen

### 1. Layout der Setting-Cards-Grid (4 Karten statt 5)

**Entscheidung:** 2+2-Layout (Vorbereitung · Hintergrund / Gong · Intervall).
Card-Maße und -Hoehen bleiben identisch zu heute, nur eine Reihe weniger.

**Hinweis:** Das Setting-Card-Layout wird im naechsten Ticket ohnehin ersetzt —
hier minimal-invasiv arbeiten, keine Schoenheits-OPs am Grid.

### 2. `CustomAudioType.attunement` ganz loeschen oder Case behalten?

**Trade-off:**
- Loeschen: konsequenter, weniger toter Code. Pflicht zur Datenmigration der `customAudioFiles_attunement`-UserDefaults-Daten und des `Application Support/CustomAudio/attunements/`-Verzeichnisses, sonst werden sie nie aufgeraeumt.
- Behalten: ein Enum-Case bleibt im Modell, ohne UI/Logik dahinter — toter Pfad. Migration trotzdem noetig (Userwerte unsichtbar, koennen nicht ausgewaehlt werden, wuerden aber Speicher belegen).

**Entscheidung:** Komplett loeschen. Migration entfernt UserDefaults-Eintrag und das Verzeichnis. Konsistent mit dem Ticket-Hinweis "tote Code-Pfade vermeiden".

### 3. `ImportAudioType` — Sheet behalten?

**Entscheidung:** Sheet bleibt mit zwei Optionen (`.guidedMeditation`, `.soundscape`).
Klangkulisse-Import via Share-Sheet ist ein legitimer Pfad und das Sheet kostet
in der reduzierten Form nichts. `customAudioType` mappt nur noch `.soundscape → .soundscape`,
das Enum bleibt erhalten.

### 4. State-Machine-Schreiben in `MeditationTimer`

**Beobachtung:** `silentPhaseStartRemaining` existiert nur, damit Interval-Gongs ihre Baseline ab Start der stillen Phase berechnen — und das war frueher noetig, weil Attunement Zeit verbrauchte. Ohne Attunement startet die stille Phase mit `totalSeconds`.

**Entscheidung:** Property entfernen. `silentPhaseStartSeconds` (computed property) gibt direkt `totalSeconds` zurueck. `endAttunement()` entfaellt komplett.

---

## Migration

**Ziel:** Beim ersten App-Start nach Update wird der Attunement-Datenbestand stillschweigend, einmalig und idempotent bereinigt. Kein Dialog, kein Hinweis.

**Wo:** Neuer `AttunementCleanupMigration` (Infrastructure), aufgerufen einmalig in `StillMomentApp` beim App-Launch (vor `UserDefaultsPraxisRepository.load()`), oder integriert in `UserDefaultsPraxisRepository.load()` als zusaetzlicher Migrationsschritt.

**Was migriert werden muss:**

1. **Praxis-JSON (`currentPraxis`-Key):** Bei vorhandenem Eintrag dekodieren + neu serialisieren ohne `introductionId`/`introductionEnabled`. Codable ignoriert die Keys nach Entfernung der CodingKeys automatisch — das alte JSON laedt sauber, die neuen Felder fehlen einfach. Re-Save schreibt ohne sie zurueck. **Praxis-Codable-Migration**: `init(from:)` darf nicht crashen, wenn die Keys fehlen (sind ja schon mit `decodeIfPresent` markiert). Nach Removal sind die Keys einfach nicht mehr Teil von `CodingKeys`, ergo werden sie ignoriert.
2. **UserDefaults legacy-Keys:** `removeObject(forKey: "introductionId")`, `removeObject(forKey: "introductionEnabled")`.
3. **Custom-Attunement-UserDefaults:** `removeObject(forKey: "customAudioFiles_attunement")`.
4. **Custom-Attunement-Dateien:** `Application Support/CustomAudio/attunements/` rekursiv loeschen (`fileManager.removeItem(at:)`).
5. **Idempotenz-Marker:** `UserDefaults.set(true, forKey: "stillmoment.migration.attunementRemoved.v1")` — beim naechsten Start wird die Migration uebersprungen.

**Reihenfolge (App-Launch):**
```
1. AttunementCleanupMigration.runIfNeeded()       — bereinigt UserDefaults + Files
2. UserDefaultsPraxisRepository.load()            — laedt jetzt sauberes JSON
3. CustomAudioRepository.loadAll(type: .soundscape) — kein .attunement mehr
```

**Logging:** `Logger.infrastructure.info("Attunement cleanup migration completed", metadata: ["filesDeleted": N, "userDefaultKeysCleared": M])`.

---

## Refactorings (nicht-trivial)

1. **`MeditationSettings.validateDuration` und `minimumDuration`** — werden auf eine schlanke Form reduziert. Risiko: niedrig. Tests in `MeditationSettingsTests` pruefen vorher.
2. **`TimerReducer.reduce`** — `attunementResolver`-Parameter entfaellt. Alle Aufrufer (TimerViewModel + 4+ Test-Dateien) muessen aktualisiert werden. Risiko: mittel. Build-Fehler decken Aufrufer auf.
3. **`MeditationTimer` Builder/Init** — `silentPhaseStartRemaining` entfernen. Init-Kette in 4 internen Builder-Methoden anpassen. Risiko: mittel. Tests fangen Regressionen.
4. **`Praxis.init(from:)` Codable-Compat** — alte JSON darf nicht crashen. Tests in `PraxisRepositoryTests` mit Fixtures alter Form ergaenzen. Risiko: mittel — produktive Daten betroffen.
5. **`AudioService` Cleanup** — Init/Deactivate-Pfade kuerzen. Risiko: niedrig.

---

## Fachliche Szenarien

### AK-1: Timer-Konfiguration zeigt keine Einstimmung mehr

- Gegeben: Frische Installation, App-Start
  Wenn: User oeffnet Timer-Tab
  Dann: Setting-Cards zeigen 4 Karten (Vorbereitung, Hintergrund, Gong, Intervall) — keine Einstimmungs-Karte

- Gegeben: Timer-Konfiguration ist offen
  Wenn: User sucht im UI nach Einstimmung
  Dann: Es gibt keinen Tap-Pfad mehr zu einem Attunement-Auswahl-Screen

### AK-2: Datei-Import bietet keine Einstimmung mehr

- Gegeben: User teilt eine MP3-Datei mit der App
  Wenn: Auswahl-Sheet erscheint
  Dann: Sheet zeigt nur "Gefuehrte Meditation", "Klangkulisse" und "Abbrechen" — keine "Einstimmung"-Option

### AK-3: Timer-State-Machine hat keine Attunement-Phase

- Gegeben: Timer wird mit beliebiger Konfiguration gestartet
  Wenn: Vorbereitung endet → Start-Gong endet
  Dann: Timer wechselt direkt nach `running` (keine `attunement`-Phase mehr durchlaufen)

- Gegeben: Timer reset waehrend `running`
  Wenn: User drueckt Reset
  Dann: Effekte enthalten kein `stopAttunement` mehr

### AK-4: Timer-Zeitberechnung ohne Attunement

- Gegeben: User waehlt 1 Minute im Timer-Picker
  Wenn: Vor dem Update war 1 Min wegen Attunement nicht moeglich
  Dann: Min-Duration ist konstant 1 Minute, unabhaengig von vorherigen Settings

- Gegeben: Interval-Gongs alle 2 Min, 10 Min Timer
  Wenn: Timer laeuft
  Dann: Gongs feuern bei 2:00, 4:00, 6:00, 8:00 — Baseline ist `totalSeconds`, nicht `silentPhaseStartRemaining`

### AK-5: Update mit konfigurierter Einstimmung crasht nicht

- Gegeben: Frueheres App-Build hat `introductionId="atemuebung"` und `introductionEnabled=true` in UserDefaults gespeichert sowie eine importierte Custom-Einstimmung
  Wenn: User aktualisiert auf neue Version und startet die App
  Dann: App startet ohne Crash, Timer-Konfig zeigt keine Einstimmung, importierte Datei und Eintrag sind weg, kein Migrations-Dialog

- Gegeben: Praxis-JSON in UserDefaults enthaelt `introductionId`-Feld
  Wenn: Repository laedt Praxis
  Dann: Praxis wird ohne Crash dekodiert, neue Praxis-Felder fehlen einfach, nach erstem `save()` ist das JSON sauber

### AK-6: Custom-Attunement-Dateien werden geloescht

- Gegeben: `Application Support/CustomAudio/attunements/` enthaelt drei MP3s
  Wenn: Migration laeuft beim ersten Start
  Dann: Verzeichnis ist leer oder geloescht, `customAudioFiles_attunement`-UserDefaults-Key existiert nicht mehr

- Gegeben: Migration wurde bereits einmal ausgefuehrt (Marker gesetzt)
  Wenn: User startet App erneut
  Dann: Migration laeuft nicht erneut (idempotent)

### AK-7: Lokalisierungs-Keys sind weg

- Gegeben: Build mit aktiven Lokalisierungs-Pruefungen (`make check`)
  Wenn: Lokalisierungs-Diff lauft
  Dann: Keine `attunement.*`-, `settings.attunement.*`-, `praxis.editor.attunement.*`-, `import.type.attunement.*`-Keys mehr in DE und EN

### AK-8: Bundle-Audio-Dateien sind weg

- Gegeben: Build-Output
  Wenn: `.app`-Bundle inspiziert wird
  Dann: Kein `IntroductionAudio/`-Verzeichnis, keine `intro-breath-de.mp3`/`intro-breath-en.mp3`

---

## Reihenfolge der Implementierung

Strategie: Bottom-up vom Domain-Layer zum UI, Tests vor Production-Code (TDD-Loop pro Schicht).
Migration als letzten Schritt nach den Code-Changes — sonst muessten Tests gegen
"halbe" Zustaende gefahren werden.

1. **Domain — Modelle** (AK-3, AK-4)
   - Tests in `MeditationSettingsTests`, `MeditationTimerEventTests`, `PraxisTests` rot machen durch Entfernung der Attunement-Faelle
   - `TimerState`, `TimerAction`, `TimerEffect` reduzieren
   - `MeditationSettings` Felder + Validierung reduzieren
   - `Praxis` Felder + Codable + Builder reduzieren (Codable-Compat-Test fuer alte JSON ergaenzen!)
   - `MeditationTimer` `silentPhaseStartRemaining` + `endAttunement()` entfernen
   - `CustomAudioFile`/`CustomAudioType`, `ImportAudioType` reduzieren
2. **Domain — Services** (AK-3)
   - `AudioServiceProtocol`, `TimerServiceProtocol` reduzieren
   - `TimerReducer` Attunement-Branch entfernen — Aufrufer-Signatur aendert sich
3. **Infrastructure** (AK-3, AK-5, AK-6)
   - `AttunementResolver.swift`, `AudioService+Attunement.swift` loeschen
   - `AudioService` Properties/Cleanup reduzieren
   - `TimerService` Phase-Methoden entfernen
   - `UserDefaultsTimerSettingsRepository` Attunement-Load entfernen
   - `CustomAudioRepository` `getDirectory(.attunement)`/`storageKey(.attunement)` entfernen
   - `AttunementCleanupMigration` schreiben + im App-Start-Pfad einbauen
4. **Application** (AK-1)
   - `TimerViewModel` Attunement entfernen
   - `TimerViewModel+ConfigurationDescription`, `TimerViewModel+Preview` reduzieren
   - `PraxisEditorViewModel` Attunement entfernen
   - `FileOpenHandler` Attunement-Routing entfernen
5. **Presentation** (AK-1, AK-2)
   - `AttunementSelectionView.swift` loeschen
   - `SettingDestination`, `SettingDetailRoot` reduzieren
   - `SettingCardsGrid`, `TimerView` (4 Karten)
   - `SettingsView` Attunement-Section entfernen
   - `ImportTypeSelectionView` zwei Optionen
   - `SettingCard.swift` Preview-Beispiel
6. **Resources & Lokalisierung** (AK-7, AK-8)
   - `Resources/IntroductionAudio/` loeschen
   - 18 Localizable-Keys in DE+EN entfernen
7. **Mocks + Tests** (parallel, nach jedem Schritt rot/gruen ueberpruefen)
   - `MockAttunementResolver.swift` loeschen
   - `MockTimerService`, `MockCustomAudioRepository` reduzieren
   - Test-Dateien loeschen oder anpassen (siehe Liste oben)
   - UI-Test in `LibraryFlowUITests` aktualisieren
8. **Dokumentation** (Pflicht-Akzeptanzkriterien)
   - Glossary, State-Chart-MD, DDD-Doku, ios/CLAUDE.md, CHANGELOG.md
9. **Manueller Test** auf Simulator laut Ticket-Manual-Test

---

## Vorbereitung

Keine externen Schritte. Reine Code-Reduktion — Xcode-Target benutzt FileSystemSynchronizedRootGroup,
geloeschte Dateien fallen automatisch raus.

---

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| Praxis-JSON in `currentPraxis` enthaelt `introductionId` und Decoder crasht beim Laden | `init(from:)`-Migration-Test mit alter JSON-Fixture in `PraxisRepositoryTests` ergaenzen — Decode darf nicht crashen, fehlende Felder werden ignoriert |
| `silentPhaseStartRemaining`-Removal bricht Interval-Gong-Berechnung | `MeditationTimerEventTests` mit Interval-Gongs muss vor und nach Refactor gruen sein. Baseline = `totalSeconds`, identisch zum bisherigen Verhalten ohne Attunement |
| Custom-Audio-Dateien werden nicht geloescht (Permissions, Pfad falsch) | Migration nutzt `try?` — fehlt eine Datei, ist das ok. Verzeichnis-Loeschung idempotent |
| `TimerReducer.reduce`-Signaturaenderung uebersieht Test-Aufrufer | Compiler erzwingt Anpassung. Vor Commit `make test-unit-agent` durchlaufen lassen |
| `validateDuration` ohne Attunement-Parameter bricht UI-Picker-Clamp | `selectedMinutes` clamped auf 1...60. Tests in `MeditationSettingsTests` decken Min-Duration ab |
| Alte UI-Test-Identifier `praxis.attunement.toggle`, `praxis.attunement.<id>` werden in CI nicht gefunden | UI-Tests aktualisieren bevor entfernen — UITests laufen nicht in `make test-unit`, also vor PR explizit ausfuehren |

---

## Geklaerte Entscheidungen

- **Card-Layout (4 Karten):** 2+2-Layout, minimal-invasiv. Folge-Ticket ersetzt das Layout ohnehin.
- **ImportTypeSelectionView:** Sheet bleibt mit zwei Optionen (Geführte Meditation, Klangkulisse).
- **Migration-Marker-Key:** `stillmoment.migration.attunementRemoved.v1`.
- **Android:** Eigener Plan unter `dev-docs/tickets/plans/shared-088-android.md`. iOS zuerst implementieren, Android danach.
