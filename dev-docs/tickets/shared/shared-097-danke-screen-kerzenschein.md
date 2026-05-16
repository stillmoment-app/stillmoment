# Ticket shared-097: Danke-Screen Refinement Kerzenschein 2.0

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Mittel — bestehende `MeditationCompletionView` wird visuell neu aufgesetzt: pulsierender Glow-Kreis weicht einem statischen Doppel-Lotus-Mandala, Headline-Text wird ersetzt, der Gradient-CTA-Button wird zur Glas-Pille im KS-2.0-Vokabular (gleiche Behandlung wie der Pause-Button im Player aus shared-096). Da `MeditationCompletionView` die einzige zentrale Abschluss-View ist, profitieren Timer-Ende, Guided-Meditation-Ende und der Pending-Termination-Recovery-Overlay aus einem einzigen Umbau.
**Phase**: 4-Polish
**Plan (iOS)**: [Implementierungsplan](../plans/shared-097-ios.md)

---

## Was

Der Danke-Screen nach Meditationsende wird auf Kerzenschein 2.0 angepasst: das zentrale Symbol wechselt vom Glow-Kreis zu einem statischen Doppel-Lotus-Mandala (16 Petals), die Headline lautet aktiver „Danke, dass du dir diese Zeit geschenkt hast.", und der Abschluss-Button wird zur Glas-Pille im selben Vokabular wie der Pause-Button im Player.

## Warum

Der bisherige Danke-Screen mit pulsierendem Glow-Kreis und „Danke, dass du dir diesen Moment genommen hast." fuehrt das Atem-Vokabular aus dem alten Player fort. Mit shared-096 atmet der Player nicht mehr — der Danke-Screen soll sich vom Player abheben (Sitzung ist vorbei, der Screen ist ruhig), nicht ihn fortsetzen. Das Mandala als statisches Symbol traegt das visuelle Gewicht ohne Bewegung; die Glas-Pille bringt den Screen ins gemeinsame KS-2.0-Vokabular.

Referenz: `handoffs/claude_code_handoff_danke_ks2/README.md` (High-Fidelity-Spec mit Mandala-Geometrie, Hex-Werten, Stroke-Widths, Opacities).

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-096    |
| Android   | [ ]    | shared-096 (Android) |

---

## Akzeptanzkriterien

<!-- Validiert nach Guided-Meditation-Ende, Timer-Ende und im Pending-Termination-Recovery-Overlay, jeweils in Light + Dark Mode -->

### Mandala statt Glow

- [ ] Anstelle des bisherigen Glow-Kreises sitzt ein Doppel-Lotus-Mandala (16 Petals: 8 aeussere Lang-Petals, 8 innere Kurz-Petals um 22.5° versetzt) als zentrales Symbol
- [ ] Mandala ist statisch — keine Animation, kein Pulsieren, kein Atem-Vokabular
- [ ] Mandala ist 160 × 160 pt gross, in der Bildschirm-Mitte zentriert
- [ ] Petals nur Stroke (kein Fill), Mittelpunkt zeigt einen gefuellten Punkt + dezenten Outline-Ring
- [ ] Akzent-Farbe kommt aus `theme.interactive` (warmer Akzent, flippt zwischen Light und Dark)

### Hintergrund

- [ ] Hintergrund ist der KS-2.0-Linear-Gradient (oben backgroundPrimary, Mitte backgroundSecondary, unten accentBackground) — gleicher Stack wie der Player nach shared-096

### Headline

- [ ] Text lautet „Danke, dass du dir diese Zeit geschenkt hast." (DE) bzw. eine sinngemaesse aktive Formulierung (EN)
- [ ] Text ist horizontal zentriert, schmal genug, dass er natuerlich umbricht
- [ ] Kein Farb-Akzent auf einzelnen Woertern — bewusst schlicht, Mandala traegt das Gewicht
- [ ] Lokalisiert (DE + EN) — der bestehende Key `guided_meditations.player.completion.headline` wird inhaltlich aktualisiert

### Abschluss-Button (Glas-Pille)

- [ ] Button „Fertig" wird zur Glas-Pille im KS-2.0-Vokabular — halbtransparenter Glas-Hintergrund, dezenter Border in der Akzent-Farbe, Akzent-Schrift; identische Behandlung wie der Pause-Button im Player
- [ ] Glas-Hue ist im Dark Mode dunkel-getoent, im Light Mode hell-getoent
- [ ] Button sitzt am unteren Bildschirmrand mit Safe-Area-Abstand; ist **nicht** Teil der vertikal zentrierten Mandala+Text-Gruppe, damit er auf kleineren Devices stabil unten bleibt
- [ ] Bisheriger Gradient-CTA (`.warmPrimaryButton()`) wird auf diesem Screen nicht mehr verwendet

### Verhalten

- [ ] Tap auf „Fertig" dismissed den Abschluss-Screen wie bisher (Standard-Sheet-Dismiss / Reset)
- [ ] Auf dem Screen bewegt sich nichts — keine Eigen-Animation des Mandalas oder der Pille
- [ ] Kein zusaetzliches Schliessen-X top-left — der „Fertig"-Button ist der einzige Dismiss-Pfad

### Geltung an allen drei Aufrufern

- [ ] Nach Ende einer Guided Meditation zeigt der Player den neuen Danke-Screen
- [ ] Nach Ablauf des Stillen-Meditations-Timers zeigt der Timer den neuen Danke-Screen
- [ ] Nach iOS-Termination einer laufenden Sitzung zeigt der Pending-Recovery-Overlay beim naechsten App-Start den neuen Danke-Screen — derselbe visuelle Abschluss, unabhaengig vom Pfad dorthin

### Nicht-Aenderungen (bewusst draussen)

- [ ] Trigger-Logik unveraendert: Wann der Danke-Screen erscheint, bleibt wie bisher
- [ ] Keine Stats, Streaks, Zahlen oder „heute gemeditiert"-Marker auf dem Screen
- [ ] Now-Playing-Verhalten unveraendert — Audio ist beim Erscheinen des Screens bereits gestoppt
- [ ] Kein Cross-Fade-Sondereffekt vom Player aus erforderlich — der Wechsel darf auch hart sein

### Tests

- [ ] Snapshot- oder UI-Tests fuer den Abschluss-Screen in Light + Dark Mode
- [ ] Test fuer die Mandala-Geometrie (16 Petals, 8 innere um 22.5° versetzt) — strukturell, nicht pixelgenau
- [ ] Lokalisiert (DE + EN) — neuer Headline-Text liegt in beiden Sprachen vor

### Dokumentation

- [ ] CHANGELOG.md (user-sichtbare visuelle Aenderung)

---

## Manueller Test

1. Eine kurze Guided Meditation (z. B. 30 s) komplett durchlaufen lassen
2. Erwartung: Abschluss-Screen erscheint mit Mandala in der Mitte, neuem Satz darunter, Glas-Pille „Fertig" am unteren Rand — nichts bewegt sich
3. „Fertig" tippen — Player wird dismissed, Library / Timer wieder sichtbar
4. Einen kurzen Stillen-Meditations-Timer (z. B. 1 min) komplett durchlaufen lassen
5. Erwartung: Identischer Danke-Screen, identisches Verhalten
6. App in den Light Mode wechseln und Schritte 1–5 wiederholen — Akzentfarbe wird heller-warm, Glas-Pille wird hell-getoent
7. Recovery-Pfad: einen Timer starten, die App per Swipe-Up gewaltsam beenden, App neu oeffnen
8. Erwartung: Beim Wiedereintritt erscheint derselbe Danke-Screen — visuell identisch zu Schritten 2 und 5

---

## Referenz

- Handoff: `handoffs/claude_code_handoff_danke_ks2/README.md` (High-Fidelity-Spec mit Mandala-SVG, Hex-Werten, Stroke-Widths)
- Vorgaenger: shared-094 (KS-2.0-Tokens), shared-096 (Player-Refinement, liefert das Glas-Pille-Vokabular)
- iOS: `ios/StillMoment/Presentation/Views/Shared/MeditationCompletionView.swift`, `ios/StillMoment/Presentation/Views/Shared/CompletionGlow.swift`
- Android: aequivalente Composables im `ui/`-Bereich

---

## Hinweise

- **Zentrale Shared-View.** `MeditationCompletionView` (iOS) bzw. die analoge Compose-Komponente (Android) wird einmal umgebaut — alle drei Aufrufer (Timer, Guided Player, Pending-Recovery) bekommen den neuen Look automatisch. Keine Aufspaltung erforderlich.
- **Mandala-Geometrie ist trivial.** Eine kubische Bézier-Petal-Form, 16-fach rotiert. Implementierung als SVG-Asset im Bundle oder direkt via `Canvas`/`Path` (iOS) / `Canvas` (Compose) — beide Wege sind okay.
- **Glas-Pille wiederverwenden.** Falls shared-096 bereits einen wiederverwendbaren Glas-Pille-Style geliefert hat, anwenden statt neu bauen. Falls nicht, das Glas-Vokabular vom Pause-Button uebernehmen.
- **Glow-Komponente kann weg.** `CompletionGlow` ist mit diesem Ticket obsolet und sollte entfernt werden, sofern keine anderen Aufrufer existieren.
- **Close-X bewusst weggelassen.** Der Handoff zeigt ein Schliessen-X top-left. In Still Moment ist der „Fertig"-Button eindeutig — ein zweites Dismiss-Element waere im Pending-Recovery-Pfad sinnlos (kein Player-Header dahinter) und an den anderen Pfaden redundant. „Less is more."
