# Implementierungsplan: shared-096 (iOS)

Ticket: [shared-096](../shared/shared-096-player-kerzenschein-refinement.md)
Erstellt: 2026-05-16

---

## Annahmen

Bewusst getroffene Annahmen, die in den Plan eingeflossen sind:

1. **Eigene Player-Ring-Komponente, kein Eingriff in `BreathingCircleView`.**
   Der `BreathingCircleView` wird auch von `TimerView` (Pre-Roll) genutzt — eine Modifikation würde Timer-Idle visuell mit verändern. Der User hat explizit entschieden, dass der Player eine eigene Komponente bekommt. `RingMetrics` (lineWidth = 3, beadDiameter = 9) bleibt damit ebenfalls unangetastet — der Player-Ring nutzt seine eigenen Stroke-Werte (1 px Track, 1.5 px Arc, Perle ⌀ 12).

2. **`theme.ringTrack` wird im Player nicht verwendet.**
   Der Handoff verlangt einen warmen, leisen Track in `interactive @ 0.32`. Der existierende `theme.ringTrack`-Token hat einen anderen Wert (Dark `#A1605E`-aehnlich, Light Apricot) — wuerde nicht zum Handoff passen. Player-Ring nutzt `theme.interactive.opacity(0.32)` direkt.

3. **`theme.backgroundGradient` wird bereits korrekt verwendet.**
   `GuidedMeditationPlayerView` ruft schon `self.theme.backgroundGradient` auf, der bereits ein vertikaler 3-Stop-Linear-Gradient (backgroundPrimary → backgroundSecondary → accentBackground) ist. Das ist exakt der KS-2.0-Hintergrund — Punkt 1 des Handoffs ist auf iOS-Seite bereits umgesetzt. Wird im Plan trotzdem als Akzeptanzkriterium gepruefte Ist-Vorgabe behalten.

4. **`GlassPauseButton` bleibt strukturell unveraendert.**
   Das existierende Button-Design (80 × 80, `.ultraThinMaterial`-Backdrop, `.strokeBorder` mit `theme.interactive @ 0.25`, Glyph in `theme.interactive`, 200 ms Cross-Fade) entspricht dem Handoff in den wesentlichen Punkten. Der Handoff schlaegt unterschiedliche Border-Opacities fuer Pause vs. Playing und fuer Light vs. Dark vor (0.35–0.65) — der bestehende einheitliche Wert 0.25 ist visuell ruhiger und im Handoff-Spec mit „Engineering-Spielraum" gedeckt. Wir lassen es so, ausser Light-Validierung zeigt einen Mangel.

5. **PAUSIERT-Prefix als eigener Localization-Key, keine String-Konkatenation.**
   Neuer Key `guided_meditations.player.remainingTime.format.paused` mit Vollformat `"PAUSIERT · NOCH %@ MIN"` (DE) / `"PAUSED · %@ MIN LEFT"` (EN). Der View entscheidet zwischen den beiden Format-Keys anhand `viewModel.isPlaying`.

6. **„Center-Disc" als neue, kleine View-Komponente** (`PlayerCenterDisc`) — modus-abhaengig (Light/Dark), statischer `RadialGradient`, kein State, keine Animation, `allowsHitTesting(false)`. Sitzt im Player-Ring hinter dem `GlassPauseButton` und ist nur in der Hauptphase sichtbar (Pre-Roll: keine Disc).

7. **Reduced-Motion-Pfad faellt im Player komplett weg.**
   Aktuell nutzt `GuidedMeditationPlayerView` `@Environment(\.accessibilityReduceMotion)` ausschliesslich, um diesen Wert an `BreathingCircleView` weiterzureichen. Da der neue `PlayerRingView` keine Animation hat (ausser dem progress-basierten Bogen-Wachstum, das fachlich noetig ist), wird `reduceMotion` aus dem Player entfernt. Cross-Fade-Transitions (Pre-Roll → Haupt) bleiben — die respektieren `reduceMotion` ohnehin via SwiftUI automatisch nicht, sind aber so kurz und so semantisch zwingend (Phasenwechsel = Inhaltswechsel), dass das hier akzeptabel ist.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift` | Presentation | Erweitern | `BreathingCircleView` durch neue `PlayerRingView` ersetzen. `accessibilityReduceMotion`-Environment entfernen. Restzeit-Label um PAUSIERT-Prefix-Branching erweitern. |
| `Presentation/Views/GuidedMeditations/PlayerRingView.swift` | Presentation | **Neu** | Player-eigene Ring-Komponente. Track + Restzeit-Bogen + Perle in KS-2.0-Norm (1 px / 1.5 px / Perle ⌀ 12). Pre-Roll zeigt nur Track. Inhalt (Pause-Button oder Countdown) via `@ViewBuilder`-Closure. |
| `Presentation/Views/GuidedMeditations/PlayerCenterDisc.swift` | Presentation | **Neu** | Statische Glühscheibe hinter dem Pause-Button, modus-abhaengig (`@Environment(\.colorScheme)`), zwei `RadialGradient`-Stops nach Handoff. `allowsHitTesting(false)`. |
| `Presentation/Views/GuidedMeditations/GlassPauseButton.swift` | Presentation | Unangetastet | Bereits handoff-nah. Wird nur im Player verwendet. |
| `Presentation/Views/Shared/BreathingCircleView.swift` | Presentation (shared) | **Unangetastet** | Wird weiter von `TimerView` Pre-Roll genutzt. |
| `Presentation/Views/Shared/RingMetrics.swift` | Presentation (shared) | **Unangetastet** | Bleibt bei den bisherigen Werten (3 px / 9 px). |
| `Presentation/Theme/ThemeColors.swift` + `+Palettes.swift` | Presentation | **Unangetastet** | Alle benoetigten Tokens (backgroundPrimary/Secondary, accentBackground, interactive, textPrimary, textSecondary) sind vorhanden. `backgroundGradient` ist bereits der KS-2.0-Linear-Gradient. |
| `Resources/de.lproj/Localizable.strings` | Presentation | Erweitern | Neuer Key `guided_meditations.player.remainingTime.format.paused` |
| `Resources/en.lproj/Localizable.strings` | Presentation | Erweitern | Neuer Key (gleiche ID) in EN |
| `Application/ViewModels/GuidedMeditationPlayerViewModel.swift` | Application | **Unangetastet** | `isPlaying`, `phase`, `progress`, `remainingCountdownSeconds`, `formattedRemainingMinutes` bereits vorhanden. View bindet daran. |
| `StillMomentTests/GuidedMeditationPlayerViewModelTests*.swift` | Tests | Unangetastet | View-Model-Logik nicht betroffen. |
| `StillMomentUITests/` (ggf. Screenshot-Snapshot-Lauf via Fastlane) | Tests | Manuell pruefen | Vorhandener `04_PlayerView.png`-Screenshot wird sich aendern. Akzeptanz nach manueller Validierung des neuen Screenshots. |
| `CHANGELOG.md` | Docs | Erweitern | Neuer Polish-Eintrag fuer die visuelle Player-Anpassung. |

---

## API-Recherche

Keine externe Recherche noetig — alle verwendeten APIs sind SwiftUI-Basics und seit iOS 15/16 stabil. Deployment-Target ist **iOS 16.0**.

| API | Min. Version | Hinweis |
|-----|--------------|---------|
| `LinearGradient`, `RadialGradient` | iOS 13+ | bereits in Theme/PauseButton verwendet |
| `Circle().trim(from:to:)` | iOS 13+ | bereits in `BreathingCircleView` verwendet |
| `Circle().stroke / .strokeBorder` | iOS 13+ / iOS 16+ fuer `.strokeBorder` als ShapeStyle | bereits verwendet |
| `.ultraThinMaterial` (als `ShapeStyle`) | iOS 15+ | bereits im `GlassPauseButton` verwendet |
| `@Environment(\.colorScheme)` | iOS 13+ | fuer `PlayerCenterDisc` Light/Dark-Discriminator |
| `monospacedDigit()` | iOS 15+ | bereits verwendet |

---

## Design-Entscheidungen

### 1. Eigene Komponente vs. `BreathingCircleView` migrieren

**Trade-off:** Geteilter Code = ein Vokabular zwischen Timer-Idle und Player; getrennte Komponenten = sauberer Schnitt, kein Risiko fuer Timer.

**Entscheidung:** Eigene Player-Komponente (`PlayerRingView` + `PlayerCenterDisc`). Der User hat explizit gewaehlt, das Timer-Idle nicht im selben Ticket anzufassen. Falls sich der Player-Ring in der Praxis als „die richtige" Norm zeigt, kann der Timer-Idle in einem Folge-Ticket auf dieselbe Komponente migriert werden — dann wird `BreathingCircleView` zur Legacy-Wrapper-Komponente oder vollstaendig ersetzt.

### 2. PAUSIERT-Prefix: Eigener Format-Key vs. konkatenierter Prefix

**Trade-off:** Voller Format-Key = sauber uebersetzbar, mehr Strings; konkatenierter Prefix = ein zusaetzlicher String, aber String-Konkatenation in Localized-Texten ist laut Projekt-CLAUDE.md ein Bug-Pattern.

**Entscheidung:** Voller Format-Key. Vermeidet das in CLAUDE.md explizit verbotene Pattern `Text("prefix: \(key)")` mit lokalisierten Strings.

### 3. Center-Disc: Drin vs. weg

**Trade-off:** Drin = warmer Anker hinter Pause-Button, Light-Mode-Lift; weg = noch weniger Bildelemente, monkfriendly.

**Entscheidung:** Drin (User-Wahl). Aber als isolierte View-Komponente, so dass das Folge-Ticket sie einfach entfernen kann, ohne den Ring zu beruehren.

---

## Refactorings

Kein echtes Refactoring. Lediglich:
- Entfernung des `reduceMotion`-Environment-Reads aus `GuidedMeditationPlayerView` (war nur fuer `BreathingCircleView`-Pass-through da)
- Entfernung des `BreathingCircleView`-Imports/Aufrufs aus dem Player (bleibt in `TimerView` bestehen)

---

## Fachliche Szenarien

### AK-1 / AK-2: Hintergrund + Ring in der Hauptphase

- **Gegeben:** Eine Guided Meditation laeuft seit 30 Sekunden (Hauptphase, nicht pausiert), Dark Mode aktiv.
  **Wenn:** Player sichtbar ist.
  **Dann:** Hintergrund ist ein vertikaler Linear-Gradient von dunklem Mahagoni oben zu warmem Akzent-Ton unten. Im Ring sichtbar: dünne warme Track-Linie, daraueber ein ca. 5 % gefüllter Restzeit-Bogen (gleiche Farbe, etwas kraeftiger) mit einer kleinen leuchtenden Perle an der Vorderkante. Hinter dem zentralen Pause-Button: leichte statische Glühscheibe in waermerem Akzent-Ton.

- **Gegeben:** Light Mode statt Dark.
  **Wenn:** Gleicher Zustand.
  **Dann:** Gradient laeuft von hellem Apricot oben zu kraeftigerem Apricot/Sunrise unten. Ring-Farben sind die dunklere Light-Mode-Akzent-Variante. Glühscheibe ist deutlich dezenter, aber sichtbar.

### AK-3: Keine Bewegung in der Hauptphase ausser der Perle

- **Gegeben:** Eine Guided Meditation laeuft seit 30 Sekunden.
  **Wenn:** Der Player 10 Sekunden lang ohne Interaktion betrachtet wird.
  **Dann:** Auf dem Bildschirm bewegt sich nichts ausser der Perle, die einmal pro Sekunde (oder seltener — Animation glaettet uebers Tick-Interval) eine minimale Position weiter Richtung Uhrzeigersinn wandert. Keine Atem-Animation, kein Pulsieren der Glühscheibe, kein Skalieren.

- **Gegeben:** „Bewegung reduzieren" ist im System aktiviert.
  **Wenn:** Gleicher Zustand.
  **Dann:** Identisches Verhalten (es gibt keine Animation, die reduziert werden muesste). Reduced-Motion-Pfad existiert nicht mehr im Player.

### AK-4: Pre-Roll-Phase

- **Gegeben:** Vorbereitungszeit ist auf 10 s eingestellt, Meditation wurde gerade gestartet.
  **Wenn:** Player oeffnet sich.
  **Dann:** Ring zeigt **nur** die dünne Track-Linie — kein Restzeit-Bogen, keine Perle. In der Mitte des Rings: grosse Countdown-Zahl (10, 9, 8, …) und darunter klein „Vorbereitung". Unter dem Ring der Hint „Gleich geht's los". Keine Glühscheibe, kein Pause-Button.

- **Gegeben:** Vorbereitungszeit ist 0 s (Toggle „aus") oder Meditation hat keine Pre-Roll-Phase.
  **Wenn:** Player oeffnet sich.
  **Dann:** Pre-Roll-Visual ist nie sichtbar; Player startet direkt in der Hauptphase.

### AK-5: Übergang Pre-Roll → Hauptphase

- **Gegeben:** Pre-Roll-Countdown laeuft auf 0.
  **Wenn:** Phase wechselt von `.preRoll` zu `.playing`.
  **Dann:** Innerhalb von ca. 400 ms blenden Countdown-Zahl und „Vorbereitung"-Label aus; Restzeit-Bogen (bei Position 0 startend), Perle, Glühscheibe und Pause-Button blenden ein; „Gleich geht's los" wird durch das Restzeit-Label ersetzt.

### AK-6: Pause-Zustand

- **Gegeben:** Hauptphase laeuft, Perle ist bei ca. 30 % des Bogens.
  **Wenn:** User tippt auf den Pause-Button.
  **Dann:** Audio pausiert sofort. Glyph wechselt von Pause-Bars zu Play-Dreieck (200 ms Cross-Fade). Perle friert exakt an der aktuellen Position ein — der Bogen waechst nicht weiter. Restzeit-Label zeigt zusaetzlich „Pausiert · " vor der Restzeit-Angabe.

- **Gegeben:** Pause-Zustand (wie eben).
  **Wenn:** User tippt erneut auf den Button.
  **Dann:** Audio laeuft weiter. Glyph wechselt zurueck zu Pause-Bars. Perle wandert weiter ab der eingefrorenen Position. Pausiert-Prefix verschwindet sofort, Restzeit-Label kehrt zum Standard-Format zurueck.

### AK-7: Lockscreen-Spiegelung unveraendert

- **Gegeben:** Player laeuft, Bildschirm wird gesperrt.
  **Wenn:** User tippt auf Pause am Lockscreen.
  **Dann:** Audio pausiert, In-App-Zustand spiegelt — beim Entsperren ist der Player im Pause-Zustand mit Pausiert-Prefix.

### AK-8: Schliessen

- **Gegeben:** Player in beliebiger Phase.
  **Wenn:** User tippt das X oben links.
  **Dann:** Audio stoppt, Player schliesst. Verhalten unveraendert gegenueber bestehendem Spec.

---

## Reihenfolge der Akzeptanzkriterien (TDD-Sequenz)

1. **Localization-Keys hinzufuegen** (`paused.format` in DE + EN). Test: `NSLocalizedString` liefert in beiden Sprachen den richtigen Format-String.
2. **`PlayerRingView` neu schreiben** — Track + Arc + Perle. Tests:
   - Pre-Roll-Phase rendert keinen Arc (View-Hierarchie-Test oder Snapshot).
   - Hauptphase rendert Arc + Perle.
   - Arc-Trim folgt dem `progress`-Parameter (z. B. progress = 0.5 → trim from 0 to 0.5).
3. **`PlayerCenterDisc` neu schreiben** — statische Disc, modus-abhaengig. Test: `colorScheme = .dark` vs. `.light` liefert unterschiedliche Render-Snapshots (oder visuell via Preview validiert).
4. **`GuidedMeditationPlayerView` umbauen:**
   - `BreathingCircleView` durch `PlayerRingView` ersetzen.
   - `accessibilityReduceMotion`-Read entfernen.
   - In Hauptphase: `PlayerCenterDisc` als Hintergrund-Layer hinter `GlassPauseButton` legen.
   - Restzeit-Label: in `bottomLabel` zwischen Standard- und Paused-Format-Key branchen anhand `viewModel.isPlaying`.
5. **Manuelle visuelle Validierung** auf Simulator iPhone 16 Plus, beide Modi, Pre-Roll + Haupt + Pause. Fastlane-Screenshot fuer `04_PlayerView.png` neu aufnehmen.
6. **CHANGELOG-Eintrag.**

---

## Offene Fragen

Keine. Alle vier Entscheidungen wurden bereits beim Ticket-Erstellen mit dem User geklaert (Scope, Ring-Komponente, Pausiert-Prefix, Center-Disc).

---

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| `BreathingCircleView` und `PlayerRingView` driften visuell auseinander, obwohl der Handoff sie als „gleiche Ring-Sprache" beschreibt | Akzeptiert. Folge-Ticket fuer Timer-Idle-Migration auf KS-2.0-Norm anlegen, sobald der Player produktiv ist. |
| Light-Mode-Pause-Button-Glas wirkt zu dunkel (alter Dark-Wert versehentlich aktiv) | `GlassPauseButton` nutzt bereits `.ultraThinMaterial`, das automatisch auf den Color-Scheme reagiert. Trotzdem in der manuellen Validierung explizit beide Modi pruefen. |
| Pre-Roll-Countdown blitzt vor dem ersten Tick durch | Bestehender `didKickOff`-Mechanismus im Player wird beibehalten — verhindert genau das. |
| Fastlane-Screenshot bricht weil `BreathingCircleView`-Komponenten-ID anders ist | Fastlane-Screenshots sind nicht-blockierend, werden vor Release neu generiert. |
