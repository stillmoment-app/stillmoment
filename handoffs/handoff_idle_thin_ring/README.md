# Handoff: Idle-Ring — dünn (Running-Sprache)

## Übersicht

Der Dauer-Picker im **Timer-Idle-Screen** bekam bisher einen **dicken, gradient-gefüllten Ring** mit großem Knob — der visuell stark vom **laufenden Timer** abwich (dünner Ring + kleine Lichtperle). Dieses Handoff stellt die optische Einheit her: **gleiche Strichstärken, gleiche Lichtperle, gleicher zarter Glow** in beiden Zuständen.

Die Geometrie/Interaktion bleibt gleich (Drag um den Ring, 1–60 Minuten) — nur die **Ring-Erscheinung** ändert sich.

**Wichtig:** Die **Settings-Liste unter dem Ring bleibt unverändert** — Listen-Reihen mit Label links, Wert + Chevron rechts, wie im aktuellen iOS-Build. Keine Glyph-Karten, keine Grid-Anordnung.

## Fidelity

**High-fidelity (hifi).** Die Werte in diesem Dokument sind final und sollen 1:1 in der Ziel-Codebase nachgebaut werden.

## Vorher / Nachher

| Aspekt | Vorher (H2-Final) | Nachher (Thin) |
|---|---|---|
| Basis-Ring | 2 px, `rgba(235,226,214,0.06)` | **1 px**, `var(--sm-accent-soft)` @ opacity 0.35 |
| Fortschritts-Bogen | 2.5 px Linear-Gradient (`#f4c4a8 → #d68a6e → #a8624a`) | **1.5 px**, einfarbig `var(--sm-accent-glow)` @ opacity 0.6, `stroke-linecap: round` |
| Knob / Bead | r = 6, harter Drop-Shadow 10 px | **r = 5**, weicher Drop-Shadow 8 px |
| Atem-Animation | nur Halo-Pulse via `<animate>` | gemeinsame `useBreath`-Hook (sin-basiert, 8 s Periode), skaliert das ganze SVG um ±3 % |
| Glow | radial gradient hinter dem Ring | `filter: drop-shadow(0 0 [8..16]px var(--sm-accent-dim))` — pulsiert mit Atem |
| Hintergrund | dezenter Sternenhimmel | radialer Akzent-Glow oben (gleich wie Running-Screen, opacity 0.55) |

## Ring-Spezifikation (exakt)

Identisch zwischen Idle und Running. Container 280 × 280 px (oder 262 × 262 im H2-Layout).

```
size = 262
r    = 110          // Bahn-Radius
cx   = size / 2
cy   = size / 2

base ring:   stroke=var(--sm-accent-soft),  opacity=0.35,  width=1
progress:    stroke=var(--sm-accent-glow),  opacity=0.6,   width=1.5
             linecap=round
             dasharray = `${t * arcLen} ${arcLen}` mit arcLen = 2πr
             rotate(-90 cx cy)
bead:        cx,cy = (cx + cos(angle) * r, cy + sin(angle) * r)
             angle = t * 2π − π/2
             r=5, fill=var(--sm-accent-glow)
             filter: drop-shadow(0 0 8px var(--sm-accent-glow))

t (Idle)     = minutes / 60
t (Running)  = elapsed / duration
```

### Atem-Animation

Eine `useBreath(period)`-Hook teilt sich beide Screens. Phase `b ∈ [0, 1]` via `0.5 − 0.5·cos(t·2π)`.

| Screen | Periode | Scale | Glow |
|---|---|---|---|
| **Idle** | 8 s | `0.98 + b·0.03` | `drop-shadow(0 0 [8..16]px var(--sm-accent-dim))` |
| **Running** | 8 s | `0.97 + b·0.04` | `drop-shadow(0 0 [10..20]px var(--sm-accent-dim))` |

Idle ist absichtlich **etwas zurückhaltender** (kleinere Amplitude), weil der Nutzer hier noch interagiert. Sobald die Sitzung läuft, atmet der Ring deutlicher.

## Reduced Motion

Bei `prefers-reduced-motion: reduce` die `useBreath`-Animation komplett auslassen (`scale = 1`, statischer Glow). Der Ring darf statisch sein — die Atem-Hilfe ist zier, nicht funktional.

## Accessibility

- Picker bekommt `role="slider"` mit `aria-valuemin=1`, `aria-valuemax=60`, `aria-valuenow={minutes}`, `aria-valuetext="${minutes} Minuten"`.
- Tastatur: ←/→ ändert ±1, Shift + ←/→ ±5, Home/End springen auf 1/60.
- Touch-Target des Beads erweitert die Touch-Area des gesamten Rings via padded HitArea (radial 24 px nach außen). In SwiftUI: `contentShape(Circle().inset(by: -24))`.

## Implementations-Hinweise (Plattform-spezifisch)

### SwiftUI
- Basis und Bogen: `Circle().trim(from:0,to:t).stroke(.linearGradient/.color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))`
- Glow: `.shadow(color: .accentDim, radius: 8 + breath*8)`
- Atem: `withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true))` auf einen `@State var breath: CGFloat`
- Bead: `Circle().fill(.accentGlow).frame(width: 10, height: 10).offset(x: cos(angle)·r, y: sin(angle)·r)`
- Drag: `DragGesture(minimumDistance: 0).onChanged` → `atan2`, dann clamp 1...60

### Jetpack Compose
- `Canvas`-basiert: `drawArc(color, startAngle = -90f, sweepAngle = t·360, useCenter = false, style = Stroke(width = 1.5.dp.toPx(), cap = StrokeCap.Round))`
- Atem: `rememberInfiniteTransition().animateFloat(0f → 1f, infiniteRepeatable(tween(8000), RepeatMode.Reverse))`
- Glow: extra `drawCircle` mit `BlendMode.Plus` und alpha-falloff, oder Renderscript-Blur — pragmatisch: weicher Schatten via Layer + `RenderEffect.createBlurEffect`
- Drag: `Modifier.pointerInput { detectDragGestures }`, atan2 → state

### React Native (falls relevant)
- `react-native-svg` + `react-native-reanimated` für Atem (Worklet-getrieben).
- Glow: `Shadow`-Komponente (`react-native-shadow-2`) oder native `shadowOpacity/shadowRadius` (iOS) — Android braucht ggf. einen separaten Layered-Circle-Trick.

## Tokens (zur Erinnerung)

```
--sm-accent       #c47a5e
--sm-accent-soft  #b06a4f   ← Basis-Ring
--sm-accent-glow  #d68a6e   ← Bogen + Bead
--sm-accent-dim   rgba(196,122,94,0.18)   ← Drop-Shadow
--sm-accent-text  #d99a7e   ← Glyph-Icons
```

Bei Theme-Wechsel (Salbei, Dämmerung) bleiben alle Verhältnisse gleich — nur die fünf Token-Hex-Werte tauschen aus. Siehe `styles.css`.

## Dateien in diesem Bundle

| Datei | Inhalt |
|---|---|
| `Idle Thin Ring.html` | Lauffähiger Side-by-Side-Vergleich (Idle + Running) |
| `timer-idle-thin.jsx` | `TimerIdleThin` + `ThinRing` + `useBreathTT` |
| `timer-prep-running.jsx` | Referenz: `RunningTimerFinal` + `useBreath` (gleiche Hook) |
| `shell.jsx` | `StatusBar`, `TabBar`, `Phone`, Icon-Set |
| `styles.css` | Tokens + globale Klassen |

## Was nicht in Scope ist

- Setting-Rows unter dem Ring (Vorbereitung, Gong, Intervall, Hintergrund) — Layout bleibt wie im aktuellen iOS-Build: Label links, Wert in Akzentfarbe + Chevron rechts, Hairline-Divider dazwischen. Tap öffnet das jeweilige Sheet.
- Drag-Acceleration mittels +/−-Buttons (gibt es in dieser Variante nicht).
- Pre-Roll, Sheet-Picker, Tab-Bar-Inhalte.

## Open Questions

1. Möchten wir den **Atem-Scale auch im Idle-Screen** (aktuell ±3 %)? Falls zu unruhig: `scale = 1` setzen und nur den Glow leise pulsieren lassen.
2. Soll der **Bead beim Drag** vergrößern (z. B. r=5 → r=7 während aktiv)? Würde die Greifbarkeit erhöhen, ist aktuell weggelassen, um den Vergleich zum Running-Screen sauber zu halten.
