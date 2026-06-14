# Ticket shared-115: Gong-Auswahl "Start & Ende" Redesign

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Komplexitaet**: Reines Presentation-Layer-Uplift — Domain/Persistenz/AudioService bleiben unangetastet. Risiken liegen im Theme-korrekten Mapping (kein hardcoded Akzent), der bedeutungstragenden Mini-Wellenform (statische Hüllkurve je Klang) und der Cross-Platform-Konsistenz der neuen visuellen Elemente.
**Phase**: 4-Polish

---

## Was

Der Bildschirm zur Auswahl des Start-/End-Gongs einer Timer-Meditation ("Start & Ende") wird visuell überarbeitet: von der flachen Liste zu einem Karten-Layout mit plastischem Vorhör-Button auf der Auswahl, charaktertragenden Mini-Wellenformen je Klang und einer minimalistischen Lautstärke-Karte.

## Warum

Der Screen ist funktional vollständig, aber visuell die schwächste Stelle im Timer-Flow. Das Redesign hebt ihn auf das "Kerzenschein 2.0"-Niveau der übrigen App (Player, Danke-Screen) und macht den Klang-Charakter über die Wellenform vorab erfahrbar — passend zur ruhigen, hochwertigen Anmutung der App.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Geltungsbereich (unverändert)

Das funktionale Modell bleibt wie heute — **nicht** neu zu bauen:
- Ein gemeinsamer Klang für Start **und** Ende, eine gemeinsame Lautstärke.
- Lautstärke-Bereich entfällt, wenn "Vibration" gewählt ist.
- Vorhören beim Antippen, in der aktuell eingestellten Lautstärke.
- "Vibration" nur auf Phones (nicht auf Tablets).
- Klänge & Reihenfolge: Tempelglocke (Default), Klassisch, Tiefe Resonanz, Klarer Anschlag, Vibration.

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Die Klangliste erscheint als abgesetzte Karte mit Eyebrow-Label "KLANG" darüber.
- [x] Jede Zeile zeigt von links: Vorhör-Button, Klangname, Mini-Wellenform; die ausgewählte Zeile zusätzlich ein Häkchen und einen abgesetzten Hintergrund.
- [x] Der Vorhör-Button der **ausgewählten** Zeile ist die plastische Variante (Verlauf + Glanz + getönter Schatten); die übrigen Zeilen zeigen eine flache Variante (Umrandung, Icon in Akzentfarbe).
- [x] Die Mini-Wellenform je Klang ist charaktertragend: feste Hüllkurve (Anschlag links, Ausklang rechts), die Tiefe/Fülle und Nachhall des Klangs abbildet — identische Hüllkurven-Werte auf beiden Plattformen.
- [x] Beim Vorhören läuft ein dezenter, weich expandierender Ring (~1,5 s); bei reduzierter Bewegung (Reduce Motion) ist die Animation deaktiviert.
- [x] "Vibration": Vorhör-Button zeigt ein Haptik-Icon statt Play, statt Wellenform drei Punkte; Antippen löst die Vibration aus; die Lautstärke-Karte ist ausgeblendet und ein erklärender Helper-Text erscheint.
- [x] Die Lautstärke-Karte ist eine abgesetzte Karte mit Eyebrow-Label "LAUTSTÄRKE": kleines Lautsprecher-Icon links, Slider, großes Lautsprecher-Icon rechts — ohne Prozentwert/Caption.
- [x] Klangnamen verwenden das Projekt-Typografie-System (Typografie 2.1, Body/Geist) — keine Serif-Sonderschrift.
- [x] Alle Farben über semantische Theme-Rollen; der Screen sieht in allen Themes und in Light/Dark korrekt aus (kein hardcoded Akzent).
- [x] Klang-Beschreibungstexte sind standardmäßig nicht sichtbar.
- [x] Lokalisiert (DE + EN), inkl. Helper-Text und Accessibility-Labels.
- [x] Visuell konsistent zwischen iOS und Android.

### Tests
- [x] Unit Tests iOS (sofern testbare Logik, z.B. Sichtbarkeit Lautstärke-Karte / Wellenform-Mapping)
- [x] Unit Tests Android

### Dokumentation
- [x] CHANGELOG.md

---

## Manueller Test

1. Timer-Tab → Konfiguration → "Start & Ende" öffnen.
2. Verschiedene Klänge antippen: Auswahl wechselt, Klang spielt vor, Wellenform/Häkchen aktualisieren sich, Ring-Animation läuft.
3. Lautstärke verändern, dann erneut vorhören: lauter/leiser hörbar.
4. "Vibration" wählen: Lautstärke-Karte verschwindet, Helper-Text erscheint, Gerät vibriert beim Antippen.
5. Theme und Light/Dark wechseln: Farben/Kontraste überall stimmig.
6. Reduce Motion aktivieren: Ring-Animation läuft nicht mehr.
7. Erwartung: identisches Verhalten und Erscheinungsbild auf iOS und Android.

---

## Referenz

- Design-Handoff (verbindlich für Layout, Abstände, Radien, Interaktion): `handoffs/design_handoff_gong_auswahl/README.md` + Screenshots
- WAVE-Hüllkurven-Werte je Klang: `handoffs/design_handoff_gong_auswahl/design/auswahl-app.jsx` (Map `WAVE`)
- iOS Screen heute: `ios/StillMoment/Presentation/Views/Timer/GongSelectionView.swift`
- Android Screen heute: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/SelectGongScreen.kt`
- Plastisches Vorhör-Button-Material existiert bereits (semantische Theme-Farben `playGradientTop`/`playGradientBot` + Glanz-Overlay): iOS `ios/StillMoment/Presentation/Views/Shared/PlayButtonCircle.swift`

---

## Hinweise

- **Kein hardcoded `#CC7E5F`.** Der Handoff fixiert den Akzent, aber die App ist theme-reaktiv; Handoff-Werte nur für Layout/Radien/Abstände, Farben über die semantischen Rollen mappen. Der plastische Disc nutzt bereits `playGradientTop`/`playGradientBot`.
- **Schriften = Projektstandard.** Der Handoff schlägt Newsreader für Klangnamen vor; bewusst verworfen, um das 10-Token-System (Typografie 2.1) nicht zu sprengen. Titel weiter über `screenTitleBar`.
- **Beschreibungstexte vorerst aus** — kein UI-Zwang; das `descriptions`-Tweak des Prototyps ist Demo-Werkzeug, nicht produktiv.
- iOS `UISlider`/UIKit-Bridges reagieren nicht live auf Theme-Wechsel → `.id(theme)`-Muster beachten (siehe bestehende `VolumeSliderRow`).
- Vibration auf dem Lock Screen ist hier irrelevant (Auswahl-Screen läuft im Vordergrund) — die Preview-Vibration darf die Standard-Foreground-Haptik nutzen.
- Eine spätere Vereinheitlichung der drei duplizierten plastischen Play-Buttons (PlayButtonCircle / WaveformTransportButton / TrimTransportRow) ist **kein** Teil dieses Tickets.
