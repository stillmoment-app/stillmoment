# Ticket ios-046: Running-Timer-Display — Akku-Vessel

**Status**: [ ] TODO
**Plan**: [Implementierungsplan](../plans/ios-046.md)
**Prioritaet**: MITTEL
**Komplexitaet**: Mittel. Reines Visual-Redesign der laufenden Sitzung, keine Domain- oder Audio-Aenderung. Risiko liegt in der linearen Pegel-Animation ueber lange Sitzungsdauern (bis 60 min) inkl. korrekter Resume-Berechnung nach App-Suspend, sowie im sauberen Trennen von der heutigen Atemkreis-Visualisierung, die der Player weiterhin nutzt.
**Abhaengigkeiten**: Keine. Player-Atemkreis (shared-087) bleibt unveraendert; Timer-Pre-Roll (shared-090) bleibt unveraendert.
**Phase**: 4-Polish

---

## Was

Die Hauptphase des Meditation-Timers (stille Praxis, laufende Sitzung) bekommt ein neues Visual: eine vertikale Glas-Capsule ("Akku-Vessel") mit warmem Verlauf, deren Fluessigkeitspegel linear ueber die Sitzungsdauer steigt — das Glas fuellt sich auf. Rechts daneben steht die Restzeit prominent in MM:SS-Form, darueber ein Eyebrow "VERBLEIBEND", darunter "von X Minuten" zur Verortung.

## Warum

Der heutige Atemkreis in der Hauptphase taktet visuell einen Atemrhythmus, den die App eigentlich nicht vorgeben will — eine Meditations-App soll nicht diktieren, wann ein- und ausgeatmet wird. Das Vessel-Visual ist still: nichts pulsiert, nichts pumpt, nur der Pegel steigt langsam (linear, nicht pro Frame wahrnehmbar). Gleichzeitig wird die Restzeit gross und ablesbar — bisher war sie klein unter dem Atemkreis. Die Botschaft des Visuals ist "Meditation fuellt dich auf, sie verbraucht dich nicht": waehrend die Restzeit praktisch runterzaehlt, erzaehlt das Glas die andere, sinnstiftende Geschichte.

---

## Akzeptanzkriterien

<!-- Gute Kriterien: Beobachtbar, testbar, user-zentriert -->

### Feature: Hauptphase-Visual

- [ ] Layout: Vessel-Visual und Restzeit-Textblock nebeneinander, horizontal und vertikal in der verfuegbaren Flaeche zentriert, definierter Abstand zwischen beiden
- [ ] Vessel ist eine vertikale, abgerundete Glas-Capsule (Hochformat, schmal) mit subtilem dunklem Glas-Hintergrund und einer feinen, hellen Randlinie
- [ ] Pegel im Vessel: warmer Vertikal-Verlauf von hellem Honig oben ueber Kupfer in der Mitte zu tiefem Kupfer unten
- [ ] Pegel-Gradient ist an der Glas-Geometrie verortet (nicht an der Fluessigkeit): wenn der Pegel steigt, "wandert" die helle Zone **nicht** mit nach oben — die Oberkante des Pegels schiebt sich nach oben durch den Farbverlauf hindurch, anfangs sind nur die tiefen Kupfertoene sichtbar, gegen Sitzungsende kommen die honigfarbenen Spitzentoene dazu
- [ ] Schmaler heller Meniskus-Glanz sitzt auf der Wasseroberflaeche und folgt der Pegelhoehe
- [ ] Schmaler statischer Glas-Reflex an der linken Innenseite des Vessels
- [ ] Restzeit rechts neben dem Vessel: grosse Display-Schrift im Format MM:SS, tabulare Ziffern (kein Spaltenwechsel beim Tick), warmer heller Textton
- [ ] Eyebrow ueber der Restzeit: "VERBLEIBEND", uppercase, kleine UI-Schrift, gedaempfter Textton, deutlicher letter-spacing
- [ ] Sub-Label unter der Restzeit: "von X Minuten" in kursiver Display-Schrift, mittlerer Textton, kleiner als die Restzeit
- [ ] Schliessen-Button oben links in der Toolbar wie bisher (kein freistehender Button auf dem Screen)
- [ ] Heutiger Atemkreis ist in der **Hauptphase** nicht mehr sichtbar (Pre-Roll behaelt ihn — siehe Out of Scope)

### Feature: Pegel-Animation

- [ ] Pegel startet bei Sitzungsbeginn leer (unten) und ist am Sitzungsende voll (oben) — Metapher: Meditation laedt dich auf
- [ ] Pegel steigt **linear** ueber die gesamte Sitzungsdauer — keine Easing-Kurve, keine sekuendlichen Spruenge
- [ ] Bei Sitzungsdauern von 1 bis 60 Minuten ist die Pegel-Bewegung pro Frame nicht wahrnehmbar, aber ueber Minuten klar sichtbar
- [ ] Restzeit-Zahl tickt im Sekundentakt von voll auf 00:00
- [ ] Keine Atem-Animation, kein Pulsen, kein Schwingen des Meniskus

### Feature: Lifecycle / Resume

- [ ] Bei Rueckkehr aus Hintergrund (App-Resume, Screen-Wake) zeigt der Pegel die korrekte Hoehe fuer die aktuell verstrichene Sitzungszeit
- [ ] Kein Snap-Back nach unten und kein Catch-up-Sprung — die Animation laeuft vom aktuellen Punkt linear weiter bis zum Sitzungsende
- [ ] Wakelock bleibt waehrend der Sitzung aktiv (Screen geht nicht von alleine schlafen) — Verhalten wie heute

### Feature: StartGong- und EndGong-Phasen

- [ ] Waehrend StartGong- und EndGong-Phasen bleibt das Vessel-Visual durchgaengig sichtbar
- [ ] Pegel-Bewegung und Restzeit-Tick verhalten sich konsistent zur Hauptphase

### Feature: Reduced Motion / Accessibility

- [ ] Bei aktivem "Bewegung reduzieren" snappt der Pegel im Sekundentakt an die korrekte Hoehe statt kontinuierlich zu steigen — bleibt informativ (Restzeit-Zahl tickt ohnehin sekuendlich)
- [ ] Vessel-Visual ist fuer Screen Reader als dekorativ markiert (keine doppelte Auslesung der Restzeit)
- [ ] Restzeit-Label ist fuer Screen Reader lesbar; bestehender accessibility-Identifier `timer.display.time` bleibt auf dem Restzeit-Text erreichbar
- [ ] Schliessen-Button behaelt seinen accessibility-Label (wie heute)

### Feature: Theming / Konsistenz

- [ ] Timer nutzt den aktiven Theme-Hintergrund (`theme.backgroundGradient`) wie bisher
- [ ] Vessel-Pegel-Farbe ist an das aktive Theme gekoppelt: nutzt `theme.interactive` als Basis und erzeugt die raeumliche Tiefe ueber einen Opacity-Verlauf (oben transparenter, unten kraeftiger). Dadurch passt die Fuellfarbe in allen drei Themes (Kerzenschein/Wald/Mondlicht) × Light/Dark zur Akzentfarbe der App
- [ ] Text-Farben (Restzeit, Eyebrow, Sub-Label) sind weiterhin Theme-getoned ueber das bestehende Semantik-Token-System

### Feature: Lokalisierung

- [ ] Eyebrow "VERBLEIBEND" lokalisiert (DE + EN)
- [ ] Sub-Label "von X Minuten" lokalisiert (DE + EN) — Singular/Plural fuer 1 Minute korrekt
- [ ] Heutiger Hauptphase-Restzeit-Key ("NOCH … MIN") wird ersetzt oder fuer den neuen Block weiterverwendet; nicht mehr genutzte Keys werden entfernt

### Tests

- [ ] Unit-Test: Pegel-Progress (0.0 bei Sitzungsstart = leer, 1.0 bei Sitzungsende = voll, monoton wachsend)
- [ ] Unit-Test: Restzeit-Formatierung MM:SS fuer typische Werte (60 min, 7:36, 0:01, 0:00)
- [ ] Unit-Test: Resume-Berechnung — nach simulierter Pause-Phase ist Progress aus `started_at` und aktuellem Zeitpunkt korrekt
- [ ] Bestehende Timer-ViewModel-Tests (Reducer, State-Machine, Completion) laufen unveraendert
- [ ] UI-Test: `timer.display.time` ist in der Hauptphase auf dem Restzeit-Label erreichbar

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare Aenderung — Running-Timer hat neues Visual, kein Atemkreis mehr waehrend laufender Sitzung)
- [ ] `dev-docs/architecture/timer-state-machine.md` aktualisiert, falls dort das UI-Display-Verhalten der Hauptphase dokumentiert ist
- [ ] CLAUDE.md (Root oder iOS) aktualisiert, falls dort das alte Atemkreis-Display in der Hauptphase dokumentiert ist
- [ ] **Keine** Aenderung an Handoff-Dokumenten oder Plan-Files vergangener Tickets — historische Dokumente bleiben unveraendert

---

## Manueller Test

1. Timer-Tab oeffnen, Vorbereitungszeit auf 0 setzen, Sitzung mit z.B. 10 Minuten starten
2. Erwartung Hauptphase: vertikales Glas-Vessel links, Pegel leer (Boden), warmer Honig/Kupfer-Verlauf erst sichtbar wenn die Fluessigkeit hochkommt. Rechts daneben: "VERBLEIBEND" als Eyebrow, darunter die grosse Restzeit (z.B. "10:00"), darunter "von 10 Minuten" kursiv. Kein Atemkreis, kein Pulsen
3. Restzeit tickt sekuendlich nach unten; Sekundenstellen rutschen nicht, weil Zahlen monospaced sind
4. Nach ca. 1 Minute Beobachtung: Pegel ist sichtbar gestiegen; Bewegung war zu keinem Zeitpunkt sprunghaft oder pro Frame "fluessig"
5. App in Hintergrund schicken (Home-Wisch), 30 s warten, App zurueck: Pegel zeigt die korrekte Hoehe fuer die jetzt verstrichene Sitzungszeit, ohne Snap-Back oder Catch-up-Sprung
6. Sitzung mit Vorbereitungszeit > 0 starten: Pre-Roll bleibt wie heute (Atemkreis mit Countdown). Beim Uebergang in die Hauptphase erscheint das Vessel-Visual und die Pegel-Animation startet bei leer
7. Sitzung auf 1 Minute starten und durchlaufen lassen: Pegel ist am Ende voll; EndGong spielt; Uebergang zum Danke-Screen wie heute
8. Schliessen-Button in der Toolbar oben links: beendet die Sitzung sauber wie heute
9. Settings → "Bewegung reduzieren" einschalten, Sitzung starten: Pegel snappt sekuendlich an die korrekte Hoehe; Restzeit tickt normal
10. Theme-Wechsel (Kerzenschein / Wald / Mondlicht) und Light/Dark: Vessel-Pegel-Farbe wechselt mit der Akzentfarbe des Themes (Terrakotta / Oliv / Blau bzw. Lavendel); Glas-Hintergrund bleibt neutral; Text- und Hintergrund-Farben passen sich dem Theme an
11. Auf iPhone SE: Vessel und Restzeit-Block sind komplett sichtbar ohne Abschneiden; Layout bleibt zentriert
12. VoiceOver: Restzeit wird gelesen, Vessel-Visual nicht doppelt; Schliessen-Button hat ein verstaendliches Label

---

## Referenz

- Handoff mit Designdetails (Maße, Farben, Verläufe, Animationsverhalten): `handoffs/claude_code_handoff_running_timer/`
- iOS Timer heute: `ios/StillMoment/Presentation/Views/Timer/TimerView.swift`
- Heute genutzte Atemkreis-Komponente (bleibt fuer Pre-Roll und Player): geteilte Komponente aus shared-087
- Vorgaenger-Ticket: `dev-docs/tickets/shared/shared-090-timer-atemkreis-analog-player.md`
- Verwandt: `dev-docs/tickets/shared/shared-092-danke-screen-redesign.md` (gleiche Stossrichtung "Stille statt Atemtaktung")
- Typografie-Rollen: `Font+Theme.swift` — fuer den 64-px-Restzeit-Block wird ggf. eine neue oder bestehende Display-Rolle genutzt

---

## Hinweise

**Lineare Animation ueber lange Dauer:**

Bei 60 Minuten Sitzungsdauer laeuft die Pegel-Animation 3600 Sekunden linear. Eine einzige durchgaengige SwiftUI-Animation ueber diese Dauer ist in Ordnung — Voraussetzung ist eine zuverlaessige Resume-Logik, die nach App-Suspend nicht in den falschen Endwert "snappt". Source of Truth ist `started_at` als Wall-Clock-Timestamp; daraus wird jedes Mal, wenn die View aktiv wird, der aktuelle Progress berechnet und die Restanimation mit der verbleibenden Dauer neu gestartet.

**Pegel-Farbe folgt dem Theme:**

Die Fuellfarbe nutzt das bestehende `theme.interactive`-Token — dasselbe, das Buttons und der Atemkreis tragen. Damit ist der Akku-Pegel in jedem Theme die Akzentfarbe der App (warmes Terrakotta in Kerzenschein, gedaempfter Olivton in Wald, tiefes Blau/Lavendel in Mondlicht). Die raeumliche Tiefe entsteht ueber drei Opacity-Stops (0.55 oben → 0.95 unten) gegen den dunklen Glas-Hintergrund — keine zusaetzlichen Theme-Tokens noetig.

**Pre-Roll und Danke-Screen bleiben unveraendert:**

Diese beiden Phasen sind explizit out of scope. Der Pre-Roll behaelt das Atemkreis-Design aus shared-090. Der Danke-Screen wird separat in shared-092 behandelt. Folge: in der Pre-Roll-Phase zeigt der Screen einen Atemkreis, in der Hauptphase ein Vessel — der Stilbruch ist bewusst akzeptiert und kann spaeter durch ein eigenes Pre-Roll-Redesign aufgeloest werden.

**Atemkreis-Komponente bleibt:**

Die geteilte Atemkreis-Komponente wird vom Player und vom Timer-Pre-Roll weiterhin genutzt. Sie wird **nicht** entfernt, sondern nur in der Hauptphase des Timers nicht mehr eingebunden. Der Timer-Pre-Roll bindet weiterhin die geteilte Komponente ein.

**Newsreader/Geist sind Design-Sprache des Handoffs, nicht der App:**

Der Handoff nennt Newsreader (Restzeit, kursives Sub-Label) und Geist (Eyebrow) als Schriften. In der App werden die bestehenden, theme-getragenen Typografie-Rollen verwendet — also die App-Display-Schrift fuer die Restzeit und die App-UI-Schrift fuer das Eyebrow. Ob es dafuer eine neue Typografie-Rolle (z.B. "running-display") braucht oder ob eine bestehende Rolle passt, ist Implementierungs-Entscheidung. `font-variant-numeric: tabular-nums` (oder das iOS-Pendant) ist auf der Restzeit-Zahl Pflicht.

**Pause nicht im Scope:**

Der Timer hat seit shared-048 keine Pause-Funktion mehr; dieses Ticket aendert daran nichts. Es gibt im Vessel-Visual entsprechend kein Pause-Bedienfeld, keinen Tap auf das Visual und keine eigene Pause-UI.

**iPhone SE Layout:**

Vessel ist ca. 110×360 pt im Handoff-Referenzgeraet (iPhone Pro). Auf kleineren Geraeten (iPhone SE) muss das Layout zusammen mit der Restzeit-Spalte vertikal in die verfuegbare Hoehe passen. Falls eng: Vessel proportional verkleinern, Verhaeltnis zwischen Vessel-Breite und -Hoehe (ca. 1:3.3) beibehalten. Restzeit-Schriftgrad ggf. ebenfalls leicht reduzieren — Lesbarkeit und Tap-Bereich des Schliessen-Buttons in der Toolbar dabei nicht beruehren.

---

<!--
WAS NICHT INS TICKET GEHOERT:
- Kein Code (Claude Code schreibt den selbst)
- Keine Dateilisten (Claude Code findet die Dateien)
- Keine Architektur-Diagramme (steht in CLAUDE.md)
- Keine Test-Befehle (steht in CLAUDE.md)
-->
