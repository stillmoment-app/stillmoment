# Implementierungsplan: shared-090 (Android)

Ticket: [shared-090-timer-atemkreis-analog-player](../shared/shared-090-timer-atemkreis-analog-player.md)
Erstellt: 2026-05-05
Scope: nur Android. iOS ist abgeschlossen ([Plan iOS](shared-090-ios.md), Commit `4e6a3d6`). shared-087 Android (geteilter Atemkreis) ist DONE — die Komponente steht bereit.

---

## Mentales Modell

`TimerFocusScreen` bekommt das gleiche visuelle Vokabular wie der `GuidedMeditationPlayerScreen`. Beide Screens werden danach Geschwister: derselbe `BreathingCircle`, derselbe `BottomLabel`-Mechanismus, dieselbe Pre-Roll-Sprache.

- **Pre-Roll** (`TimerState.Preparation`) — `BreathingCircle(phase = PreRoll)`. Inhalt im Kreis: Countdown-Zahl + Label "Vorbereitung". Unter dem Kreis: Hint "GLEICH GEHT'S LOS".
- **Hauptphase** (`StartGong` / `Running` / `EndGong`) — `BreathingCircle(phase = Playing)` mit Track + Restzeit-Bogen + Sonnen-Punkt + atmender Glow. **Inneres leer** (Timer hat keine Pause). Unter dem Kreis: "NOCH 8:32 MIN".
- **Idle** (`TimerScreen` / `BreathDial`-Picker) und **Completed** (`TimerCompletionContent`) — unverändert.

Die `BreathingCircle`-Komponente liegt bereits in `presentation/ui/common/` — neutraler Ort, kein Move nötig. `MeditationPhase` lebt im **Domain-Layer** (Android-Stand seit shared-087); das bleibt so. Auf iOS lebt der Typ im Application-Layer — diese Plattform-Abweichung wurde mit shared-087 bewusst akzeptiert und wird hier nicht angefasst.

Affirmations-Texte (5 Preparation + 5 Running) und die `welcome_title`-Headline während laufender Sitzung fliegen raus — inklusive UiState-Property, ViewModel-Rotation, Compose-Arrays in `TimerFocusScreen` und Lokalisierungs-Keys in DE+EN. Idle, Completion und Settings-Sheet behalten ihre Texte.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `presentation/ui/timer/TimerFocusScreen.kt` | Presentation | Umbau | `welcome_title`-Headline während Sitzung entfernen; alten `TimerRing` (zwei `CircularProgressIndicator` + `formattedTime`-Text) durch `BreathingCircle` mit Slot-Inhalt ersetzen; `BottomLabel` analog Player einführen; `getStateText` + `preparationAffirmations` + `runningAffirmations`-Arrays löschen; `FocusTimerDisplay` neu strukturieren |
| `presentation/viewmodel/TimerUiState.kt` | Presentation/ViewModel | Bereinigen + Erweitern | `currentAffirmationIndex` entfernen, `formattedTime` (samt `formatDefaultTime`) entfernen. Neu: `phase: MeditationPhase` (computed), `formattedRemainingMinutes: String` (`mm:ss` aus `remainingSeconds`, ohne führende Null bei Minuten — analog `PlayerUiState.formattedRemainingMinutes`) |
| `presentation/viewmodel/TimerViewModel.kt` | Presentation/ViewModel | Bereinigen | `AFFIRMATION_COUNT` und Index-Rotation in `startTimer()` (Z. 192) entfernen |
| `domain/models/MeditationTimer.kt` | Domain | Bereinigen | `formattedTime` Property löschen (toter Pfad nach View-Umbau, kein anderer Aufrufer — weder `TimerForegroundService` noch Notification) |
| `app/src/main/res/values/strings.xml` | Resources | Löschen | `affirmation_preparation_1..5`, `affirmation_running_1..5`, `welcome_title`, `state_ready`, `state_completed` (siehe Designentscheidung 4) |
| `app/src/main/res/values-de/strings.xml` | Resources | Löschen | dito DE |
| `app/src/test/kotlin/.../domain/models/MeditationTimerTest.kt` | Tests | Bereinigen | Drei `formattedTime`-Tests löschen (Z. 606, 613, 620) — `formattedTime` Property fällt weg |
| `app/src/test/kotlin/.../viewmodel/TimerViewModelUiStateTest.kt` | Tests | Bereinigen + Erweitern | Sechs `formattedTime`-Tests (Z. 186 ff.) löschen. Neu: `phase returns PreRoll during Preparation`, `phase returns Playing during Running`, `formattedRemainingMinutes formats mm:ss without leading zero`, `formattedRemainingMinutes handles zero seconds` |
| `app/src/test/kotlin/.../viewmodel/TimerViewModelRegressionTest.kt` | Tests | Prüfen | Falls Affirmations-Rotation dort getestet wird → entfernen. (Schnell-Check: aktuell keine Treffer auf `currentAffirmationIndex`/`AFFIRMATION` in Test-Files; Datei trotzdem beim Implementieren öffnen) |
| `app/src/androidTest/kotlin/.../ui/timer/TimerScreenTest.kt` | UI Tests | Prüfen | Aktuell keine Treffer auf `welcome_title`/`affirmation_*`/`state_ready`. Falls `formattedTime`-Text auf dem Ring abgefragt wird, anpassen — der grosse mittige Timer-Text fällt weg |
| `app/src/androidTest/kotlin/.../screenshots/ScreengrabScreenshotTests.kt` | Screenshots | Prüfen | Z. 232 ff. navigiert in den `TimerFocusScreen` — nur visuelles Layout ändert sich, keine String-Assertion erwartet. Screenshots werden im nächsten Release-Lauf neu erzeugt |
| `dev-docs/architecture/timer-state-machine.md` | Docs | Prüfen + ggf. anpassen | Falls UI-Display dort beschrieben ist (Affirmations, Welcome-Headline), entsprechend kürzen |
| `CHANGELOG.md` | Docs | Eintrag | "Timer-Display nutzt den Atemkreis aus dem Player; Begrüßungs-Headline und Affirmations während der Sitzung entfernt" — beide Plattformen, da iOS denselben Eintrag nutzt |

### Codestellen, die explizit unverändert bleiben

- `presentation/ui/common/BreathingCircle.kt` — geteilte Komponente, additiv genutzt; **kein** Move, **keine** Signatur-Änderung
- `domain/models/MeditationPhase.kt` — bleibt im Domain-Layer
- `domain/models/MeditationTimer.kt`, `domain/models/PreparationCountdown.kt` — Domain unangetastet
- `domain/services/TimerReducer.kt` — Reducer/Effects unverändert
- `infrastructure/audio/AudioService*` und `TimerForegroundService*` — kein Audio/Lifecycle-Change
- `presentation/ui/timer/TimerScreen.kt`, `BreathDial.kt`, `IntervalGongsEditorScreen.kt`, `PraxisEditorScreen.kt`, `Select*Screen.kt`, `SettingsSheet.kt`, `WheelPicker.kt` — Idle-Screen und Settings-Flows bleiben
- `presentation/ui/meditations/GuidedMeditationPlayerScreen.kt` — wird nur als Referenz gelesen, nicht geändert
- Lokalisierungs-Keys `guided_meditations_player_preroll_label`, `..._preroll_hint`, `..._remaining_time_format` — werden vom Timer mitbenutzt (pragmatisch, kein Rename in diesem Scope, analog iOS)
- `accessibility_countdown_seconds`, `accessibility_time_remaining`, `accessibility_close_focus` — bleiben

---

## API-Recherche

Keine neuen Framework-APIs. Werkzeuge sind alle bereits im Player im Einsatz:

| API | Verfügbarkeit | Verwendung |
|---|---|---|
| `BreathingCircle(phase, progress, reduceMotion, outerSize, content)` | bereits da (shared-087) | Atemkreis im Timer-Display, gleiche Aufruf-Signatur wie im Player |
| `rememberIsReducedMotion()` aus `presentation/util/ReducedMotion.kt` | bereits da | Reduced-Motion-Detection, identisch zum Player |
| `AnimatedContent` mit `fadeIn(tween) togetherWith fadeOut(tween)` | androidx.compose.animation | Cross-Fade zwischen Pre-Roll-Inhalt und leerem Inneren bzw. zwischen Hint und Restzeit-Label — analog `CircleContent`/`BottomLabel` im Player |
| `LocalConfiguration.current.screenHeightDp` | androidx.compose.ui.platform | Compact-Detection (< 700 dp → 240 dp Kreis, sonst 280 dp) — gleiche Konstanten wie Player |

Hinweis: `BreathingCircle` ist über `content: @Composable () -> Unit` slot-parametrisiert. Die Hauptphase übergibt `{ }` (leerer Slot) — Compose rendert dann nichts im Inneren; im Pre-Roll wird `PreRollContent`-äquivalentes `Column { Text(countdown); Text("Vorbereitung") }` übergeben.

---

## Designentscheidungen

### 1. Wiederverwendung der Player-Composables vs. Extraktion in `common/`

**Trade-off:** `PreRollContent`, `BottomLabel`, `PreRollHint`, `RemainingTimeLabel` sind heute `private` in `GuidedMeditationPlayerScreen.kt`. Zwei Wege: (a) Composables nach `presentation/ui/common/` extrahieren und teilen, oder (b) in `TimerFocusScreen` parallel implementieren.

**Entscheidung:** **(a) extrahieren.** Begründung:

- Die Composables sind reine View-Bausteine ohne Player-Spezifika (nur `phase`, `countdownSeconds`, `formattedRemainingMinutes` als Inputs).
- Doppelpflege bei zwei identischen Implementierungen wäre genau die "frühere App-Generation"-Falle, die das Ticket adressiert.
- Zielort: **eine Datei** `presentation/ui/common/MeditationDisplayContent.kt` mit `PreRollCircleContent`, `MeditationBottomLabel`, intern `PreRollHint` und `RemainingTimeLabel` plus `PHASE_TRANSITION_MS`-Konstante (~120 Zeilen). Die zwei Slots — Inhalt im Kreis, Label unter dem Kreis — sind ein Konzept; Splitten wäre Selbstzweck. Player-Aufrufer wird angepasst (additiv — kein Verhalten-Change).
- **testTags via `Modifier`-Parameter:** Die extrahierten Composables setzen **keine** festen testTags intern — sie nehmen einen `modifier: Modifier = Modifier`-Parameter und der Aufrufer setzt den Tag von außen. Player behält `Modifier.testTag("player.countdown")`, `…("player.text.preRollHint")`, `…("player.text.remainingTime")` (unverändert, kein Breaking Change). Timer setzt `Modifier.testTag("timer.display.countdown")`, `…("timer.display.preRollHint")`, `…("timer.display.remainingTime")` — gleiches Schema (`<screen>.<area>.<element>`), eigener Namespace.

**Risiko:** Player-Tests / Player-Screenshot-Vergleich. Mitigation: `make test-unit-agent` vor und nach dem Extract; visuelle Diff-Prüfung im Simulator (Player und Timer side-by-side).

### 2. `MeditationPhase` bleibt im Domain-Layer

iOS hat den Typ im Application-Layer. Android hat ihn seit shared-087 im Domain. Der Plattform-Unterschied wurde damals akzeptiert; wir ziehen ihn jetzt nicht nach. Begründung: Domain-Verwendung ist semantisch tragbar (Phase ist ein Layout-Konzept der Meditation, kein UI-Detail) und ein Move in dieser Iteration brächte zusätzliches Refactoring ohne Funktions-Gewinn.

### 3. Restzeit-Bogen-Progress: `uiState.progress`

`MeditationTimer.progress` ist während Pre-Roll = 0 (weil `remainingSeconds == totalSeconds`) und wächst in der Hauptphase mit. Genau das Verhalten, das `BreathingCircle` erwartet. Der `phase != Playing`-Branch in `BreathingCircle.drawTrackAndProgress` (Z. 139) blendet den Bogen in Pre-Roll ohnehin aus — kein Sonderpfad nötig.

### 4. Aufräum-Schwelle: `state_ready` und `state_completed` ebenfalls löschen

`R.string.state_ready` und `R.string.state_completed` werden ausschließlich in `getStateText` (Z. 401, 410) referenziert. `getStateText` fällt mit dem Affirmations-Cleanup weg, damit sind beide Keys tot. Konsequent löschen — `Idle` wird im `TimerFocusScreen` durch das `LaunchedEffect`-Back-Navigation-Konstrukt nie gerendert; `Completed` rendert `TimerCompletionContent` mit `completion_headline`/`completion_subtitle`.

### 5. `formattedRemainingMinutes` an `TimerUiState` als computed Property

**Entscheidung:** Property-Format wie im Player: `m:ss` ohne führende Minutenzahl-Null (z. B. `8:32` für 8 Min 32 Sek, `0:45` für 45 Sek). `String.format(Locale.ROOT, "%d:%02d", minutes, seconds)`. Source-Wert: `remainingSeconds`. Der Player nutzt `currentPosition`/`duration` in ms — Timer hat Sekunden direkt, also keine ms-Umrechnung.

**Hinweis:** `TimerUiState.formattedTime` (für den heutigen Ring-Mittel-Text) bleibt zunächst — wird vom Domain-Modell `MeditationTimer.formattedTime` geliefert und ist mit Tests abgesichert. Nach dem View-Umbau ist `formattedTime` allerdings nirgends mehr im Aufruf — siehe **Offene Frage** unten.

### 6. Layer-Reihenfolge im neuen `FocusTimerDisplay`

Layout vertikal innerhalb des `Column` von `FocusScreenLayout`:

1. `Spacer(weight = 1f)` (top, expanding)
2. `BreathingCircle(outerSize = 240/280 dp je nach Compact)` mit Slot-Inhalt
3. `Spacer(height = 24 dp)`
4. `MeditationBottomLabel(phase, formattedRemainingMinutes, reduceMotion)` — Pre-Roll: Hint, Hauptphase: Restzeit-Label
5. `Spacer(weight = 1f)` (bottom, expanding)

Lehrer/Titel-Block des Players entfällt — Timer hat keinen Lehrer. Schließen-Button bleibt als `IconButton` in `StillMomentTopAppBar` (heutiges Verhalten unverändert).

### 7. `accessibility_time_remaining` und `accessibility_countdown_seconds` neu verdrahtet

Heute hängt der Accessibility-Description-Text am `TimerRing` als `contentDescription` mit `LiveRegionMode.Polite`. Nach dem Umbau wandert er auf das neue Display:

- **Pre-Roll:** `accessibility_countdown_seconds(remainingPreparationSeconds)` als `contentDescription` auf den Pre-Roll-Inhalts-`Column` im `BreathingCircle`-Slot. `LiveRegion` hier behalten — TalkBack soll mitzählen.
- **Hauptphase:** `accessibility_time_remaining(minutes, seconds)` als `contentDescription` am `RemainingTimeLabel`. `LiveRegion.Polite` ebenfalls — TalkBack liest die Restzeit, wenn der User explizit auf das Label fokussiert.

Das iOS-Akzeptanzkriterium "bestehender accessibility-Identifier `timer.display.time` bleibt erreichbar" ist iOS-spezifisch (`accessibilityIdentifier`). Auf Android setzen wir testTags via `Modifier`-Parameter (siehe Designentscheidung 1): `timer.display.countdown` (Pre-Roll-Inhalt im Slot) und `timer.display.remainingTime` (Hauptphasen-Restzeit-Label). Player behält parallel `player.countdown` und `player.text.remainingTime`.

### 8. Cross-Fade Pre-Roll → Hauptphase via `AnimatedContent`

Identisch zum Player: `AnimatedContent(targetState = phase, transitionSpec = fadeIn(tween(400)) togetherWith fadeOut(tween(400)))` für den Inneren-Slot UND für den `BottomLabel`. Bei `reduceMotion = true` ist `transitionDuration = 0` (Player-Pattern, Z. 347).

---

## Refactorings

Drei klar abgegrenzte Schritte vor dem View-Umbau, jeweils mit grünem Build dazwischen:

1. **Player-Composables nach `presentation/ui/common/` extrahieren**
   - Neue Datei `MeditationDisplayContent.kt` mit `PreRollCircleContent`, `MeditationBottomLabel`, internen `PreRollHint` + `RemainingTimeLabel`.
   - `GuidedMeditationPlayerScreen.kt`: lokale `private fun PreRollContent`, `BottomLabel`, `PreRollHint`, `RemainingTimeLabel` löschen → durch Aufrufe der extrahierten Composables ersetzen.
   - Risiko: Niedrig — pure Move-Refactor, keine Verhaltens-Änderung. Mitigation: `make test-unit-agent` + visueller Smoke-Test im Player.

2. **Affirmations-Code entfernen**
   - `TimerUiState.currentAffirmationIndex` Property löschen.
   - `TimerViewModel.startTimer()` Z. 192 (Index-Rotation) und `AFFIRMATION_COUNT` companion-Konstante löschen.
   - `TimerFocusScreen.kt`: `preparationAffirmations`/`runningAffirmations`-Arrays + `getStateText`-Funktion löschen (wird gleich Schritt 3 ohnehin neu gebaut, aber sauber als eigener Commit-Schritt).
   - 12 Lokalisierungs-Keys (DE+EN) löschen: `affirmation_preparation_1..5`, `affirmation_running_1..5`, `welcome_title`, `state_ready`, `state_completed`.
   - Risiko: Niedrig. Test-Files greifen nicht auf diese Properties zu (geprüft).

3. **`TimerUiState.phase` und `TimerUiState.formattedRemainingMinutes` als computed Properties**
   - TDD: erst Tests in `TimerViewModelUiStateTest.kt` schreiben, rot, dann implementieren.

---

## Fachliche Szenarien

### AK Pre-Roll-Phase

- **Gegeben:** Vorbereitungszeit 6 s, Timer gerade gestartet
  **Wenn:** `TimerFocusScreen` rendert
  **Dann:** `BreathingCircle` zentriert, statischer Track, Glow gedämpft (kein Atem). Im Slot: Countdown-Zahl "6" + Label "Vorbereitung". Unter dem Kreis: "GLEICH GEHT'S LOS". Schließen-Button oben links erreichbar. **Keine** "Schön, dass du da bist"-Headline. **Keine** Affirmations-Zeile.

- **Gegeben:** Pre-Roll läuft, eine Sekunde vergeht
  **Dann:** Countdown-Zahl wechselt zu "5", `TimerRing`-Bogen erscheint **nicht**.

### AK Hauptphase / Atemkreis

- **Gegeben:** Pre-Roll abgelaufen, Timer in `StartGong`/`Running`/`EndGong`
  **Dann:** `BreathingCircle` mit allen drei Schichten (Track + Restzeit-Bogen + Sonnen-Punkt + atmender Glow). **Slot leer** — kein Pause-Button, kein Restzeit-Text. Unter dem Kreis: "NOCH 9:54 MIN" o. ä.

- **Gegeben:** Restzeit 8:32
  **Dann:** Anzeige "NOCH 8:32 MIN" (DE) bzw. "8:32 MIN LEFT" (EN) via `guided_meditations_player_remaining_time_format`.

- **Gegeben:** Reduced Motion an
  **Dann:** Glow statisch, Restzeit-Bogen aktualisiert sich weiter, `AnimatedContent`-Übergänge mit Dauer 0.

### AK Übergang Pre-Roll → Hauptphase

- **Gegeben:** Pre-Roll bei 1 s, Timer geht auf `StartGong`
  **Dann:** Cross-Fade (~400 ms): Countdown + "Vorbereitung" + "GLEICH GEHT'S LOS" blenden aus; Restzeit-Bogen erscheint bei 0 und wächst; Glow startet zu atmen; "NOCH … MIN" blendet ein.

### AK Entfernte Elemente

- **Gegeben:** Timer in Pre-Roll, Hauptphase, StartGong oder EndGong
  **Dann:** `welcome_title`-Text **nicht** im UI-Tree. `getStateText`-Container existiert nicht mehr. Alter `TimerRing` (zwei `CircularProgressIndicator`) ist weg — `BreathingCircle` ist die einzige Visualisierung.

- **Gegeben:** Idle (vor `Beginnen`-Tap)
  **Dann:** `TimerScreen` (BreathDial + Settings-Liste + Beginnen-Button) unverändert.

- **Gegeben:** Completed
  **Dann:** `TimerCompletionContent` (Herz-Icon + `completion_headline` + `completion_subtitle` + Back-Button) unverändert.

### AK Schließen während Sitzung

- **Gegeben:** Pre-Roll oder Hauptphase
  **Wenn:** User tippt Close-IconButton
  **Dann:** `viewModel.resetTimer()` wird aufgerufen, `LaunchedEffect` navigiert zurück zum `TimerScreen`. Verhalten unverändert.

### AK Geteilte Komponente

- **Gegeben:** `BreathingCircle` und neue `MeditationDisplayContent`-Bausteine in `presentation/ui/common/`
  **Wenn:** Build läuft
  **Dann:** Beide Aufrufer (`GuidedMeditationPlayerScreen`, `TimerFocusScreen`) kompilieren. Keine Player-spezifischen Annahmen (ExoPlayer, AudioFocus) leaken in die Bausteine — Inputs sind nur `phase`, `countdownSeconds`, `formattedRemainingMinutes`, `reduceMotion`.

### AK Aufräumen

- **Gegeben:** `make check` läuft (detekt + Localization-Lint)
  **Dann:** Keine Warnungen über unbenutzte String-Resources; keine `R.string.affirmation_*`/`welcome_title`/`state_ready`/`state_completed`-Referenzen mehr im Code.

- **Gegeben:** `make test-unit-agent` läuft
  **Dann:** Alle Tests grün. Bestehende Reducer-/State-Machine-/Completion-Tests laufen unverändert. Neue Tests für `TimerUiState.phase` und `formattedRemainingMinutes` grün.

### AK Reduced Motion / Accessibility

- **Gegeben:** Hauptphase, Reduced Motion an
  **Dann:** Atem-Animation aus, Glow konstant (`reduceMotion -> 0.78f`), Restzeit-Bogen aktualisiert sich weiter, Phase-Übergänge ohne Fade.

- **Gegeben:** Pre-Roll, TalkBack fokussiert auf Countdown-Inhalt
  **Dann:** `contentDescription = accessibility_countdown_seconds(remainingPreparationSeconds)`, `LiveRegion.Polite` — TalkBack zählt mit.

- **Gegeben:** Hauptphase, TalkBack fokussiert auf Restzeit-Label
  **Dann:** `contentDescription = accessibility_time_remaining(minutes, seconds)`, `LiveRegion.Polite`.

- **Gegeben:** Schließen-Button im TopAppBar
  **Dann:** `contentDescription = accessibility_close_focus` — unverändert.

### AK Theming

- **Gegeben:** Theme = "warm", System-Mode = Dark
  **Dann:** Hintergrund nutzt warmen Dark-Gradient, Atemkreis-Glow warm-orange — visuell identisch zum Player im selben Theme/Mode.

- **Gegeben:** Theme-Wechsel während laufender Sitzung
  **Dann:** `BreathingCircle` nimmt neue `MaterialTheme.colorScheme`-Werte an — gleiche Tokens wie Player, keine doppelten oder timer-spezifischen Farben.

---

## Reihenfolge der Akzeptanzkriterien (TDD)

Innen → außen, damit Build immer grün bleibt:

1. **Refactor Player-Composables extrahieren** — neue `MeditationDisplayContent.kt`, Player anpassen, `make test-unit-agent` grün, `screengrab`/Preview visuell prüfen.
2. **Affirmations + welcome + state_ready/state_completed entfernen** — UiState, ViewModel, FocusScreen-Arrays, 12 Lokalisierungs-Keys (DE+EN). `make check` + `make test-unit-agent` grün.
3. **`TimerUiState.phase` + `formattedRemainingMinutes`** — Tests rot → implementieren → grün. (`testPhaseInPreparation`, `testPhaseInRunning`, `testFormattedRemainingMinutesFormatsWithoutLeadingZero`, `testFormattedRemainingMinutesHandlesZeroSeconds`).
4. **`TimerFocusScreen.FocusTimerDisplay` umbauen** — `BreathingCircle` + Slot-Inhalt + `MeditationBottomLabel`, Welcome-Headline-Block in der Sitzung entfernen, `TimerRing` löschen. Previews nachziehen (`Preparation`, `Running`, `Completed`, `Compact`, `Tablet`).
5. **UI-Tests prüfen** — `androidTest/.../TimerScreenTest.kt` und `ScreengrabScreenshotTests.kt` durchgehen, Selektoren auf alten Ring-Text → ggf. neue testTags `timer.display.countdown`/`timer.display.remainingTime`.
6. **Manueller Test** auf Pixel 4 (Standard) und kompaktem Emulator (`heightDp = 640`): Idle → Pre-Roll → Hauptphase → Completion durchlaufen, Theme-Wechsel prüfen, Reduced-Motion via Developer Options "Animator duration scale = off".
7. **Doku** — `CHANGELOG.md`, `dev-docs/architecture/timer-state-machine.md` prüfen, ggf. `android/CLAUDE.md` (falls dort Affirmations-Pattern referenziert).

---

## Risiken

| Risiko | Mitigation |
|---|---|
| Player-Composables-Extraktion bricht Player-Layout | Reine Move-Refactor; `make test-unit-agent` und Player-Screenshot-Vergleich vor/nach. |
| `BreathingCircle` mit Compact-`outerSize = 240 dp` reicht auf sehr kleinen Devices nicht | Player nutzt dieselbe Konstante seit shared-087 ohne Probleme. Bei Bedarf zusätzlicher Schwellwert (`heightDp < 600 → 200 dp`) — additiv möglich. |
| `state_ready`/`state_completed` werden außerhalb von Code referenziert (z. B. accessibility-string-Verweise in XML) | `grep` über `app/src` (Code + Resources) — bestätigt: nur in `TimerFocusScreen.kt` referenziert. Sauberer Cut. |
| `LiveRegion` doppelt gesetzt (Pre-Roll-Slot UND Restzeit-Label) führt zu doppeltem TalkBack-Announce | Nur **eines** der beiden ist je nach Phase im UI-Tree (durch `AnimatedContent` ist immer nur ein Branch sichtbar). Trotzdem manuell mit TalkBack verifizieren. |
| Detekt `LongMethod` schlägt bei neuem `FocusTimerDisplay` zu | Aufteilen in `PreRollSlot`, `MainPhaseSlot`, `FocusTimerDisplay` als Wrapper — proaktiv splitten (siehe `android/CLAUDE.md` Memory zu detekt). |

---

## Vorbereitung

Nichts manuell — keine neuen Gradle-Dependencies, keine Asset-Änderung, keine Permission-Änderung.

---

## Offene Fragen

Keine — alle Entscheidungen sind getroffen (siehe Designentscheidungen 1, 4, 7).

---

Bereit für `/implement-ticket shared-090` (Android-Teil) — sobald shared-089 Android abgeschlossen ist.
