# Ticket ios-050: Typografie 2.1 — Layout-Anpassungen fuer Dynamic Type AX2+

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Reine Presentation-Layer-Arbeit ohne neue Domain-Logik. Risiko liegt im konsistenten Verhalten ueber alle Hauptscreens hinweg und im sauberen Umgang mit `@Environment(\.dynamicTypeSize)` (Layout-Switch HStack→VStack ab AX-Stufen). Keine neuen Tokens; das Typografie-System (TextStyle.swift) bleibt unveraendert.
**Abhaengigkeiten**: ios-048 (Typografie 2.1 abgeschlossen)
**Phase**: 5-QA

---

## Was

Die in ios-048 (Typografie 2.1) eingefuehrten Tokens skalieren ueber Dynamic Type bis AX5 mit. Ab AX2/AX3 werden die einzelnen Texte aber teils unleserlich oder ueberlaufen ihre Container, weil die **Layouts** sich heute nicht anpassen (Custom HStacks mit `lineLimit(1)` etc.). Dieses Ticket zieht die Layout-Anpassungen nach, die der "Typografie 2.1"-Plan in Sektion "Accessibility" verlangt:

- **List-Rows wechseln zu VStack** ab `dynamicTypeSize >= .accessibility1`
- **Timer-Numerik** (BreathDial, RunningTimerDisplay) **unter den Ring/Mond** verschieben ab `>= .accessibility2`
- **Bottom-Sheets** mit `presentationDetents([.large])` oder dynamischer Hoehe, damit sie nicht von der Tab-Bar ueberdeckt werden
- **lineLimit(nil)**-Audit: nirgends darf primaerer Inhalt truncate-d sein

## Warum

Beim SE-2022-AX3-Smoketest in ios-048 wurden konkrete Truncates und Ueberlauf-Stellen identifiziert:
- Library-Empty-State: "Dein persönlic...", "+ Meditatio...", "Wo finde ich Medit..." truncated bei AX3
- Timer Idle: Headline "Wie viel Zeit schenkst du dir?" ueberlappt Status-Bar; List-Rows (Vorbereitung/Gong/Intervall/Hintergrund) truncaten; Beginnen-Button kollidiert mit Tab-Bar
- Settings-Form skaliert von alleine — dort kein Problem (System-Default)

Die App soll bis AX5 lesbar bleiben (Plan-Section "A11y Scale"). Aktuell ist sie ab AX2 in Custom-Layouts unleserlich. Das ist nicht primaer ein Typografie-Problem — sondern ein Layout-Problem.

---

## Akzeptanzkriterien

### Feature

- [ ] Library-Empty-State: alle Texte sind bei AX3 vollstaendig lesbar (Umbruch statt Truncate). Import-Button bleibt anklickbar, nicht von TabBar verdeckt.
- [ ] Timer Idle: IdleSettingsList-Rows wechseln ab `.accessibility1` von HStack auf VStack (Label oben, Wert darunter). Headline und Beginnen-Button bleiben sichtbar (Safe-Area + Scroll).
- [ ] Timer Running: ab `.accessibility2` wandert die Numerik aus dem Mond/Ring heraus *unter* die Visualisierung; oberes Eyebrow bleibt am Platz.
- [ ] BreathDial (Auswahl-Modal): Numerik-Wert bleibt lesbar bei AX3 (Plan: container-Diameter × 0.32, AX1-Cap).
- [ ] Bottom-Sheets (ContentGuide, GuidedMeditationEditSheet, DownloadOverlay): bei AX3 nicht von der Tab-Bar oder Status-Bar ueberdeckt — `presentationDetents` oder dynamische Hoehe.
- [ ] Smoketest auf SE 2022 (375x667) bei `accessibility-extra-large` (AX3) zeigt kein truncate auf primaerem Inhalt, keine Ueberlappung mit TabBar/StatusBar, alle Aktionen erreichbar.

### Tests

- [ ] Falls vorhanden / sinnvoll: Snapshot-Test der Hauptscreens bei `.accessibility3` (Light+Dark), um Regressionen zu fangen.

### Dokumentation

- [ ] CHANGELOG.md: "Layouts passen sich an Dynamic Type AX2+ an — Texte umbrechen, Numerik wandert unter den Ring."

---

## Manueller Test

1. Simulator-DT auf AX3 setzen: `xcrun simctl ui <UDID> content_size accessibility-extra-large`
2. App starten, Library oeffnen — Texte muessen umbrechen, nicht truncaten
3. Timer-Tab oeffnen — IdleSettingsList-Rows als VStack (Label oben, Wert darunter), Beginnen-Button im sichtbaren Bereich
4. Timer starten — Pre-Roll-Countdown und Running-Display vollstaendig lesbar, Numerik unter dem Mond bei AX3
5. Library → Import-Sheet, ContentGuide oeffnen — Sheet bedeckt nicht die Tab-Bar (oder TabBar bei aktivem Sheet versteckt)
6. Settings-Tab — Form-Layout (System) bleibt unauffaellig

---

## Referenz

- Voriges Ticket: ios-048 (Typografie 2.1 — Tokens + DisplayNumeral)
- Plan-Quelle: `handoffs/Typografie 2.1 - Plan.html` (Sektion "Verhalten unter Accessibility")
- SE-AX3-Smoketest-Screenshots (im Rahmen ios-048 erstellt): `tmp/se-ax3-01-library.png`, `tmp/se-ax3-02-timer-idle.png`, `tmp/se-ax3-03-settings.png`

---

## Hinweise

- `@Environment(\.dynamicTypeSize) private var dt` in den relevanten Views. Verzweigung `if dt >= .accessibility1 { VStack { ... } } else { HStack { ... } }` — keine Magic-`.accessibility3`-Vergleiche.
- `@ScaledMetric` fuer Spacing-Werte die mit DT skalieren sollen (z.B. `padding`).
- Plan-Regel: ".display cappt @ AX1". `DisplayNumeral` setzt das schon um — die View-Komponente muss bei AX2+ das Layout aendern, nicht die Numerik selbst.
- Android: gleicher Pattern (`MaterialTheme.typography` reagiert auf System-Font-Scale, aber Layouts brauchen analoge `WindowSizeClass`-/Density-Switches). Eigenes Ticket falls portiert.
