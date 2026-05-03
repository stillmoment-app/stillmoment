# Ticket shared-086: Atemkreis-Picker und UI-Feinpolitur am Timer-Konfig

**Status**: [x] DONE (iOS) / [ ] TODO (Android)
**Plan**: [Implementierungsplan iOS](../plans/shared-086-ios.md)
**Prioritaet**: MITTEL
**Komplexitaet**: Mittel. Neuer gestischer Picker (Drag im Ring + radial platzierte +/-Buttons mit Long-Press-Beschleunigung) ersetzt den bestehenden Wheel-Picker. Geometrie ist exakt vom Design vorgegeben, muss aber vertikal responsiv skalieren. Daneben mehrere Layout-Anpassungen (Headline-Reihe, Sentence-Case-Labels, Atem-Spacing). Risiko liegt vor allem in der korrekten Geste-Mathematik (atan2 + Clamping mit dynamischem Min) und der Skalierung auf kleinen Geraeten.
**Phase**: 4-Polish

---

## Was

Schritt 2 auf dem Weg zu "H2-Final": Der Wheel-Picker fuer die Sitzungsdauer wird durch einen **Atemkreis-Picker** ersetzt — Drag-Geste auf einem Ring fuer schnelle, atmosphaerische Wahl plus +/-Buttons radial unten am Kreis fuer minutengenaue Korrektur (mit Long-Press-Beschleunigung). Der Idle-Screen bekommt zusaetzlich eine Headline-Reihe ("Wie viel Zeit schenkst du dir?" ueber dem Dial, "Passe den Timer an" als Section-Trenner ueber den Cards), Sentence-Case-Card-Labels und mehr Atem-Spacing zwischen Picker und Cards.

Der Atemkreis und alle umgebenden Sektionen verteilen sich vertikal responsiv, sodass der Idle-Screen auf iPhone SE bis iPhone 15 Pro Max ohne Scrollen passt und die Komposition auf jeder Hoehe aesthetisch bleibt.

## Warum

Der Wheel-Picker fuehlt sich wie ein iOS-System-Control an und bricht den meditativen Charakter der App. Der Atemkreis ist gleichzeitig **Geste, Affordance und Visualisierung** — der pulsierende Tropfen wandert auf dem Ring, der Bogen fuellt sich, die zentrale Zahl bleibt minutengenau lesbar. Drag deckt den Modus "ich will ungefaehr 20 Minuten" ab, +/-Buttons den Modus "auf die Minute genau". Sentence-Case-Labels und die Headline-Reihe geben dem Konfigurations-Screen einen waermeren, lesbareren Rahmen.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit                |
|-----------|--------|------------------------------|
| iOS       | [x]    | shared-083                   |
| Android   | [ ]    | shared-083                   |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen -->

### Atemkreis-Picker

- [ ] Dial in der Mitte des Picker-Bereichs, Drag-Geste auf dem Ring setzt den Wert kontinuierlich (atan2-basiert)
- [ ] Aktiv-Bogen startet bei 12-Uhr und waechst im Uhrzeigersinn proportional zu `value / 60`
- [ ] Drag-Tropfen sitzt am Ende des Bogens auf dem Ring-Mittelradius (Outer-Ring + Center-Dot)
- [ ] Drag-Tropfen hat einen sanft pulsierenden Halo (~2.6 s Loop) als Affordance
- [ ] Zwei radiale +/-Buttons, 44 x 44 px, an 7-Uhr- und 5-Uhr-Position (Winkel 45 Grad zur Vertikalen)
- [ ] Tap auf "+"/"-" erhoeht/erniedrigt um 1; Long-Press startet nach kurzer Verzoegerung beschleunigtes Ticken
- [ ] "-"-Button ist disabled (sichtbar gedimmt), wenn `value <= minimumDurationMinutes`
- [ ] "+"-Button ist disabled, wenn `value >= 60`
- [ ] Drag-Geste klemmt gegen `[minimumDurationMinutes, 60]` — keine 0-Minuten-Sitzung moeglich
- [ ] Werteaenderung ueber Drag oder +/- aktualisiert dieselbe Quelle (`viewModel.selectedMinutes`); Bogen, Tropfen-Position und zentrale Zahl bleiben synchron

### Layout & Texte

- [ ] Headline "Wie viel Zeit schenkst du dir?" steht ueber dem Atemkreis (ueberschreibt das Entfernen aus shared-083 bewusst)
- [ ] Untertitel "Passe den Timer an" steht zwischen Atemkreis und Cards-Reihen als Section-Trenner
- [ ] Spacing zwischen Atemkreis und Untertitel folgt dem Design-Atem (~44 px auf Standardhoehe, responsiv)
- [ ] Card-Labels werden auf Sentence-Case umgestellt: "Vorbereitung", "Einstimmung", "Hintergrund", "Gong", "Intervall" — kein Uppercase, kein Letter-Spacing
- [ ] Reihenfolge der Cards (3+2 aus shared-083) bleibt: Vorbereitung, Einstimmung, Hintergrund / Gong, Intervall

### Big Number & Einheit-Label

- [ ] Aktueller Wert mittig im Dial in einer neuen Typo-Rolle `.dialValue` (Newsreader Light, Letter-Spacing leicht negativ), Groesse skaliert 62 px (klein) bis 76 px (gross)
- [ ] Unter der Zahl ein "Minuten"-Label in einer neuen Typo-Rolle `.dialUnit` (UI-Font, klein, uppercase, weites Letter-Spacing)
- [ ] Beide Rollen sind in das bestehende Theme-/Typography-System eingebunden und respektieren Light- und Dark-Mode
- [ ] "Minuten"-Label ist lokalisiert (DE: "Minuten" / EN: "Minutes")

### Responsive Vertikale

- [ ] Dial-Durchmesser skaliert mit verfuegbarer Hoehe: **Min 180 px**, **Max 220 px**
- [ ] Big Number skaliert proportional: **Min 62 px**, **Max 76 px**
- [ ] +/-Buttons bleiben fix **44 x 44 px** (Apple HIG / Material Mindestgroesse), aber ihr radialer Offset zum Dial-Zentrum skaliert mit der Dial-Groesse
- [ ] Auf iPhone SE (375 x 667): Headline, Atemkreis, Untertitel, alle fuenf Cards und der Beginnen-Button sind ohne Scrollen sichtbar
- [ ] Auf iPhone 15 Pro Max (430 x 932): die Sektionen sind aesthetisch verteilt, kein "auseinandergerissenes" Gefuehl, kein doppelt so grosser Atemkreis
- [ ] Auf Android-Pendants (z.B. Pixel 5 / Pixel 8 Pro) gleicher Grundsatz: kompakte Geraete kein Scroll, grosse Geraete keine grossen Leerflaechen

### Theming & Accessibility

- [ ] Atemkreis (Track-Ring, Aktiv-Bogen, Tropfen-Halo, Tropfen, +/-Buttons) verwendet ausschliesslich semantische Theme-Tokens — keine direkten Hex-Werte, keine `.warmBlack`/`.paleApricot`-Direktreferenzen
- [ ] Bei Bedarf neue semantische Tokens fuer Dial-spezifische Farben einfuehren (Bogen, Tropfen-Halo) und in allen drei Themes (warm, sage, dusk) sowie Light/Dark belegen
- [ ] Reduced Motion (iOS: `accessibilityReduceMotion`, Android: `Settings.Global.TRANSITION_ANIMATION_SCALE` / Compose-Pendant): Tropfen-Halo ist **statisch sichtbar** (mittlerer Radius, mittlere Opazitaet), kein Pulse
- [ ] Picker exponiert eine Slider-Rolle fuer Screen Reader (iOS: `.accessibilityValue`/`.accessibilityAdjustableAction`, Android: `Modifier.semantics { progressBarRangeInfo }` o.ae.) — VoiceOver/TalkBack koennen den Wert mit Increment/Decrement aendern
- [ ] +/-Buttons haben sprechende `accessibilityLabel`s ("Eine Minute weniger" / "Eine Minute mehr"), lokalisiert
- [ ] Disabled-State der +/-Buttons ist fuer Screen Reader korrekt ausgewiesen
- [ ] WCAG-Kontrast bleibt erfuellt (Big Number, "Minuten"-Label, Bogen)

### Konsistenz

- [ ] Lokalisiert (DE + EN) — Headline, Untertitel, Card-Labels, "Minuten"-Label, +/--Accessibility-Labels
- [ ] Visuell konsistent zwischen iOS und Android (gleiche Geometrie-Verhaeltnisse, gleiche Farben aus dem Theme, gleiche Skalierungs-Logik)
- [ ] Bestehender Primary-Button-Stil (`warmPrimaryButton()` auf iOS, Android-Pendant) bleibt **unveraendert** — kein Ueberschreiben mit dem copper-Pill-Glow aus dem Design

### Tests

- [ ] Unit-Tests fuer die Geste-Mathematik (Punkt → Winkel → Wert; Wert-Wraparound an 12-Uhr; Clamping gegen `minimumDurationMinutes` und 60)
- [ ] Unit-Tests fuer die Long-Press-Beschleunigung (Initial-Bump, dann Tick-Frequenz)
- [ ] Unit-Tests fuer den Disabled-State der +/--Buttons
- [ ] Snapshot/UI-Tests fuer das responsive Layout in mindestens drei Hoehen (kompakt / mittel / gross) — Idle-Screen ohne Scroll-Bedarf
- [ ] Bestehende Tests fuer Setting-Cards (aus shared-083) bleiben gruen

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare Aenderung)
- [ ] Falls neue Theme-Tokens: `dev-docs/reference/color-system.md` aktualisieren
- [ ] Falls neue Typo-Rollen: zentrale Liste der `TypographyRole`-Eintraege aktualisieren

---

## Manueller Test

1. Timer-Tab oeffnen.
2. Erwartung: Headline "Wie viel Zeit schenkst du dir?" oben, darunter der Atemkreis mit zentraler Minutenzahl, Tropfen pulsiert sanft auf dem Ring, +/-Buttons unten links und rechts radial vom Kreis.
3. Im Ring ziehen — Wert aendert sich kontinuierlich, Bogen waechst/schrumpft, Tropfen folgt der Fingerposition.
4. "-"-Button tippen — Wert -1. Halten — nach kurzem Initial-Delay beschleunigtes Heruntertasten.
5. Einstimmung von "Ohne" auf eine ~5-Minuten-Einstimmung umstellen, zurueck zum Timer: Wert klemmt mindestens auf der neuen Untergrenze, "-"-Button disabled bei diesem Wert.
6. Versuchen, Wert ueber 60 zu ziehen / zu tippen — clamp't auf 60, "+"-Button disabled.
7. Cards-Reihen pruefen: Labels sind Sentence-Case ("Vorbereitung", "Einstimmung", ...), nicht UPPERCASE.
8. Untertitel "Passe den Timer an" steht zwischen Atemkreis und der ersten Card-Reihe; Atem-Spacing wirkt grosszuegig, nicht gequetscht.
9. Auf iPhone SE / kleinem Android-Geraet: alles passt ohne Scrollen, Atemkreis wirkt nicht ueberdimensioniert.
10. Auf iPhone 15 Pro Max / grossem Android-Geraet: Atemkreis wirkt nicht verloren, Sektionen verteilen sich aesthetisch, keine grossen Leerflaechen.
11. Settings → Accessibility → Bewegung reduzieren: Tropfen-Halo ist sichtbar, aber statisch (kein Puls).
12. VoiceOver/TalkBack einschalten: Atemkreis ist als adjustable Slider erreichbar, +/-Buttons sind sprechend benannt.
13. Theme-Wechsel (warm → sage → dusk) und Locale-Wechsel (DE ↔ EN): alle Texte, Farben und Spacings bleiben konsistent.

Erwartung: Auf iOS und Android identisches Verhalten und identische Komposition.

---

## UX-Konsistenz

| Verhalten                       | iOS                                          | Android                                          |
|---------------------------------|----------------------------------------------|--------------------------------------------------|
| Drag-Geste                      | `DragGesture` auf der Dial-Hit-Area          | `detectDragGestures` in `pointerInput`           |
| Long-Press-Beschleunigung       | Combine-Timer / `Task` mit Sleep             | Coroutine mit `delay`                            |
| Atemkreis-Rendering             | SwiftUI `Canvas` oder `Path`                 | Compose `Canvas`                                 |
| Big Number Font                 | Newsreader (gebuendelt)                      | Newsreader (gebuendelt)                          |
| Slider-Accessibility            | `accessibilityAdjustableAction`              | `Modifier.semantics { progressBarRangeInfo }` + `setProgress` |
| Reduced Motion                  | `@Environment(\.accessibilityReduceMotion)`  | `LocalAccessibilityManager` / Settings-Check     |

Beide Plattformen folgen ihrem nativen Pattern fuer Geste-Erkennung und Animation, das resultierende Erlebnis muss aber identisch wirken.

---

## Referenz

- Design-Handoff: `handoffs/timer settings step2/` (`README.md`, `pickers-hybrid-v2.jsx`, `timer-config-step2-v2.jsx`, `Timer Config Step 2 v2.html`)
- iOS aktueller Idle-Screen: `ios/StillMoment/Presentation/Views/Timer/TimerView.swift` (`durationWheel`, `idleScreen`)
- Android aktueller Idle-Screen: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/TimerScreen.kt`
- Vorgaenger-Ticket: shared-083 (Setting-Karten statt Pills) — muss zuerst abgeschlossen sein
- Bestehende Setting-Cards: aus shared-083 uebernommen, hier nur Label-Casing geaendert

---

## Hinweise

**Konflikt mit shared-083 bewusst aufgeloest:**
shared-083 entfernt die Headline "Wie viel Zeit schenkst du dir?" vom Idle-Screen. Step 2 fuehrt sie als zentrale H1 wieder ein und ergaenzt den Untertitel "Passe den Timer an" ueber den Cards. Reihenfolge: shared-083 zuerst, shared-086 setzt darauf auf und uebersteuert das Headline-Kriterium.

**Drag-Mathematik:**
- Punkt → Winkel: `atan2(dy, dx)`, Origin Dial-Zentrum
- Winkel → Wert: `(deg + 90) mod 360 → value` mit `value === 0 ? minimumDurationMinutes : v` und Clamping `[minimumDurationMinutes, 60]`
- Bogen-Geometrie: Sweep-Flag basiert auf `((endA - startA + 360) mod 360) > 180`
- Bogen-Skala bleibt fest 1..60 (nicht `[minimumDurationMinutes, 60]`), sonst springt der Bogen, sobald sich die Einstimmung aendert. Lediglich der Drag-Wert wird geclamp't.

**Long-Press-Timing:**
Design-Spec: 320 ms Initial-Delay, danach 80 ms Tick. Auf nativ als Combine-Timer / Coroutine umsetzen, beim Loslassen sauber aufraeumen (kein Tick-Leak nach `onTouchUp`).

**Newsreader-Font:**
Sowohl iOS als auch Android buendeln Newsreader bereits (Display-Font im Typography-System). Es muss kein neuer Font registriert werden — nur die zwei neuen Rollen `.dialValue` und `.dialUnit` ergaenzen.

**Beginnen-Button bewusst nicht angefasst:**
Das Design zeigt einen copper-Pill-Button mit Gradient + grossem Glow. Die App hat bereits einen einheitlichen Primary-Button-Stil (`warmPrimaryButton()` auf iOS, Pendant auf Android). Diesen hier zu ueberschreiben, wuerde Inkonsistenz erzeugen. Ein eventueller App-weiter Button-Refactor ist eigenes Polish-Ticket.

**Plattform-Reihenfolge:**
Sequenziell: iOS zuerst, dann Android mit der iOS-Implementierung als Referenz.

**Nicht im Scope (kommt in Schritt 3):**
- Sternenhimmel-Hintergrund / atmosphaerische Tiefe
- Halos um die Cards
- 2-zeilige Card-Werte
- Neue Settings einfuehren oder Sitzungs-Engine anfassen

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
