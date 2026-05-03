# Implementierungsplan: shared-087 (iOS)

Ticket: [shared-087-player-atemkreis-redesign](../shared/shared-087-player-atemkreis-redesign.md)
Erstellt: 2026-05-03

---

## Mentales Modell

Der Player wird komplett auf **eine Geste** (Pause/Play in der Hauptphase) reduziert. Die View ist ein dreischichtiger Atemkreis (statischer Track + animierter Restzeit-Bogen + atmender Glow), in dessen Mitte ein Glas-Pause-Button sitzt. Zwei Phasen:

- **Pre-Roll** — gleicher 280×280-Container, aber Bogen entleert sich linear, kein Glow-Atem, Countdown-Zahl statt Pause-Button. Auto-Start bei `onAppear`. Nur UI-Timer, kein Audio.
- **Hauptphase** — Bogen wächst mit Fortschritt, Glow atmet 16 s pro Zyklus (unabhängig vom Audio, läuft auch bei Pause weiter), Pause-Button mittig im Glow.

Der **Übergang** ist ein 400 ms Cross-Fade (visuell). Audio startet direkt auf voller Lautstärke (kein Volume-Fade).

ViewModel-Logik (Pre-Roll-State, hasSessionStarted-Guard, transitionFromSilentToPlayback, completionEvent) bleibt strukturell. **Der einzige Trigger-Wechsel:** `onAppear` ruft `startPlayback()`, der Pause-Button ruft `togglePlayPause()` direkt — das umgeht die "auf erstem Tap mit Pre-Roll starten"-Logik, die wir nicht mehr brauchen.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift` | Presentation | **Komplette Neuschreibung** | Slider/Skip/Elapsed entfernen, Atemkreis + Glas-Pause + Restzeit-Label aufbauen, Auto-Start in `onAppear` |
| `Presentation/Views/GuidedMeditations/BreathingCircleView.swift` | Presentation | **Neu** | Wiederverwendbare 280×280-Komponente mit drei Layern (Track, Restzeit-Bogen, Glow). Akzeptiert `phase` + `progress` + `reduceMotion` |
| `Presentation/Views/GuidedMeditations/GlassPauseButton.swift` | Presentation | **Neu** | 80×80 Glass-Button mit `.ultraThinMaterial`-Backdrop, Pause/Play-Glyph mit 200 ms Cross-Fade |
| `Application/ViewModels/GuidedMeditationPlayerViewModel.swift` | Application | Erweitern | Neue computed `phase: PlayerPhase` (preRoll/playing/paused), `formattedRemainingMinutes` für "NOCH … MIN" |
| `Resources/de.lproj/Localizable.strings` | Resources | Erweitern | Neue Keys: `guided_meditations.player.remainingTime.format` ("NOCH %@ MIN"), `guided_meditations.player.preroll.hint` ("GLEICH GEHT'S LOS"), `guided_meditations.player.preroll.label` ("Vorbereitung") |
| `Resources/en.lproj/Localizable.strings` | Resources | Erweitern | EN-Pendants: "%@ MIN LEFT", "STARTING IN A MOMENT", "Preparation" |
| `StillMomentTests/GuidedMeditationPlayerViewModelTests.swift` | Tests | Erweitern | Tests für `phase` und `formattedRemainingMinutes` |
| `StillMomentTests/PlayerPreparationTests.swift` | Tests | Erweitern | Test für Auto-Start (View ruft `startPlayback()` direkt nach `loadAudio()`) |
| `StillMomentUITests/ScreenshotTests.swift` | UI Tests | Anpassen | Slider-Erwartung entfernen, Pause-Button als Anchor nutzen |

### Codestellen, die explizit unverändert bleiben

- `Domain/Models/PreparationCountdown.swift` — Domain-Modell stimmt
- `Domain/Services/AudioPlayerServiceProtocol.swift` + `Infrastructure/Services/AudioPlayerService.swift` — kein Volume-Fade, Service unangetastet
- `Application/ViewModels/GuidedMeditationPlayerViewModel.swift` `setupBindings()`, `startCountdown()`, `tickCountdown()`, `completionEvent`-Logik, `cleanup()`, `isZenMode`
- `Presentation/Theme/ThemeColors.swift` + Palettes — keine neuen Tokens, alles aus `theme.interactive` und `theme.textPrimary` abgeleitet
- `Presentation/Views/Shared/MeditationCompletionView.swift` — separater Spec
- Lockscreen-/Now-Playing-Logik in `AudioPlayerService`

---

## API-Recherche

| API | Verfügbarkeit | Verwendung |
|---|---|---|
| `@Environment(\.accessibilityReduceMotion)` | iOS 13+ | Reduced-Motion-Detection in der View |
| `Material.ultraThinMaterial` als View `.background(.ultraThinMaterial)` | iOS 15+ (Deployment 16) — OK | Backdrop-Blur für den Pause-Button |
| `Animation.easeInOut(duration:).repeatForever(autoreverses: true)` | iOS 13+ | Atem-Animation: 8 s Halb-Zyklus = 16 s Vollzyklus |
| `withAnimation(_:_:)` mit `@State` Bool | iOS 13+ | Trigger der Repeat-Animation in `onAppear` |
| `Circle().trim(from:to:).stroke(...)` mit `.rotationEffect(.degrees(-90))` | iOS 13+ | Restzeit-Bogen, Linecap-rund |

Hinweise:
- AVPlayer-Volume-Fade nicht mehr relevant (Volume-Fade aus Spec entfernt).
- `withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) { breathing.toggle() }` lässt den Atem **kontinuierlich** laufen — auch bei Pause. Das ist das gewünschte Verhalten (Atem ist Atemführung, nicht Audio-Indikator).

---

## Designentscheidungen

### 1. Glow-Farben — themed via `theme.interactive`

**Entscheidung:** Variante B aus der initialen Diskussion. Glow nutzt `theme.interactive` mit gestaffelten Opacities:
- Center: `theme.interactive.opacity(0.35)`
- Edge:   `theme.interactive.opacity(0.12)`
- Border: `theme.interactive.opacity(0.25)`

Das gibt jedem Theme einen passenden Atemkreis (warm-orange bei Candlelight, gedämpftes Grün bei Forest, kühles Blau bei Moon) — und funktioniert in Light- wie Dark-Mode, weil `theme.interactive` pro Theme bereits passende Light- und Dark-Werte hat.

**Warum:** Maximale Theme-Konsistenz, keine neuen Tokens nötig, hält das Theme-System sauber.

### 2. Player-Hintergrund — aktiver Theme-Gradient (Light + Dark wie Rest der App)

**Entscheidung:** Variante A. Player nutzt `theme.backgroundGradient` direkt — Light-Mode-User sieht hellen Player, Dark-Mode-User sieht dunklen Player. Kein `.preferredColorScheme(.dark)`-Override.

**Warum:** Konsistent mit App, respektiert User-Choice. Die "permanent dunkel atmosphärisch"-Anmutung des Specs war designerseitig motiviert; in der Praxis ist Theme-Konsistenz wichtiger.

### 3. Atem-Animation — `withAnimation(.repeatForever)`, läuft kontinuierlich auch bei Pause

**Entscheidung:** Klassischer SwiftUI-Weg mit `@State Bool breathing` und `withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true))`. Der Atem läuft kontinuierlich — auch wenn der User pausiert.

**Warum:** Pragmatisch und semantisch sauber. Der Atem ist eine Atemführung, kein Audio-Indikator. Wenn der User pausiert, atmet die Person trotzdem weiter. Spart komplexe Time-Tracking-Logik (TimelineView mit `pausedAt`-Workaround). AC im Ticket entsprechend angepasst: "Atem-Animation läuft kontinuierlich weiter".

**Reduced Motion:** Branch in `BreathingCircleView` — wenn `reduceMotion == true`, kein `withAnimation`, statischer Glow bei `scale=0.93`/`opacity=0.85` (Mittelwerte zwischen min/max).

### 4. Volume-Fade — entfällt komplett

**Entscheidung:** Kein Audio-Fade beim Übergang Pre-Roll → Hauptphase, kein Audio-Fade beim Schließen. Audio startet direkt auf voller Lautstärke, stoppt direkt beim Schließen-Tap.

**Warum:** Pragmatisch. Aktueller Player hat es nicht, niemand hat sich beschwert. Spart eine Service-Methode, Mock-Erweiterung, Timer-Logik, Tests. Der visuelle 400-ms-Cross-Fade beim Pre-Roll-→-Hauptphasen-Übergang macht ohnehin die Sanftheit; ein Audio-Fade wäre nice-to-have, nicht essentiell. ACs im Ticket angepasst.

### 5. Atemtempo — 16 s pro Vollzyklus

**Entscheidung:** Spec-Wert. Implementierung: `Animation.easeInOut(duration: 8).repeatForever(autoreverses: true)` ergibt 16 s Vollzyklus.

### 6. Auto-Start ohne Race Condition

`startPlayback()` darf erst aufgerufen werden, wenn `loadAudio()` fertig ist. Im View-`onAppear`:

```swift
Task {
    await self.viewModel.loadAudio()
    self.viewModel.startPlayback()
}
```

Wenn `loadAudio()` einen Fehler setzt (`errorMessage != nil`), zeigt die View den Fehler-Alert wie heute. Der `startPlayback()`-Call macht in dem Fall nichts kaputt (das ViewModel guarded selbst).

### 7. Pause-Button vs. erstes Auto-Start

`startPlayback()` hat heute zwei Bedeutungen: "Pre-Roll starten oder Audio toggeln". Mit Auto-Start gibt es genau **eine Bedeutung pro Aufrufer**:
- `onAppear` ruft `startPlayback()` (Initial-Start mit Pre-Roll falls konfiguriert)
- Pause-Button ruft `togglePlayPause()` direkt

Das schärft die Semantik, ohne `startPlayback()` umzubenennen — bestehende Tests bleiben grün.

---

## Refactorings

Keine größeren Refactorings nötig.

- **`GuidedMeditationPlayerView`** wird komplett neu geschrieben (kleiner als heute), aber das ist nicht wirklich Refactoring — die alte View wird einfach ersetzt.
- **ViewModel** wird nur additiv ergänzt (`phase`, `formattedRemainingMinutes`); bestehende Methoden und Tests bleiben.

Risiko: niedrig.

---

## Fachliche Szenarien

### AK Auto-Start

- **Gegeben:** Library zeigt geladene Meditation, `preparationTimeSeconds = 0`
  **Wenn:** User tippt eine Meditation an
  **Dann:** Player öffnet sich, Audio startet sofort in der Hauptphase (volle Lautstärke), kein initialer Play-Tap nötig

- **Gegeben:** `preparationTimeSeconds = 15`
  **Wenn:** User öffnet den Player
  **Dann:** Pre-Roll-Phase startet sofort, Countdown-Zahl 15 sichtbar, Bogen voll, Audio läuft noch nicht, Hint "GLEICH GEHT'S LOS" sichtbar

- **Gegeben:** Player ist offen mit Pre-Roll
  **Wenn:** Countdown läuft auf 0
  **Dann:** Cross-Fade (~400 ms) zur Hauptphase, Pause-Button erscheint, Restzeit-Label "NOCH … MIN" erscheint, Audio startet direkt

### AK Hauptphase / Atemkreis

- **Gegeben:** Hauptphase aktiv, Audio spielt
  **Wenn:** 1 Sekunde vergeht
  **Dann:** Restzeit-Bogen wächst (`progress` aus aktueller Sitzung), Restzeit-Label aktualisiert sich, Atem-Glow atmet kontinuierlich (16 s Zyklus, unabhängig vom Audio)

- **Gegeben:** Hauptphase aktiv
  **Wenn:** User tippt **außerhalb** des Pause-Buttons
  **Dann:** Nichts passiert (kein Slider, kein Skip)

- **Gegeben:** Hauptphase aktiv mit Reduced-Motion-Setting
  **Wenn:** Player rendert
  **Dann:** Glow ist statisch (scale 0.93, opacity 0.85), kein Atem; Restzeit-Bogen aktualisiert sich weiterhin

### AK Pause-Verhalten

- **Gegeben:** Audio spielt
  **Wenn:** User tippt Pause-Button
  **Dann:** Audio pausiert, Atem-Glow läuft kontinuierlich weiter, Restzeit-Bogen friert ein (weil currentTime nicht mehr tickt), Glyph wechselt mit 200 ms Cross-Fade von Pause zu Play, weiches Haptic-Tap (`UIImpactFeedbackGenerator(.soft)` — App ist im Vordergrund beim Tap)

- **Gegeben:** Player ist pausiert
  **Wenn:** User tippt Play-Button
  **Dann:** Audio läuft weiter, Glyph wechselt zurück, Atem hat ohnehin nie pausiert

- **Gegeben:** Audio spielt
  **Wenn:** User auf Lockscreen "Pause" drückt
  **Dann:** Player-Zustand spiegelt → Glyph wechselt — wenn User App wieder öffnet, sieht er korrekten Pause-Zustand

### AK Pre-Roll-Spezifika

- **Gegeben:** Pre-Roll läuft
  **Wenn:** View rendert
  **Dann:** Kein Pause-Button sichtbar, Schließen-Button oben links sichtbar, Glow atmet **nicht**

- **Gegeben:** Pre-Roll läuft mit Reduced-Motion
  **Wenn:** Übergang zur Hauptphase
  **Dann:** Instant cut (kein Cross-Fade), Audio startet, Atem bleibt im neutralen Zustand

### AK Schließen

- **Gegeben:** Hauptphase läuft, Audio spielt
  **Wenn:** User tippt Schließen-Button
  **Dann:** Audio stoppt direkt (kein Fade), View dismisst zurück zur Library

- **Gegeben:** Pre-Roll läuft (kein Audio)
  **Wenn:** User tippt Schließen-Button
  **Dann:** View dismisst sofort

### AK Restzeit-Format

- **Gegeben:** Restzeit ist 8:32
  **Wenn:** View rendert das Restzeit-Label
  **Dann:** Anzeige "NOCH 8:32 MIN" (uppercase, tabular-Numerals) — DE
  Anzeige "8:32 MIN LEFT" — EN

- **Gegeben:** Restzeit ist 0:45
  **Wenn:** View rendert
  **Dann:** "NOCH 0:45 MIN" — keine Sonderbehandlung für <1 Minute, weil das Spec den `mm:ss`-Modus festlegt

### AK Responsive Layout

- **Gegeben:** iPhone SE (375 × 667)
  **Wenn:** Player rendert
  **Dann:** Lehrer/Titel oben sichtbar, Atemkreis 280×280 zentriert, Restzeit-Label unten sichtbar, **kein** Scrollen, kein Clipping

- **Gegeben:** iPhone Pro Max (430 × 932)
  **Wenn:** Player rendert
  **Dann:** Atemkreis bleibt 280×280, mehr Spacing, Layout wirkt nicht verloren

### AK Theming

- **Gegeben:** Theme = "warm" (candlelight), System-Mode = Dark
  **Wenn:** Player rendert
  **Dann:** Hintergrund nutzt Dark-Variante des Candlelight-Gradients (Mahagoni-Töne), Atemkreis-Glow warm

- **Gegeben:** Theme = "sage" (forest), System-Mode = Light
  **Wenn:** Player rendert
  **Dann:** Hintergrund nutzt Forest-Light-Gradient, Atemkreis-Glow gedämpftes Grün — Player passt sich konsistent dem Theme an

---

## Reihenfolge der Akzeptanzkriterien (TDD)

Die Implementierung folgt von innen nach außen, um Build-Stabilität zu wahren.

1. **ViewModel-Erweiterungen** — `phase: PlayerPhase` + `formattedRemainingMinutes` als computed properties. Tests: Format-Output, Phase-Übergänge.
2. **`GlassPauseButton`** — eigenständige reusable View mit `.ultraThinMaterial`-Backdrop. Snapshot-/Visual-Test optional.
3. **`BreathingCircleView`** — eigenständige Komponente, akzeptiert phase + progress + reduceMotion. Test: Layer-Sichtbarkeit pro Phase, Reduced-Motion-Branch.
4. **`GuidedMeditationPlayerView` Neuschreibung** — Slider/Skip raus, Atemkreis + Pause + Label rein, `onAppear` ruft `loadAudio` und dann `startPlayback`. Tests: Auto-Start beim onAppear, kein initialer Play-Button.
5. **Localization** — Keys für DE+EN ergänzen. Validation via `make check` (Lokalisations-Linter im Projekt vorhanden).
6. **UI-Test anpassen** — `ScreenshotTests.testScreenshot04_playerView` ohne Slider-Erwartung; Pause-Button als Anchor.
7. **Snapshot-Tests** — Pre-Roll, Hauptphase Playing, Hauptphase Paused, Reduced Motion (vier Screenshots — laut Ticket gefordert).

---

## Risiken

| Risiko | Mitigation |
|---|---|
| Auto-Start triggert vor `loadAudio()` fertig → kein Player → `togglePlayPause()` no-op | View ruft `startPlayback()` **nach** `await loadAudio()` im `Task {}` |
| `withAnimation(.repeatForever)` läuft im Hintergrund weiter und verbraucht CPU | onDisappear setzt `breathing = false`, Animation wird gecancelt; `cleanup()` im ViewModel löst View-Disappear ohnehin aus |
| `.ultraThinMaterial` auf altem iPhone (SE 1./2. Gen) zu langsam | iOS 16 Deployment-Target schließt SE 1. Gen aus; SE 2. Gen+ rendert Material flüssig. Falls dennoch Probleme: `.background(Color.black.opacity(0.55))` als Fallback |
| `prefers-reduced-motion` greift nicht für Repeat-Animation | Direkter Branch: `if !reduceMotion { withAnimation { breathing = true } }`. Wenn `reduceMotion` aktiv, bleibt `breathing = false` → statischer Frame |
| Bestehender `togglePlayPause`-Pfad bei `playbackState == .finished` ruft Restart auf — bei Pause-Button-Tap am Ende der Session unerwartet | Pause-Button verschwindet ohnehin bei Completion (Completion-View übernimmt). Kein Konflikt |
| Pre-Roll-Hint und Restzeit-Label überschneiden sich beim Cross-Fade | `.transition(.opacity)` auf beide; Layout-Position ist identisch, der Inhalt wechselt nur |

---

## Vorbereitung

Nichts manuell — kein neues Xcode-Target, keine Provisioning-Profiles.

---

## Offene Fragen

Alle Designentscheidungen geklärt. Bereit für `/implement-ticket shared-087 ios`.
