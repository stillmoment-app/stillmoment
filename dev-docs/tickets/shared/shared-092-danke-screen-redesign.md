# Ticket shared-092: Danke-Screen Redesign — Glow statt Herz

**Status**: [ ] TODO
**Plan**: [Implementierungsplan iOS](../plans/shared-092-ios.md)
**Prioritaet**: MITTEL
**Komplexitaet**: Niedrig. Reines Visual-Redesign eines bestehenden Screens. Der Glow ist statisch (zwei konzentrische Kreise mit Radial-Gradient) — keine Animationen, kein Lifecycle-Pfad, kein Eingriff in geteilte Komponenten. Risiko liegt im Theme-Mapping und in der Lokalisierungs-Hygiene (alten Subtitle-Key sauber entfernen).
**Phase**: 4-Polish

---

## Was

Redesign des Completion-Screens, der nach Ende einer Meditation (Timer abgelaufen oder geleitete Meditation fertig) angezeigt wird:

- **Herz-Icon weicht einem ruhigen, statischen Glow-Kreis** — zwei konzentrische Kreise mit warmem Radial-Gradient (aeusserer Halo + innerer Kern). Bewusst NICHT animiert: die Sitzung ist zu Ende, ein pulsierender Atem wuerde faelschlich Aktivitaet suggerieren.
- **Eine zentrale warme Botschaft** statt Headline + Subline: "Danke, dass du dir diesen Moment genommen hast." Der heutige Subtitle entfaellt komplett.
- **Button "Fertig"** statt "Zurueck" — waermerer Abschluss, kein Rueckzugs-Wording. Neuer Localization-Key.
- **Auftritt ohne Stagger**: Der Screen erscheint als direkter Schnitt aus der Sitzung. Keine Fade-In-/Y-Versatz-Animationen — die Stille soll nicht durch UI-Bewegung unterbrochen werden.

Der Screen-Hintergrund nutzt weiterhin den aktiven Theme-Gradient — kein Hardcode-Mahagoni aus dem Handoff. Glow- und Textfarben werden auf bestehende semantische Tokens gemappt (analog zur Setzung in shared-087).

## Warum

Der heutige Danke-Screen wirkt transaktional: Herz-Icon, generische Floskel "Vielen Dank", "Zurueck"-Button. Das Redesign macht den Abschluss waermer — ein nachglimmendes Licht statt eines Icons, eine aktive Aussage statt einer Floskel. Die Sprache wird aktiv und warm: nicht "Vielen Dank", sondern "Danke, dass *du dir* diesen Moment genommen hast." Bewusst statisch und ohne Auftritts-Animation: nach einer Meditation soll die Stille fortgesetzt werden, nicht durch UI-Bewegung unterbrochen. Keine Zahlen, keine Streaks, keine Statistiken — die bewusste Produkt-Entscheidung bleibt.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [ ]    | iOS-Implementierung als Referenz |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen, sofern nicht anders vermerkt -->

### Feature: Glow statt Herz (beide Plattformen)

- [ ] Das Herz-Icon (`heart.fill` / `Icons.Filled.Favorite`) ist auf dem Completion-Screen entfernt
- [ ] An seiner Stelle steht eine statische Glow-Kreis-Visualisierung als eigenstaendige Komponente (z. B. `CompletionGlow` / `CompletionGlowOrb`) — KEIN Wiederverwendung von `BreathingCircleView` / `BreathingCircle`
- [ ] Der Glow besteht aus zwei konzentrischen Kreisen: aeusserer Halo + innerer Kern, beide mit warmem Radial-Gradient. Beide Kreise sind statisch (keine Scale-/Opacity-Animation, kein Atem-Loop)
- [ ] Bounding-Box ca. 160–180 pt im Standard-Layout; auf iPhone SE / compact-height proportional kleiner
- [ ] Geteilte Komponenten (`BreathingCircleView` iOS / `BreathingCircle` Android) bleiben unveraendert — kein neuer Case im `MeditationPhase`-Enum, keine Switch-Anpassungen an den heutigen Aufrufern

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

### Feature: Auftritt (beide Plattformen)

- [ ] Der Screen erscheint ohne Auftritts-Animation — direkter Schnitt vom Sitzungs-Ende auf den Danke-Screen. Kein Stagger-Fade-In, kein Y-Versatz.
- [ ] Da der Screen statisch ist, ist der Reduced-Motion-Pfad implizit erfuellt — er verhaelt sich identisch zur Normalansicht.
- [ ] Der statische Auftritt ist unabhaengig vom Lifecycle-Pfad: ob aus einer aktiven Session (Timer/Player fertig) oder beim App-Start nach Termination (shared-080) — kein onAppear-getriggerter Effekt noetig.

### Feature: Theming (beide Plattformen)

- [ ] Hintergrund nutzt den aktiven Theme-Gradient (`theme.backgroundGradient` o. ae.) — keine theme-unabhaengigen Hardcoded-Farben
- [ ] Glow-Farbe nutzt das Akzent-Token `theme.interactive` (warmes Akzent in allen drei Themes); innerer Kern heller, aeusserer Halo gedaempfter
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

- [ ] iOS Unit-Test: `MeditationCompletionView` ruft `onBack`-Closure auf, wenn der Button getappt wird
- [ ] Android Unit-Test: aequivalentes Verhalten fuer `MeditationCompletionContent`
- [ ] Bestehende Player- und Timer-Tests laufen unveraendert (keine Beruehrung der geteilten `BreathingCircle`-Komponente)

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare Aenderung — "Danke-Screen ueberarbeitet, ruhiger und waermer")
- [ ] Glossar nur bei Bedarf

---

## Manueller Test

1. Timer starten (1 Min reicht), ablaufen lassen → Danke-Screen erscheint
2. Erwartung: Statischer Glow (kein Atem-Pulse), Botschaft "Danke, dass du dir diesen Moment genommen hast.", Button "Fertig" — alles direkt sichtbar, kein Fade-In
3. "Fertig" antippen: zurueck zur Library/Home (wie heute)
4. Geleitete Meditation starten, durchspielen lassen → identischer Danke-Screen mit identischem Verhalten
5. Android: App waehrend laufender Meditation killen, Meditation laeuft im Hintergrund zu Ende → beim naechsten App-Start erscheint der Danke-Screen (shared-080-Pfad), identisch statisch
6. Settings → Bedienungshilfen → "Bewegung reduzieren" einschalten, Test 1+2 wiederholen → Screen ist ohnehin statisch, kein Unterschied erwartet
7. Theme wechseln (Candlelight → Forest → Moon, jeweils Light + Dark): Hintergrund und Glow passen sich an, keine Hardcode-Mahagoni-Reste
8. Auf iPhone SE (compact height): kein Scrollen noetig, Glow nicht abgeschnitten, Button mit genug Abstand zum Home-Indicator

Erwartung: Auf iOS und Android identisches Verhalten und nahezu identische visuelle Wirkung.

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Glow-Darstellung | Eigenes `CompletionGlow`-View, zwei `Circle` mit `RadialGradient` | Eigenes `CompletionGlow`-Composable, zwei `Box`/`Canvas` mit `Brush.radialGradient` |
| Auftritt | Direkt sichtbar — kein `withAnimation`, kein onAppear-Effekt | Direkt sichtbar — kein `animate*AsState`, kein `LaunchedEffect` |
| Theme-Quelle | `theme.backgroundGradient`, `theme.interactive` | `MaterialTheme.colorScheme` / Theme-Tokens analog |

---

## Referenz

- Handoff: `handoffs/design_handoff_danke_screen/` (insb. `README.md`)
- iOS heute: `ios/StillMoment/Presentation/Views/Shared/MeditationCompletionView.swift`
- Android heute: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/common/MeditationCompletionContent.kt`
- Related Tickets: shared-087 (Player-Redesign mit BreathingCircle), shared-080 (Completion survives termination), shared-052 (Timer-Completion), shared-053 (Player-Completion)

---

## Hinweise

**Vom Design-Handoff abweichend** (analog zu shared-087):

- Hintergrund: Handoff zeigt einen spezifischen Mahagoni-Radial-Gradient. Wir nutzen stattdessen den aktiven `theme.backgroundGradient`, damit der Screen nicht aus der App-Atmosphaere ausbricht und auch in den Themes Forest/Moon funktioniert.
- Typografie: Handoff nennt Newsreader/Geist. Wir bleiben bei den projekteigenen Typography-Rollen.
- Farb-Hex-Werte: werden auf bestehende oder neue semantische Tokens gemappt, nicht hardcoded uebernommen. Der innere Glow-Kern bleibt aber sichtbar heller als der aeussere Halo — die Hierarchie "heisser Punkt → diffuses Licht" bleibt erhalten.
- Glow-Bounding-Box: Handoff sagt 180 × 180 px (mit 96 × 96 Kern). Wir orientieren uns daran und skalieren bei compact-height proportional.

**Glow als eigene, statische Komponente:**

- KEIN Wiederverwendung von `BreathingCircleView` / `BreathingCircle`. Diese Komponente kommuniziert "die App atmet, die Sitzung laeuft" — fuer den Abschluss-Screen ist genau das die falsche Botschaft.
- KEIN neuer Case im `MeditationPhase`-Enum. Die Phase beschreibt eine laufende Sitzung; der Danke-Screen ist keine Phase einer Sitzung, sondern deren Nachklang.
- Der Glow ist zwei stillstehende Radial-Gradient-Kreise (Halo + Kern). Kein Lifecycle, kein State, kein Timer.

**Lock-Screen-Lifecycle:**

- Da der Screen statisch ist, ist der shared-080-Termination-Pfad (Completion-Overlay beim App-Start) trivial erfuellt: der Screen sieht identisch aus, unabhaengig davon, woher er kommt.

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
- Aufruf-/Verlassens-Animationen am Container — bewusst kein Fade-Out

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
