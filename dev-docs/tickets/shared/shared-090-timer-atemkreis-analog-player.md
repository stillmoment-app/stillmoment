# Ticket shared-090: Timer-Display analog zum Player (Atemkreis-Visualisierung)

**Status**: [~] IN PROGRESS
**Plan iOS**: [Implementierungsplan](../plans/shared-090-ios.md)
**Prioritaet**: MITTEL
**Komplexitaet**: Niedrig-mittel. Umbau einer existierenden View mit geteilter Komponente — kein neues Domain-Verhalten, keine Audio-Aenderung. Risiko liegt im sauberen Aufraeumen toter Pfade (Affirmations, alte Lokalisierungs-Keys) ohne Tests zu zerschiessen, sowie in der Wiederverwendung der Atemkreis-Komponente ohne Player-spezifische Annahmen einzuschleusen.
**Phase**: 4-Polish
**Abhaengigkeit**: shared-087 (Player-Atemkreis-Komponente) — bereits iOS abgeschlossen.

---

## Was

Der Meditation-Timer (stille Praxis) bekommt das gleiche visuelle Vokabular wie der Guided-Meditation-Player:

- **Pre-Roll (Vorbereitung)**: Atemkreis mit statischem Track, gedaempfter Glow ohne Atem-Animation. Countdown-Zahl + Label "Vorbereitung" im Inneren. Hint-Label "GLEICH GEHT'S LOS" unter dem Ring.
- **Hauptphase (laufender Timer)**: Atemkreis mit Track, Restzeit-Bogen + Sonnen-Punkt, atmender Glow. **Inneres bleibt leer** — der Timer hat keine Pause-Funktion und braucht entsprechend keinen Pause-Button. Restzeit-Label "NOCH … MIN" unter dem Ring.
- **Entfernt**: Begruessungs-Headline "Schoen, dass du da bist" waehrend laufender Meditation; rotierende Affirmations-Texte (Vorbereitung und Hauptphase) sowie der alte Progress- bzw. Preparation-Ring im Timer-Display.
- **Aufgeraeumt**: tote Lokalisierungs-Keys (`affirmation.preparation.*`, `affirmation.running.*`) und ungenutzt gewordener Code (Affirmations-Properties am ViewModel, falls nicht mehr referenziert).
- **Geteilte Komponente**: Atemkreis-Komponente wird zwischen Player und Timer geteilt (eine Quelle der Wahrheit fuer Visuals und Animation).

## Warum

Der Player wurde mit shared-087 zum zentralen Atemkreis hin radikal vereinfacht. Der Timer fuehrt heute parallel ein anderes Vokabular (Progress-Circle, Affirmations, Welcome-Text) und wirkt daneben wie eine fruehere App-Generation. Eine stille Sitzung und eine gefuehrte Sitzung sind aus Sicht des Users derselbe Akt — die Visualisierung soll das spiegeln.

Affirmations-Texte und die "Schoen, dass du da bist"-Headline sind beide gut gemeinte Zugaben, die dem Standard-Use-Case (Phone weglegen, Lockscreen) widersprechen: niemand liest sie. Sie nehmen Platz vom Atemkreis, der die eigentliche Atemfuehrung ist. Weniger ist mehr.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-087 iOS (vorhanden) |
| Android   | [ ]    | iOS-Implementierung als Referenz; shared-087 Android (offen) |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen, sofern nicht anders vermerkt. -->

### Feature: Pre-Roll (Vorbereitung) — beide Plattformen

- [ ] Atemkreis-Box vertikal und horizontal zentriert, mit Safe-Area-Beruecksichtigung
- [ ] Statischer Ring-Hintergrund (subtiler Stroke, semantisches Token) — einzige sichtbare Ring-Schicht in dieser Phase
- [ ] Inneres Glow-Feld in gedaempftem Zustand, **keine** Atem-Animation
- [ ] Inhalt im Glow-Feld: Countdown-Zahl gross (themed Font-Rolle, monospaced) + Label "Vorbereitung" darunter
- [ ] Hint-Label unter dem Ring: "GLEICH GEHT'S LOS" in Uppercase, gedaempfte Sekundaerfarbe
- [ ] Schliessen-Button oben links jederzeit erreichbar; Tap beendet die Sitzung (analog zum heutigen Verhalten)
- [ ] Visuell und verhaltensgleich zur Pre-Roll-Phase des Guided-Meditation-Players (shared-087)

### Feature: Hauptphase — beide Plattformen

- [ ] Layout vertikal: Schliessen-Button (oben links) · Atemkreis (zentriert) · Restzeit-Label unten. **Kein** Begruessungs-/Headline-Text
- [ ] Atemkreis-Box vertikal und horizontal zentriert
- [ ] Layer 1: statischer Ring-Hintergrund
- [ ] Layer 2: Restzeit-Bogen entspricht **vergangener** Sitzungszeit; Sonnen-Punkt am vorderen Bogen-Ende wandert mit
- [ ] Layer 3: Atem-Glow — kontinuierliche Animation (~16 s Zyklus, ease-in-out, infinite), unabhaengig vom Audio
- [ ] **Inneres des Atemkreises bleibt leer** — kein Pause-Button, kein Restzeit-Text, keine Affirmation. Begruendung: der Timer hat keine Pause-Funktion und kein Audio, das gepausiert werden koennte
- [ ] Restzeit-Label-Format wie im Player ("NOCH 8:32 MIN", Uppercase, tabular-Numerals)
- [ ] StartGong- und EndGong-Phasen verhalten sich visuell wie die laufende Hauptphase (Atemkreis bleibt sichtbar, Bogen laeuft weiter — keine eigene Anzeige)

### Feature: Uebergang Pre-Roll → Hauptphase — beide Plattformen

- [ ] Cross-Fade von Countdown-Inhalt zu leerem Inneren
- [ ] Restzeit-Bogen erscheint bei 0 und waechst mit Fortschritt
- [ ] Inneres Glow-Feld beginnt zu atmen (Easing-Start)

### Feature: Entfernte Elemente — beide Plattformen

- [ ] Headline "Schoen, dass du da bist" / "Lovely to see you" wird waehrend Pre-Roll, Hauptphase, StartGong und EndGong **nicht** mehr angezeigt
- [ ] Rotierende Affirmations-Texte (Vorbereitung und Hauptphase) sind nicht mehr Teil des Timer-Views
- [ ] Alter Progress-Circle / Preparation-Circle des Timers ist entfernt — der Atemkreis aus shared-087 ist die einzige Visualisierung
- [ ] Idle-Screen (vor Sitzungsstart) bleibt unveraendert (BreathDial-Picker + Settings-Liste + Beginnen-Button)
- [ ] Completion-/Danke-Screen bleibt unveraendert

### Feature: Geteilte Atemkreis-Komponente — beide Plattformen

- [ ] Die Atemkreis-Komponente, die heute nur vom Player genutzt wird, wird so refaktoriert, dass sie auch ohne Pause-Button-Inhalt sinnvoll ist (Inhalts-Slot ist optional bzw. leer fuer den Timer)
- [ ] Keine Player-spezifischen Annahmen (Audio, AVPlayer, MediaPlayer) leaken in die geteilte Komponente
- [ ] Phase-Begriff (Pre-Roll vs. Hauptphase) ist neutral genug, um vom Timer und vom Player gleichermassen genutzt zu werden — ggf. wird der Typ semantisch umbenannt, wenn er heute "Player"-im-Namen traegt

### Feature: Aufraeumen — beide Plattformen

- [ ] Lokalisierungs-Keys, die nach dem Umbau auf keiner Plattform mehr referenziert werden, sind in DE und EN entfernt (insbesondere `affirmation.preparation.*` und `affirmation.running.*`, falls nicht mehr verwendet)
- [ ] ViewModel-Properties / -Extensions, die ausschliesslich die Affirmations bedient haben, sind entfernt — sofern sie nirgends mehr (auch nicht in Tests) gebraucht werden
- [ ] Zugehoerige Unit-Tests werden mit entfernt — keine Tests fuer toten Code

### Feature: Reduced Motion / Accessibility — beide Plattformen

- [ ] Bei aktivem "Bewegung reduzieren" wird die Atem-Animation deaktiviert; Glow konstant
- [ ] Restzeit-Bogen aktualisiert sich auch bei Reduced Motion (Information, keine Dekoration)
- [ ] Schliessen-Button hat ein verstaendliches Accessibility-Label
- [ ] Restzeit-Label und Pre-Roll-Countdown sind als Text fuer Screen Reader zugaenglich
- [ ] Bestehender accessibility-Identifier `timer.display.time` bleibt erreichbar — in der Pre-Roll-Phase auf der Countdown-Zahl, in der Hauptphase auf dem Restzeit-Label

### Feature: Theming / Konsistenz — beide Plattformen

- [ ] Timer nutzt den aktiven Theme-Hintergrund (`theme.backgroundGradient` o. ae.) — wie heute
- [ ] Atemkreis-Token (Track, Glow, Sonnen-Punkt, Akzent) sind dieselben wie im Player; keine doppelten oder timer-spezifischen Theme-Tokens
- [ ] Light- und Dark-Mode-Verhalten konsistent zum Player

### Tests

- [ ] Bestehende Timer-ViewModel-Tests (Reducer, State-Machine, Completion) laufen unveraendert weiter
- [ ] iOS UI-Test: Assertion auf alten `timer.state.text` (Affirmations-Container) entfaellt; `timer.display.time` bleibt vorhanden
- [ ] Lokalisierungs-Lint / Tests bestaetigen, dass entfernte Keys auch tatsaechlich nicht mehr referenziert werden (kein toter Key, keine ungenutzte Ressource)

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare Aenderung — Timer-Look angepasst, Affirmations und Begruessung waehrend Sitzung weg)
- [ ] CLAUDE.md (Root und/oder Plattform-spezifisch) aktualisiert, falls dort Affirmations-Logik oder das alte Timer-Display dokumentiert ist
- [ ] `dev-docs/architecture/timer-state-machine.md` aktualisiert, falls dort UI-Display-Verhalten dokumentiert ist
- [ ] **Keine** Aenderung an Handoff-Dokumenten oder Plan-Files vergangener Tickets — historische Dokumente bleiben wie sie sind

---

## Manueller Test

1. Timer-Tab oeffnen — Idle-Screen bleibt wie heute (BreathDial, Settings-Liste, Beginnen)
2. Vorbereitungszeit auf einen Wert > 0 stellen, Beginnen tippen
3. Erwartung Pre-Roll: Atemkreis mit statischem Track, gedaempfter Glow, Countdown-Zahl + "Vorbereitung" im Inneren, "GLEICH GEHT'S LOS" unter dem Ring. **Keine** "Schoen, dass du da bist"-Headline. **Keine** Affirmations-Zeile
4. Pre-Roll lauft ab → Cross-Fade in die Hauptphase: Atemkreis beginnt zu atmen, Restzeit-Bogen waechst, Sonnen-Punkt wandert. Inneres bleibt leer (kein Pause-Button, kein Text). Restzeit-Label "NOCH … MIN" unter dem Ring
5. Schliessen-Button oben links: beendet die Sitzung sauber (wie heute)
6. Visueller Vergleich Side-by-Side mit dem Player: gleiche Atemkreis-Komponente, gleiche Pre-Roll-Logik, gleiches Restzeit-Label. Einziger sichtbarer Unterschied: Timer hat oben keinen Lehrer/Titel-Block und in der Mitte keinen Pause-Button
7. Vorbereitungszeit auf 0 setzen, neu starten: kein Pre-Roll, sofortige Hauptphase
8. Settings → "Bewegung reduzieren" einschalten: Atem-Animation aus, Restzeit-Bogen laeuft weiter
9. Theme-Wechsel (warm / sage / dusk): Atemkreis-Tokens passen sich konsistent zum Player-Verhalten an
10. Auf iPhone SE: gesamtes Layout ohne Scrollen sichtbar, Atemkreis nicht abgeschnitten, Restzeit-Label nicht ueberlappt
11. Auf Android (sobald portiert): identisches Verhalten zu iOS

Erwartung: Timer und Player wirken visuell und mechanisch wie zwei Geschwister. Beide nutzen denselben Atemkreis, beide haben die gleiche Pre-Roll-Sprache. Der Timer ist erkennbar die "stille Variante" — kein Pause, kein Lehrer, sonst alles gleich.

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Atemkreis-Komponente | geteilt mit Player | geteilt mit Player (sobald Android-Player nachgezogen ist) |
| Reduced-Motion-Detection | `accessibilityReduceMotion` | Plattform-spezifische API |
| Schliessen-Button | Toolbar oben links (wie heute) | IconButton im SafeContent-Padding oben links |

---

## Referenz

- iOS Timer heute: `ios/StillMoment/Presentation/Views/Timer/TimerView.swift`
- iOS Player als Vorlage: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift`
- iOS Atemkreis-Komponente: `ios/StillMoment/Presentation/Views/GuidedMeditations/BreathingCircleView.swift` (heute im GuidedMeditations-Ordner — wird im Zuge dieses Tickets ggf. in einen neutralen Ort verschoben, da Timer und Player sie teilen)
- Android Timer heute: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/...`
- Vorgaenger-Ticket: `dev-docs/tickets/shared/shared-087-player-atemkreis-redesign.md`
- Theme-System: `dev-docs/reference/color-system.md`
- Typografie-Rollen: `Font+Theme.swift` — bestehende Player-Rollen werden wiederverwendet

---

## Hinweise

**Geteilte Komponente — Verschiebung:**

Die Atemkreis-Komponente liegt heute unter `Presentation/Views/GuidedMeditations/`. Wenn sie auch der Timer nutzt, sollte sie in einen neutralen Ordner (z. B. `Presentation/Views/Shared/` oder `Presentation/Components/`). Auch der Phase-Typ (heute "PlayerPhase") sollte semantisch neutralisiert werden, sofern er ueber den Player hinaus geteilt wird.

**Affirmations vs. tote Pfade:**

Die Affirmations-Properties am Timer-ViewModel sind heute mit Unit-Tests abgedeckt. Wenn der View sie nicht mehr nutzt UND sie auch sonst nirgends gebraucht werden, fliegen sowohl die Properties als auch die Tests raus. Die Lokalisierungs-Keys folgen dem gleichen Prinzip: nicht referenziert → weg, in DE und EN.

**Lokalisierungs-Keys teilen:**

Player-spezifische Keys wie `guided_meditations.player.preroll.label`, `…preroll.hint`, `…remainingTime.format` werden vom Timer mitbenutzt werden. Wenn ein Key sowohl von Player als auch Timer genutzt wird, ist das semantisch unsauber — eine spaetere Umbenennung zu einem neutralen Praefix (z. B. `meditation.preroll.label`) ist denkbar, aber nicht in diesem Ticket erforderlich. Pragmatisch: bestehende Keys nutzen.

**UI-Tests:**

Mindestens eine bestehende UI-Test-Assertion (`timer.state.text`) verschwindet mit dem Affirmations-Block. Die Tests werden entsprechend angepasst — Test-Aenderung ist Teil der Implementierung, kein separates Ticket.

**Keine historischen Dokumente anfassen:**

Vergangene Plan-Files (`dev-docs/plans/...`), Handoff-Dokumente und abgeschlossene Tickets bleiben unveraendert — auch wenn sie Begriffe wie "Affirmations" oder "Welcome-Headline" referenzieren. Sie sind Schnappschuesse vergangener Zustaende.

**Plattform-Reihenfolge:**

Sequenziell: iOS zuerst, dann Android mit der iOS-Implementierung als Referenz. Voraussetzung fuer Android ist, dass shared-087 (Player-Atemkreis) auf Android abgeschlossen ist — sonst gibt es noch keine geteilte Atemkreis-Komponente, die der Timer mitnutzen koennte.

**Nicht im Scope:**

- Timer-Idle-Screen aendert sich nicht (das ist shared-089)
- Completion-/Danke-Screen aendert sich nicht
- Domain / State-Machine / Audio bleibt unangetastet
- Atemtempo-Variation oder Lehrer-spezifische Atem-Modi (zukuenftig)
- Lokalisierungs-Refactor zu neutralem Praefix (kann separat passieren)

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
