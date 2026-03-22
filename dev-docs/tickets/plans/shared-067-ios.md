# Implementierungsplan: shared-067 (iOS)

Ticket: [shared-067](../shared/shared-067-rename-introduction-attunement.md)
Erstellt: 2026-03-22

## Uebersicht

Rein mechanischer Rename: `Introduction` → `Attunement` / `Einleitung` → `Einstimmung` in Code, UI-Texten und Lokalisierung. Keine Logik-Aenderungen. Der Rename ist breit (~35 Source-Dateien, ~23 Test-Dateien), aber pro Datei trivial.

## Betroffene Codestellen

### Domain Layer

| Datei | Aktion | Beschreibung |
|-------|--------|--------------|
| `Domain/Models/Introduction.swift` | **Rename → `Attunement.swift`** | Struct `Introduction` → `Attunement`, alle static Members (`allIntroductions` → `allAttunements`, `hasAvailableIntroductions` → `hasAvailableAttunements` etc.) |
| `Domain/Models/TimerState.swift` | Rename Case | `.introduction` → `.attunement` |
| `Domain/Models/TimerAction.swift` | Rename Case | `.introductionFinished` → `.attunementFinished` |
| `Domain/Models/TimerEffect.swift` | Rename Cases | `.playIntroduction` → `.playAttunement`, `.stopIntroduction` → `.stopAttunement`, `.beginIntroductionPhase` → `.beginAttunementPhase`, `.endIntroductionPhase` → `.endAttunementPhase` |
| `Domain/Models/MeditationTimer.swift` | Rename Methoden | `tickIntroduction()` → `tickAttunement()`, `endIntroduction()` → `endAttunement()`, `silentPhaseStartRemaining` Kommentare |
| `Domain/Models/MeditationTimer+Display.swift` | Rename Referenzen | `.introduction` Case-Referenzen |
| `Domain/Models/TimerEvent.swift` | Kommentare | Evtl. Referenzen auf "introduction" |
| `Domain/Models/MeditationSettings.swift` | Rename Properties | `introductionId` → `attunementId`, `introductionEnabled` → `attunementEnabled`, `activeIntroductionId` → `activeAttunementId`, `customIntroDurationSeconds` → `customAttunementDurationSeconds`. **Keys.introductionId/introductionEnabled: String-Werte NICHT aendern** (Legacy-Persistenz) |
| `Domain/Models/Praxis.swift` | Rename Properties | `introductionId` → `attunementId`, `introductionEnabled` → `attunementEnabled`. Builder: `withIntroductionId` → `withAttunementId`, `withIntroductionEnabled` → `withAttunementEnabled`. **CodingKeys: String-Werte NICHT aendern** (`"introductionId"`, `"introductionEnabled"` bleiben) |
| `Domain/Models/ResolvedAttunement.swift` | Pruefen | Evtl. schon umbenannt — pruefen ob "introduction" Referenzen existieren |
| `Domain/Models/ImportAudioType.swift` | Pruefen | Referenzen auf "introduction" |
| `Domain/Models/CustomAudioFile.swift` | Pruefen | Referenzen auf "introduction" |
| `Domain/Services/AudioServiceProtocol.swift` | Rename | `introductionCompletionPublisher` → `attunementCompletionPublisher`, `playIntroduction` → `playAttunement`, `stopIntroduction` → `stopAttunement`, `playIntroductionPreview` → `playAttunementPreview`, `stopIntroductionPreview` → `stopAttunementPreview` |
| `Domain/Services/TimerServiceProtocol.swift` | Rename | Methoden die "introduction" enthalten |
| `Domain/Services/TimerReducer.swift` | Rename | Alle `.introduction`/`.introductionFinished`/`.playIntroduction` etc. Referenzen |
| `Domain/Services/AttunementResolverProtocol.swift` | Pruefen | Evtl. schon umbenannt |
| `Domain/Services/CustomAudioRepositoryProtocol.swift` | Pruefen | Referenzen |

### Infrastructure Layer

| Datei | Aktion | Beschreibung |
|-------|--------|--------------|
| `Infrastructure/Services/AudioService.swift` | Rename | `introductionPlayer`, `introductionPreviewPlayer`, `introductionPlayerDelegate`, `introductionCompletionSubject` — alle Properties und Methoden |
| `Infrastructure/Services/AudioService+Introduction.swift` | **Rename → `AudioService+Attunement.swift`** | Dateiname + alle Methoden/Klassen (`IntroductionPlayerDelegate` → `AttunementPlayerDelegate`) + `"IntroductionAudio"` Bundle-Subdirectory **NICHT** umbenennen |
| `Infrastructure/Services/AudioService+MeditationPreview.swift` | Pruefen | Evtl. Introduction-Referenzen |
| `Infrastructure/Services/TimerService.swift` | Rename | `endIntroduction`-Methode und Referenzen |
| `Infrastructure/Services/AttunementResolver.swift` | Pruefen | Evtl. schon umbenannt |
| `Infrastructure/Services/UserDefaultsTimerSettingsRepository.swift` | Rename | Swift-Properties umbenennen. **Key-Strings NICHT aendern** (liest `MeditationSettings.Keys.introductionId` — dieser Key bleibt `"introductionId"`) |
| `Infrastructure/Services/GongPlayerDelegate.swift` | Pruefen | Evtl. Referenzen |

### Application Layer

| Datei | Aktion | Beschreibung |
|-------|--------|--------------|
| `Application/ViewModels/TimerViewModel.swift` | Rename | Alle introduction-Referenzen in Properties, Methoden, Bindings |
| `Application/ViewModels/TimerViewModel+Preview.swift` | Rename | Introduction-Preview-Methoden |
| `Application/ViewModels/TimerViewModel+ConfigurationDescription.swift` | Rename | Description-Text-Referenzen |
| `Application/ViewModels/PraxisEditorViewModel.swift` | Rename | Introduction-Properties und -Methoden |

### Presentation Layer

| Datei | Aktion | Beschreibung |
|-------|--------|--------------|
| `Presentation/Views/Timer/IntroductionSelectionView.swift` | **Rename → `AttunementSelectionView.swift`** | Dateiname + View-Struct umbenennen |
| `Presentation/Views/Timer/SettingsView.swift` | Rename | Introduction-Sektions-Referenzen |
| `Presentation/Views/Timer/TimerView.swift` | Rename | Evtl. State-Referenzen |
| `Presentation/Views/Timer/PraxisEditorView.swift` | Rename | Introduction-Row-Referenzen |
| `Presentation/Views/Shared/ImportAudioButton.swift` | Rename | Import-Type-Referenzen |

### Lokalisierung

| Datei | Aktion |
|-------|--------|
| `Resources/en.lproj/Localizable.strings` | Keys: `introduction.*` → `attunement.*`, `settings.introduction.*` → `settings.attunement.*`, `accessibility.introduction.*` → `accessibility.attunement.*`, `praxis.editor.introduction.*` → `praxis.editor.attunement.*`. Texte: "Introduction" → "Attunement", "Use as introduction" → "Use as attunement" |
| `Resources/de.lproj/Localizable.strings` | Keys: gleich wie EN. Texte: "Einleitung" → "Einstimmung" (teilweise schon "Einstimmung" im praxis.editor — normalisieren) |

### Tests (~23 Dateien)

Alle Test-Dateien folgen dem Source-Rename mechanisch. Datei-Renames:
- `IntroductionTests.swift` → `AttunementTests.swift`
- `MeditationSettingsTests+Introduction.swift` → `MeditationSettingsTests+Attunement.swift`
- `TimerReducerIntroductionTests.swift` → `TimerReducerAttunementTests.swift`
- `AudioServiceIntroductionTests.swift` → `AudioServiceAttunementTests.swift`
- `MeditationTimerIntroductionTests.swift` → `MeditationTimerAttunementTests.swift`

## Design-Entscheidungen

### 1. Persistenz-Stabilitaet durch stabile CodingKeys

**Entscheidung:** `Praxis.CodingKeys` und `MeditationSettings.Keys` behalten ihre String-Werte (`"introductionId"`, `"introductionEnabled"`). Nur die Swift-Identifier werden umbenannt.

```swift
// Praxis.CodingKeys
case attunementId = "introductionId"       // alter JSON-Key bleibt
case attunementEnabled = "introductionEnabled"
```

```swift
// MeditationSettings.Keys (Legacy)
static let attunementId = "introductionId"       // alter UserDefaults-Key bleibt
static let attunementEnabled = "introductionEnabled"
```

**Warum:** Kein custom Decoder noetig, kein Migrations-Flag, kein Risiko fuer Datenverlust. Bestehende JSON-Daten und UserDefaults werden weiterhin korrekt gelesen. Das Ticket-AK "Persistenz-Migration" ist damit erfuellt — die Migration ist implizit durch stabile Keys.

**Trade-off:** Key-Strings und Swift-Namen divergieren. Das ist akzeptabel — CodingKeys existieren genau fuer diesen Zweck.

### 2. Bundle-Subdirectory bleibt "IntroductionAudio"

Per Ticket: Audio-Dateinamen werden NICHT umbenannt. Der Bundle-Pfad `"IntroductionAudio"` bleibt. Ein Kommentar dokumentiert den historischen Namen.

### 3. Lokalisierungs-Keys komplett umbenennen

Lokalisierungs-Keys sind nicht persistiert — sie werden zur Laufzeit aufgeloest. Daher koennen `introduction.*` Keys bedenkenlos zu `attunement.*` umbenannt werden.

## Reihenfolge

Der Rename ist mechanisch und hat keine echten Abhaengigkeiten zwischen Schritten. Trotzdem sinnvolle Reihenfolge fuer TDD:

1. **Domain-Models** — `Introduction.swift` → `Attunement.swift`, `TimerState`, `TimerAction`, `TimerEffect`, `MeditationTimer`, `MeditationSettings`, `Praxis` + zugehoerige Tests anpassen → `make test-unit-agent`
2. **Domain-Services** — `AudioServiceProtocol`, `TimerServiceProtocol`, `TimerReducer`, `AttunementResolverProtocol` + Tests → `make test-unit-agent`
3. **Infrastructure** — `AudioService`, `AudioService+Introduction` → `+Attunement`, `TimerService`, `UserDefaultsTimerSettingsRepository` + Tests → `make test-unit-agent`
4. **Application** — `TimerViewModel`, `PraxisEditorViewModel` + Tests → `make test-unit-agent`
5. **Presentation** — Views + `IntroductionSelectionView` → `AttunementSelectionView` → `make test-unit-agent`
6. **Lokalisierung** — Keys und Texte in beiden `.strings`-Dateien
7. **Dokumentation** — Glossar, Audio-System, Timer-State-Machine, DDD, ADR-004
8. **`make check`** — Finaler Durchlauf

## Fachliche Szenarien

Da rein mechanischer Rename: keine neuen Szenarien. Alle bestehenden Tests muessen nach Rename weiterhin gruen sein. Das ist der einzige Qualitaets-Gate.

### Persistenz-Szenario (implizit durch stabile Keys)

- Gegeben: User hat eine Einstimmung konfiguriert (gespeicherte Praxis mit `"introductionId": "breath"`)
  Wenn: App-Update mit Rename installiert wird
  Dann: Einstimmung ist weiterhin konfiguriert (JSON-Deserialisierung funktioniert ueber stabile CodingKeys)

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| Vergessene Referenz → Compile-Error | `make check` am Ende. Compiler findet alle Swift-Referenzen. |
| Lokalisierungs-Key vergessen → leerer Text in UI | Grep nach alten Keys (`introduction.`) nach Rename — darf keine Treffer in `.swift`-Dateien geben |
| Bundle-Subdirectory versehentlich umbenannt → Audio bricht | Plan explizit: `"IntroductionAudio"` bleibt |

## Offene Fragen

Keine — Ticket und Code sind eindeutig. Rein mechanischer Rename.
