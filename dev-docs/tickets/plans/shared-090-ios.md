# Implementierungsplan: shared-090 (iOS)

Ticket: [shared-090-timer-atemkreis-analog-player](../shared/shared-090-timer-atemkreis-analog-player.md)
Erstellt: 2026-05-04
Scope: nur iOS (Android wird spaeter, sobald shared-087 Android steht)

---

## Mentales Modell

Der Timer-Display bekommt das gleiche visuelle Vokabular wie der Player aus shared-087:

- **Pre-Roll** — `BreathingCircleView` mit `phase: .preRoll` (statischer Track, gedaempfter Glow ohne Atem). Inhalt: Countdown-Zahl + Label "Vorbereitung". Hint "GLEICH GEHT'S LOS" unter dem Ring.
- **Hauptphase** (StartGong / Running / EndGong) — `BreathingCircleView` mit `phase: .playing` (Track + Restzeit-Bogen + Sonnen-Punkt + atmender Glow). Inhalt **leer** (kein Pause-Button — Timer hat keine Pause-Funktion). Restzeit-Label "NOCH 8:32 MIN" unter dem Ring.
- **Idle** und **Completion** — unveraendert.

Die `BreathingCircleView`-Komponente wird aus `Presentation/Views/GuidedMeditations/` nach `Presentation/Views/Shared/` verschoben. Damit der Typ nicht mehr "Player" im Namen traegt, wird `PlayerPhase` zu `MeditationPhase` umbenannt — der Timer hat keinen `.paused`-Zustand, also reduziert sich der Enum auf zwei Cases (`preRoll`, `playing`). Der Player mappt sein bisheriges `paused` ebenfalls auf `.playing` — visuell war das schon vorher identisch (Bogen friert ein, weil `currentTime` nicht mehr tickt; Atem laeuft kontinuierlich weiter). Damit verschwindet ein Case, der ohnehin nirgends visuell unterschieden wurde.

Affirmations-Texte und die "Schoen, dass du da bist"-Welcome-Headline fliegen waehrend der Sitzung raus — inklusive aller Properties, Tests und Lokalisierungs-Keys, die sie bedient haben. Idle und Completion behalten ihre Texte unveraendert.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `Presentation/Views/Timer/TimerView.swift` | Presentation | Umbau | `welcome.title` waehrend Sitzung entfernen, alte `preparationCircle()` und `progressCircle()` durch `BreathingCircleView` ersetzen, neuen `bottomLabel` (Hint vs. Restzeit-Label) einfuehren, `stateText`-Pfad entfernen |
| `Presentation/Views/GuidedMeditations/BreathingCircleView.swift` | Presentation | Verschieben | nach `Presentation/Views/Shared/BreathingCircleView.swift`. Inhaltlich unveraendert ausser Phase-Typ-Rename |
| `Application/ViewModels/GuidedMeditationPlayerViewModel.swift` | Application | Umbenennen | `PlayerPhase` → `MeditationPhase`, Cases auf `.preRoll` und `.playing` reduzieren (`.paused` faellt weg, `phase`-Computed mappt entsprechend) |
| `Application/ViewModels/TimerViewModel.swift` | Application | Bereinigen + Erweitern | `currentAffirmationIndex`-Property entfernen, Affirmations-Rotation in `dispatch(.startPressed)` entfernen, neue computed Properties: `phase: MeditationPhase`, `formattedRemainingMinutes` (mm:ss-Format), `progressInRunningPhase: Double` (0–1, vergangene Sitzungszeit ohne Pre-Roll-Anteil) |
| `Application/ViewModels/TimerViewModel+Affirmations.swift` | Application | Loeschen | komplette Extension wird entfernt |
| `Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift` | Presentation | Anpassen | `case .paused` aus zwei `switch`-Statements entfernen (Phase ist jetzt zwei Cases) |
| `Resources/de.lproj/Localizable.strings` | Resources | Loeschen | `affirmation.preparation.1-4`, `affirmation.running.1-5` entfernen |
| `Resources/en.lproj/Localizable.strings` | Resources | Loeschen | dito EN |
| `StillMomentTests/TimerViewModel/TimerViewModelStateTests.swift` | Tests | Bereinigen + Erweitern | `testAffirmationsRotation`, `testPreparationAffirmations`, `testRunningAffirmations` entfernen. Neu: `testPhaseInPreparation`, `testPhaseInRunning`, `testFormattedRemainingMinutes` |
| `StillMomentTests/GuidedMeditationPlayerViewModelTests+Phase.swift` | Tests | Anpassen | Tests, die `.paused` als Phase erwarten, an neuen Zwei-Case-Enum anpassen (sofern vorhanden) |
| `StillMomentUITests/TimerFlowUITests.swift` | UI Tests | Anpassen | Z. 171 `XCTAssertTrue(self.app.staticTexts["timer.state.text"]…)` entfernen — der Container existiert nicht mehr |
| `StillMomentTests/Presentation/TypographyTests.swift` | Tests | Pruefen | `playerRemainingTime` wird jetzt auch vom Timer genutzt — Test-Group "Player" bleibt unveraendert (Rolle wandert nicht) |

### Codestellen, die explizit unveraendert bleiben

- `Domain/Models/MeditationTimer.swift` — Domain-Modell, State-Machine, `progress`, `remainingSeconds`, `totalSeconds` bleiben
- `Domain/Models/PreparationCountdown.swift` — bleibt
- `Application/ViewModels/TimerReducer.swift` — Reducer, Effects unveraendert
- `Infrastructure/Services/AudioService.swift` — Lock-Screen-Keep-Alive, Gongs unveraendert
- `Presentation/Views/Timer/Components/BreathDial.swift` — Idle-Picker bleibt
- `Presentation/Views/Timer/Components/IdleSettingsList.swift` — Idle-Liste bleibt
- `Presentation/Views/Shared/MeditationCompletionView.swift` — Completion-Screen bleibt
- `Presentation/Views/Shared/Font+Theme.swift` — bestehende Rollen werden wiederverwendet (`playerCountdown`, `playerTimestamp`, `playerRemainingTime`); Doku-Beispiel mit `welcome.title` darf stehen bleiben (rein Doku)
- Player-Lokalisierungs-Keys (`guided_meditations.player.preroll.label`, `…preroll.hint`, `…remainingTime.format`) — werden vom Timer mitbenutzt. Pragmatisch, kein Refactor

---

## API-Recherche

Keine neuen Framework-APIs noetig — alles im Werkzeugkasten von shared-087:

| API | Verfuegbarkeit | Verwendung |
|---|---|---|
| `@Environment(\.accessibilityReduceMotion)` | iOS 13+ | Reduced-Motion-Detection in `TimerView`, an `BreathingCircleView` durchgereicht |
| `Animation.easeInOut(duration:).repeatForever(autoreverses: true)` | iOS 13+ | Atem-Animation, bereits in `BreathingCircleView` |
| `Circle().trim(from:to:).stroke(...)` | iOS 13+ | Restzeit-Bogen, bereits in `BreathingCircleView` |
| `withAnimation(_:_:)` mit `@State Bool` | iOS 13+ | Cross-Fade Pre-Roll → Hauptphase via `.transition(.opacity)` und `.animation(.easeInOut, value: phase)` |

Hinweis: `BreathingCircleView` ist bereits generisch ueber `Content: View` parametrisiert. Der Timer uebergibt fuer die Hauptphase einen leeren `EmptyView` als Inhalt.

---

## Designentscheidungen

### 1. Phase-Enum reduziert auf zwei Cases (`preRoll`, `playing`)

**Trade-off:** Drei Cases (`preRoll`, `playing`, `paused`) lassen den Player-Code lesbarer ("paused" steht explizit). Zwei Cases zwingen den Player, "ist gerade pausiert?" ueber `viewModel.isPlaying` separat zu beantworten — was er ohnehin schon tut (`GlassPauseButton(isPlaying: …)`).

**Entscheidung:** Zwei Cases. Begruendung:

- Visuell hat `BreathingCircleView` `playing` und `paused` schon vorher identisch behandelt (siehe heutigen Code: `case .playing, .paused:` in jedem Switch).
- `MeditationPhase` ist eine **Layout-Phase** der View, kein Audio-Zustand. Ob Audio gerade pausiert, ist orthogonal zur Frage, ob die Hauptphase laeuft.
- Der Timer hat keinen `paused`-Zustand — das Ticket fordert explizit, dass das Innere des Atemkreises leer bleibt.

### 2. `MeditationPhase` lebt im Application-Layer

**Trade-off:** Der Phase-Typ koennte nach Domain wandern (semantisch sauberer fuer ein Zwei-Phasen-Modell), oder im Presentation-Layer bei `BreathingCircleView` bleiben (View-spezifisch). Application-Layer ist der Mittelweg.

**Entscheidung:** Bleibt im Application-Layer, weiter in `GuidedMeditationPlayerViewModel.swift` definiert. Beide ViewModels (`TimerViewModel`, `GuidedMeditationPlayerViewModel`) berechnen ihre `phase` aus dem jeweiligen Domain-Zustand. Domain bleibt clean (kein UI-Begriff), Presentation referenziert nur den Application-Typ. Eine spaetere Verschiebung in eine eigene Datei `Application/Models/MeditationPhase.swift` ist denkbar, aber erst sinnvoll wenn der Enum waechst.

### 3. Welcome-Headline `welcome.title` bleibt im Lokalisierungs-Key

**Trade-off:** Der Key wird nach diesem Ticket nirgends mehr referenziert. Konsequent waere, ihn ebenfalls zu loeschen.

**Entscheidung:** Key wird **entfernt**, da der Hinweis im Ticket explizit "tote Lokalisierungs-Keys aufraeumen" verlangt und der Key nach dem Umbau nirgends mehr referenziert wird. Auch das Doku-Beispiel in `Font+Theme.swift` Z. 242 wird auf einen anderen Key umgehaengt (z.B. `timer.idle.headline`), damit kein toter Key-Verweis stehen bleibt.

### 4. Restzeit-Bogen-Progress: vergangene Sitzungszeit ohne Pre-Roll-Anteil

**Trade-off:** `MeditationTimer.progress` aus dem Domain-Modell ist `1.0 - (remainingSeconds / totalSeconds)` — also vergangene Zeit / gesamte Sitzung. Der Wert ist **0 in der Pre-Roll-Phase** (weil `totalSeconds` die Hauptphasen-Sekunden meint und `remainingSeconds` waehrend Pre-Roll noch `totalSeconds` betraegt). Genau das Verhalten, das wir wollen: bei Uebergang zur Hauptphase startet der Bogen bei 0 und waechst.

**Entscheidung:** `BreathingCircleView` bekommt `progress: viewModel.progress` — keine Sonderlogik. Der Pre-Roll-Branch in `BreathingCircleView` zeigt den Bogen ohnehin nicht (siehe `progressArc` switch).

### 5. Restzeit-Format teilen mit dem Player ueber `formattedRemainingMinutes`

**Entscheidung:** Neue computed Property `TimerViewModel.formattedRemainingMinutes` mit identischer Semantik wie im Player: `mm:ss` aus `remainingSeconds`. Verwendet zusammen mit dem Player-Lokalisierungs-Key `guided_meditations.player.remainingTime.format` ("NOCH %@ MIN"). Der Key ist heute Player-praefigiert; der Hinweis im Ticket erlaubt Pragmatismus — kein Rename in diesem Scope.

### 6. Layer-Reihenfolge im neuen `timerDisplay`

**Entscheidung:** Layout vertikal:

1. Spacer (top, expanding)
2. `BreathingCircleView` — Groesse: 280 px (analog zum Player; iPhone SE: 240 px wenn `geometry.size.height < 700`)
3. Spacer (12 px)
4. `bottomLabel` — Pre-Roll: "GLEICH GEHT'S LOS"-Hint, Hauptphase: "NOCH … MIN"-Restzeit-Label
5. Spacer (expanding)

Lehrer/Titel-Block des Players entfaellt — Timer hat keinen Lehrer. Schliessen-Button bleibt in der Toolbar oben links (heutiges Verhalten). Das ist der "einzige sichtbare Unterschied" laut Ticket Punkt 6 im Manuellen Test.

### 7. `circleContent` der Hauptphase bleibt leer

**Entscheidung:** `BreathingCircleView(...) { EmptyView() }` in der Hauptphase. Pre-Roll uebergibt das Countdown+Label-VStack identisch zum Player.

### 8. Cross-Fade Pre-Roll → Hauptphase via `.animation(.easeInOut, value: phase)`

**Entscheidung:** `.animation(.easeInOut(duration: 0.4), value: self.viewModel.phase)` auf das `timerDisplay`-Container-VStack. Pre-Roll-Inhalt und Hauptphasen-Inhalt nutzen `.transition(.opacity)`, sodass das Label "Vorbereitung" und der Hint "GLEICH GEHT'S LOS" weich gegen den leeren Inneren-Slot und das Restzeit-Label kreuzblenden. Identisch zur Player-Loesung.

---

## Refactorings

Drei kleine, klar abgegrenzte Refactorings vor dem eigentlichen View-Umbau:

1. **`PlayerPhase` → `MeditationPhase` umbenennen + auf zwei Cases reduzieren**
   - Risiko: Niedrig. Drei Stellen (`GuidedMeditationPlayerViewModel.swift`, `BreathingCircleView.swift`, `GuidedMeditationPlayerView.swift`) fassen den Typ an. Player-Tests in `…+Phase.swift` beruehren `.paused` ggf. — pruefen und Test-Erwartungen anpassen.
   - Mitigation: Test-Suite vor und nach dem Refactor laufen lassen.

2. **Affirmations-Code restlos entfernen**
   - `TimerViewModel+Affirmations.swift` Datei loeschen
   - `TimerViewModel.currentAffirmationIndex` Property entfernen
   - Affirmations-Rotation in `dispatch(.startPressed)` (Z. 154–157) entfernen
   - Drei Tests in `TimerViewModelStateTests.swift` entfernen
   - Lokalisierungs-Keys `affirmation.preparation.1-4` und `affirmation.running.1-5` (DE+EN) entfernen
   - Risiko: Niedrig. Das Feature ist visuell tot, sobald `TimerView` die Affirmations nicht mehr referenziert.

3. **`BreathingCircleView.swift` verschieben** nach `Presentation/Views/Shared/`
   - Risiko: Niedrig. Datei-Verschiebung in synchronisierter Group — Xcode erkennt es automatisch. Imports unveraendert (gleiches Modul).

---

## Fachliche Szenarien

### AK Pre-Roll-Phase

- **Gegeben:** Vorbereitungszeit ist 6 s, Timer wurde gerade gestartet
  **Wenn:** View rendert
  **Dann:** Atemkreis-Box zentriert sichtbar, statischer Ring-Track, Glow gedaempft (kein Atem). Im Inneren: Countdown-Zahl "6" gross + Label "Vorbereitung". Unter dem Ring: "GLEICH GEHT'S LOS" (Uppercase, Sekundaerfarbe). Schliessen-Button oben links erreichbar. **Keine** "Schoen, dass du da bist"-Headline. **Keine** Affirmations-Zeile.

- **Gegeben:** Pre-Roll laeuft, Vorbereitungszeit war 6 s
  **Wenn:** Eine Sekunde vergeht
  **Dann:** Countdown-Zahl wechselt zu "5" — keine sonstige visuelle Aenderung, der Bogen erscheint **nicht**.

- **Gegeben:** Pre-Roll laeuft mit aktivem Reduced-Motion-Setting
  **Wenn:** View rendert
  **Dann:** Identisches Verhalten — Glow ist ohnehin nicht animiert in Pre-Roll.

### AK Hauptphase / Atemkreis

- **Gegeben:** Pre-Roll ist abgelaufen, Timer ist in `.startGong`/`.running`
  **Wenn:** View rendert
  **Dann:** Atemkreis sichtbar mit allen drei Layern: Track + Restzeit-Bogen (waechst mit Sitzungsverlauf) + Sonnen-Punkt am vorderen Bogen-Ende + atmender Glow (~16 s Zyklus). **Inneres bleibt leer** — kein Pause-Button, kein Restzeit-Text, keine Affirmation. Unter dem Ring: "NOCH 9:54 MIN" o.ae.

- **Gegeben:** Hauptphase laeuft, Sitzungs-Restzeit ist 8:32
  **Wenn:** View rendert das Restzeit-Label
  **Dann:** Anzeige "NOCH 8:32 MIN" (DE) bzw. "8:32 MIN LEFT" (EN). Uppercase, tabular-Numerals.

- **Gegeben:** Hauptphase laeuft mit aktivem Reduced-Motion
  **Wenn:** View rendert
  **Dann:** Glow ist statisch (keine Atem-Animation), Restzeit-Bogen aktualisiert sich weiterhin.

- **Gegeben:** Timer ist im `.startGong`-Zustand (kurz nach Pre-Roll-Ende)
  **Wenn:** View rendert
  **Dann:** Atemkreis verhaelt sich wie in `.running` — keine eigene Anzeige fuer den Gong. Identisch fuer `.endGong` am Ende.

### AK Uebergang Pre-Roll → Hauptphase

- **Gegeben:** Pre-Roll laeuft, Countdown bei 1 s
  **Wenn:** Eine Sekunde vergeht (Uebergang in `.startGong`/`.running`)
  **Dann:** Cross-Fade (~400 ms) — Countdown-Zahl + "Vorbereitung"-Label + "GLEICH GEHT'S LOS"-Hint blenden aus, Restzeit-Bogen erscheint bei 0 und beginnt zu wachsen, Glow startet zu atmen, Restzeit-Label "NOCH … MIN" blendet ein.

### AK Entfernte Elemente

- **Gegeben:** Timer in Pre-Roll, Hauptphase, StartGong oder EndGong
  **Wenn:** View rendert
  **Dann:** Headline `welcome.title` ("Schoen, dass du da bist" / "Lovely to see you") wird **nicht** angezeigt. Affirmations-Container `timer.state.text` existiert nicht mehr im UI-Tree. Kein alter Progress-/Preparation-Circle mehr — der `BreathingCircleView` ist die einzige Visualisierung.

- **Gegeben:** Timer-Tab ist im `.idle`-Zustand
  **Wenn:** View rendert
  **Dann:** Idle-Screen unveraendert (BreathDial-Picker + Settings-Liste + Beginnen-Button).

- **Gegeben:** Timer ist im `.completed`-Zustand
  **Wenn:** View rendert
  **Dann:** Completion-Screen unveraendert (`MeditationCompletionView`-Overlay).

### AK Schliessen waehrend Pre-Roll/Hauptphase

- **Gegeben:** Pre-Roll oder Hauptphase laeuft
  **Wenn:** User tippt den `xmark`-Button oben links
  **Dann:** `viewModel.resetTimer()` wird aufgerufen, Sitzung beendet, View kehrt in den Idle-Zustand. Verhalten unveraendert zu heute.

### AK Geteilte Atemkreis-Komponente

- **Gegeben:** `BreathingCircleView` lebt in `Presentation/Views/Shared/`
  **Wenn:** Build laeuft
  **Dann:** Beide Aufrufer (`GuidedMeditationPlayerView`, `TimerView`) compilieren ohne Aenderungen ausser Datei-Lokalisierung. Es gibt keinerlei Player-spezifische Annahmen (Audio, AVPlayer) im Komponenten-Code. Phase-Typ heisst `MeditationPhase`, nicht `PlayerPhase`.

### AK Aufraeumen

- **Gegeben:** Build laeuft mit Lokalisierungs-Lint
  **Wenn:** `make check` ausgefuehrt wird
  **Dann:** Keine Warnungen ueber tote Keys; `affirmation.preparation.*`, `affirmation.running.*`, `welcome.title` sind in DE und EN entfernt.

- **Gegeben:** Test-Suite laeuft
  **Wenn:** `make test-unit` ausgefuehrt wird
  **Dann:** Alle Tests gruen. Keine Tests fuer Affirmations existieren mehr. Bestehende Reducer-/State-Machine-/Completion-Tests laufen unveraendert.

### AK Reduced Motion / Accessibility

- **Gegeben:** Hauptphase laeuft mit Reduced-Motion aktiv
  **Wenn:** View rendert
  **Dann:** Atem-Animation aus, Glow konstant, Restzeit-Bogen aktualisiert sich weiterhin.

- **Gegeben:** Pre-Roll laeuft
  **Wenn:** Screen Reader fokussiert auf den Countdown
  **Dann:** Accessibility-Identifier `timer.display.time` ist auf der Countdown-Zahl, accessibilityLabel beschreibt die verbleibenden Sekunden ("Noch 6 Sekunden Vorbereitung" o.ae., bestehender String).

- **Gegeben:** Hauptphase laeuft
  **Wenn:** Screen Reader fokussiert auf das Restzeit-Label
  **Dann:** Accessibility-Identifier `timer.display.time` ist auf dem Restzeit-Label, accessibilityValue beschreibt die verbleibende Zeit ("8 Minuten und 32 Sekunden verbleibend" o.ae., bestehender String).

- **Gegeben:** Schliessen-Button im Toolbar
  **Wenn:** Screen Reader fokussiert
  **Dann:** Label `accessibility.endMeditation`, Hint `accessibility.endMeditation.hint` — unveraendert.

### AK Theming

- **Gegeben:** Theme = "warm", System-Mode = Dark
  **Wenn:** View rendert
  **Dann:** Hintergrund nutzt warmen Dark-Gradient, Atemkreis-Glow warm-orange — visuell identisch zum Player im selben Theme/Mode.

- **Gegeben:** Theme-Wechsel waehrend laufender Sitzung
  **Wenn:** User wechselt Theme
  **Dann:** Atemkreis nimmt neue Tokens an (gleiche Tokens wie Player) — keine doppelten oder timer-spezifischen Theme-Werte.

---

## Reihenfolge der Akzeptanzkriterien (TDD)

Innen → aussen, damit Build immer gruen bleibt:

1. **Refactor: `PlayerPhase` → `MeditationPhase`** (zwei Cases) — Tests anpassen, Player-Build pruefen, alle Tests gruen halten.
2. **Refactor: BreathingCircleView verschieben** — Datei-Move nach `Shared/`, alle Aufrufer kompilieren.
3. **Aufraeumen: Affirmations entfernen** — `TimerViewModel+Affirmations.swift` loeschen, `currentAffirmationIndex` und Rotation entfernen, drei Tests entfernen, Lokalisierungs-Keys entfernen. `welcome.title` entfernen.
4. **TimerViewModel erweitern** — `phase: MeditationPhase` und `formattedRemainingMinutes` als computed Properties, neue Tests `testPhaseInPreparation`, `testPhaseInRunning`, `testFormattedRemainingMinutes` (Red-Green-Refactor).
5. **TimerView umbauen** — Pre-Roll und Hauptphase auf `BreathingCircleView` umstellen, neuen `bottomLabel` einfuehren, `stateText`/`preparationCircle`/`progressCircle` entfernen, Welcome-Headline-Block in der Sitzung entfernen.
6. **UI-Test anpassen** — `TimerFlowUITests.testTimerStateNavigation` Z. 171 (`timer.state.text`-Assertion) entfernen.
7. **Manueller Test** auf Simulator (iPhone SE + iPhone 16 Plus): Idle → Pre-Roll → Hauptphase → Completion durchlaufen, Theme-Wechsel pruefen, Reduced-Motion pruefen.
8. **Doku** — CHANGELOG.md ergaenzen, `dev-docs/architecture/timer-state-machine.md` pruefen ob UI-Display dort beschrieben ist.

---

## Risiken

| Risiko | Mitigation |
|---|---|
| Phase-Rename bricht bestehende Player-Tests | Vor Refactor `make test-unit` als Baseline. Nach Refactor sofort gruen, sonst zurueckrollen. |
| `BreathingCircleView` verschieben in synchronisierter Group erzeugt Xcode-Probleme | Datei wird per `mv` verschoben, Xcode synct automatisch (Sync-Group). Build-Check direkt im Anschluss. |
| Restzeit-Bogen springt bei Pre-Roll → Hauptphase-Uebergang sichtbar | Bogen erscheint bei `progress = 0` und waechst — der Cross-Fade verdeckt den ersten Frame ohnehin. Bei Bedarf `.animation(.linear(duration: 0.5), value: progress)` (existiert schon in `BreathingCircleView`). |
| Welcome-Key-Loeschung haengt mit `Font+Theme.swift`-Doku zusammen | Doku-Beispiel auf `timer.idle.headline` umhaengen — dieser Key bleibt, da der Idle-Screen ihn nutzt. |
| Affirmations-Tests-Loeschung haengt sich an importierte Imports | `XCTAssertFalse(affirmation.isEmpty)` — keine kritischen Imports, sauberer Cut. |
| iPhone SE Layout: BreathingCircleView 280 px ist zu gross | In `TimerView` `isCompactHeight ? 240 : 280` als Groessen-Override. Heutige `circleSize`-Logik (Z. 305) wird sinngemaess uebernommen — `BreathingCircleView` hat `outerSize: 280` als Konstante; ggf. parametrisierbar machen oder in einem `frame(width:height:)`-Wrapper skalieren. **Pruefen ob `.scaleEffect()` reicht oder ob `BreathingCircleView` einen `outerSize`-Init-Parameter braucht.** |

---

## Vorbereitung

Nichts manuell — keine Xcode-Target-Aenderung, keine Provisioning-Profiles, kein neues Asset.

---

## Offene Fragen

- [ ] **BreathingCircleView fixe 280 px vs. parametrisierbar:** Auf iPhone SE muss der Atemkreis kleiner werden (heutige Timer-Logik: 55 % der Breite). Option A: `BreathingCircleView` bekommt einen optionalen `outerSize`-Parameter (default 280). Option B: Wrapper-`.scaleEffect()` + `.frame()` im Aufrufer. — **Empfehlung: Option A**, da auch der Player auf iPhone SE knapp wird und davon profitieren wuerde. Diese Aenderung beruehrt den Player nicht (default-Wert) — additive API-Erweiterung.
- [ ] **`welcome.title`-Loeschung wirklich gewollt?** Der Idle-Screen nutzt `timer.idle.headline`, nicht `welcome.title` — der Key war einzig fuer den Sitzungs-Header. Bestaetigt das Loeschen, oder behalten als "kann jemand anders nochmal brauchen"?

---

Bereit fuer `/implement-ticket shared-090` (iOS-Teil) — sobald die offenen Fragen geklaert sind.
