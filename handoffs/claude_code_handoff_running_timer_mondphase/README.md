# Handoff: Running Timer — Mondphase (Dark + Light)

## Übersicht

Dies ist die **Running-Timer-Visualisierung** als Ablösung der aktuellen Sanduhr (oder als zusätzliche Theme-Option, falls beide weitergeführt werden sollen). Konzept aus den Organic Explorations, Variante **C · Mondphase**.

**Idee:** Über die Dauer einer Sitzung wandert der Schatten vom Mond — von **Neumond** (Start, 10:00) zu **Vollmond** (Ende, 00:00). Der schwarze Schatten-Kreis driftet nach links aus dem Bildausschnitt, sodass am Ende ein purer, voll erleuchteter Mond steht.

**Keine Bewegung, die ablenkt.** Der Mond bleibt am Platz. Nur der Terminator (Schattenkante) wandert. Sehr meditativ, ohne Naturalismus.

## Über die Design-Dateien

`Mondphase Pair Preview.html` ist eine **HTML-Design-Referenz** mit lauffähiger Animation in beiden Modi nebeneinander. In SwiftUI mit den etablierten Patterns nachbauen.

## Fidelity

**High-fidelity.** Geometrie, Farben, Easing und Timing sind final. Pixelgenau übernehmen.

---

## Geometrie

Der Mond sitzt im **unteren Drittel** des Screens (so wie aktuell die Sanduhr / der Ring) — die Zeit-Anzeige sitzt darüber im oberen Drittel.

| Element | Wert |
|---|---|
| SVG-Viewport | `viewBox="-110 -110 220 220"` (220 × 220 logisch) |
| Sichtbare Größe | `220 × 220` px (1:1) |
| Position auf 340×736 Phone | `left: 50%; top: 460px; transform: translate(-50%, -50%)` |
| Mond-Radius | `90` (logical) |
| Mond-Mittelpunkt | `(0, 0)` (immer) |
| Schatten-Radius | `90` (= Mond-Radius) |
| Halo-Container | `width: 480px; height: 480px`, zentriert auf Mond |

---

## Animation

### Schatten-Position (lineare Interpolation)

```
cx = -progress × 200
```

`progress` ∈ `[0, 1]` (verstrichene Anteil der Sitzung).

| Progress | cx | Phase |
|---|---|---|
| `0.0` | `0` | Neumond — Schatten exakt über Mond, komplett schwarz |
| `0.5` | `-100` | Halbmond — Schatten halb über dem Mond |
| `0.9` | `-180` | **Vollmond** — rechte Schattenkante berührt linken Mondrand |
| `1.0` | `-200` | Schwarze Scheibe vollständig aus dem SVG-Bild |

**Wichtig:** Die `-180 → -200`-Strecke (letzte 10 %) ist bewusst — sie räumt den Bildausschnitt, sodass am Sitzungsende kein dunkler Rest links vom Mond hängt. Linear, kein Easing.

### Halo-Intensität (Smoothstep ease-in)

```
haloEase = progress × progress × (3 − 2 × progress)
haloAlpha = 0.02 + haloEase × 0.48
```

`haloAlpha` läuft von `0.02` (Neumond, fast unsichtbarer Schein) bis `0.5` (Vollmond, sanfter warmer Halo). Smoothstep, damit der Halo nicht linear/aufdringlich anschwillt, sondern erst spät richtig sichtbar wird.

Anwendung im CSS (per CSS-Variable aktualisieren):

```css
background: radial-gradient(circle,
  rgba(242, 200, 168, var(--moon-halo, 0.02)) 0%,
  rgba(199, 125, 99, calc(var(--moon-halo, 0.02) * 0.5)) 40%,
  transparent 70%);
```

### Tick-Rate

`requestAnimationFrame` reicht völlig. Der Schatten muss flüssig wandern (60 fps); die Zeit-Anzeige kann auch nur einmal pro Sekunde aktualisiert werden. Keine `transition` auf `cx` — die Position wird in jedem Frame neu gesetzt.

---

## Token-Map · Moon-spezifisch

Diese Tokens kommen **zusätzlich** zu den Kerzenschein-2.0-Tokens. Sie steuern nur den Mond + Halo + Schatten.

### Dark · Lifted Warm

| Slot | Wert | Bemerkung |
|---|---|---|
| `moonDiscFrom` | `#F4E2C8` | innerer warmer Cream |
| `moonDiscMid` | `#E5C8A8` | mittlerer Ton |
| `moonDiscTo` | `#B89478` | äußerer ockerfarbener Rand |
| `moonShadow` | `#1A100C` | = `backgroundPrimary` |
| `moonRing` | `rgba(244,226,200,0.16)` | feiner Mondrand-Strich (0.7 px) |
| `haloFrom` | `rgba(242,200,168, α)` | α = `haloAlpha` |
| `haloTo` | `rgba(199,125,99, α/2)` | bei 40 % Radius |

### Light · Sunrise Confident

Die größte Herausforderung im Light Mode: der Mond muss sich gegen einen **hellen, warmen** Hintergrund behaupten, der Schatten darf nicht als brutales Schwarzloch wirken. Lösung: kontrastreicherer Disc-Verlauf + tiefes Erdbraun statt Reinschwarz als Schatten.

| Slot | Wert | Bemerkung |
|---|---|---|
| `moonDiscFrom` | `#FFF3DD` | nahezu weiß, hebt sich gegen Cream-bg |
| `moonDiscMid` | `#E8C896` | wärmer als im Dark, mehr Sättigung |
| `moonDiscTo` | `#9A6A42` | tiefer Ocker — stärkere Tiefe am Rand |
| `moonShadow` | `#3A2418` | = `textPrimary`, warmer Tinten-Dunkel |
| `moonRing` | `rgba(58,36,24,0.18)` | sichtbar gegen helle Disc |
| `haloFrom` | `rgba(252,232,200, α)` | α = `haloAlpha` |
| `haloTo` | `rgba(184,95,70, α/2)` | bei 40 % Radius |

> **Akzeptanz Light Mode:** Der Vollmond am Ende der Sitzung darf nicht „verloren" gegen den Sunrise-Hintergrund wirken. Der Disc-Verlauf von Weiß zu Ocker muss dem Mond Plastizität geben, ohne dass der Mond aufdringlich wird.

---

## Disc-Gradient

Ein **radialer Gradient mit verschobenem Zentrum**, um leichte Beleuchtung von oben-links zu suggerieren:

```html
<radialGradient id="moon-disc" cx="0.35" cy="0.35" r="0.8">
  <stop offset="0%"   stop-color="var(--moon-disc-from)"/>
  <stop offset="60%"  stop-color="var(--moon-disc-mid)"/>
  <stop offset="100%" stop-color="var(--moon-disc-to)"/>
</radialGradient>
```

**Keine Krater. Keine Mare-Flecken.** Wir hatten beides probiert — wirkt schnell nach Comic-Mond. Pure Disc-Schattierung + Schattenkante + Halo trägt die Stimmung allein.

---

## Layer-Reihenfolge (von unten nach oben)

1. **Halo** — `<div>` mit radial-gradient, Mittelpunkt = Mond-Mittelpunkt. Geometrie statisch, nur die Intensität wächst.
2. **Mond-Disc** — `<circle cx="0" cy="0" r="90" fill="url(#moon-disc)">`.
3. **Schatten-Disc** — `<circle cx="..." cy="0" r="90" fill="var(--moon-shadow)">`. **Diese `cx` wird animiert.**
4. **Mond-Ring** (optional) — feiner Stroke um den Mond, kein Fill. Macht die Silhouette schärfer.

---

## Zeit-Block (über dem Mond)

Identisch zum aktuellen Running Timer:

```
EYEBROW   verbleibend
TIME      07:23
SUB       von 10 Minuten
```

| Element | Spec |
|---|---|
| Eyebrow | Geist 500, 10 px, letter-spacing 0.28em, uppercase, `textSecondary` |
| Time | Newsreader 300, 60 px, line-height 1, letter-spacing −0.02em, **tabular-nums**, `textPrimary` |
| Sub | Newsreader italic, 12.5 px, `textSecondary` |

Position: zentriert, `top: 110 px` vom Bildschirm-Anfang (also etwas unter der Statusbar, deutlich oberhalb des Monds).

---

## Close-Button (oben rechts)

Bleibt unverändert vom aktuellen Running Timer (kleine Kapsel mit X-Glyph, `top: 56 px; right: 22 px`).

---

## Swift-Snippet (Skizze)

```swift
struct MoonPhase: View {
    let progress: Double          // 0 … 1
    @Environment(\.colorScheme) var scheme

    var body: some View {
        ZStack {
            Halo(alpha: haloAlpha)
            MoonDisc()
            // Schatten driftet nach links
            Circle()
                .fill(moonShadow)
                .frame(width: 180, height: 180)   // 90er-Radius in Render-Punkten
                .offset(x: shadowOffset)
        }
        .frame(width: 220, height: 220)
    }

    private var shadowOffset: CGFloat {
        // Logical: cx = -progress × 200; Mond r = 90 logical
        // In Render-Punkten ist „logical 200" = halbe Mond-Pixelbreite × (200/90)
        // Bei 180 pt Mond-Durchmesser entspricht das 200 pt Verschiebung
        -CGFloat(progress) * 200
    }

    private var haloAlpha: Double {
        let p = progress
        let eased = p * p * (3 - 2 * p)            // smoothstep
        return 0.02 + eased * 0.48
    }

    private var moonShadow: Color {
        scheme == .dark ? Color(hex: 0x1A100C) : Color(hex: 0x3A2418)
    }
}
```

Halo + Disc als separate Views; Disc ist eine `Circle` mit `AngularGradient` oder `RadialGradient` mit `center: UnitPoint(x: 0.35, y: 0.35)`.

---

## Akzeptanzkriterien

- **Start (10:00 verbleibend):** Mond ist **vollständig schwarz** — die Schattenkante ist nicht sichtbar, weil sie exakt mit dem Mondrand abschließt. Halo ist auf `α = 0.02` quasi unsichtbar.
- **Mitte (~05:00):** Klarer Halbmond, Schattenkante exakt vertikal in der Mondmitte. Halo deutlich sichtbar, aber noch zurückhaltend.
- **Ende (~00:48):** Mond zu ~95 % erleuchtet, Schatten driftet weiter nach links. Halo nahe Maximum.
- **00:00:** Voller Mond, **kein** schwarzer Rest mehr im Bildausschnitt. Halo bei `α = 0.5`.
- **Dark + Light:** Animation läuft in beiden Modi identisch. Im Light Mode bleibt der Vollmond klar lesbar gegen den Sunrise-Verlauf.

---

## Was wir _nicht_ in diesem Handover liefern

- **Idle Screen / Picker** — der bleibt wie im Kerzenschein-2.0-Handover spezifiziert.
- **Library / Settings** — unangetastet.
- **Audio-Verhalten** der Gongs — unverändert.
- **Pause-State** — wenn die Sitzung pausiert wird, friert die Animation auf der aktuellen `cx`-Position ein. Keine zusätzliche visuelle Behandlung nötig (der Mond steht eh schon still).

---

## Dateien in diesem Bundle

| Datei | Zweck |
|---|---|
| `README.md` | Dieses Dokument |
| `Mondphase Pair Preview.html` | Lauffähige HTML-Animation in beiden Modi nebeneinander |

Im Browser öffnen, ein paar Loops laufen lassen — der Lauf in Dark + Light synchronisiert.
