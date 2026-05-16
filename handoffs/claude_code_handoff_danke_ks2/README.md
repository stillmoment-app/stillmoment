# Handoff: Danke-Screen — Kerzenschein 2.0

## Übersicht

Neuer **Abschluss-Screen** für **Still Moment**, der nach Ende einer Meditation (geführt oder frei) eingeblendet wird. Ersetzt den bisherigen Danke-Screen mit dem Glow-Kreis und dem Satz „Danke, dass du dir diesen Moment genommen hast."

Drei Änderungen gegenüber dem bisherigen Stand:

1. **Glow-Kreis → Doppel-Lotus-Mandala.** Zwei Petal-Ringe als zentrales Symbol, statt der pulsierenden Lichtscheibe. Keine Animation, kein Atem-Vokabular mehr — der Screen soll sich vom Player abheben (Player atmet bereits), nicht ihn fortsetzen.
2. **Neuer Satz:** „Danke, dass du dir **diese Zeit** geschenkt hast." Aktiver, weniger transaktional als „Vielen Dank / Schön, dass du dir diese Zeit genommen hast".
3. **Button trägt KS-2.0-Vokabular** — Glas-Pille mit Akzent-Schrift, dieselbe Behandlung wie der Pause-Button im Player. Kein Gradient-CTA mehr.

Verhalten unverändert: Screen erscheint, Nutzerin tippt „Fertig" (oder Schließen-X oben links), Player wird dismissed.

## Über die Design-Datei

`Danke Screen.html` ist eine **HTML-Design-Referenz**, kein Produktionscode. In SwiftUI mit den etablierten Patterns nachbauen. Tokens und Maße aus diesem README sind die Lieferung.

## Fidelity

**High-fidelity.** Alle Hex-Werte, Opacities, Rotationen und Stroke-Widths sind final. Pixelgenau übernehmen.

---

## Layout

Telefon-Referenz: 393 × 852 (iPhone 15 logical). Im HTML auf 320 × 692 reduziert für die Vorschau — Maße unten beziehen sich auf den **Produktions-Frame 393 × 852**.

```
┌─────────────────────────┐
│  09:51        ●●● ⌃ ▮  │   Status-Bar (vorhanden, unverändert)
│ ╳                       │   Schließen-Button top-left (44 × 44 hit, 36 × 36 visuell)
│                         │
│                         │
│           [Mandala]     │   Mandala vertikal-zentriert
│          160 × 160      │   (Center y ≈ Screen-Höhe × 0.42)
│                         │
│   Danke, dass du dir    │   48 px unter Mandala
│   diese Zeit geschenkt  │
│         hast.           │
│                         │
│                         │
│         ┌──────┐        │
│         │Fertig│        │   Bottom-anchored, 56 px Safe-Area Abstand
│         └──────┘        │
└─────────────────────────┘
```

**Vertikales Zentrum.** Mandala + Text als eine Gruppe vertikal zentriert in der Restfläche (zwischen Status-Bar und Button-Zone). Button als separate Bottom-Anchor-Komponente, **nicht** Teil der zentrierten Gruppe — das hält den Button auch bei kleineren Devices stabil unten.

---

## Tokens

Alle Werte stammen aus dem **gemeinsamen KS-2.0-Theme** — kein Danke-eigenes Mapping. Wenn der Player diese Tokens schon konsumiert (sollte er nach dem Player-Handover), nichts Neues anzulegen.

### Hintergrund — Linear-Gradient

```
linear-gradient(180deg,
  backgroundPrimary   0%,
  backgroundSecondary 55%,
  accentBackground    100%)
```

| Token | Dark | Light |
|---|---|---|
| `backgroundPrimary` (top) | `#1A100C` | `#FBEEDB` |
| `backgroundSecondary` (mid) | `#321F19` | `#F6CDA8` |
| `accentBackground` (bot) | `#5D3A2F` | `#E8A074` |

### Text

| Slot | Dark | Light |
|---|---|---|
| `textPrimary` (Danke-Satz, Schließen-X) | `#E5DCCD` | `#3A2418` |
| `interactive` (Mandala-Stroke, Button-Text) | `#D68A6E` | `#A2503E` |

> Im Dark nutzen wir die helle Variante des Akzents (`#D68A6E`, der `glow`-Wert). Im Light sind Akzent und Glow identisch (`#A2503E`).

### Button („Fertig") — Glas-Pille

| Token | Dark | Light |
|---|---|---|
| Background | `rgba(15, 8, 5, 0.55)` | `rgba(255, 246, 230, 0.55)` |
| Border (1 px) | `rgba(214, 138, 110, 0.50)` | `rgba(162, 80, 62, 0.55)` |
| Text | `#D68A6E` | `#A2503E` |
| Blur | `backdrop-filter: blur(8px)` | dito |
| Padding | `14 px (V) × 44 px (H)` | dito |
| Radius | `999 px` (Pille) | dito |
| Font | Geist 14 / 500, `letter-spacing 0.04em` | dito |

Identisches Glas-Vokabular wie der **Pause-Button im Player** — Background-Alpha gleich, Border-Alpha einen Tick höher (50 statt 40) damit die Pille als Tap-Target liest.

---

## Typografie

### Danke-Satz

```
Newsreader, weight 300, size 23 px, line-height 1.35,
letter-spacing -0.005em, text-wrap: balance, max-width 240 px,
text-align: center, color: textPrimary
```

Inhalt: **„Danke, dass du dir diese Zeit geschenkt hast."**

> Kein Farb-Akzent auf einzelnen Wörtern. Bewusst schlicht — der Mandala trägt das visuelle Gewicht.

### Schließen-Button

X-Glyph wie im Player: 12 × 12 px SVG, Stroke 1.6, Linecap `round`, in `textPrimary`. Hit-Area 44 × 44, visueller Frame 36 × 36, top-left bei (18, 56).

---

## Das Mandala — Doppel-Lotus, 16 Petals

**Größe:** 160 × 160 px (visuell), in einem 170 × 170 ViewBox-Frame. Center des SVG bei (85, 85).

**Stroke:** 1.3 px in `interactive`, `linecap: round`, `linejoin: round`. **Kein Fill** für die Petals (nur Stroke).

### Geometrie

Eine wiederverwendete Petal-Pfad-Form, je 8× im Kreis rotiert:

```
Outer Petal Path (8×, rotiert 0°, 45°, 90°, ..., 315°):
  M 0 -72  C -10 -54  -10 -32  0 -22  C 10 -32  10 -54  0 -72  Z

Inner Petal Path (8×, rotiert 22.5°, 67.5°, 112.5°, ..., 337.5°):
  M 0 -42  C -7 -32  -7 -18  0 -10  C 7 -18  7 -32  0 -42  Z
```

- **Outer-Ring:** 8 lange Petals, Spitze bei y = -72, Bauch bei x = ±10, y = -54 / -32, Basis bei y = -22.
- **Inner-Ring:** 8 kürzere Petals, identische Proportion, 60% Skala. Versetzt um 22.5° gegenüber dem Outer-Ring — die kurzen Petals sitzen also in den **Zwischenräumen** der langen.

### Opacities

| Element | Opacity |
|---|---|
| Outer-Petals | `1.0` |
| Inner-Petals | `0.6` |
| Center-Punkt (gefüllt, r = 5) | `1.0` |
| Center-Ring (Outline, r = 9, stroke 1.3) | `0.5` |

### Zentrum

Konzentrisch:
1. Gefüllter Punkt, r = 5, Fill `interactive`, kein Stroke.
2. Dünner Outline-Ring, r = 9, Stroke 1.3, `interactive` @ 0.5, kein Fill.

Beide bei (85, 85) im Local-Koordinatensystem.

### Vollständiges SVG (Copy-paste-fähig)

```html
<svg width="160" height="160" viewBox="0 0 170 170" fill="none"
     stroke="currentColor" stroke-width="1.3"
     stroke-linecap="round" stroke-linejoin="round">
  <g transform="translate(85 85)">
    <!-- Outer ring: 8 long petals -->
    <g>                          <path d="M0 -72 C -10 -54 -10 -32 0 -22 C 10 -32 10 -54 0 -72 Z"/></g>
    <g transform="rotate(45)">   <path d="M0 -72 C -10 -54 -10 -32 0 -22 C 10 -32 10 -54 0 -72 Z"/></g>
    <g transform="rotate(90)">   <path d="M0 -72 C -10 -54 -10 -32 0 -22 C 10 -32 10 -54 0 -72 Z"/></g>
    <g transform="rotate(135)">  <path d="M0 -72 C -10 -54 -10 -32 0 -22 C 10 -32 10 -54 0 -72 Z"/></g>
    <g transform="rotate(180)">  <path d="M0 -72 C -10 -54 -10 -32 0 -22 C 10 -32 10 -54 0 -72 Z"/></g>
    <g transform="rotate(225)">  <path d="M0 -72 C -10 -54 -10 -32 0 -22 C 10 -32 10 -54 0 -72 Z"/></g>
    <g transform="rotate(270)">  <path d="M0 -72 C -10 -54 -10 -32 0 -22 C 10 -32 10 -54 0 -72 Z"/></g>
    <g transform="rotate(315)">  <path d="M0 -72 C -10 -54 -10 -32 0 -22 C 10 -32 10 -54 0 -72 Z"/></g>

    <!-- Inner ring: 8 short petals, offset 22.5°, opacity 0.6 -->
    <g transform="rotate(22.5)">  <path opacity="0.6" d="M0 -42 C -7 -32 -7 -18 0 -10 C 7 -18 7 -32 0 -42 Z"/></g>
    <g transform="rotate(67.5)">  <path opacity="0.6" d="M0 -42 C -7 -32 -7 -18 0 -10 C 7 -18 7 -32 0 -42 Z"/></g>
    <g transform="rotate(112.5)"> <path opacity="0.6" d="M0 -42 C -7 -32 -7 -18 0 -10 C 7 -18 7 -32 0 -42 Z"/></g>
    <g transform="rotate(157.5)"> <path opacity="0.6" d="M0 -42 C -7 -32 -7 -18 0 -10 C 7 -18 7 -32 0 -42 Z"/></g>
    <g transform="rotate(202.5)"> <path opacity="0.6" d="M0 -42 C -7 -32 -7 -18 0 -10 C 7 -18 7 -32 0 -42 Z"/></g>
    <g transform="rotate(247.5)"> <path opacity="0.6" d="M0 -42 C -7 -32 -7 -18 0 -10 C 7 -18 7 -32 0 -42 Z"/></g>
    <g transform="rotate(292.5)"> <path opacity="0.6" d="M0 -42 C -7 -32 -7 -18 0 -10 C 7 -18 7 -32 0 -42 Z"/></g>
    <g transform="rotate(337.5)"> <path opacity="0.6" d="M0 -42 C -7 -32 -7 -18 0 -10 C 7 -18 7 -32 0 -42 Z"/></g>

    <!-- Center -->
    <circle r="5" fill="currentColor" stroke="none"/>
    <circle r="9" opacity="0.5"/>
  </g>
</svg>
```

**`currentColor`** im SVG nimmt die `interactive`-Farbe aus dem umgebenden View — keine Hard-coded-Hex-Werte im SVG. Dadurch flippt Dark↔Light automatisch.

### Empfehlung Bundling

Als **Asset im App-Bundle** ablegen (z. B. `mandala.svg`) und über SwiftUI's SVG-Support / SF-Symbols-Style einfärben. Alternativ als `Shape`/`Path` direkt in Swift nachgebaut — die Pfad-Form ist trivial genug (eine kubische Bézier-Schleife), beide Wege sind okay.

---

## Swift-Snippet (Vorschlag — anpassen an euer Pattern)

```swift
struct DankeScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Hintergrund
            LinearGradient(
                colors: [
                    Color.themeBackgroundPrimary,
                    Color.themeBackgroundSecondary,
                    Color.themeAccentBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Mandala + Text vertikal zentriert
            VStack(spacing: 48) {
                LotusMandala()
                    .frame(width: 160, height: 160)
                    .foregroundStyle(Color.themeInteractive)

                Text("Danke, dass du dir diese Zeit geschenkt hast.")
                    .font(.custom("Newsreader", size: 23).weight(.light))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.themePrimary)
                    .frame(maxWidth: 240)
                    .lineSpacing(23 * 0.35)  // line-height 1.35
            }

            // Bottom-Anchor: Fertig
            VStack {
                Spacer()
                Button("Fertig") { dismiss() }
                    .buttonStyle(GlassPillButtonStyle())
                    .padding(.bottom, 56)
            }

            // Top-left: Schließen
            VStack {
                HStack {
                    CloseButton { dismiss() }
                        .padding(.leading, 18)
                        .padding(.top, 56)
                    Spacer()
                }
                Spacer()
            }
        }
    }
}
```

```swift
// Doppel-Lotus-Mandala (16 Petals = 8 outer + 8 inner offset 22.5°)
struct LotusMandala: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.translateBy(x: size.width / 2, y: size.height / 2)
            ctx.scaleBy(x: size.width / 170, y: size.height / 170)  // viewBox 170×170

            // Outer ring
            for angle in stride(from: 0.0, to: 360.0, by: 45.0) {
                ctx.drawLayer { layer in
                    layer.rotate(by: .degrees(angle))
                    layer.stroke(petalPath(tipY: -72, bellyX: 10,
                                           bellyHigh: -54, bellyLow: -32, baseY: -22),
                                 with: .color(.themeInteractive),
                                 lineWidth: 1.3)
                }
            }

            // Inner ring, offset 22.5°
            for angle in stride(from: 22.5, to: 360.0, by: 45.0) {
                ctx.drawLayer { layer in
                    layer.rotate(by: .degrees(angle))
                    layer.opacity = 0.6
                    layer.stroke(petalPath(tipY: -42, bellyX: 7,
                                           bellyHigh: -32, bellyLow: -18, baseY: -10),
                                 with: .color(.themeInteractive),
                                 lineWidth: 1.3)
                }
            }

            // Center: filled dot r=5
            ctx.fill(Path(ellipseIn: CGRect(x: -5, y: -5, width: 10, height: 10)),
                     with: .color(.themeInteractive))

            // Center: outline r=9 @ 0.5
            ctx.stroke(Path(ellipseIn: CGRect(x: -9, y: -9, width: 18, height: 18)),
                       with: .color(.themeInteractive.opacity(0.5)),
                       lineWidth: 1.3)
        }
    }

    private func petalPath(tipY: CGFloat, bellyX: CGFloat,
                           bellyHigh: CGFloat, bellyLow: CGFloat,
                           baseY: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: tipY))
        p.addCurve(to: CGPoint(x: 0, y: baseY),
                   control1: CGPoint(x: -bellyX, y: bellyHigh),
                   control2: CGPoint(x: -bellyX, y: bellyLow))
        p.addCurve(to: CGPoint(x: 0, y: tipY),
                   control1: CGPoint(x: bellyX, y: bellyLow),
                   control2: CGPoint(x: bellyX, y: bellyHigh))
        p.closeSubpath()
        return p
    }
}
```

```swift
// Glas-Pille — exakt dieselbe Behandlung wie der Pause-Button im Player
struct GlassPillButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let isDark = colorScheme == .dark
        let bg = isDark
            ? Color(red: 15/255, green: 8/255, blue: 5/255).opacity(0.55)
            : Color(red: 255/255, green: 246/255, blue: 230/255).opacity(0.55)
        let border = isDark
            ? Color(red: 214/255, green: 138/255, blue: 110/255).opacity(0.50)
            : Color(red: 162/255, green: 80/255, blue: 62/255).opacity(0.55)

        configuration.label
            .font(.custom("Geist", size: 14).weight(.medium))
            .tracking(14 * 0.04)               // letter-spacing 0.04em
            .foregroundStyle(Color.themeInteractive)
            .padding(.vertical, 14)
            .padding(.horizontal, 44)
            .background(.ultraThinMaterial)
            .background(bg)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(border, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
```

---

## Verhalten

| Trigger | Verhalten |
|---|---|
| Meditation läuft auf 0 ab | Player-Audio fade-out 600 ms → Danke-Screen blendet ein (Cross-Fade 400 ms, gleicher Hintergrund-Stack) |
| Tap auf „Fertig" | Player wird dismissed (Standard-Sheet-Dismiss). Audio ist zu diesem Zeitpunkt bereits gestoppt. |
| Tap auf Schließen-X (top-left) | Identisch zu „Fertig". |
| Lockscreen / Control Center | Danke-Screen erzeugt **keine** „Now Playing"-Anzeige mehr — Audio ist beendet, Now-Playing wird beim Player-Stop ausgehängt. |

**Keine Animation auf dem Screen selbst.** Kein Atem, kein Pulsieren, kein Auf-/Abklingen einzelner Elemente. Der Screen ist statisch — die Sitzung ist vorbei, der Bildschirm ist ruhig.

**Cross-Fade vom Player.** Beim Übergang vom Player zum Danke-Screen kann das Mandala 600 ms verzögert eingeblendet werden (fade-in 0 → 1) — kosmetisch, kein Muss. Wenn instabil oder zu viel: weglassen, harte Einblendung ist okay.

---

## Akzeptanzkriterium

> Nach Sitzungsende erscheint der Danke-Screen mit dem Doppel-Lotus-Mandala in der Bildschirm-Mitte, dem Satz **„Danke, dass du dir diese Zeit geschenkt hast."** darunter und der Glas-Pille **„Fertig"** am unteren Bildschirmrand. Auf dem Screen bewegt sich nichts. Akzent-Farbe ist `#D68A6E` im Dark und `#A2503E` im Light. Tap auf „Fertig" oder Schließen-X dismissed den Player.

---

## Implementierungs-Reihenfolge

1. **Bestehende Glow-Komponente entfernen** (`GlowOrb` aus dem alten Danke-Screen samt Halo-Animation).
2. **Mandala-View anlegen** — entweder als SVG-Asset im Bundle oder als `Canvas`/`Path` in Swift (Snippet oben).
3. **Hintergrund** auf den KS-2.0-LinearGradient umstellen (sollte schon aus dem Player-Handover existieren — Tokens wiederverwenden).
4. **Text** auf den neuen Satz aktualisieren, Newsreader 23/300 mit `text-wrap: balance` (in SwiftUI: `.multilineTextAlignment(.center)` + `.frame(maxWidth: 240)` reicht für den Effekt).
5. **Button** auf `GlassPillButtonStyle` umstellen (s. Snippet). Label „Fertig".
6. **Schließen-X top-left** belassen / hinzufügen — identisches X wie im Player.
7. **Light-Variante prüfen** — Glas-Pille muss hell sein (nicht der Dark-Wert), Mandala-Hue muss `#A2503E` sein.

---

## Was wir _nicht_ in diesem Handover ändern

- **Trigger-Logik** — Danke-Screen erscheint nach Sitzungsende, wie bisher.
- **Dismiss-Verhalten** — Standard-Sheet-Dismiss, keine Sonderwege.
- **Streak / Stats / Journal** — der Screen zeigt bewusst **keine** Zahlen, keine Statistik, kein „Heute gemeditiert"-Marker. Funktioniert identisch nach geführter und freier Sitzung.

---

## Dateien in diesem Bundle

| Datei | Zweck |
|---|---|
| `README.md` | Dieses Dokument |
| `Danke Screen.html` | HTML-Referenz · Dark + Light nebeneinander |

Im Browser öffnen für visuelle Referenz. Tokens und Maße aus diesem README sind die Lieferung — das HTML ist nur die Anschauung.

---

## Vorgängerdokumente

- `claude_code_handoff_player_ks2/README.md` — Player auf Kerzenschein 2.0. Liefert die Theme-Tokens, die der Danke-Screen wiederverwendet.
- `handoff_danke/Danke Screen Final.html` — vorheriger Danke-Screen (Glow-Kreis, „Vielen Dank"). Wird durch dieses Bundle abgelöst.
