# Implementierungsplan: shared-083

Ticket: [shared-083](../shared/shared-083-setting-karten-timer-konfig.md)
Erstellt: 2026-05-03
Plattform-Reihenfolge: **iOS zuerst**, dann Android (Referenz-Implementierung).

---

## Scope-Klärung

Drei parallele Veränderungen, die zusammen einen einzigen UX-Wechsel ergeben:

1. **Idle-Layout** wird umgebaut: HandsHeart + Frage-Text raus, fünf sichtbare Karten unter dem Picker.
2. **Detail-Views bleiben funktional gleich**, sind aber direkt vom Idle-Screen aus erreichbar — der Praxis-Editor-Index als Zwischenstop entfällt.
3. **Save-Pattern** wechselt von Save-on-Dismiss auf Live-Schreiben pro Setter.

Die Sitzungs-Engine, der Number-Picker, die Detail-Views selbst und alle Domain-Modelle bleiben unverändert.

---

## Betroffene Codestellen

### iOS

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `Presentation/Theme/ThemeColors.swift` | Presentation | Erweitern | Neue Tokens `settingCardBackground`, `settingCardBorder` (subtile Akzent-getönte Werte gemäss Handoff). |
| `Presentation/Theme/ThemeColors+Palettes.swift` | Presentation | Erweitern | Tokens für alle 6 Paletten (warm/sage/dusk × Light/Dark) definieren. |
| `Presentation/Views/Timer/TimerView.swift` | Presentation | Refactoring | `minutePicker` umbauen: HandsHeart + Frage entfernen, `configurationPillsRow` durch `settingCardsGrid` ersetzen. Navigation auf `NavigationStack(path: $settingPath)` mit `[SettingDestination]`-Array umstellen. `onChange(navigateToEditor)` entfällt — Live-Schreiben pro Setter. Custom-Audio-Import-onChange pusht direkt die passende Destination auf den Pfad. |
| `Presentation/Views/Timer/SettingDestination.swift` | Presentation | **NEU** | `enum SettingDestination: Hashable { case preparation, attunement, background, gong, interval }` für `NavigationStack(path:)`-basiertes Routing. |
| `Presentation/Views/Timer/Components/SettingCard.swift` | Presentation | **NEU** | Kart-Komponente: Label (uppercase, letter-spacing) · Icon · Wert. Off-State per Opazität 0.45. Press-State 0.98 scale. Verwendet die neuen Theme-Tokens. |
| `Presentation/Views/Timer/Components/SettingCardsGrid.swift` | Presentation | **NEU** | Layout 3+2 (LazyVGrid, 2 Reihen). Erhält die fünf Karten-Configs vom TimerViewModel. |
| `Presentation/Views/Timer/PreparationTimeSelectionView.swift` | Presentation | **NEU** | Push-Detail-View im selben Stil wie `AttunementSelectionView`/`BackgroundSoundSelectionView`. Erste Option "Aus", dann 5/10/15/20/30/45 Sek. Bindet auf `PraxisEditorViewModel.preparationTimeEnabled`/`.preparationTimeSeconds`. |
| `Presentation/Views/Timer/PraxisEditorView.swift` | Presentation | **ENTFERNEN** | Datei ersatzlos löschen. |
| `Application/ViewModels/SessionConfigurationViewModel.swift` | Application | **Umbenennen + Refactoring** | Datei-Rename von `PraxisEditorViewModel.swift` → `SessionConfigurationViewModel.swift`. Klasse wird umbenannt. `didSet` (oder Combine-Sink) auf jedem `@Published` Property → ruft `save()` automatisch bei jeder Änderung. Bestehender `save()`-Aufruf-Pfad in TimerView wird obsolet, fällt aber weg, sobald TimerView umgebaut ist. |
| `Application/ViewModels/TimerViewModel+ConfigurationDescription.swift` | Application | Refactoring | Pill-Labels werden Karten-Werte: alle fünf werden zu **immer-vorhandenen** Strings (statt `String?`). Off-State drückt sich durch separate Property `<x>IsOff: Bool` aus. Werte für Aus-Zustand: "Aus" / "Ohne" / "Stille". |
| `Application/ViewModels/TimerViewModel.swift` | Application | Erweitern | `makePraxisEditorViewModel` → `makeSessionConfigurationViewModel`. Eine Instanz pro Idle-Session als lazy-gehaltene Property `idleSessionConfigurationViewModel: SessionConfigurationViewModel?`, beim Übergang Idle→non-Idle nilen. Wird in TimerView als `@StateObject` gehalten, an alle fünf Detail-Views als `@ObservedObject` weitergereicht. |
| `Resources/de.lproj/Localizable.strings` + `en.lproj/Localizable.strings` | Resources | Ergänzen | Neue Keys: `settings.card.label.preparation`, `.attunement`, `.background`, `.gong`, `.interval`; `settings.card.value.preparation.off` ("Aus"), `.attunement.off` ("Ohne"); `settings.card.hint` ("Tippen, um anzupassen"); `preparation.option.off` ("Aus"); kompakte Sekunden-Werte `preparation.option.5s` ("5 Sek.") etc. Alte `duration.question` und `praxis.pill.preparation` werden überflüssig (aufräumen). |
| `StillMomentTests/Application/ViewModels/TimerViewModel+ConfigurationDescriptionTests.swift` | Test | Erweitern | Karten-Werte und Off-Zustände pro Karte abdecken. |
| `StillMomentTests/Application/ViewModels/PraxisEditorViewModelLiveSaveTests.swift` | Test | **NEU** | Setter-Mutation triggert Repository-Save sofort. |
| `StillMomentTests/Presentation/Views/Timer/PreparationTimeSelectionViewTests.swift` | Test | **NEU** | Auswahl-Persistenz, Aus-Option, alle 6 Sekunden-Werte. |

### Android

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `presentation/ui/theme/StillMomentColors.kt` (oder äquiv.) | Presentation | Erweitern | Neue Tokens `settingCardBackground`, `settingCardBorder` für alle Paletten. |
| `presentation/ui/timer/TimerScreen.kt` | Presentation | Refactoring | `MinutePicker` von HandsHeart/Frage befreien. `ConfigurationPills` durch `SettingCardsGrid` ersetzen. Statt `onNavigateToEditor: () -> Unit` jetzt fünf Lambdas (`onNavigateToPreparation`, `onNavigateToAttunement`, `onNavigateToBackground`, `onNavigateToGong`, `onNavigateToIntervalGongs`). |
| `presentation/ui/timer/components/SettingCard.kt` | Presentation | **NEU** | Composable analog iOS-Komponente. |
| `presentation/ui/timer/SelectPreparationTimeScreen.kt` | Presentation | **NEU** | Pendant zu `SelectAttunementScreen` — Liste mit "Aus" + 5/10/15/20/30/45 Sek. Bindet an `SessionConfigurationViewModel`. |
| `presentation/ui/timer/PraxisEditorScreen.kt` | Presentation | **ENTFERNEN** | Datei löschen. |
| `presentation/viewmodel/SessionConfigurationViewModel.kt` | Application | **Umbenennen + Refactoring** | Datei-Rename von `PraxisEditorViewModel.kt`. Klasse, `PraxisEditorUiState`, alle Hilt-Bindings und Test-Imports anpassen. Jeder Setter ruft am Ende `save()` (oder zentralisiert `_uiState.update` + `persistCurrentState()`). `applyPraxisUpdate` im TimerViewModel wird über `praxisFlow` ohnehin propagiert — wird aber als Fast-Path beibehalten. |
| `presentation/navigation/NavGraph.kt` | Presentation | Refactoring | `Screen.PraxisEditor` und `praxisEditorComposable` entfernen. `Screen.SelectPreparationTime` ergänzen. Sub-Screens (Attunement, Background, Gong, Interval, **Preparation**) hängen direkt an `Screen.TimerGraph`. `praxisEditorNavGraph` → `timerSettingsNavGraph` mit `Screen.SelectPreparationTime`/`SelectAttunement`/`SelectBackground`/`SelectGong`/`IntervalGongs` als Geschwister. **Wichtig**: `handleCustomAudioImport` navigiert nicht mehr über `Screen.PraxisEditor`, sondern direkt zur Ziel-Detail. Der bisherige Sub-Graph hielt einen geteilten `SessionConfigurationViewModel` über `getBackStackEntry(PraxisEditorGraph)` — der neue Graph muss das gleiche tun (z.B. `getBackStackEntry(TimerGraph)` als Scope). |
| `presentation/viewmodel/TimerUiState.kt` | Application | Erweitern | Pro Karte je ein `*IsOff: Boolean` und je ein `*Label: String` als computed/UI-state. Werte ergeben sich aus dem bestehenden `currentPraxis`. |
| `app/src/main/res/values/strings.xml` + `values-de/strings.xml` | Resources | Ergänzen | Analog zu iOS. |
| `app/src/test/.../viewmodel/PraxisEditorViewModelLiveSaveTest.kt` | Test | **NEU** | Setter triggert Repository-Save. |
| `app/src/test/.../viewmodel/TimerUiStateCardLabelTest.kt` | Test | **NEU** | Karten-Label und Off-Zustände pro Karte. |
| `app/src/test/.../ui/timer/SelectPreparationTimeScreenTest.kt` | Test | **NEU** | Auswahl-Persistenz, Aus-Option. |

### Beide Plattformen

| Datei | Aktion | Beschreibung |
|---|---|---|
| `CHANGELOG.md` | Ergänzen | "Sitzungs-Settings als Karten direkt am Timer-Konfig-Screen — Praxis-Editor-Zwischenscreen entfällt." |
| `dev-docs/reference/glossary.md` | Prüfen | Begriff "Praxis-Editor" entfernen oder umbenennen, falls erwähnt. |

---

## API-Recherche

Kein Framework-API-Risiko — alle eingesetzten APIs (SwiftUI `LazyVGrid`/`NavigationStack`, Compose `LazyColumn` + `Row` mit `weight`) sind ab den Min-Targets stabil. Keine neuen Frameworks.

Hinweise:
- **iOS `LazyVGrid` mit zwei Reihen unterschiedlicher Spaltenzahl**: Geht nicht mit einem einzigen `LazyVGrid`. Lösung: zwei `HStack` untereinander (3+2). Einfacher, weniger fragil.
- **iOS Push-Detail-View via `NavigationStack`**: Bestehender `.navigationDestination(isPresented:)`-Pattern. Fünf `@State`-Booleans im `TimerView` — analog zum bisherigen `navigateToEditor`.
- **Android `praxisFlow`** propagiert Änderungen automatisch in den TimerViewModel (siehe `TimerViewModel.observePraxis`). Live-Schreiben funktioniert bereits, sobald PraxisEditor-Setter `save()` aufrufen.

---

## Design-Entscheidungen

### 1. Live-Schreiben ohne Architektur-Umbau

**Trade-off:**
- (a) PraxisEditorViewModel auflösen, Detail-Views direkt an TimerViewModel binden → konzeptionell sauberer, aber grosser Refactoring-Hub (Custom-Audio-Methoden, Preview-Methoden, etc. müssten umziehen).
- (b) PraxisEditorViewModel beibehalten, jeder Setter ruft `save()` → kleine, gezielte Änderung; bestehende Tests bleiben grösstenteils intakt.

**Entscheidung:** (b). Der Editor-Screen entfällt, aber der ViewModel als **Zustandskoordinator für die Detail-Views** bleibt sinnvoll — er bündelt Custom-Audio-Verwaltung, Audio-Preview-Lifecycle und die geteilten Listen für alle fünf Detail-Views. Eine einzige `editorViewModel`-Instanz pro Idle-Session des TimerViewModel, an alle fünf Detail-Views weitergereicht.

### 2. Karten-Werte als immer-vorhandene Strings statt `String?`

**Trade-off:**
- Heute liefern Pill-Properties `nil` für Off-Zustände — die Pill rendert dann nicht.
- Karten dagegen rendern immer (gedimmt im Off-Zustand) — daher braucht jede Karte einen Wert.

**Entscheidung:** ConfigurationDescription liefert pro Karte `(label: String, isOff: Bool)`. Off-Werte sind lokalisiert: "Aus" (Vorbereitung, Intervall), "Ohne" (Einstimmung). Hintergrund- und Gong-Karten haben kein Off (Hintergrund-Off ist "Stille" — bewusste Auswahl, kein Aus-Zustand).

### 3. iPhone-SE-Test bewusst Akzeptanzkriterium

**Trade-off:** Das Layout könnte auf SE knapp werden, wenn Karten + Picker + Button-Bereich nicht zusammen in 667pt passen.

**Entscheidung:** HandsHeart und Frage-Text fallen ohnehin weg (Akzeptanzkriterium). Wenn es trotzdem eng wird: kompaktere Card-Padding und Picker-Höhe in `isCompactHeight`-Branch. Visuelles QA in beide Geräte-Previews.

### 4. Custom-Audio-Import-Flow

**iOS heute:** `pendingCustomAudioImport` öffnet PraxisEditorView → PraxisEditorView triggert `navigateToBackground`/`navigateToAttunement` per `onAppear`.

**Android heute:** `handleCustomAudioImport` navigiert via `navController.navigate(Screen.PraxisEditor.route)` und dann `navController.navigate(targetScreen.route)`.

**Neu:** Auf beiden Plattformen direkt zur Ziel-Detail-View navigieren. Auf iOS: `TimerView.onChange(pendingCustomAudioImport)` setzt direkt das passende `navigateTo<X>`. Auf Android: `handleCustomAudioImport` springt direkt von `Screen.TimerGraph` zu `Screen.SelectAttunement`/`SelectBackground`.

---

## Refactorings (vor Feature)

1. **iOS `TimerViewModel.makePraxisEditorViewModel`** — heute pro Aufruf eine neue Instanz. Mit fünf Karten brauchen wir **eine** Instanz pro Idle-Session. Lösung: Lazy-Singleton `private var idleEditorViewModel: PraxisEditorViewModel?`, beim Übergang Idle→non-Idle nilen.
   - Risiko: Niedrig. Niemand sonst ruft `makePraxisEditorViewModel`.
2. **Android-Navigation: `praxisEditorNavGraph` umbenennen/umstrukturieren** auf `timerSettingsNavGraph`. Sub-Screens hängen direkt am `TimerGraph`.
   - Risiko: Mittel. Falls die Sub-Screens den geteilten `SessionConfigurationViewModel` über `getBackStackEntry(PraxisEditorGraph)` halten — wir müssen den Scope umlenken, ohne die Custom-Audio-Listen zu verlieren.

---

## Fachliche Szenarien

### AK-1: Karten-Layout sichtbar und tippbar

- Gegeben: Idle-Screen mit Default-Konfiguration
  Wenn: User schaut auf den Screen
  Dann: Unter dem Picker liegen fünf Karten in zwei Reihen (3+2). Jede Karte zeigt Label (uppercase), Icon, aktuellen Wert. Darunter "Tippen, um anzupassen".

- Gegeben: HandsHeart-Bild und Frage "Wie viel Zeit schenkst du dir?" waren früher sichtbar
  Wenn: Der Screen rendert nach dem Update
  Dann: Beide Elemente sind vollständig entfernt.

### AK-2: Off-State pro Karte

- Gegeben: Vorbereitung ist deaktiviert, Einstimmung ist "Ohne", Intervall ist deaktiviert
  Wenn: Idle-Screen rendert
  Dann: Vorbereitung-, Einstimmung-, Intervall-Karte sind sichtbar gedimmt (Opazität ≈ 0.45). Werte zeigen "Aus", "Ohne", "Aus".

- Gegeben: Hintergrund ist auf "Stille"
  Wenn: Idle-Screen rendert
  Dann: Hintergrund-Karte ist nicht gedimmt (Stille ist eine bewusste Wahl). Wert zeigt "Stille".

- Gegeben: Beliebige Gong-Auswahl
  Wenn: Idle-Screen rendert
  Dann: Gong-Karte ist nicht gedimmt.

### AK-3: Tap öffnet Detail-View direkt

- Gegeben: Idle-Screen, Vorbereitung-Karte
  Wenn: User tippt
  Dann: Push zur **neuen** Vorbereitungszeit-Detail-View. Erste Option "Aus" markiert (oder Sekunden-Wert markiert, je nach Praxis).

- Gegeben: Idle-Screen, Einstimmung-/Hintergrund-/Gong-/Intervall-Karte
  Wenn: User tippt
  Dann: Push zur **bestehenden** Detail-View für dieses Setting (visuell unverändert).

### AK-4: Vorbereitungszeit-Detail-View

- Gegeben: Praxis hat Vorbereitung 15 Sek. aktiv
  Wenn: User öffnet die Detail-View
  Dann: Liste zeigt "Aus", "5 Sek.", "10 Sek.", "15 Sek.", "20 Sek.", "30 Sek.", "45 Sek.". "15 Sek." ist markiert.

- Gegeben: Detail-View offen, Vorbereitung 15 Sek. aktiv
  Wenn: User wählt "Aus"
  Dann: `preparationTimeEnabled = false`. Markierung wechselt zu "Aus". Beim Zurück zeigt die Karte "Aus", ist gedimmt.

- Gegeben: Detail-View offen, Vorbereitung "Aus"
  Wenn: User wählt "30 Sek."
  Dann: `preparationTimeEnabled = true`, `preparationTimeSeconds = 30`. Beim Zurück zeigt die Karte "30 Sek.", ist nicht gedimmt.

### AK-5: Live-Schreiben

- Gegeben: User in einer beliebigen Detail-View (z.B. Hintergrundklang-Auswahl)
  Wenn: User wählt "Regen"
  Dann: Repository ist sofort aktualisiert (innerhalb des Frame, nicht erst beim Pop). Beim Zurück steht "Regen" sofort auf der Karte — kein Flackern, keine Race.

- Gegeben: User wählt etwas, App wird vom System getötet, neu gestartet
  Wenn: User öffnet den Idle-Screen
  Dann: Die Karte zeigt die zuletzt getroffene Auswahl.

### AK-6: Wegfall des Editor-Index

- Gegeben: Es gibt keine sichtbare Tippmöglichkeit, die zu einer Liste mit allen fünf Settings führt
  Wenn: User sucht aktiv nach einer solchen Liste
  Dann: Der Editor-Index existiert nicht mehr. Auch tag-artige Pillen unter dem Picker existieren nicht mehr.

### AK-7: Custom-Audio-Import

- Gegeben: User teilt eine MP3 als Soundscape via Share Sheet
  Wenn: Import abgeschlossen ist
  Dann: User landet direkt im Hintergrund-Detail-Screen mit dem neu importierten File markiert (kein Zwischenstop im entfallenen Editor-Index).

- Gegeben: User teilt eine MP3 als Attunement via Share Sheet
  Wenn: Import abgeschlossen ist
  Dann: User landet direkt im Einstimmungs-Detail-Screen.

### AK-8: iPhone SE / kleine Bildschirme

- Gegeben: iPhone SE (375×667)
  Wenn: Idle-Screen rendert
  Dann: Greeter-Title + Picker + 5 Karten + "Tippen, um anzupassen" + Start-Button passen ohne Scrollen.

### AK-9: Theme- und Locale-Wechsel

- Gegeben: Beliebiges Theme (warm/sage/dusk), Light oder Dark Mode, DE oder EN
  Wenn: Idle-Screen rendert
  Dann: Karten verwenden Theme-Tokens, Off-State-Werte sind lokalisiert ("Aus"/"Off", "Ohne"/"None", "Stille"/"Silence").

### AK-10: iOS-Android-Konsistenz

- Gegeben: Gleiche Konfiguration auf beiden Plattformen
  Wenn: User vergleicht Idle-Screens
  Dann: Layout (3+2), Reihenfolge (Vorbereitung·Einstimmung·Hintergrund·Gong·Intervall), Werte und Off-Zustände sind identisch. Visuelle Details folgen den jeweiligen nativen Listen-Patterns (Form/insetGrouped vs. LazyColumn).

---

## Reihenfolge der Akzeptanzkriterien (TDD-Pfad)

iOS zuerst, identische Reihenfolge auf Android:

1. **Theme-Tokens** (Refactoring-Vorbereitung) — `settingCardBackground`, `settingCardBorder` in allen Paletten.
2. **AK-2 Karten-Werte/Off-State (TimerViewModel-Erweiterung)** — `settingCardLabels`/`isOff` als Pure Logic, schnell unit-testbar. Pendant zu Pill-Labels.
3. **AK-5 Live-Schreiben** — `SessionConfigurationViewModel`-Setter triggern Save sofort. Unit-Test pro Field.
4. **AK-4 Vorbereitungszeit-Detail-View** — Neue View mit "Aus" + 6 Sekunden-Optionen. Unit-Test der ViewModel-Bindung.
5. **AK-1 Karten-Layout** — `SettingCard` + `SettingCardsGrid`-Komponenten. Snapshot/Preview-Test.
6. **AK-3 Navigation** — TimerView umbauen: fünf `navigateTo<X>`. Praxis-Editor-View weg.
7. **AK-7 Custom-Audio-Import** — File-Open-Handler-onChange direkt zur Detail-View statt zum Editor.
8. **AK-6 Wegfall Editor-Index** — `PraxisEditorView.swift` löschen, alte Pills entfernen.
9. **AK-8 iPhone SE** — Layout im Compact-Mode prüfen (HandsHeart/Frage entfällt sowieso, sollte passen).
10. **AK-9/AK-10 Theme + Locale + Cross-Platform** — Visuelle Smoke-Tests in allen Theme/Locale-Kombinationen.

Auf Android dann äquivalent — bestehender NavGraph wird zusätzlich umstrukturiert (Schritt 6 grösser).

---

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| Custom-Audio-Sub-Screens halten den geteilten `SessionConfigurationViewModel` über `getBackStackEntry(PraxisEditorGraph)` (Android). Wenn dieser Graph entfällt, geht Listen-Sharing verloren. | Sub-Screens hängen am neuen `timerSettingsNavGraph` (oder direkt am TimerGraph). `getBackStackEntry(TimerGraph)` als Scope nutzen — TimerViewModel + ein eigens hier gehaltener PraxisEditorViewModel. |
| Live-Schreiben pro Setter kann auf iOS `didSet`-Schleifen erzeugen, wenn `attunementEnabled` und `attunementId` sich gegenseitig setzen. | `didSet` mit Re-Entrancy-Guard oder Combine-`debounce`. Bestehende Logik in `setAttunementEnabled` ist explizit, das Pattern beibehalten. |
| iPhone SE: Karten + Picker + Button doch nicht ohne Scrollen | `isCompactHeight`-Branch: kompaktere Padding-Werte für SettingCard, ggf. Picker-Höhe weiter reduzieren. |
| Eine PraxisEditorViewModel-Instanz wird über fünf Sub-Screens geteilt — wenn iOS den ViewModel beim Verlassen einer einzelnen Detail-View deinitialisiert, verliert der nächste Tap den State. | iOS: ViewModel als `@StateObject` im TimerView halten (oder `@State` mit lazy init), nicht in den einzelnen Detail-Views. Detail-Views erhalten ihn als `@ObservedObject`. |

---

## Entschiedene Punkte

- ✅ **Detail-View-Navigation auf iOS**: `NavigationStack(path: $settingPath)` mit `[SettingDestination]`-Array (Variante B). Single Source of Truth, exakt eine Detail-View kann offen sein, Custom-Audio-Import setzt den Pfad direkt.
- ✅ **PraxisEditorViewModel umbenennen** zu `SessionConfigurationViewModel` (iOS und Android). Datei-Rename, Klassen-Rename, Hilt-Bindings, Test-Imports, `PraxisEditorUiState` → `SessionConfigurationUiState`.

## Offene Fragen

- [ ] **Naming**: "Setting-Karten" vs. "Konfig-Karten" vs. "Sitzungs-Karten" — welcher Begriff in Code/Strings? Ticket nutzt "Setting-Karten".
- [ ] **Glossar-Begriff "Praxis"** generell behalten? Mit Wegfall des Editor-Index ist der Begriff weniger sichtbar — bleibt aber als Domain-Modell relevant. Vermutlich nichts ändern.
