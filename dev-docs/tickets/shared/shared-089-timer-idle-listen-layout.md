# Ticket shared-089: Timer-Idle-Screen mit flacher Settings-Liste statt Karten-Grid

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Komplexitaet**: Mittel. Visuelle Beruhigung des Idle-Screens durch Ersetzen des Karten-Grids durch eine flache Listenkomponente und Entfernen der +/- Buttons am Atemkreis. Bewusster Konflikt mit shared-086 (Sub-Headline und +/- Buttons werden ueberschrieben). Voraussetzung ist shared-088 (genau 4 Settings uebrig). Risiko liegt in der vertikalen Verteilung auf kleinen vs. grossen Geraeten und in der semantischen Theme-Belegung der Listen-Optik (akzentuierter Wert-Text, Trennlinien, Inaktiv-Opazitaet) ohne direkte Hex-Werte.
**Phase**: 4-Polish

---

## Was

Der Timer-Idle-Screen ("Wie viel Zeit schenkst du dir?") wird visuell beruhigt: Das Karten-Grid mit den Setting-Karten wird durch eine flache Listenkomponente ersetzt — eine Zeile pro Setting, Label links, Wert rechts mit dezentem Chevron, durchgehende Trennlinien, keine Backgrounds und keine Icons. Die Sub-Headline "Passe den Timer an" und die +/- Buttons am Atemkreis werden komplett entfernt. Inaktive Zeilen (z.B. Vorbereitung "Aus") fallen optisch zurueck.

## Warum

Das aktuelle Karten-Grid (3+2) konkurriert visuell mit dem Atemkreis und macht den Konfigurations-Screen unruhig. Eine flache Liste stellt klar, dass der Atemkreis die Hauptaktion ist und die Settings nur ergaenzende Details. Die +/- Buttons am Ring sind zusaetzliches visuelles Rauschen — die Drag-Geste reicht zur Bedienung, die Adjustable-Slider-Accessibility (aus shared-086) bleibt als alleinige nicht-gestische Eingabe. Mit nur noch 4 Settings (nach shared-088) passt die flache Liste komfortabel auf jedes Geraet inklusive iPhone SE, ohne zu scrollen.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit              |
|-----------|--------|----------------------------|
| iOS       | [x]    | shared-086, shared-088     |
| Android   | [x]    | shared-086, shared-088     |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen -->

### Layout & Struktur

- [x] Idle-Screen zeigt von oben nach unten: Headline → Atemkreis → flache Settings-Liste → Beginnen-Button. Keine weiteren Sektionen. (iOS)
- [x] Die Sub-Headline "Passe den Timer an" zwischen Atemkreis und Settings entfaellt komplett. (iOS)
- [x] Die Settings sind eine flache Liste mit genau 4 Zeilen — kein Karten-Grid mehr, keine Hintergrundflaechen pro Zeile, keine Icons. (iOS)
- [x] Reihenfolge der Zeilen (zeitlich: vor / waehrend / dauerhaft): Vorbereitung → Gong → Intervall → Hintergrund. (iOS)
- [x] Jede Zeile zeigt links das Label, rechts den aktuellen Wert mit dezentem Chevron als Affordance. Tap auf die gesamte Zeile oeffnet den jeweiligen bestehenden Picker (Detail-View / Sheet) — die Picker selbst aendern sich nicht. (iOS)
- [x] Zwischen den Zeilen gibt es eine durchgehende, dezente Trennlinie. Asymmetrische Variante: Top-Trenner als oberer Abschluss, kein sichtbarer Abschluss-Strich nach unten — die Liste leitet visuell zum Beginnen-Button hinueber. (iOS)

### Atemkreis

- [x] Die +/- Buttons radial unten am Atemkreis (aus shared-086) entfallen komplett. Der Atemkreis bleibt visuell mittig im Picker-Bereich. (iOS)
- [x] Die Drag-Geste auf dem Ring bleibt unveraendert (atan2-basiert, Clamping wie in shared-086). (iOS)
- [x] Die VoiceOver/TalkBack-Slider-Accessibility am Ring (adjustable, increment/decrement) aus shared-086 bleibt erhalten und ist die alleinige nicht-gestische Eingabe. (iOS)
- [x] Reduced Motion am Atemkreis bleibt unveraendert (statisch sichtbarer Halo, kein Puls). (iOS)

### Inaktiv-Zustand

- [x] Wenn ein Setting im Daten-Sinne inaktiv ist (Vorbereitung "Aus", Intervall "Aus", Hintergrund "Stille"), wirkt die gesamte zugehoerige Zeile optisch zurueckgenommen — Label, Wert und Chevron sind gleichermassen gedaempft (Opazitaet 0.45). (iOS)
- [x] Der Uebergang aktiv → inaktiv und zurueck ist sanft (`.easeInOut(duration: 0.2)`-Opazitaets-Transition). (iOS)
- [x] Inaktive Zeilen sind weiterhin tap-bar — der Picker erlaubt das Wieder-Aktivieren. (iOS)
- [x] Der Wert "Gong" hat keinen Inaktiv-Zustand (Gong ist immer an); seine Zeile bleibt durchgehend in der aktiven Optik. (iOS)

### Responsive Vertikale

- [x] Auf iPhone SE (375 x 667) sind Headline, Atemkreis, alle 4 Settings-Zeilen und der Beginnen-Button gleichzeitig sichtbar — kein Scrollen noetig. (iOS, am Simulator verifiziert)
- [x] Auf iPhone 16 Plus (430 x 932) verteilen sich die Sektionen aesthetisch atmend — Atemkreis und Liste als getrennte Bloecke, Beginnen-Button optisch der Liste zugehoerig. (iOS, am Simulator verifiziert)
- [x] Spacings zwischen Headline, Atemkreis, Liste und Beginnen-Button skalieren mit der Geraete-Hoehe (~700 px-Breakpoint): kompakter auf SE, atmender auf Pro Max. (iOS)
- [x] Listenzeilen-Padding (vertikal) und Schriftgroesse skalieren analog: kompakter auf SE (40 px Zeilenhoehe, 15 pt Label), grosszuegiger auf grossen Geraeten (48 px Zeilenhoehe, 17 pt Label). (iOS)

### Theming & Accessibility

- [x] Alle Farben werden ausschliesslich aus dem semantischen Theme-System bezogen — keine direkten Hex-Werte. (iOS)
- [x] Neue semantische Rolle `settingsValueAccent` fuer den akzentuierten Wert-Text eingefuehrt (= `interactive`, computed property — wirkt automatisch in allen drei Themes × Light/Dark). (iOS)
- [x] Trennlinien-Farbe ueber neue Rolle `settingsDivider` (= `controlTrack.opacity(0.30)`) bezogen — nicht aus einer Text-Rolle. (iOS)
- [x] Der Inaktiv-Zustand wird auf Zeilen-Ebene per `.opacity(0.45)` visualisiert (Label + Wert + Chevron gleichermassen), nicht durch Umfaerben einzelner Elemente. `isOff`-Datenfluss bleibt das Daten-Signal. (iOS)
- [x] Theme-Wechsel und Light/Dark-Wechsel funktionieren ohne Regression — alle neuen Tokens sind computed properties auf `ThemeColors`, nehmen automatisch an SwiftUIs Observation-System teil. (iOS)
- [x] WCAG-Kontrast bleibt erfuellt — `settingsValueAccent` = `interactive` ist bereits via WCAGContrastTests gegen Background gesichert; inaktive Zeilen daempfen bewusst auf 0.45 (klar als "ausgeschaltet" lesbar, nicht primaerer Lesepfad). (iOS)
- [x] Jede Listenzeile ist als Button mit sprechendem Accessibility-Label erreichbar ("Vorbereitung, 15s, doppelt tippen zum Ändern" — Format-String `accessibility.idleSettings.row`, DE+EN). (iOS)
- [x] Inaktive Zeilen sind fuer Screen Reader weiterhin als tap-bar ausgewiesen — der Inaktiv-Zustand ist Teil des Werts ("Aus", "Stille"), kein Disabled-Flag. (iOS)

### Konsistenz

- [x] Beginnen-Button bleibt der bestehende `.warmPrimaryButton()` — kein neuer Stil, kein copper-Pill-Glow aus dem Handoff. (iOS)
- [x] Headline "Wie viel Zeit schenkst du dir?" bleibt unveraendert in Text, Position und Typo-Rolle. (iOS)
- [x] Lokalisierung DE + EN: bestehende Setting-Labels weiterverwendet, "timer.idle.sectionTitle" entfernt, neuer Format-String `accessibility.idleSettings.row` hinzugefuegt. (iOS)
- [x] Visuell konsistent zwischen iOS und Android — gleiche Reihenfolge, gleiche Wert-Akzentuierung, gleiche Inaktiv-Optik, gleiche responsive Logik.

### Tests

- [x] UI-Tests pruefen die vier Listenzeilen via `timer.row.preparation/gong/interval/background` (`LibraryFlowUITests.testSettingRowsFlow`); Layout-Verifikation erfolgt zusaetzlich am Simulator (SE 375x667 + Plus 430x932). (iOS)
- [x] Test, dass die Listen-Reihenfolge Vorbereitung → Gong → Intervall → Hintergrund stabil ist (`testSettingRowsFlow` iteriert in dieser Reihenfolge). (iOS)
- [x] Test fuer Hintergrund "Stille" als inaktiv: `TimerViewModelPraxisTests.testBackgroundCard_whenSilent_showsSilenceAndIsOff` + Gegentest `testBackgroundCard_whenSoundscapeSelected_isNotOff`. (iOS)
- [x] Bestehende Tests fuer das Karten-Grid (aus shared-083) auf die neue Listenkomponente umgestellt — `timer.card.*`-Identifier durch `timer.row.*` ersetzt; `SettingCard`/`SettingCardsGrid`-Komponenten geloescht. (iOS)
- [x] Tests aus shared-086 fuer die +/- Buttons am Ring werden geloescht. Die Drag- und Slider-Accessibility-Tests am Ring bleiben erhalten. (iOS)

### Dokumentation

- [x] CHANGELOG.md aktualisiert (user-sichtbare Aenderung). (iOS)
- [x] `dev-docs/reference/color-system.md` aktualisiert: `settingsDivider` und `settingsValueAccent` ergaenzt; `settingCardBackground`, `settingCardBorder`, `dialButtonBackground`, `dialButtonBorder` entfernt. (iOS)
- [x] In shared-086 die Hinweise zu "Sub-Headline" und "+/- Buttons" als von shared-089 ueberschrieben markiert. (iOS)

---

## Manueller Test

1. Frische App-Installation. Timer-Tab oeffnen.
2. Erwartung: Headline "Wie viel Zeit schenkst du dir?" oben, Atemkreis darunter (ohne radiale +/- Buttons), darunter eine flache Liste mit den vier Zeilen Vorbereitung / Gong / Intervall / Hintergrund (in dieser Reihenfolge), darunter der Beginnen-Button.
3. Im Ring ziehen — Wert aendert sich kontinuierlich. Es gibt keine +/- Buttons mehr.
4. Auf eine Listenzeile tippen — der jeweilige Picker oeffnet sich (gleicher Picker wie zuvor).
5. Vorbereitung auf "Aus" stellen, zurueck zum Idle-Screen: die Vorbereitungs-Zeile ist sichtbar gedaempft, Wert zeigt "Aus", Zeile ist weiterhin tap-bar.
6. Hintergrund auf "Stille" stellen: Hintergrund-Zeile gedaempft, Wert "Stille".
7. Wieder einen Hintergrund-Sound waehlen: Zeile uebergeht weich (~200 ms) zurueck in die aktive Optik.
8. Auf iPhone SE / kleinem Android-Geraet: alles ohne Scrollen sichtbar, Sektionen wirken nicht gequetscht.
9. Auf iPhone 15 Pro Max / grossem Android-Geraet: Sektionen verteilen sich grosszuegig, keine Leer-Inseln, Atemkreis nicht verloren.
10. Theme-Wechsel (warm → sage → dusk) und Light/Dark-Wechsel: Liste, Trennlinien, akzentuierte Werte und Inaktiv-Zeilen aktualisieren sich live.
11. VoiceOver/TalkBack einschalten: Atemkreis ist als adjustable Slider erreichbar (Increment/Decrement aendern den Wert), jede Listenzeile ist ein sprechender Button, der den Picker oeffnet.
12. Reduced Motion: Atemkreis-Halo ist statisch (kein Puls), Inaktiv-Uebergang der Liste ist trotzdem sichtbar oder reduziert (Plattform-Konvention folgen).

Erwartung: Auf iOS und Android identische Komposition und identisches Verhalten.

---

## UX-Konsistenz

| Verhalten                       | iOS                                          | Android                                          |
|---------------------------------|----------------------------------------------|--------------------------------------------------|
| Listenzeile als Button          | SwiftUI-Button mit transparentem Hintergrund | Compose `Modifier.clickable` auf Row             |
| Trennlinie zwischen Zeilen      | `Divider` mit semantischer Theme-Farbe       | `HorizontalDivider` mit semantischer Theme-Farbe |
| Chevron-Affordance              | SF Symbol `chevron.right` in Tertiary-Ton    | Material-Icon `KeyboardArrowRight` in Tertiary-Ton |
| Inaktiv-Uebergang               | `.opacity(...)` mit `animation(.easeInOut)`  | `Modifier.alpha(...)` mit `animateFloatAsState`  |
| Listen-Accessibility            | Button-Trait mit kombiniertem Label          | `Modifier.semantics { role = Button }` + contentDescription |

Beide Plattformen folgen ihrem nativen Pattern. Die resultierende Komposition muss identisch wirken.

---

## Referenz

- Design-Handoff: `handoffs/handoff_timer_idle_polish/` (`README.md`, `preview/`, `screenshots/`) — Variante A "Ruhig"
- Vorgaenger-Tickets: shared-083 (Setting-Karten eingefuehrt), shared-086 (Atemkreis-Picker und Sub-Headline eingefuehrt), shared-088 (Einstimmung-Feature entfernt)
- iOS aktueller Idle-Screen: `ios/StillMoment/Presentation/Views/Timer/TimerView.swift` (`idleScreen`, `settingCardsGrid`)
- iOS Karten-Komponenten zur Ablösung: `ios/StillMoment/Presentation/Views/Timer/Components/` (`SettingCard.swift`, `SettingCardsGrid.swift`)
- iOS bestehende Picker (bleiben unveraendert): `PreparationTimeSelectionView.swift`, `GongSelectionView.swift`, `IntervalGongsEditorView.swift`, `BackgroundSoundSelectionView.swift`
- Android aktueller Idle-Screen: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/TimerScreen.kt`

---

## Hinweise

**Verhaeltnis zu shared-086 (bewusst ueberschreibend):**
shared-086 hat die Sub-Headline "Passe den Timer an" und die radialen +/- Buttons am Ring eingefuehrt. shared-089 entfernt beides wieder. Reihenfolge: shared-086 zuerst (ist auf iOS bereits DONE), shared-088 muss zuvor abgeschlossen sein, dann shared-089 als finale Polish-Stufe. Auf Android laeuft shared-086 noch — dort wird shared-089 die +/- Buttons entweder gar nicht erst implementieren oder unmittelbar wieder entfernen, je nach Reihenfolge der Umsetzung. Der Implementierende entscheidet pragmatisch.

**Verhaeltnis zu shared-088 (Hard-Dependency):**
Erst nach Abschluss von shared-088 sind exakt 4 Settings uebrig. shared-089 baut auf diesem Stand auf. Wuerde shared-089 zuerst umgesetzt, muesste eine 5. Zeile mit Einstimmung temporaer in der Liste mitlaufen — das ist nicht gewollt.

**Layout-Richtwerte aus dem Handoff (nur als Orientierung):**
Der Handoff (`handoffs/handoff_timer_idle_polish/README.md`) gibt konkrete pixelwerte fuer Spacing, Schriftgroessen und Listenzeilen-Padding, getrennt nach SE und Pro. Diese Werte sind nicht bindend zu uebernehmen — die Implementierung waehlt im jeweiligen System (SwiftUI, Compose) Spacings, die der bestehenden Stillmoment-Spacing-Skala folgen und das beobachtbare Ziel erfuellen (kompakter auf SE, atmender auf Pro Max). Im Zweifel haben die Projekt-Standards Vorrang vor den Handoff-Pixelwerten.

**Designreferenz aus claude design:**
Die Dateien im Handoff-Ordner (HTML/React/Babel-Prototyp) sind reine Design-Referenz — nicht zu uebernehmen. Naming, Farben, Conventions des Projekts haben Vorrang. Insbesondere: keine CSS-Variablen wie `--sm-accent-text` direkt portieren; stattdessen ueber das semantische Theme-System mappen.

**Bestehende Setting-Karten-Komponenten:**
Die Karten-Komponenten der Idle-View (Karten-Grid plus die einzelne Setting-Karte) werden nicht mehr benoetigt und sollten geloescht werden, wenn keine andere View sie konsumiert. Vor dem Loeschen pruefen, ob das Datenmodell des Karten-Items (Label, Wert, isOff-Flag, Identifier, Tap-Action) als generisches Listen-Item-Modell weiterverwendbar ist oder durch ein eigenes Modell ersetzt wird.

**Inaktiv-Zustand und `isOff`:**
Das bestehende `isOff`-Flag bleibt das Daten-Signal fuer "Setting ist im Aus-Zustand" (z.B. Vorbereitung Aus). Bisher wurde es nur durch Wert-Color-Wechsel visualisiert. Mit shared-089 wird es zusaetzlich auf Zeilen-Ebene als Opazitaets-Daempfung visualisiert — das Datenmodell aendert sich nicht, nur die Bindung zur UI.

**Plattform-Reihenfolge:**
Sequenziell: iOS zuerst, dann Android mit der iOS-Implementierung als Referenz. Da shared-086 auf Android noch nicht umgesetzt ist, kann shared-089 dort in einem Zug mitgenommen werden (Atemkreis-Picker direkt ohne +/- Buttons und ohne Sub-Headline implementieren).

**Nicht im Scope:**
- Re-Design der einzelnen Picker (Detail-Sheets / Detail-Screens fuer Vorbereitung, Gong, Intervall, Hintergrund)
- App-weiter Primary-Button-Refactor
- Aenderungen am Atemkreis selbst ausser dem Entfernen der +/- Buttons
- Neue Settings einfuehren oder die Sitzungs-Engine anfassen

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
