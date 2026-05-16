# Ticket shared-096: Player-Refinement Kerzenschein 2.0

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Mittel — Player-View bekommt KS-2.0-Background-Gradient, der atmende Glow wird komplett entfernt (auch der Reduced-Motion-Pfad), Ring uebernimmt die KS-2.0-Norm aus Timer-Idle (1px Track + 1.5px Arc mit wandernder Perle), Pre-Roll zeigt keinen Sitzungs-Arc mehr. Risiko: Player-Ring darf nicht versehentlich an die geteilte Atemkreis-Komponente angefasst werden, die noch fuer Timer-Idle genutzt wird.
**Phase**: 4-Polish
**Plan (iOS)**: [Implementierungsplan](../plans/shared-096-ios.md)

---

## Was

Der Player-Screen (Guided Meditation) wird auf Kerzenschein 2.0 angepasst: warmer Linear-Gradient als Hintergrund, keine Atem-Animation mehr, Ring-Vokabular wie im Timer-Idle (warme Akzent-Linie + Restzeit-Bogen mit Perle), und im Pre-Roll trägt allein die Countdown-Zahl die Information.

## Warum

Der Player ist visuell aktuell noch im alten Mahagoni-Radial-Look mit atmender Glow-Scheibe — das wirkt im KS-2.0-Kontext zu unruhig und semantisch widerspruechlich (Atem-Animation und Restzeit-Bogen konkurrieren beide um „Sitzungsfortschritt"). Mit dem Refinement schließt sich der Player ans Ring-Vokabular der App an und beruhigt sich auf das, was zum Standard-Use-Case (Handy weglegen) passt: nichts bewegt sich außer dem langsamen Wandern der Perle entlang des Restzeit-Bogens.

Referenz: `handoffs/claude_code_handoff_player_ks2/README.md` (High-Fidelity-Spec mit Hex-Werten, Opacities, Stroke-Widths).

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-094    |
| Android   | [ ]    | shared-094 (Android) |

---

## Akzeptanzkriterien

<!-- Validiert an Pre-Roll-, Haupt- und Pause-State in Light + Dark Mode -->

### Hintergrund

- [ ] Player-Hintergrund nutzt denselben vertikalen Linear-Gradient wie der Rest der KS-2.0-App (oben backgroundPrimary, Mitte backgroundSecondary, unten accentBackground) — kein eigenes Player-Mapping
- [ ] Im Dark Mode wandert die warme Mahagoni-Aufhellung ins untere Drittel; die Ring-Mitte bleibt ruhig
- [ ] Im Light Mode wandert der Apricot-Stop ins untere Drittel; Vollmond-Helligkeit bleibt im oberen Bereich

### Ring + Restzeit-Bogen

- [ ] Ring-Track ist eine warme leise Akzent-Linie (1 px), keine kalte neutrale Linie wie bisher
- [ ] Restzeit-Bogen ist 1.5 px breit, in derselben Akzent-Farbe, mit abgerundeten Enden
- [ ] An der Vorderkante des Restzeit-Bogens sitzt eine kleine Akzent-Perle mit weichem Glow — identisches Vokabular wie im Timer-Idle
- [ ] Geometrie unveraendert: Ring sitzt zentriert, Start bei 12 Uhr, Bogen waechst im Uhrzeigersinn

### Atem-Glow entfernt, statische Center-Disc

- [ ] Es gibt keine atmende Glow-Animation mehr — weder im Standard- noch im Reduced-Motion-Pfad. Während einer laufenden Sitzung bewegt sich auf dem Bildschirm nichts außer der Perle, die einmal pro Sekunde (oder seltener) ihre Position aktualisiert
- [ ] Hinter dem Pause-Button liegt eine statische, sehr dezente Glühscheibe als reiner visueller Anker (kein Skalieren, kein Pulsieren, kein Opazitäts-Wechsel)
- [ ] Im Dark Mode ist die Glühscheibe leicht waermer und sichtbarer; im Light Mode dezenter

### Pre-Roll-Phase

- [ ] Während des Pre-Rolls ist im Ring **nur** die Track-Linie sichtbar — kein Restzeit-Bogen, keine Perle
- [ ] Die Countdown-Zahl traegt allein die Information „wie lange noch bis Start"
- [ ] Der „Gleich geht's los"-Hint sitzt wie bisher unterhalb des Rings
- [ ] Beim Übergang Pre-Roll → Hauptphase blenden Countdown + Hint aus, Restzeit-Bogen + Perle + Pause-Button + Restzeit-Label blenden ein (Cross-Fade ca. 400 ms — Verhalten wie vorher)

### Pause-State

- [ ] Bei Pause friert die Perle an ihrer aktuellen Position ein (Bogen waechst nicht weiter)
- [ ] Der Pause-Glyph wechselt zum Play-Glyph (Cross-Fade ca. 200 ms — Verhalten wie vorher)
- [ ] Restzeit-Label zeigt zusaetzlich ein „Pausiert"-Prefix vor der Restzeit, damit der Pause-Zustand auch ohne Glyph-Blick erkennbar ist
- [ ] Das „Pausiert"-Prefix verschwindet beim Resume und die Restzeit-Anzeige zeigt wieder das Standard-Format
- [ ] Tab-Bar bleibt waehrend Pause verborgen (Zen-Mode aktiv) — der Player ist auch im Pause-Zustand die aktive Flaeche, der naechste Schritt soll Resume oder Schliessen sein, kein Tab-Wechsel

### Light + Dark Mode

- [ ] Pause-Button-Glas ist im Light Mode hell-getoent, im Dark Mode dunkel-getoent (Hue-Anpassung des Glas-Hintergrunds — nicht versehentlich Dark-Werte im Light-Modus stehen lassen)
- [ ] Track-Linie, Restzeit-Bogen, Perle und Glyph sind in beiden Modi gut sichtbar
- [ ] Center-Disc-Opacity ist in beiden Modi so gewählt, dass sie nicht als „Lichtblitz" auffällt, sondern als ruhiger Anker wirkt

### Nicht-Aenderungen (bewusst draussen)

- [ ] Geste-Set unveraendert: nur Pause + Schliessen, kein Slider, kein Skip, kein Restart
- [ ] Auto-Start beim Oeffnen unveraendert
- [ ] Lockscreen-Spiegelung (Pause/Play von aussen) unveraendert
- [ ] Pre-Roll-Dauer-Konfiguration unveraendert
- [ ] Atemkreis-Komponente fuer Timer-Idle bleibt unangetastet (Player bekommt seine eigene Ring-Komponente)

### Tests

- [ ] Snapshot- oder UI-Tests fuer Pre-Roll, Hauptphase und Pause-State in Light + Dark Mode (4 × 2 = bis zu 8 Snapshots)
- [ ] Lokalisiert (DE + EN) — neuer „Pausiert"-Prefix-String

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare visuelle Aenderung)

---

## Manueller Test

1. Eine Guided Meditation mit Pre-Roll (z. B. 10 s) starten
2. Pre-Roll beobachten: nur Track-Linie sichtbar, Countdown zaehlt
3. Übergang in Hauptphase beobachten: Bogen + Perle + Pause-Button blenden ein
4. Sitzung 30–60 s laufen lassen: nichts bewegt sich außer der Perle, die langsam wandert
5. Pause tippen: Glyph wechselt, Perle friert, Restzeit-Label zeigt „Pausiert"-Prefix
6. Resume tippen: Glyph wechselt zurueck, Perle wandert weiter, Prefix verschwindet
7. App in den Light Mode wechseln und die Schritte 1–6 wiederholen
8. Erwartung: Identisches Verhalten auf iOS und Android, nur Farben unterscheiden sich zwischen Light und Dark

---

## Referenz

- Handoff: `handoffs/claude_code_handoff_player_ks2/README.md` (High-Fidelity-Spec)
- Theme-Refinement-Vorgaenger: shared-094 (Kerzenschein 2.0 Tokens)
- Ring-Vokabular: shared-095 / Timer-Idle (gleiche Stroke-Werte und Perle)
- Original-Player-Spec: `handoffs/design_handoff_player/README.md` (gilt fuer alles was sich nicht aendert)

---

## Hinweise

- **Player bekommt seine eigene Ring-Komponente.** Die geteilte Atemkreis-Komponente wird vom Timer-Idle weiter genutzt und in diesem Ticket nicht angefasst — eine spaetere Migration des Timer-Idle ist Sache eines Folge-Tickets.
- **Reduced-Motion-Pfad faellt fuer den Player komplett weg**, weil sich ohne Atem-Animation nichts mehr bewegt, das man abschalten müsste. Andere Reduced-Motion-Pfade in der App bleiben unberuehrt.
- **Center-Disc ist ein kosmetischer Anker**, kein semantisches Element — der Pause-Button trägt sich auch ohne. Standardspur ist „drin", aber kein Test-Showstopper falls sie spaeter rausfaellt.
- **Light-Variante ist erstmals spezifiziert** (vorher war der Player Dark-only). Beide Modi nutzen dieselbe Geometrie + Animation-Profil; nur die Tokens flippen.
