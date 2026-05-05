# Ticket shared-087: Guided Meditation Player Redesign — Atemkreis & Auto-Start

**Status**: [x] DONE
**Plan iOS**: [Implementierungsplan](../plans/shared-087-ios.md)
**Plan Android**: [Implementierungsplan](../plans/shared-087-android.md)
**Prioritaet**: HOCH
**Komplexitaet**: Mittel-hoch. Komplette View-Neuschreibung mit eigenstaendiger Atemkreis-Komponente, Pre-Roll-/Hauptphasen-Uebergang mit Cross-Fade, neuer Glas-Pause-Button. ViewModel-Logik bleibt weitgehend, aber UI-Triggering wechselt von Play-Tap zu Auto-Start. Risiko: korrekte Sync der Atem-Animation mit Pause-State, Backdrop-Blur-Performance auf aelteren Geraeten, Reduced-Motion-Pfad.
**Phase**: 3-Feature

---

## Was

Der Guided-Meditation-Player wird komplett neu gestaltet:

- **Auto-Start**: kein initialer Play-Tap mehr — Pre-Roll oder Audio startet sofort beim Oeffnen des Player-Screens.
- **Radikale Reduktion auf eine Geste**: kein Slider, kein Skip ±10 s, keine Elapsed-Zeit. Einzige sichtbare Bedienung ist Pause/Play (existiert nur in der Hauptphase).
- **Atemkreis als zentrales Element**: 280 × 280-Komponente mit statischem Track, Restzeit-Bogen (waechst mit Fortschritt) inkl. „Sonnen"-Punkt am vorderen Bogen-Ende und atmendem Glow (~16 s Zyklus, ease-in-out, kontinuierlich, nicht ans Audio gekoppelt). Pause-Button als Glas-Element mittig im Glow.
- **Pre-Roll-Variante**: gleiche 280 × 280-Box, aber **nur der statische Track** ist sichtbar — kein Restzeit-Bogen, der die verbleibende Vorbereitungszeit visualisiert. Glow atmet noch nicht. Countdown-Zahl im Inneren kommuniziert die Restzeit, Hint "GLEICH GEHT'S LOS" unter dem Ring. Schliessen jederzeit moeglich, kein Pause.
- **Restzeit-Label**: "NOCH 8:32 MIN" 36 pt unter dem Ring (ersetzt das Currenttime/Remaining-HStack).
- **Responsive in der Vertikale**: Layout passt sich an iPhone SE (compact height) bis Pro Max an, ohne Scrollen.

ViewModel-Logik (Pre-Roll-State, CompletionEvent, hasSessionStarted-Guard, Audio-Engine, Lockscreen-Integration) bleibt unveraendert. Nur das Triggering verschiebt sich von explizitem Play-Tap zu onAppear-getriggertem Start.

## Warum

Der heutige Player ist visuell ein Apple-Music-Klon (Slider, ±10 s, dominante Play-Taste) und damit ein Anti-Pattern fuer Meditation: jeder Slider ist eine Falle (man landet ungewollt im Outro), jede sichtbare Steuerung ist ein Versprechen, dass es etwas zu bedienen gaebe — und reisst aus der Praxis.

Das neue Design folgt dem Standard-Use-Case: User startet Meditation, legt Phone weg, Lockscreen geht an. Waehrend der Praxis schaut niemand auf den Bildschirm. Daher: weniger Controls, eine zentrale Atem-Visualisierung als sanfte Atemfuehrung, Pause als einzige Geste. Restzeit wird passiv kommuniziert (feiner Bogen + eine Zahl). Der ganze Bildschirm wird zu einem langsam atmenden Kreis — Lebenszeichen und Atemfuehrung in einem.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | iOS-Implementierung als Referenz |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen, sofern nicht anders vermerkt -->

### Feature: Auto-Start (beide Plattformen)

- [ ] Beim Oeffnen des Player-Screens startet Pre-Roll bzw. Audio **sofort**, ohne dass ein Play-Tap erforderlich ist
- [ ] Wenn `preparationTimeSeconds == 0` oder nicht gesetzt ist, startet Audio direkt in der Hauptphase
- [ ] Wenn `preparationTimeSeconds > 0` ist, startet Pre-Roll automatisch und geht nach Ablauf nahtlos in die Hauptphase ueber
- [ ] Es existiert zu keinem Zeitpunkt im Lifecycle ein initialer Play-Button

### Feature: Pre-Roll-Phase (beide Plattformen)

- [ ] 280 × 280-Box, vertikal und horizontal zentriert, mit Safe-Area-Beruecksichtigung
- [ ] Statischer Ring-Hintergrund (subtiler Stroke, semantisches Token) — **einzige** sichtbare Ring-Schicht in dieser Phase
- [ ] **Kein Vorbereitungs-Bogen / kein zweiter Bogen ausserhalb des Glow.** Die verbleibende Vorbereitungszeit wird ausschliesslich durch die Countdown-Zahl in der Mitte kommuniziert (zwei parallele Restzeit-Visualisierungen wirken redundant)
- [ ] Inneres Glow-Feld (ca. 220 × 220, Kreis): warmer Radial-Gradient — gedaempfter als Hauptphase. **Keine** Atem-Animation in dieser Phase
- [ ] Inhalt im Glow-Feld: Countdown-Zahl gross (themed Font-Rolle, monospaced/tabular-Numerals) + Label "Vorbereitung" darunter
- [ ] Hint-Label unter dem Ring: "GLEICH GEHT'S LOS" in Uppercase, gedaempfte Sekundaerfarbe
- [ ] **Kein Pause-Button** waehrend der Pre-Roll
- [ ] Schliessen-Button oben links jederzeit erreichbar
- [ ] Audio-Engine ist waehrend der Pre-Roll **noch nicht** gestartet — nur ein UI-Timer laeuft
- [ ] Reduced Motion: identisches Verhalten — Track plus Countdown-Zahl. Cross-Fade entfaellt, instant cut

### Feature: Uebergang Pre-Roll → Hauptphase (beide Plattformen)

- [ ] Cross-Fade von Countdown-Zahl + Label "Vorbereitung" + Hint zu Hauptphasen-Inhalten in ca. 400 ms
- [ ] Restzeit-Bogen erscheint bei 0 und waechst dann mit Fortschritt; Sonnen-Punkt am vorderen Ende erscheint mit
- [ ] Inneres Glow-Feld beginnt zu atmen (kein Sprung, sondern Easing-Start aus `scale(1)`)
- [ ] Pause-Button erscheint per Fade-In mittig im Glow
- [ ] Restzeit-Label "NOCH … MIN" erscheint per Fade-In
- [ ] Audio startet bei Sekunde 0 der Hauptphase direkt auf voller Lautstaerke (kein Volume-Fade)

### Feature: Hauptphase / Atemkreis (beide Plattformen)

- [ ] Layout von oben nach unten: Schliessen-Button (oben links) · Lehrer-Name · Meditationstitel · Atemkreis (zentriert) · Restzeit-Label
- [ ] Atemkreis-Box 280 × 280, vertikal und horizontal zentriert, mit Safe-Area-Beruecksichtigung
- [ ] **Layer 1**: statischer Ring-Hintergrund (subtiler Stroke, semantisches Token)
- [ ] **Layer 2a**: Restzeit-Bogen — Stroke in Akzent-Token, Linecap rund, Rotation -90°. Gefuellter Anteil entspricht **vergangener** Sitzungszeit. Update-Frequenz 1–5 s reicht visuell
- [ ] **Layer 2b**: „Sonnen"-Punkt — kleiner gefuellter Kreis (~9 pt) in Akzent-Token mit dezentem Soft-Shadow, sitzt am vorderen Ende des Restzeit-Bogens und wandert mit dem Fortschritt mit
- [ ] **Layer 3**: Atem-Glow — kontinuierliche Animation ~16 s pro Zyklus, ease-in-out, infinite. Skala variiert leicht, Opacity variiert leicht. Animation laeuft **unabhaengig vom Audio**
- [ ] Pause-Button 80 × 80, exakt zentriert im Glow
- [ ] Pause-Button-Look: halbtransparenter Glas-Stil mit Backdrop-Blur (~8 px). Auf Plattformen ohne Backdrop-Filter: opaker dunkler Fallback ohne Blur
- [ ] Pause/Play-Glyph in Akzent-Glow-Token
- [ ] Restzeit-Label-Format: "NOCH 8:32 MIN" (Uppercase, tabular-Numerals, monospaced)
- [ ] Tap **ausserhalb** des Pause-Buttons macht nichts (kein Slider, keine Ghost-Aktionen)

### Feature: Pause-Verhalten (beide Plattformen)

- [ ] Tap auf Pause-Button: toggelt Play/Pause des Audios
- [ ] Cross-Fade zwischen Pause- und Play-Glyph in ca. 200 ms
- [ ] Bei Pause: Atem-Animation laeuft kontinuierlich weiter (unabhaengig vom Audio — der Atem ist Atemfuehrung, nicht Audio-Indikator); Restzeit-Bogen friert ein, weil Audio steht
- [ ] Bei Resume: Audio laeuft weiter, Atem-Animation hat ohnehin nie pausiert
- [ ] Externe Pause/Play-Quellen (Lockscreen, Control Center, AirPods) spiegeln den Player-Zustand korrekt
- [ ] Sanftes haptisches Feedback bei Tap (iOS: weiches Impact, Android: Default-Tick)

### Feature: Entfernte Funktionen (beide Plattformen)

- [ ] Kein Slider / kein Scrub-Track
- [ ] Kein Skip ±10 s
- [ ] Keine Anzeige der vergangenen Zeit (Elapsed)
- [ ] Kein "Neu starten"-Button (auch nicht hinter Long-Press — bewusst nicht im Scope)
- [ ] Kein "+1 Min Stille"-Endgesten-Button

### Feature: Schliessen (beide Plattformen)

- [ ] Schliessen-Button oben links, ca. 44 × 44, in jedem Zustand erreichbar (Pre-Roll, Playing, Paused)
- [ ] Tap auf Schliessen: Audio stoppt direkt, Uebergang zurueck zum vorherigen Screen (kein Audio-Fade)
- [ ] Visuell ein Glas-Stil-Button mit "×"-Icon, konsistent mit anderen Sheets in der App
- [ ] Auch waehrend einer aktiven Praxis bleibt der Schliessen-Button die einzige Navigation weg vom Player

### Feature: Responsives Layout (beide Plattformen)

- [ ] Auf iPhone SE (compact height) und kleinen Android-Geraeten passt der gesamte Player ohne Scrollen
- [ ] Atemkreis-Groesse passt sich proportional an: keine Ueberschneidungen mit Lehrer/Titel oben oder Restzeit-Label unten
- [ ] Auf grossen Geraeten (Pro Max, Pixel 8 Pro) wirkt das Layout nicht verloren — Spacing waechst, aber Atemkreis bleibt zentriert

### Feature: Reduced Motion / Accessibility (beide Plattformen)

- [ ] Bei aktivem "Bewegung reduzieren" wird die Atem-Animation deaktiviert; Glow bleibt sichtbar im neutralen Zustand (konstante Skala/Opacity)
- [ ] Restzeit-Bogen aktualisiert sich auch im Reduced-Motion-Modus weiterhin (Information, keine Dekoration)
- [ ] Pause-Button hat Accessibility-Label, das den aktuellen Zustand korrekt benennt ("Pausieren" / "Fortsetzen")
- [ ] Schliessen-Button hat Accessibility-Label "Zurueck zur Bibliothek"
- [ ] Restzeit-Label ist als Text fuer Screen Reader zugaenglich

### Feature: Theming (beide Plattformen)

- [ ] Player nutzt den aktiven Theme-Hintergrund (`theme.backgroundGradient` o. ae.) — keine Theme-unabhaengigen Hardcoded-Farben
- [ ] Bei Bedarf neue semantische Tokens fuer: Atemkreis-Track-Stroke, Atemkreis-Glow-Center, Atemkreis-Glow-Border, Pause-Glas-Hintergrund, Pause-Glas-Border. Tokens existieren in allen drei Themes (warm / sage / dusk)
- [ ] Light- und Dark-Mode-Verhalten konsistent zum Rest der App (aktuell ist der Player-Screen permanent dunkel atmosphaerisch — das soll erhalten bleiben)

### Feature: Konsistenz (beide Plattformen)

- [ ] Lokalisiert (DE + EN): "NOCH … MIN", "GLEICH GEHT'S LOS", "Vorbereitung", Accessibility-Labels
- [ ] Visuell und verhaltensgleich zwischen iOS und Android
- [ ] Bestehende Typografie-Rollen werden genutzt (`.playerTitle`, `.playerTeacher`, `.playerCountdown`); neue Rolle fuer das Restzeit-Label nur bei Bedarf erganzt

### Tests

- [ ] Unit-Tests iOS: Player startet automatisch beim onAppear (mit/ohne Pre-Roll); Atemkreis-View-Logik (Layer-Zustaende pro Phase); Restzeit-Label-Formatierung; Reduced-Motion-Pfad
- [ ] Unit-Tests Android: aequivalente Coverage
- [ ] Bestehende ViewModel-Tests (Countdown, Completion, Lockscreen) laufen unveraendert weiter — kein Regress
- [ ] iOS Snapshot-/UI-Test: Pre-Roll-Phase, Hauptphase Playing, Hauptphase Paused (drei Screenshots). Reduced-Motion-Verhalten bleibt manueller Test (Settings → Accessibility → Reduce Motion) — automatisierte Snapshot-Variante braucht Snapshot-Diff-Infrastruktur und einen App-seitigen Override fuer `accessibilityReduceMotion`, beides ausserhalb des Scopes

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare Aenderung — Player neu, weniger Controls, Auto-Start)
- [ ] Glossar bei Bedarf: "Atemkreis" als Begriff aufnehmen, falls neu

---

## Manueller Test

1. Library oeffnen, eine geladene Meditation antippen — Player oeffnet sich
2. Erwartung: kein Play-Button. Wenn Vorbereitung > 0, laeuft die Pre-Roll-Phase sofort (Bogen entleert sich, Zahl zaehlt runter, Hint sichtbar). Wenn Vorbereitung = 0, startet Audio sofort und Atemkreis atmet
3. Pre-Roll abwarten: Cross-Fade zur Hauptphase, Pause-Button erscheint, Restzeit-Label erscheint, Audio fadet rein
4. Atemkreis beobachten: Glow atmet ruhig (~16 s Zyklus), unabhaengig von der Audio-Sprache
5. Pause-Button antippen: Glyph wechselt zu Play, Atem friert ein, Audio pausiert. Lockscreen-Status spiegelt
6. Auf Lockscreen via Lockscreen-Control wieder Play druecken: App folgt, Glyph wechselt zurueck, Atem laeuft weiter
7. Schliessen-Button antippen: Audio fadet aus, Player verschwindet, Library wieder sichtbar
8. Settings → "Bewegung reduzieren" einschalten, Player erneut oeffnen: Atem-Animation deaktiviert, Restzeit-Bogen aktualisiert sich weiterhin
9. Auf iPhone SE: gesamter Player ohne Scrollen sichtbar, Atemkreis nicht abgeschnitten, Lehrer/Titel oben und Restzeit unten haben genug Abstand
10. Theme-Wechsel (warm → sage → dusk): Player passt sich Theme-Hintergrund an, Atemkreis-Glow bleibt warm und atmosphaerisch
11. Auf Android: identisches Verhalten zu iOS, kein zusaetzlicher Slider, kein Skip

Erwartung: Auf iOS und Android identisches Verhalten und nahezu identische visuelle Wirkung.

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Backdrop-Blur Pause-Button | `Material.ultraThinMaterial` o.ae. | `Modifier.blur` mit Fallback auf opaken Hintergrund auf Low-End |
| Atem-Animation | SwiftUI `withAnimation(.easeInOut.repeatForever)` | Compose `rememberInfiniteTransition` |
| Reduced-Motion-Detection | `accessibilityReduceMotion` | `Settings.Global.TRANSITION_ANIMATION_SCALE` o.ae. |
| Schliessen-Button | Toolbar oder Overlay-Button im SafeArea-Inset oben links | `IconButton` im SafeContent-Padding oben links |

Beide Plattformen verwenden ihre nativen Animations-Patterns; das Verhalten (Timing, Reihenfolge der Fades) ist identisch.

---

## Referenz

- iOS Player heute: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift`
- iOS ViewModel: `ios/StillMoment/Application/ViewModels/GuidedMeditationPlayerViewModel.swift`
- Android Player heute: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/guided/...`
- Design-Handoff: `handoffs/design_handoff_player/` (insbesondere `README.md`, `Player Optionen.html`, `player-options.jsx` Variante B + P1, `styles.css` Token-Block)
- Bestehende Pre-Roll-Logik: `PreparationCountdown` Domain-Model, `PreparationCountdownState` enum im ViewModel
- Theme-System: `dev-docs/reference/color-system.md`, `ThemeColors`-Struct
- Typografie-System: `Font+Theme.swift`, vorhandene Player-Rollen `.playerTeacher` / `.playerTitle` / `.playerCountdown` / `.playerTimestamp`

---

## Hinweise

**Vom Design-Handoff abweichend:**

- Hintergrund: das Handoff zeigt einen sehr spezifischen Mahagoni-Radial-Gradient. Wir nutzen stattdessen den aktiven `theme.backgroundGradient` aus dem bestehenden Theme-System, damit der Player nicht aus der App-Atmosphaere ausbricht
- Typografie: das Handoff nennt Newsreader/Geist. Wir bleiben bei den projekteigenen Typography-Rollen — visuell wird sich das leicht unterscheiden, ist aber konsistent mit dem Rest der App
- Farb-Hex-Werte (`#c47a5e`, `#d99a7e` usw.): werden auf bestehende oder neue semantische Tokens gemappt, nicht hardcoded uebernommen

**ViewModel-Scope:**

ViewModel bleibt strukturell unveraendert. Aenderungen nur dort wo zwingend:

- Auto-Start: `startPlayback()` muss vom View-`onAppear` aus aufgerufen werden statt vom Play-Button
- Skip-Methoden (`skipForward`, `skipBackward`, `seek`): bleiben im ViewModel erhalten, weil Lockscreen-Controls und Tests sie ggf. brauchen — die View ruft sie nur nicht mehr auf

**Lock-Screen / Background:**

- Pre-Roll nutzt bereits `playerService.startSilentBackgroundAudio()`, damit iOS die App nicht suspendiert. Bleibt unveraendert
- Cross-Fade Pre-Roll → Audio nutzt bereits `transitionFromSilentToPlayback()`, um keinen Audio-Gap zu erzeugen. Bleibt unveraendert
- Lockscreen-Pause-Spiegelung ist bereits implementiert (`MPNowPlayingInfoCenter`). Wird durch das neue UI nicht beeinflusst

**Performance:**

- Backdrop-Blur kann auf aelteren Geraeten teuer sein. Auf iOS reicht `.ultraThinMaterial` (gut optimiert). Auf Android: `Modifier.blur` ab Android 12+; davor opaker Fallback (kein Reduzieren des Blurs)
- Restzeit-Bogen muss nicht audio-sample-genau aktualisiert werden — 1 s Polling reicht. 5 s waere sogar visuell akzeptabel, aber das Restzeit-Label braucht ohnehin Sekunden-Updates

**Plattform-Reihenfolge:**

Sequenziell: iOS zuerst, dann Android mit der iOS-Implementierung als Referenz.

**Nicht im Scope:**

- Post-Session-Screen / Completion-Screen aendern (hat eigenes Ticket, separater Spec)
- Atemtempo individualisieren (16 s ist erste Setzung; spaetere Anpassung an Lehrer-Stil moeglich)
- Lockscreen-Now-Playing-Metadaten anpassen (aktuelle Felder bleiben)
- Long-Press-auf-Pause-fuer-Restart (Spec erwaehnt es als zukuenftige Option, nicht jetzt)

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
