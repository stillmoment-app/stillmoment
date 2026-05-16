# Ticket shared-095: Running-Timer-Visualisierung Mondphase

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Hoch — praezise Animation mit gemischtem Easing (linear fuer Schatten, smoothstep fuer Halo), Erweiterung der Theme-Tokens um Mond-spezifische Slots, Reduce-Motion-Verhalten, Snapshot-Tests in Light + Dark.
**Phase**: 4-Polish
**Plan (iOS)**: [Implementierungsplan](../plans/shared-095-ios.md)

---

## Was

Die Visualisierung im laufenden Timer wechselt vom aktuellen Atemkreis auf eine Mondphasen-Animation: Ueber die Sitzungsdauer wandert der Schatten vom Mond — Neumond am Start, Vollmond am Ende.

## Warum

Die Mondphase erzaehlt Sitzungsdauer durch ein ruhiges Naturbild. Keine pulsierende Bewegung, kein Countdown-Charakter — der Schattenrand wandert ueber die ganze Sitzung hinweg fast unmerklich. Passt zur Kerzenschein-2.0-Stimmung und loest die aktuelle Atemkreis-Visualisierung ab, die fuer die laufende Sitzung visuell zu aktiv ist.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-094    |
| Android   | [ ]    | iOS first     |

---

## Akzeptanzkriterien

### Visualisierung

- [ ] Startzustand (Sitzung beginnt): Mond komplett verschattet, kein sichtbarer Schattenrand, Halo nahezu unsichtbar
- [ ] Halbzeit: Halbmond, Schattenkante senkrecht in der Mondmitte, Halo deutlich aber zurueckhaltend
- [ ] Sitzungsende: Voller Mond, keine schwarze Restscheibe im Bildausschnitt, Halo auf Maximum
- [ ] Mond zeigt einen warmen radialen Verlauf (Beleuchtung von oben-links nach unten-rechts), keine Krater oder Flecken
- [ ] Halo waechst sanft beschleunigt (smoothstep), nicht linear — bleibt lange unauffaellig, wird erst spaet warm sichtbar
- [ ] Schatten wandert linear ueber die Sitzungsdauer (kein Easing)
- [ ] Bei pausierter Sitzung friert die Animation auf der aktuellen Position ein

### Light + Dark Mode

- [ ] Light Mode: Vollmond bleibt klar lesbar gegen den hellen Hintergrund; Schatten ist warmes Dunkel, kein Reinschwarz
- [ ] Dark Mode: Schatten verschmilzt visuell mit dem dunklen Hintergrund; Mond-Disc zeigt warmen Cream-zu-Ocker-Verlauf
- [ ] Animation laeuft in beiden Modi mit identischem Timing und Easing

### Layout

- [ ] Mond im unteren Drittel, Zeit-Block (Eyebrow + Zeit + Sub) im oberen Drittel, Close-Button oben rechts — Positionen analog zur aktuellen Running-Timer-View
- [ ] Position und Groesse skalieren proportional auf groesseren Geraeten (iPhone Plus/Max, iPad)

### Accessibility

- [ ] Bei aktiviertem "Reduce Motion" (iOS) aktualisiert sich der Schatten hoechstens einmal pro Sekunde, ruckelt aber nicht
- [ ] VoiceOver liest weiterhin die Zeit-Anzeige; Mond benoetigt kein eigenes Accessibility-Label

### Tests

- [ ] Snapshot-Tests fuer drei Progress-Staende (Start, Halbzeit, Ende) in Light + Dark

### Dokumentation

- [ ] CHANGELOG.md unter "Unreleased"

---

## Manueller Test

1. Timer-Tab oeffnen, beliebige Dauer waehlen, Timer starten
2. Beobachten: Schatten wandert ueber die Dauer hinweg langsam nach links, Halo wird gegen Ende warm sichtbar
3. Am Ende: Voller Mond, kein schwarzer Rest im Bildausschnitt links vom Mond
4. Light/Dark Mode wechseln (iOS Settings → Anzeige & Helligkeit) und Verlauf erneut beobachten
5. Reduce Motion aktivieren (iOS Bedienungshilfen → Bewegung) und pruefen, dass die Animation diskret bleibt
6. Sitzung pausieren: Animation bleibt an der aktuellen Position stehen

---

## Referenz

- Handoff (README + lauffaehige HTML-Preview): `handoffs/claude_code_handoff_running_timer_mondphase/` — enthaelt finale Geometrie, Token-Map (Light + Dark), Easing-Formeln, Layer-Reihenfolge und Akzeptanzbilder fuer Start/Mitte/Ende.
- Bestehende Running-Timer-Visualisierung als Ausgangspunkt: aktuelle Atemkreis-Visualisierung im Timer-View (vgl. shared-090).

---

## Hinweise

- **Voraussetzung shared-094 (Kerzenschein 2.0):** Die Mond-spezifischen Farb-Slots (Disc-Verlauf, Schatten, Halo, Ring) kommen *zusaetzlich* zu den Kerzenschein-2.0-Tokens. shared-094 muss vorher im iOS-Theme verankert sein.
- **Bildausschnitt am Ende vollstaendig leer:** Der Schatten wandert noch ein Stueck weiter als der Mondrand, damit am Sitzungsende kein dunkler Rest links neben dem Mond zurueckbleibt. Spec dazu im Handoff.
- **Keine `transition`-Animation auf der Schattenposition** — der Wert wird in jedem Frame frisch aus dem Sitzungs-Progress berechnet, sonst hinkt der Schatten hinter der Zeitanzeige her.
- **iOS-First:** Android-Umsetzung erfolgt nach erfolgreichem iOS-Roll-out; Ticket bleibt geoeffnet bis beide Plattformen umgesetzt sind.
