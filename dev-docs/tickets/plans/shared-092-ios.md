# Implementierungsplan: shared-092 (iOS)

Ticket: [shared-092](../shared/shared-092-danke-screen-redesign.md)
Erstellt: 2026-05-15

## Annahmen

Bewusst getroffene Entscheidungen, die in den Plan eingeflossen sind:

- **Phase-Modellierung**: `MeditationPhase` wird um `case completion` erweitert (statt eigenes `BreathingCirclePhase`-Enum). Begruendung: Das Enum ist laut Doc-Kommentar schon heute eine reine "Layout-Phase" — `.completion` passt thematisch dazu und vermeidet Duplikation. ViewModels (`TimerViewModel.phase`, `GuidedMeditationPlayerViewModel.phase`) liefern weiterhin nur `.preRoll`/`.playing`. `.completion` wird ausschliesslich von `MeditationCompletionView` hardcodiert an `BreathingCircleView` uebergeben.
- **Localization-Keys**: Headline wird umbenannt von `guided_meditations.player.completion.headline` zu `completion.headline` (User-Entscheidung). Subtitle-Key `guided_meditations.player.completion.subtitle` wird ersatzlos entfernt. Neuer Button-Key: `completion.button.done`.
- **Glow-Tempo in `.completion`**: Volle 16 s wie heute (`breathHalfPeriod = 8`). Keine Aenderung des bestehenden Wertes — falls "leicht ruhiger" gewuenscht, separates Follow-up.
- **Glow-Werte in `.completion`**: scale 0.92–1.05, opacity 0.65–1.0 (vom Ticket explizit als akzeptable Empfehlung genannt). Leicht gedaempfter als die Hauptphase, passend zum entspannenden Abschluss.
- **Glow-Bounding** auf dem Completion-Screen: `outerSize: 200` (statt Default 280). Damit ergibt sich `glowSize ≈ 157` — naehe an der Handoff-Vorgabe (160×160 Bounding-Box). Headline und Button bekommen vertikal genug Platz.
- **Headline-Zeilenumbruch**: Kein manueller `\n` im String. SwiftUI bricht mit `.multilineTextAlignment(.center)` und `.fixedSize(horizontal: false, vertical: true)` automatisch auf zwei Zeilen.
- **Stagger-Guard**: Ein `@State private var didAppear = false` verhindert mehrfaches Anstossen des Stagger-Fade-in bei wiederholtem `onAppear` (z. B. Sheet-/Toolbar-Lifecycle in iOS). Das Glow-Atem-Loop ist davon unabhaengig.
- **Subtitle-Cleanup auf iOS**: Im iOS-Test-Stand existiert kein Subtitle-spezifischer Test (gegrept). Daher nichts zu entfernen ausser dem `.strings`-Eintrag.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Application/Models/MeditationPhase.swift` | Application | Erweitern | `case completion` hinzufuegen, Doc-Kommentar erweitern |
| `Presentation/Views/Shared/BreathingCircleView.swift` | Presentation | Erweitern | Layer-Visibility + glow-Werte fuer `.completion`-Phase; bestehende `.preRoll`/`.playing` unveraendert |
| `Presentation/Views/Shared/MeditationCompletionView.swift` | Presentation | Umbauen | Herz-Icon raus; `BreathingCircleView(phase: .completion, ...)` rein; Subtitle entfernen; Button-Label "Fertig"; Stagger-Fade-in; `accessibilityReduceMotion`-Bridge |
| `Resources/de.lproj/Localizable.strings` | Resources | Aendern | `completion.headline` (neu), `completion.button.done` (neu); alte Keys (`guided_meditations.player.completion.headline`, `.subtitle`) entfernen |
| `Resources/en.lproj/Localizable.strings` | Resources | Aendern | dito EN |
| `StillMomentTests/Presentation/BreathingCirclePresentationTests.swift` (neu) | Tests | Neu | Pure-Logik-Tests fuer Layer-Visibility pro Phase |
| `StillMomentTests/Presentation/MeditationCompletionViewTests.swift` (neu) | Tests | Neu | Stagger-Konfiguration + onBack-Closure + Reduced-Motion-Zweig (siehe "Testbarkeits-Notiz") |

**Aufrufer-Check (keine Aenderung noetig, nur Verifikation):**
- `Presentation/Views/Timer/TimerView.swift` Zeile 93–97: bindet `MeditationCompletionView` als Overlay bei `timerState == .completed` — bleibt unveraendert.
- `Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift` Zeile 43–49: bindet bei `viewModel.isCompleted` — bleibt unveraendert.
- `Presentation/Views/Shared/RootContainerView.swift` Zeile 50–60: bindet bei `snapshot.isPresent` (Termination-Pfad aus shared-080) — bleibt unveraendert.
- `Presentation/Views/Timer/TimerView.swift` Zeile 287: `BreathingCircleView(phase: ...)` mit `.preRoll`/`.playing` — bleibt unveraendert. Switch-Statements im View profitieren von compiler-erzwungener Exhaustivitaet.
- `Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift` Zeile 175: dito.

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `@Environment(\.accessibilityReduceMotion)` | iOS 14+ | Apple Docs | Bereits in `TimerView` und `GuidedMeditationPlayerView` verwendet — Pattern uebernehmen |
| `withAnimation(.easeOut(duration:).delay(_:))` | iOS 13+ | Apple Docs | Standard SwiftUI. `.easeOut` (cubic-bezier-Naehe) ist gut genug; Handoff fordert `cubic-bezier(0.22, 1, 0.36, 1)` — Apples `.easeOut` ist visuell aequivalent fuer 500 ms Mikro-Animation |
| `.transition(.move(edge: .bottom).combined(with: .opacity))` | iOS 13+ | Apple Docs | Bereits an den Aufrufer-Stellen verwendet — Inner-Stagger ist `onAppear`-getriggert, unabhaengig von dieser Aussen-Transition |
| `.fixedSize(horizontal: false, vertical: true)` | iOS 13+ | Apple Docs | Stellt sicher, dass Text mehrzeilig bricht auch in geometrisch eingeschraenkten Containern |

Keine neuen APIs noetig — alles aus bestehendem SwiftUI-Repertoire.

## Design-Entscheidungen

### 1. `.completion` als dritter Case im bestehenden `MeditationPhase`

**Trade-off**: Eigenes `BreathingCirclePhase`-Enum (saubere Trennung) vs. `MeditationPhase` erweitern (Konsistenz, kein Duplikat).
**Entscheidung**: Erweitern. `MeditationPhase` ist laut Doc-Kommentar bereits eine reine Visualisierungs-Phase ("Layout-Phase"). Compiler-erzwungene Exhaustivitaet in den vorhandenen `switch self.phase`-Statements (in `BreathingCircleView`) ist ein Bonus — wir koennen den neuen Case nicht versehentlich vergessen.

### 2. Stagger via `@State`-Opacities, nicht via `.transition`

**Trade-off**: SwiftUI-`.transition` (deklarativ) vs. `@State`-Opacities mit `withAnimation(...).delay(...)` (imperativ-feiner).
**Entscheidung**: `@State`-Opacities. Stagger braucht pro Element einen anderen Delay — `.transition` kann das nicht direkt. Das Pattern matched die Aufgabenformulierung im Ticket eins zu eins.

### 3. Pure Helper fuer Layer-Visibility, kein ViewInspector

**Trade-off**: Snapshot-Test-Framework / ViewInspector einfuehren vs. Logik in pure Functions extrahieren.
**Entscheidung**: Pure Functions. Das Projekt hat kein Snapshot-/View-Test-Setup. Wir extrahieren die `phase → Layer-Visibility / glow-Werte`-Logik in eine reine `BreathingCirclePresentation`-Helper-Struct (oder freie Funktionen in einem Namespace). Die View ruft den Helper an, Tests treffen den Helper direkt. Kein neues Framework noetig.

## Refactorings

1. **`BreathingCircleView`: Phase-spezifische Visual-Werte in Pure Helper auslagern**
   - Heute: `glowScale`, `glowOpacity`, `glowAnimation` sind computed properties direkt in der View. Sie sind aber pure (nur Input: `phase`, `reduceMotion`, `breathing`).
   - Nach Refactoring: `BreathingCirclePresentation` (struct oder enum-Namespace) mit static functions oder pure properties.
   - Begruendung: noetig fuer Testbarkeit der `.completion`-Phase (siehe AK "BreathingCircle in .completion zeigt nur das Glow-Layer").
   - Scope: nur Extraktion bestehender Logik, kein Verhaltenswechsel. Risiko: niedrig — `make test-unit-agent` faengt Regressionen in den vorhandenen Phase-Tests ab.

Kein weiteres Refactoring noetig — `MeditationCompletionView` wird ohnehin umgeschrieben.

## Fachliche Szenarien

### AK-Block "Glow statt Herz"

- **AK 1.1**: Gegeben: Eine geleitete Meditation lief und ist gerade fertig.
  Wenn: Der Completion-Screen erscheint.
  Dann: Kein Herz-Symbol ist sichtbar. Stattdessen ist ein warmer, sanft pulsierender Glow zu sehen (`BreathingCircleView` in `.completion`-Phase).

- **AK 1.2**: Gegeben: Der Completion-Screen ist sichtbar.
  Wenn: Der Nutzer hinschaut.
  Dann: Es ist NUR das Glow-Layer zu sehen — kein statischer Ring-Track, kein Restzeit-Bogen, kein Sonnen-Punkt am Bogen-Ende.

- **AK 1.3**: Gegeben: `BreathingCirclePresentation.isTrackVisible(in: .completion)` ist erreichbar.
  Wenn: Der Helper aufgerufen wird.
  Dann: Er gibt `false` zurueck. Analog fuer Arc und Dot.
  (Zusatz: fuer `.preRoll` gibt `isTrackVisible` `true` zurueck, `isArcVisible` `false`. Fuer `.playing` beide `true`. → Charakterisierung des bestehenden Verhaltens, kein Drift.)

- **AK 1.4**: Gegeben: Reduced Motion ist im System-Setting AKTIV.
  Wenn: Der Completion-Screen erscheint.
  Dann: Der Glow ist sichtbar im neutralen Mittelwert (kein Atmen).

- **AK 1.5**: Gegeben: Ein Timer mit 1 Minute laeuft im Vordergrund.
  Wenn: Die Minute ablaeuft.
  Dann: Der Timer-Atemkreis (Hauptphase: Track + Arc + Dot + atmender Glow) verhaelt sich unveraendert bis zum Switch auf Completion. Keine Regression im Timer-Layer.

- **AK 1.6**: Gegeben: Eine geleitete Meditation laeuft.
  Wenn: Der Nutzer pausiert / wieder startet.
  Dann: Der Player-Atemkreis verhaelt sich unveraendert. Keine Regression im Player-Layer.

### AK-Block "Eine zentrale Botschaft"

- **AK 2.1**: Gegeben: Locale ist Deutsch.
  Wenn: Completion-Screen erscheint.
  Dann: Headline-Text lautet EXAKT "Danke, dass du dir diesen Moment genommen hast."

- **AK 2.2**: Gegeben: Locale ist Englisch.
  Wenn: Completion-Screen erscheint.
  Dann: Headline-Text lautet EXAKT "Thank you for taking this moment for yourself."

- **AK 2.3**: Gegeben: Completion-Screen ist sichtbar.
  Wenn: Der Nutzer hinschaut.
  Dann: Kein Subtitle / kein zweiter Textblock unter der Headline ist vorhanden.

- **AK 2.4**: Gegeben: VoiceOver ist aktiv.
  Wenn: Der Cursor auf die Headline wandert.
  Dann: Sie wird als Header (`.isHeader`-Trait) angesagt.

- **AK 2.5**: Gegeben: iPhone-Standard-Breite (z. B. iPhone 16 Plus, 16 Pro), Headline-Roll `.screenTitle`.
  Wenn: Headline gerendert wird.
  Dann: Sie bricht auf zwei Zeilen, horizontal zentriert.

### AK-Block "Button 'Fertig'"

- **AK 3.1**: Gegeben: Locale ist Deutsch / Englisch.
  Wenn: Button gerendert wird.
  Dann: Label ist "Fertig" / "Done" (neuer Key `completion.button.done`).

- **AK 3.2**: Gegeben: VoiceOver ist aktiv.
  Wenn: Der Cursor auf den Button wandert.
  Dann: Er liest die Konsequenz vor — kontextabhaengig "Zurueck zu Meditationen" (Player/RootContainer-Pfad) oder "Zurueck zum Timer" (Timer-Pfad). Wert kommt ueber bestehenden `backAccessibilityLabel`-Parameter.

- **AK 3.3**: Gegeben: Completion-Screen ist nach Timer-Ablauf sichtbar.
  Wenn: Nutzer tippt "Fertig".
  Dann: Wird `onBack`-Closure aufgerufen → Timer wird zurueckgesetzt (`viewModel.resetTimer()`), Screen verschwindet.

- **AK 3.4**: Gegeben: Completion-Screen ist nach Player-Ende sichtbar.
  Wenn: Nutzer tippt "Fertig".
  Dann: Wird `onBack`-Closure aufgerufen → `dismiss()` triggert Navigation zurueck zur Library.

- **AK 3.5**: Gegeben: Button-Stil ist `warmPrimaryButton` (bestehender Stil).
  Wenn: Button gerendert wird.
  Dann: Hit-Target ist ≥ 44 pt (durch `warmPrimaryButton` bereits gewaehrleistet).

### AK-Block "Auftritts-Animation"

- **AK 4.1**: Gegeben: Completion-Screen wird gerade eingeblendet, Reduced Motion ist AUS.
  Wenn: `onAppear` feuert.
  Dann: Drei Elemente animieren ihre Opacity 0 → 1 und Y-Versatz +8 → 0 mit `.easeOut`-Kurve, Dauer 500 ms:
  - Glow: Delay 0 ms
  - Headline: Delay 120 ms
  - Button: Delay 240 ms

- **AK 4.2**: Gegeben: Reduced Motion ist AN.
  Wenn: Completion-Screen erscheint.
  Dann: Alle drei Elemente sind sofort vollstaendig sichtbar (Opacity 1, kein Y-Versatz), kein Stagger, kein Atem-Pulse.

- **AK 4.3**: Gegeben: Completion-Screen wurde gerade eingeblendet (Stagger lief), `onAppear` feuert nochmal (z. B. Sheet-Resize, Toolbar-Bug).
  Wenn: Der zweite `onAppear` greift.
  Dann: Der Stagger laeuft NICHT noch einmal — Guard via `@State didAppear` verhindert Reset auf 0.

- **AK 4.4**: Gegeben: Der Glow ist eingeblendet (Stagger durch).
  Wenn: Zeit vergeht.
  Dann: Der Atem-Loop laeuft permanent weiter (16 s Vollzyklus). Stagger und Atem-Loop sind voneinander entkoppelt.

- **AK 4.5**: Gegeben: App wurde im Hintergrund beendet, Meditation lief zu Ende (shared-080-Pfad).
  Wenn: App neu startet, `RootContainerView` zeigt Completion-Overlay.
  Dann: Stagger-Fade-in laeuft hier identisch — er ist `onAppear`-getriggert, nicht an einen Vorgaenger-View gekoppelt.

### AK-Block "Theming"

- **AK 5.1**: Gegeben: Theme "Candlelight" Light Mode.
  Wenn: Completion-Screen erscheint.
  Dann: Hintergrund nutzt `theme.backgroundGradient` (NICHT den Mahagoni-Hex aus dem Handoff). Glow nutzt `theme.interactive`. Headline nutzt `theme.textPrimary` (via `themeFont(.screenTitle)`).

- **AK 5.2**: Gegeben: Theme-Wechsel zu "Forest" oder "Moon" (jeweils Light/Dark).
  Wenn: Completion-Screen erscheint.
  Dann: Hintergrund und Glow passen sich an. Keine Hardcode-Mahagoni-Reste sichtbar.

- **AK 5.3**: Gegeben: Quellcode der drei betroffenen Dateien.
  Wenn: Per Grep nach Hex-Werten gesucht wird (`#3a201a`, `#e8b294`, `#d68a6e`, etc.).
  Dann: Kein Treffer — Hex-Werte aus dem Handoff sind NICHT uebernommen.

### AK-Block "Konsistenz"

- **AK 6.1**: Gegeben: Manueller-Test-Schritt 1 (Timer 1 Minute).
  Wenn: Timer ablaeuft.
  Dann: Neuer Completion-Screen erscheint, Verhalten wie spezifiziert.

- **AK 6.2**: Gegeben: Manueller-Test-Schritt 4 (Geleitete Meditation komplett spielen).
  Wenn: Player endet.
  Dann: Identischer neuer Completion-Screen erscheint, identisches Verhalten.

- **AK 6.3**: Gegeben: shared-080-Pfad (Termination, App-Restart).
  Wenn: Completion-Overlay vom RootContainerView gezeigt wird.
  Dann: Neuer Screen, Stagger laeuft. shared-080 ist funktional unbeeinflusst.

### AK-Block "Aufraeumen"

- **AK 7.1**: Gegeben: Quellcode-Suche nach `guided_meditations.player.completion.subtitle` UND `guided_meditations.player.completion.headline`.
  Wenn: Code + `.strings` durchsucht werden.
  Dann: Kein Treffer in iOS — Keys sind entfernt. Stattdessen `completion.headline` (DE + EN) und `completion.button.done` (DE + EN) vorhanden.

- **AK 7.2**: Gegeben: `make check` mit Localization-Checks.
  Wenn: Lokalisierungs-Audit laeuft.
  Dann: Keine Warnungen ueber ungenutzte oder fehlende Keys.

## Testbarkeits-Notiz

SwiftUI-View-Rendering laesst sich im Projekt nicht direkt unit-testen (kein ViewInspector, keine Snapshot-Lib). Strategie:

1. **Logik extrahieren in pure Helpers** (`BreathingCirclePresentation`): Layer-Visibility, glow-Werte. Direkt testbar.
2. **Konstanten extrahieren in einen testbaren Namespace** (`CompletionStaggerTiming` o. ae.): Delays/Dauer. Direkt testbar als Werte-Snapshot ("die Spec sagt 0/120/240 ms — der Code haelt sich daran").
3. **Visuelles Verhalten** (Stagger ist wirklich sichtbar, Theme greift, iPhone SE rendert) wird ueber den manuellen Test (Ticket-Sektion "Manueller Test") abgedeckt.

Damit erfuellen wir die Ticket-Forderung "rendert mit neuer Glow-Phase, ruft `onBack` auf, Reduced-Motion-Pfad" — `onBack` wird direkt durch Aufruf des Closures getestet, der Reduced-Motion-Pfad ueber die Konstanten/Helper, die Glow-Phase ueber `BreathingCirclePresentation`-Tests.

## Reihenfolge der Akzeptanzkriterien

Optimale TDD-Reihenfolge (Abhaengigkeiten beruecksichtigen):

1. **AK 1.3** (Layer-Visibility Helper) — Pure Function, klein, isoliert. Grundlage fuer alles Weitere.
2. **AK 1.1, 1.2** (`.completion`-Phase in `BreathingCircleView`) — Enum erweitern, View-Switch ergaenzen, Helper bindet die View an.
3. **AK 1.4** (Reduced Motion in `.completion`) — direkt im Anschluss, gleiches Konstrukt.
4. **AK 7.1** (Localization-Keys umstellen) — frueh, damit AK 2/3 darauf aufbauen.
5. **AK 2.1–2.5** (Headline) — `MeditationCompletionView` umbauen: Herz raus, Headline rein, Subtitle raus.
6. **AK 3.1–3.5** (Button "Fertig") — Label, Action, A11y.
7. **AK 4.1–4.5** (Stagger-Fade-in) — `@State`-Opacities + `withAnimation(...).delay(...)`, Reduced-Motion-Guard, didAppear-Guard.
8. **AK 5.1–5.3** (Theming) — Verifikation via Grep auf Hex-Werte; manueller Theme-Switch-Test.
9. **AK 1.5, 1.6, 6.1–6.3** (Regression-Check) — bestehende Timer/Player-Tests laufen lassen + manueller Test laut Ticket.
10. **CHANGELOG.md** + Ticket auf DONE.

## Risiken

| Risiko | Mitigation |
|--------|------------|
| `MeditationPhase` erweitern bricht switch-Exhaustivitaet an unerwarteter Stelle | `make test-unit-agent` + Compiler faengt fehlende Cases. Vor Commit `make check`. |
| `onAppear` feuert mehrfach (iOS-Lifecycle-Eigenheit) → Stagger ruckelt | `@State private var didAppear = false` Guard. |
| Glow ist auf iPhone SE zu gross oder zu klein | `outerSize: 200` ist proportional; iPhone SE hat genug Hoehe fuer Glow + Headline + Button. Manueller Test (Ticket-Schritt 8) deckt das ab. |
| Stagger-Animation kollidiert mit Outer-Transition (`.move(edge: .bottom).combined(with: .opacity)`) am Aufrufer | Stagger ist `onAppear`-getriggert und arbeitet auf eigenem `@State`. Outer-Transition arbeitet auf Container-View. Keine Kollision zu erwarten — ggf. im manuellen Test verifizieren. |

## Offene Fragen

Keine — die Headline-Key-Frage wurde geklaert (Umbenennen zu `completion.headline`).
