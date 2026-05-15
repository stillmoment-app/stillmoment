# Ticket shared-092: Danke-Screen Redesign — Atemkreis statt Herz

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Niedrig-mittel. Reines Visual-Redesign eines bestehenden Screens. Risiko liegt darin, die `BreathingCircle`-Komponente sauber um eine neue Phase zu erweitern, ohne ihre heutigen Aufrufer (Player, Timer) zu brechen. Auftritts-Stagger und Reduced-Motion-Pfad sind die heikleren Details.
**Phase**: 4-Polish

---

## Was

Redesign des Completion-Screens, der nach Ende einer Meditation (Timer abgelaufen oder geleitete Meditation fertig) angezeigt wird:

- **Herz-Icon weicht einem ruhig atmenden Glow-Kreis** — dieselbe `BreathingCircle`-Komponente, die der Sitzungs-Anfang verwendet, in einer neuen `completion`-Phase (nur das Glow-Layer, ohne Track / Restzeit-Bogen / Sonnen-Punkt).
- **Eine zentrale warme Botschaft** statt Headline + Subline: "Danke, dass du dir diesen Moment genommen hast." Der heutige Subtitle entfaellt komplett.
- **Button "Fertig"** statt "Zurueck" — waermerer Abschluss, kein Rueckzugs-Wording. Neuer Localization-Key.
- **Sanfter Auftritt**: Glow, Headline und Button erscheinen mit leichtem Stagger-Fade-In beim `onAppear`.

Der Screen-Hintergrund nutzt weiterhin den aktiven Theme-Gradient — kein Hardcode-Mahagoni aus dem Handoff. Glow- und Textfarben werden auf bestehende semantische Tokens gemappt (analog zur Setzung in shared-087).

## Warum

Der heutige Danke-Screen wirkt transaktional: Herz-Icon, generische Floskel "Vielen Dank", "Zurueck"-Button. Das Redesign rahmt den Abschluss in dasselbe Atem-Vokabular wie der Sitzungs-Anfang — visuell schliesst sich die Klammer um die Praxis. Die Sprache wird aktiv und warm: nicht "Vielen Dank", sondern "Danke, dass *du dir* diesen Moment genommen hast." Keine Zahlen, keine Streaks, keine Statistiken — die bewusste Produkt-Entscheidung bleibt.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | iOS-Implementierung als Referenz |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen, sofern nicht anders vermerkt -->

### Feature: Glow statt Herz (beide Plattformen)

- [ ] Das Herz-Icon (`heart.fill` / `Icons.Filled.Favorite`) ist auf dem Completion-Screen entfernt
- [ ] An seiner Stelle steht eine ruhig atmende Glow-Kreis-Visualisierung, realisiert ueber eine neue Phase der bestehenden `BreathingCircle`-Komponente (z. B. `.completion`)
- [ ] In der `.completion`-Phase sind sichtbar: **ausschliesslich** das innere Atem-Glow-Layer (warmer Radial-Gradient)
- [ ] In der `.completion`-Phase sind **nicht** sichtbar: statischer Ring-Track, Restzeit-Bogen, Sonnen-Punkt am Bogen-Ende
- [ ] Glow atmet kontinuierlich (ease-in-out, infinite); Tempo entspricht der heutigen Hauptphase (ca. 16 s Vollzyklus) oder leicht ruhiger
- [ ] Bei aktivem "Bewegung reduzieren" laeuft die Atem-Animation nicht; Glow bleibt sichtbar im neutralen Mittelwert
- [ ] Bestehende `BreathingCircle`-Aufrufer (Guided Player, Timer Pre-Roll und Hauptphase) verhalten sich unveraendert — keine Regression in deren Layern

### Feature: Eine zentrale Botschaft (beide Plattformen)

- [ ] Headline-Text (exakt, in DE): "Danke, dass du dir diesen Moment genommen hast."
- [ ] Headline-Text (exakt, in EN): sinngemaesse Uebersetzung — Vorschlag: "Thank you for taking this moment for yourself."
- [ ] Der bisherige Subtitle (`completion_subtitle`) erscheint nicht mehr — nur die eine Botschaft
- [ ] Headline ist horizontal zentriert, mehrzeilig zulaessig (auf Standard-iPhone-/Pixel-Breite zwei Zeilen)
- [ ] Headline ist als Heading fuer Screen Reader markiert
- [ ] Headline nutzt die bestehende Typografie-Rolle `.screenTitle` (oder eine neue dedizierte Rolle, falls die Display-Anmutung des Handoffs hier abweichen soll)

### Feature: Button "Fertig" (beide Plattformen)

- [ ] Button-Label "Fertig" (DE) / "Done" (EN) ueber neuen Localization-Key `completion.button.done`
- [ ] Bestehender `button.back` bleibt im Repo (wird an anderen Stellen weitergenutzt)
- [ ] Accessibility-Label bleibt "Zurueck zur Bibliothek" — die Action beschreibt die Konsequenz, nicht das Label
- [ ] Tap auf "Fertig" loest dieselbe Navigation aus wie heute "Zurueck" (kein Verhaltensaenderung der Navigation)
- [ ] Button-Style: bestehender Primary-Button-Stil (`warmPrimaryButton` iOS / Material3 Pill Android) — kein Hardcode-Verlauf aus dem Handoff
- [ ] Hit-Target ≥ 44 pt

### Feature: Auftritts-Animation (beide Plattformen)

- [ ] Beim Erscheinen des Screens (`onAppear` / `LaunchedEffect`) starten Glow, Headline und Button mit Stagger:
  - Glow: 0 ms
  - Headline: +120 ms
  - Button: +240 ms
- [ ] Jedes Element animiert in ~500 ms: opacity 0 → 1, leichter Y-Versatz (~8 pt) → 0, ease-out
- [ ] Glow-Atem-Loop laeuft unabhaengig — der Stagger ist nur das Einblenden, das Atmen ist permanent
- [ ] Bei aktivem "Bewegung reduzieren": Stagger und Y-Versatz entfallen, alle Elemente erscheinen direkt sichtbar
- [ ] Der Stagger laeuft sowohl beim Erscheinen aus einer aktiven Session (Timer/Player faded raus, Completion faded rein) **als auch** beim Erscheinen auf App-Start nach Termination (shared-080) — er ist nicht an einen Vorgaenger-View gekoppelt

### Feature: Theming (beide Plattformen)

- [ ] Hintergrund nutzt den aktiven Theme-Gradient (`theme.backgroundGradient` o. ae.) — keine theme-unabhaengigen Hardcoded-Farben
- [ ] Glow-Farbe nutzt das Akzent-Token `theme.interactive` (warmes Akzent in allen drei Themes)
- [ ] Text-Farben kommen aus dem bestehenden Typografie-System (Theme-abhaengig)
- [ ] Hex-Werte aus dem Handoff (`#3a201a`, `#e8b294`, `#d68a6e`, etc.) werden NICHT uebernommen
- [ ] Newsreader/Geist Google Fonts werden NICHT integriert — App-Typografie bleibt

### Feature: Konsistenz (beide Plattformen)

- [ ] Heutige Aufrufer (Timer-Completion, Guided-Player-Completion, Android-Overlay-on-app-start aus shared-080) zeigen den neuen Screen ohne weitere Aenderungen
- [ ] shared-080 (Completion survives termination) bleibt funktional unbeeinflusst — der neue Screen ist ein reines Visual-Redesign
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell und verhaltensgleich zwischen iOS und Android

### Aufraeumen

- [ ] Ungenutzter Localization-Key `guided_meditations.player.completion.subtitle` / `completion_subtitle` entfernt (DE + EN, beide Plattformen)
- [ ] Subtitle-Test im UI-/Snapshot-Test entfernt, falls vorhanden

### Tests

- [ ] iOS Unit-Test: `MeditationCompletionView` rendert mit neuer Glow-Phase, ruft `onBack` auf, Reduced-Motion-Pfad
- [ ] iOS Unit-Test: `BreathingCircleView` in `.completion`-Phase zeigt nur das Glow-Layer (kein Track, kein Bogen, kein Dot)
- [ ] Android Unit-Test: aequivalente Coverage fuer `MeditationCompletionContent` und `BreathingCircle`
- [ ] Bestehende Player- und Timer-Tests laufen unveraendert (kein Regress in den anderen `BreathingCircle`-Phasen)

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare Aenderung — "Danke-Screen ueberarbeitet, weicheres Visual mit Atemkreis")
- [ ] Glossar nur bei Bedarf

---

## Manueller Test

1. Timer starten (1 Min reicht), ablaufen lassen → Danke-Screen erscheint
2. Erwartung: Stagger-Fade-In sichtbar (Glow zuerst, dann Headline, dann Button), Glow atmet ruhig, Botschaft "Danke, dass du dir diesen Moment genommen hast.", Button "Fertig"
3. "Fertig" antippen: zurueck zur Library/Home (wie heute)
4. Geleitete Meditation starten, durchspielen lassen → identischer Danke-Screen mit identischem Verhalten
5. Android: App waehrend laufender Meditation killen, Meditation laeuft im Hintergrund zu Ende → beim naechsten App-Start erscheint der Danke-Screen, Stagger laeuft auch hier (shared-080-Pfad)
6. Settings → Bedienungshilfen → "Bewegung reduzieren" einschalten, Test 1+2 wiederholen → kein Atem-Pulse, kein Stagger, alles direkt sichtbar
7. Theme wechseln (Candlelight → Forest → Moon, jeweils Light + Dark): Hintergrund und Glow passen sich an, keine Hardcode-Mahagoni-Reste
8. Auf iPhone SE (compact height): kein Scrollen noetig, Glow nicht abgeschnitten, Button mit genug Abstand zum Home-Indicator

Erwartung: Auf iOS und Android identisches Verhalten und nahezu identische visuelle Wirkung.

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Stagger-Fade-In | `withAnimation(.easeOut(duration: 0.5).delay(...))` auf `@State`-Opacities | `LaunchedEffect` + `animate*AsState` mit Delays |
| Reduced-Motion-Detection | `accessibilityReduceMotion` Environment | `LocalAccessibilityManager` bzw. heute genutzte Quelle der `BreathingCircle` |
| Glow-Animation | bereits in `BreathingCircleView` vorhanden | bereits in `BreathingCircle` vorhanden |

---

## Referenz

- Handoff: `handoffs/design_handoff_danke_screen/` (insb. `README.md`)
- iOS heute: `ios/StillMoment/Presentation/Views/Shared/MeditationCompletionView.swift`
- Android heute: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/common/MeditationCompletionContent.kt`
- iOS BreathingCircle: `ios/StillMoment/Presentation/Views/Shared/BreathingCircleView.swift`
- Android BreathingCircle: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/common/BreathingCircle.kt`
- Related Tickets: shared-087 (Player-Redesign mit BreathingCircle), shared-080 (Completion survives termination), shared-052 (Timer-Completion), shared-053 (Player-Completion)

---

## Hinweise

**Vom Design-Handoff abweichend** (analog zu shared-087):

- Hintergrund: Handoff zeigt einen spezifischen Mahagoni-Radial-Gradient. Wir nutzen stattdessen den aktiven `theme.backgroundGradient`, damit der Screen nicht aus der App-Atmosphaere ausbricht und auch in den Themes Forest/Moon funktioniert.
- Typografie: Handoff nennt Newsreader/Geist. Wir bleiben bei den projekteigenen Typography-Rollen.
- Farb-Hex-Werte: werden auf bestehende oder neue semantische Tokens gemappt, nicht hardcoded uebernommen.
- Glow-Bounding-Box: Handoff sagt 160 × 160 px (mit 88 × 88 Kern). Wir behalten die `outerSize`-Logik der `BreathingCircle` bei (Default 280) und skalieren auf dem Completion-Screen passend herunter (z. B. ~200), damit Headline und Button vertikal Platz haben.

**`BreathingCircle` erweitern, nicht duplizieren:**

- Neue Phase `.completion` im bestehenden `MeditationPhase`-Enum (oder eigenes `BreathingCirclePhase`-Enum, falls die Domain-Semantik dagegenspricht — `MeditationPhase` ist aktuell `.preRoll` / `.playing`, "completion" passt thematisch dazu).
- Track-/Arc-/Dot-Layer per `phase`-Switch ausblenden — bestehende `preRoll`/`playing`-Pfade bleiben unveraendert.
- Glow-Scale/Opacity in `.completion`: leicht gedaempfter Bereich (z. B. 0.92–1.05 / 0.65–1.0) ist akzeptabel, muss aber im Ticket nicht final festgelegt werden — der Implementierer waehlt mit Blick auf die Wirkung.

**Lock-Screen-Lifecycle:**

- Auf Android existiert ein Pfad, der den Completion-Screen beim App-Start anzeigt, falls die Meditation waehrend Suspend/Termination zu Ende gelaufen ist (shared-080, `CompletionOverlayViewModel`). Der Stagger-Fade-In muss auch dort laufen — also `onAppear`/`LaunchedEffect`-gesteuert, nicht an eine Vorgaenger-View-Transition gekoppelt.

**Aufraeumen:**

- Bestehender Localization-Key `completion_subtitle` / `guided_meditations.player.completion.subtitle` wird ungenutzt und ist zu entfernen (DE + EN, beide Plattformen). Der Localization-Review-Skill faengt das beim Ticket-Abschluss zusaetzlich ab.

**Plattform-Reihenfolge:**

Sequenziell: iOS zuerst, dann Android mit der iOS-Implementierung als Referenz.

**Nicht im Scope:**

- Statistik / Streaks / Tracking (bewusst nie)
- "Diese Meditation noch mal"-Button (eigenes Feature-Ticket, falls je gewollt)
- "Teilen"-Button (passt nicht zur App-Philosophie)
- Atemtempo-Individualisierung pro Lehrer
- Aenderung der Navigations-Ziele nach "Fertig" (bleibt wie heute "Zurueck")

---

<!--
WAS NICHT INS TICKET GEHOERT:
- Kein Code (Claude Code schreibt den selbst)
- Keine separaten iOS/Android Subtasks mit Code
- Keine Dateilisten (Claude Code findet die Dateien)

Claude Code arbeitet shared-Tickets so ab:
1. Liest Ticket fuer Kontext
2. Implementiert iOS komplett
3. Portiert auf Android mit Referenz
-->
