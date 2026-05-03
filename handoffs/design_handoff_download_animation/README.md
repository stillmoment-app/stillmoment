# Handoff: Download-Animation

## Overview

**Scope**: Wie sieht das Overlay aus, das während des Downloads einer Datei angezeigt wird?

Konkret: Wenn der User eine Meditation per URL importiert (oder per Share-Sheet vom Browser empfängt) und die Datei muss erst noch heruntergeladen werden, zeigen wir ein modales Overlay mit einer ruhigen, atmosphärischen Animation — passend zum meditativen Charakter der App. Ersetzt den iOS-Default-Spinner, der visuell zu generisch ist.

**Plattformen**: iOS (SwiftUI) **und** Android (Compose).

## About the Design Files

`import-flow.jsx` und `styles.css` sind **HTML/React-Designreferenzen**, nicht zum 1:1-Kopieren. Implementierungs-Aufgabe: in nativen UI-Frameworks nachbauen.

Die relevante Komponente in der Designdatei heißt `BreathingLoader` (historischer Name — die finale Variante ist die **Konstellation**, nicht mehr atmende Ringe).

## Fidelity

**High-fidelity.** Final colors, typography, spacing, copy, animation timings.

## Layout

### Backdrop

- Dimming-Overlay über dem darunterliegenden Screen (typischerweise die Library oder das Quellen-Sheet):
  - Background: `rgba(10,6,4,0.55)`
  - Volle Bildschirmfläche (unterhalb der Statusbar — Statusbar bleibt unverändert sichtbar).
  - **Tap auf Backdrop**: keine Aktion (Modal kann nur via „Abbrechen" geschlossen werden).

### Modal-Card (zentriert)

- Maximale Breite: 320pt
- Horizontaler Padding zum Bildschirmrand: 36pt
- Background: `linear-gradient(180deg, #2e1a14 0%, #211210 100%)` (etwas heller als die Library, hebt sich vom Backdrop ab)
- Border: 1px `rgba(235,226,214,0.08)`
- Border-radius: 28
- Padding: `32px 28px 24px`
- Shadow: `0 30px 60px rgba(0,0,0,0.5)`
- Inhalt vertikal gestackt, zentriert

### Inhalt von oben nach unten

1. **Konstellations-Animation** — Container 110×110, margin-bottom 22 (siehe „Animation" unten).

2. **Titel** — Newsreader 18, color `--sm-text` (`#ebe2d6`), margin-bottom 6, zentriert.
   - DE: „Meditation wird geladen…"
   - EN: „Loading meditation…"

3. **Body** — Geist 12, color `--sm-text-2` (`#a89a8c`), line-height 1.5, margin-bottom 22, zentriert.
   - DE: „Einen Moment, wir holen die Aufnahme zu dir."
   - EN: „One moment, we're fetching the recording for you."

4. **Abbrechen-Button** — Ghost-Pill, zentriert.
   - Background: `rgba(235,226,214,0.04)`
   - Border: 1px `rgba(235,226,214,0.08)`
   - Color: `--sm-accent-text` (`#d99a7e`)
   - Geist 14, padding `10px 22px`, border-radius 999
   - DE: „Abbrechen"
   - EN: „Cancel"
   - Aktion: bricht den Download ab, schließt das Modal, User landet wieder auf dem darunterliegenden Screen.

## Animation: Konstellation

**Konzept**: Ein ruhig pulsierender Kupfer-Kern in der Mitte, umkreist von 5 kleinen Lichtpunkten auf zwei Orbitalbahnen. Sehr eigene visuelle Sprache — nicht die übliche Spinner/Ring-Konvention. Passt zum Naming „Still Moment" und zur Idle-Screen-H2-Variante.

### Geometrie

Container: 110×110pt, Punkte werden relativ zum Mittelpunkt platziert.

**Kern (atmend)**:
- Punkt im Zentrum, Durchmesser 8pt
- Background: `--sm-accent-glow` (`#d68a6e`)
- Glow: `box-shadow: 0 0 18px var(--sm-accent-glow)` (oder iOS `.shadow(color: accent, radius: 9)`)

**Orbitale Punkte** (5 insgesamt):

| # | Orbit-Radius | Umlaufzeit | Phasenversatz | Punkt-Größe |
|---|---|---|---|---|
| 1 | 30pt | 6.5s | 0.0s | 5pt |
| 2 | 30pt | 6.5s | 1.3s | 4pt |
| 3 | 42pt | 9.0s | 0.4s | 3.5pt |
| 4 | 42pt | 9.0s | 3.0s | 3pt |
| 5 | 42pt | 9.0s | 5.6s | 3.5pt |

Jeder Punkt:
- Color: `--sm-accent-text` (`#d99a7e`)
- Opacity: 0.7
- Glow: `0 0 6px rgba(217,154,126,0.6)`

### Timings

**Orbital-Bewegung**:
- Inner orbit (r=30): 6.5s pro vollständige Rotation, **linear**, endlos
- Outer orbit (r=42): 9.0s pro Rotation, **linear**, endlos
- Phasenversatz: durch negativen `animation-delay` realisiert (Punkte starten an unterschiedlichen Winkeln)

**Atmender Kern**:
- Zyklus: 4.2s
- Easing: `easeInOut`, autoreverse
- Scale: 0.9 ↔ 1.15
- Opacity: 0.7 ↔ 1.0

### iOS-Implementierung (Skizze)

```swift
struct ConstellationLoader: View {
  @State private var coreScale: CGFloat = 0.9
  let orbits: [(radius: CGFloat, duration: Double, phase: Double, size: CGFloat)] = [
    (30, 6.5, 0.0, 5),
    (30, 6.5, 1.3, 4),
    (42, 9.0, 0.4, 3.5),
    (42, 9.0, 3.0, 3),
    (42, 9.0, 5.6, 3.5),
  ]

  var body: some View {
    ZStack {
      // Atmender Kern
      Circle()
        .fill(Color.accentGlow)
        .frame(width: 8, height: 8)
        .scaleEffect(coreScale)
        .shadow(color: .accentGlow, radius: 9)
        .onAppear {
          withAnimation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true)) {
            coreScale = 1.15
          }
        }

      // Orbitale Punkte
      ForEach(0..<orbits.count, id: \.self) { i in
        OrbitingDot(
          radius: orbits[i].radius,
          duration: orbits[i].duration,
          phase: orbits[i].phase,
          size: orbits[i].size
        )
      }
    }
    .frame(width: 110, height: 110)
  }
}

struct OrbitingDot: View {
  let radius: CGFloat
  let duration: Double
  let phase: Double
  let size: CGFloat
  @State private var angle: Double = 0

  var body: some View {
    Circle()
      .fill(Color.accentText.opacity(0.7))
      .frame(width: size, height: size)
      .shadow(color: Color.accentText.opacity(0.6), radius: 3)
      .offset(x: radius)
      .rotationEffect(.degrees(angle))
      .onAppear {
        // Phase über initialen Winkel realisieren
        angle = (phase / duration) * 360
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
          angle += 360
        }
      }
  }
}
```

### Android-Implementierung (Skizze)

```kotlin
@Composable
fun ConstellationLoader() {
  val orbits = listOf(
    Orbit(30f, 6500, 0f, 5f),
    Orbit(30f, 6500, 1300f, 4f),
    Orbit(42f, 9000, 400f, 3.5f),
    Orbit(42f, 9000, 3000f, 3f),
    Orbit(42f, 9000, 5600f, 3.5f),
  )

  val infinite = rememberInfiniteTransition()
  val coreScale by infinite.animateFloat(
    initialValue = 0.9f, targetValue = 1.15f,
    animationSpec = infiniteRepeatable(
      animation = tween(2100, easing = FastOutSlowInEasing),
      repeatMode = RepeatMode.Reverse
    )
  )

  Canvas(modifier = Modifier.size(110.dp)) {
    val center = Offset(size.width / 2, size.height / 2)
    // Kern
    drawCircle(
      color = AccentGlow,
      radius = 4.dp.toPx() * coreScale,
      center = center
    )
    // (Glow via zweitem, größerem semi-transparentem Circle)

    // Orbitale Punkte: Winkel von außen über separaten infiniteTransition pro Orbit
    orbits.forEach { o ->
      val angle = animatedAngle(o.duration, o.phase)
      val pos = center + Offset(
        cos(angle) * o.radius.dp.toPx(),
        sin(angle) * o.radius.dp.toPx()
      )
      drawCircle(
        color = AccentText.copy(alpha = 0.7f),
        radius = o.size.dp.toPx() / 2,
        center = pos
      )
    }
  }
}
```

(Die `animatedAngle()`-Helper-Funktion mappt Phasenversatz auf einen Startwinkel und animiert dann linear endlos.)

## Interactions & Behavior

- **Trigger**: Wird vom Import-Flow eingeblendet, sobald der Download startet (URL-Import oder Share-Sheet-Empfang von externer URL).
- **Dauer**: Bleibt sichtbar bis Download abgeschlossen oder abgebrochen.
- **Abschluss-Übergang**: Wenn fertig, fade-out 200ms → User landet im „Importieren als…"-Sheet (oder direkt im Save-Formular, je nach Flow).
- **Fehlerfall**: Modal wird ersetzt durch eine Error-Variante (eigenes Ticket — hier nicht im Scope).
- **Abbrechen**: Bricht Download ab, schließt Modal sofort.
- **Keine Fortschrittsanzeige**: Kein Prozent, keine Bytes — bewusst zurückgenommen. Die Aufnahme ist meist klein (<10MB), Wartezeit kurz; eine ruhige Animation passt besser zum App-Charakter als ein Progress-Balken.

## Acceptance Criteria

- [ ] Modal erscheint zentriert über dimm-überlagertem Background.
- [ ] Konstellations-Animation läuft flüssig (60fps), 5 orbitale Punkte + atmender Kern.
- [ ] Phasen und Timings entsprechen der Tabelle oben.
- [ ] Titel und Body lokalisiert (DE + EN).
- [ ] Abbrechen-Button bricht Download ab und schließt Modal.
- [ ] Tap auf Backdrop hat keinen Effekt.
- [ ] Funktioniert in allen 3 Themes (Kupfer/Salbei/Dämmerung), Light + Dark — Akzentfarben passen sich an.
- [ ] Accessibility: Modal ist als Alert/Modal markiert; VoiceOver liest Titel + Body; Abbrechen-Button hat `accessibilityLabel`.
- [ ] Performance: Animation pausiert wenn App im Hintergrund (kein unnötiger CPU-Verbrauch).

### Tests
- [ ] Snapshot-Test: Modal in DE + EN, Light + Dark, alle 3 Themes.
- [ ] Unit-Test: Abbrechen-Aktion ruft Cancel-Callback auf.

## Files in this bundle

- `import-flow.jsx` — Referenz. Komponente: `BreathingLoader` (Zeilen ~500–580). **Final design.**
- `styles.css` — Token-Definition (Farben, Schriften, Radien).

## Notes

- Wenn die Animation auf älteren Geräten ruckelt, ist es OK, die Anzahl der orbitalen Punkte auf 3 zu reduzieren (nur outer orbit). Aber: erst messen, dann optimieren.
- **Nicht** mit Lottie/Rive umsetzen — die Animation ist klein und geometrisch, native Implementierung ist sauberer und kleiner im Bundle.
- Die Konstellation greift visuell die H2-Idle-Screen-Variante auf (Atemkreis-Ruhig) — bewusst gewollt, schafft App-weite visuelle Kohärenz.
