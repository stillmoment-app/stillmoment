# Ticket ios-052: Bibliothek — letzte Zeile verschwindet im unteren Verlauf

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Komplexitaet**: klein — zwei Zahlen und ein fehlender Bodenabstand; die Android-Seite ist bereits korrekt und dient als Vorlage
**Abhaengigkeiten**: shared-094 (Theme-Refinement Kerzenschein 2.0, dort entstand der Verlauf)
**Phase**: 4-Polish

---

## Was

Der weiche Verlauf am unteren Rand der Bibliothek wird auf eine feste Zone von 140 pt begrenzt,
statt wie bisher 18 % der gesamten Listenhoehe einzunehmen. Zusaetzlich bekommen die
Meditationsliste und die Trefferliste der Suche 80 pt Bodenabstand, damit der letzte Eintrag
ueber den Verlauf und die schwebende Tab-Leiste hinausgeschoben werden kann.

Die Gradient-Stops (0.0 / 0.82 / 1.0) bleiben unveraendert — nur ihr Bezugsrahmen wechselt von
"gesamte Listenhoehe" auf die feste Zone. Damit entspricht iOS exakt dem, was Android in
`BottomFadeMask.kt` bereits tut.

## Warum

Die Stop-Positionen eines `LinearGradient` sind Anteile der Hoehe der maskierten View. Die Maske
liegt auf dem gesamten Scroll-Container, der auf einem grossen iPhone rund 700 pt hoch ist — aus
18 % wurden so etwa 120 pt Uebergangszone, mehr als eine ganze Listenzeile. Zusammen mit dem
fehlenden Bodenabstand war die letzte Meditation am Listenende doppelt benachteiligt: Sie lag
vollstaendig im Verlauf und liess sich auch durch Scrollen nicht daraus befreien, weil die Liste
direkt an der Bildschirmkante endete. Titel und Dauer waren dort nicht mehr sicher zu lesen.

Android rechnet dieselben Stops auf eine feste Zone von 140 dp; die tatsaechliche Uebergangszone
ist dort nur rund 25 dp, und die Listen tragen `contentPadding(bottom = 80.dp)`. Der Kommentar in
der Android-Datei verweist auf die iOS-Vorlage — auf iOS war diese Vorlage nie angekommen. Beide
Plattformen sollen sich identisch verhalten.

---

## Akzeptanzkriterien

### Verlauf

- [x] Der Verlauf am unteren Rand der Bibliothek ist auf eine feste Zone begrenzt und waechst nicht
      mehr mit der Bildschirmgroesse
- [x] Die Zone entspricht dem Android-Wert (140 pt), die Stops bleiben 0.0 / 0.82 / 1.0 — die
      sichtbare Uebergangszone betraegt damit rund 25 pt statt rund 120 pt
- [x] Der Uebergang bleibt weich; es entsteht keine harte Kante zwischen Inhalt und Hintergrund

### Bodenabstand

- [x] Die Meditationsliste hat 80 pt Bodenabstand
- [x] Die Trefferliste der Suche hat denselben Bodenabstand
- [x] Am Ende der Liste steht der letzte Eintrag vollstaendig sichtbar ueber der Tab-Leiste — weder
      vom Verlauf ausgewaschen noch von der Leiste verdeckt
- [x] Der Bodenabstand sitzt an der jeweiligen Liste, nicht am umschliessenden Container: sonst
      verschieben sich die Bounds, an denen die Maske haengt

### Keine Regression

- [x] `make check` laeuft ohne Violations durch
- [x] Die Unit-Tests bleiben gruen

---

## Nicht Teil dieses Tickets

- **Android.** Dort sind beide Werte bereits korrekt; es gibt nichts zu tun.
- **Der Timer-Tab.** Auf iOS liegt der Verlauf ausschliesslich auf der Bibliothek. Auf Android
  traegt `TimerScreen.kt` ihn zusaetzlich — dort aber mit der korrekten festen Zone.

---

## Hinweise zur Umsetzung

Getestet wurde nicht mit einem Unit-Test: Der Fehler ist ein reines Layout-Verhalten in einem
SwiftUI-ViewModifier, und ein Test auf die Konstante wuerde diese nur gegen sich selbst pruefen.
Die Absicherung lief ueber `make check`, die bestehende Unit-Test-Suite (Regression) und eine
visuelle Pruefung am Simulator.

Fuer die visuelle Pruefung muss ein echter Scroll-Zustand erzwungen werden — die Fixture-Bibliothek
des Screenshot-Schemas ist bei normaler Schriftgroesse zu kurz zum Scrollen. Ueber
`simctl ui <device> content_size accessibility-extra-extra-extra-large` laesst sich das
zuverlaessig herstellen (danach auf `large` zuruecksetzen).
