# Handoff: Running Timer — "Sanduhr-Vessel"

## Übersicht

Dies ist der **Running-Screen** einer Meditations-App ("Still Moment") — was angezeigt wird, während eine Sitzung läuft (1–60 Min). Er ersetzt einen Vorgänger mit dünnem Ring + sehr weichem, atmenden Glow, der als „leer" und „träge" empfunden wurde.

**Kerngedanke: Stille als Designentscheidung.** Es gibt **keine visuelle Atembewegung**. Eine Meditations-App, die per Animation vorgibt, wann ein- und ausgeatmet wird, führt den inneren Prozess. Wer meditiert, atmet selbst. Die App ist still und begleitet — sie taktet nicht.

Auf dem Screen bewegt sich pro Sitzung nur eine Sache: **der Flüssigkeitspegel im Glas sinkt linear** über die gesamte Sitzungsdauer (z.B. 360 px in 10 min ≈ 0,6 px/s — nicht wahrnehmbar pro Frame, deutlich nach Minuten). Daneben tickt die Restzeit im Sekundentakt nach unten.

Das Visual ist eine vertikale **Glas-Capsule** mit warmem Verlauf (Honig → Kupfer), dünnem Meniskus-Glanz an der Wasserlinie und einem schmalen Glas-Reflex links. Rechts daneben: Restzeit (Newsreader, 64 px), darüber das Eyebrow „verbleibend", darunter eine kursive Zeile „von 10 Minuten" zur Verortung.

## Über die Design-Dateien

Die Dateien in diesem Bundle sind **HTML-Design-Referenzen** — ein Prototyp, der das beabsichtigte Aussehen und Verhalten zeigt, **kein Produktionscode zum direkten Kopieren**. Aufgabe: Dieses Design in der Ziel-Codebase mit deren etablierten Patterns nachbauen (SwiftUI für iOS, Jetpack Compose für Android, React Native, Flutter — je nach Stack).

D wurde unter anderem deshalb gewählt, weil es **nativ extrem unkompliziert** ist: ein abgerundeter Container mit Clipping, ein farbgefüllter Rechteck-Pegel, eine Ellipse als Meniskus, ein dünner Glanz-Streifen. Keine Shader, keine Masken, keine Pfad-Animationen.

## Fidelity

**High-fidelity (hifi).** Alle Maße, Farben, Typografie und Stop-Stellen des Gradients sind final. Pixelgenau nachbauen.

## Bildschirm

### Name
**Running Timer — Sanduhr-Vessel**

### Zweck
Die laufende Sitzung begleiten, ohne den Atem zu takten. Restzeit sichtbar, Visual als räumlicher Verlauf statt zirkulärer Indikator.

### Layout (Frame: 393 × 852, iPhone 15/16/17 Pro logical)

```
┌───────────────────────────────────────┐
│ Status Bar (54 px)                    │  09:41 + Signal/Wifi/Battery
│                                       │
│   [×]                                 │  CloseBtn oben links, 18/64
│                                       │
│                                       │
│                                       │
│                                       │
│                                       │
│       ┌───┐                           │
│       │   │  ┌────────────────┐       │
│       │ ░ │  │ VERBLEIBEND    │       │  Eyebrow 11/0.22em
│       │ ░ │  │                │       │
│       │ ▒ │  │   07:36        │       │  Newsreader 64/300, tabular
│       │ ▒ │  │                │       │
│       │ █ │  │ von 10 Minuten │       │  Newsreader italic 13
│       │ █ │  └────────────────┘       │
│       │ █ │                           │
│       │ █ │                           │
│       │ █ │                           │
│       └───┘                           │
│                                       │
│         (vertikal zentriert)          │
│                                       │
│         (gap 36 px zwischen           │
│         Vessel und Text-Block)        │
│                                       │
│                                       │
└───────────────────────────────────────┘
```

Vessel + Text-Block sind als Flex-Row mittig auf dem Screen platziert (`align: center; justify: center; gap: 36`). Kein Tab-Bar während Sitzung (entspricht App-Konvention für Vollbild-Sitzungs-Modi).

### Komponenten

#### 1. Vessel (`Vessel`)
Datei: `timer-running-sanduhr.jsx`

- **Container:** 112 × 362 (110 + 2 für Border), border-radius 28, overflow hidden
- **Border:** 1 px `rgba(235,226,214,0.10)`
- **Glas-Hintergrund:** `linear-gradient(180deg, rgba(58,32,26,0.4), rgba(26,13,9,0.6))` (leerer Glas-Schimmer)
- **Glas-Tiefen-Shadow:** `inset 0 0 30px rgba(0,0,0,0.4)`
- **Innen-SVG:** 110 × 360
- **Fluid-Pegel (gradient):**
  - Rechteck, x=0, y=`360*(1-progress)`, width=110, height=`360*progress` (von oben gesehen: Auffüllung sinkt von voll auf null über die Sitzung; bei Start ist die Flasche voll, am Ende leer)
  - Fill: `linearGradient` (id `sv-fluid`), x1=0 y1=0 → x2=0 y2=1
    - 0 %: `rgba(232,178,148,0.85)` — Honig oben
    - 40 %: `rgba(214,138,110,0.85)` — Kupfer
    - 100 %: `rgba(176,106,79,0.95)` — tiefer Kupfer unten
- **Meniskus-Glanz:** Ellipse cx=55, cy=`top + 1.5`, rx=46.2, ry=1.5, fill `rgba(255,230,210,0.55)`. Sitzt **auf** der Oberkante des Pegels.
- **Glas-Reflex (Seitenglanz):** absolutes Div, top:8, left:12, bottom:8, width:6, border-radius:6, `linear-gradient(180deg, rgba(255,255,255,0.18), transparent)`. Bleibt statisch.

#### 2. Text-Block (rechts vom Vessel)
- Flexspalte, alignItems: flex-start, gap-mäßig manuell:
  - **Eyebrow „verbleibend"** — Geist 11 px, weight 400, letter-spacing 0.22em, uppercase, color `--sm-text-3` (#6f6358). margin-bottom 6.
  - **Restzeit** — Newsreader 64 px, weight 300, line-height 1, letter-spacing −0.02em, `font-variant-numeric: tabular-nums`, color `--sm-text` (#ebe2d6). Format `MM:SS`.
  - **„von X Minuten"** — Newsreader Italic 13 px, color `--sm-text-2` (#a89a8c). margin-top 18.

#### 3. Close-Button (`CloseBtnSV`)
- Position absolut, top 64, left 18, z-index 4.
- Verwendet `.icon-btn` + `.press` aus `styles.css`.
- 40 × 40 px, kreisrund, Hintergrund `rgba(235,226,214,0.06)`, Border `1px rgba(235,226,214,0.05)`.
- Glyph: 14 × 14 SVG-X, `stroke-width 1.6`, currentColor.

#### 4. Phone-Shell
Statusbar (`SM.StatusBar`) und Phone-Wrapper (`SM.Phone`) aus `shell.jsx`. Phone-Hintergrund: radialer Gradient (in `.phone` aus `styles.css`).

## Interaktionen & Verhalten

| Trigger | Effekt |
|---|---|
| Sitzung läuft | Pegel sinkt **linear** von voll (progress=0) auf leer (progress=1) über die Sitzungsdauer. **Eine** Animation, keine Easing-Kurve. |
| Restzeit | Tickt einmal pro Sekunde herunter. Newsreader-Tabular-Nums halten Wertbreite konstant. |
| Tap auf X | Schließt die Sitzung (Bestätigungs-Dialog außerhalb dieses Handoffs). |
| Sitzung endet | Pegel auf 0, Gong, Übergang zum Danke-Screen (außerhalb dieses Handoffs). |
| Pause / Resume | Empfehlung: Pegel-Animation pausieren und beim Resume mit neuer `duration_left` linear weiterführen. **Kein Snap-Back, kein Catch-up-Sprung.** |

**Was sich NICHT bewegt:**
- Glas-Container — statisch.
- Glas-Reflex — statisch.
- Meniskus — folgt nur dem Pegel (nicht eigenständig bewegt, kein Wellenschwingen).
- Fluid-Gradient — die Farben sind absolut zur Glas-Höhe, nicht zur Flüssigkeit. Wenn der Pegel sinkt, wandert die obere helle Hälfte nicht mit; sie bleibt da, wo sie geometrisch hingehört. Das ist gewollt — der Spiegel wandert durch den Gradient hindurch.

## State

```ts
type RunningState = {
  durationSec: number;   // Sitzungs-Gesamtdauer in Sekunden, 60..3600
  elapsedSec: number;    // aktuell verstrichene Sekunden, 0..durationSec
  isPaused: boolean;
};

const remaining = durationSec - elapsedSec;
const progress  = elapsedSec / durationSec; // 0..1

function formatMMSS(sec: number): string {
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}
```

**Source of truth:** ein einziger `started_at` Timestamp (Wall-Clock). Daraus jedes Frame `elapsed = now - started_at` ableiten — kein eigener Counter, der weglaufen kann (Hintergrund/App-Suspend-Recovery).

## Design Tokens

### Farben (aus `styles.css`)

| Token | Verwendung | Hex / Wert |
|---|---|---|
| `--sm-text` | Restzeit-Zahl | `#ebe2d6` |
| `--sm-text-2` | „von 10 Minuten" | `#a89a8c` |
| `--sm-text-3` | Eyebrow „VERBLEIBEND" | `#6f6358` |
| (lokal) | Honig (Pegel-Oben) | `rgba(232,178,148,0.85)` |
| (lokal) | Kupfer (Pegel-Mitte, 40 %) | `rgba(214,138,110,0.85)` |
| (lokal) | Tief-Kupfer (Pegel-Unten) | `rgba(176,106,79,0.95)` |
| (lokal) | Meniskus-Glanz | `rgba(255,230,210,0.55)` |
| (lokal) | Glas-Reflex | `rgba(255,255,255,0.18) → transparent` |
| (lokal) | Glas-Border | `rgba(235,226,214,0.10)` |
| (lokal) | Glas-Inner-Tint | `rgba(58,32,26,0.4) → rgba(26,13,9,0.6)` |
| (lokal) | Glas-Inner-Shadow | `rgba(0,0,0,0.4)` |

> **Hinweis:** Pegel-Farben, Meniskus und Glas-Reflex sind bewusst **lokal** (nicht in `--sm-accent-*`), weil sie eine eigene Material-Identität tragen ("warmer Honig"), die woanders in der App nicht auftaucht. Bei Theme-Wechsel müsste der Gradient separat angepasst werden.

### Typografie

| Stelle | Family | Size | Weight | Letter-Spacing |
|---|---|---|---|---|
| Restzeit | Newsreader | 64 | 300 | −0.02em |
| Eyebrow „VERBLEIBEND" | Geist | 11 | 400 | 0.22em (uppercase) |
| „von X Minuten" | Newsreader Italic | 13 | 400 | — |
| Statusbar Time | SF Pro Text | 17 | 600 | — |

`font-variant-numeric: tabular-nums` auf der Restzeit (verhindert Spaltenwechsel beim Tick).

### Spacing
- Vessel ↔ Text-Block: 36 px
- Eyebrow → Restzeit: 6 px (margin-bottom auf Eyebrow)
- Restzeit → „von X Minuten": 18 px (margin-top)
- Close-Button: top 64, left 18 (= 10 px unter Statusbar-Höhe 54)

### Border-Radius
- Vessel: 28 px
- Glas-Reflex: 6 px
- Close-Button: 50 % (kreisrund)

## Plattform-Implementations-Hinweise

### iOS / SwiftUI

```swift
struct Vessel: View {
  let progress: Double // 0..1
  let height: CGFloat = 360
  let width: CGFloat = 110

  var body: some View {
    ZStack(alignment: .bottom) {
      // Glas-Hintergrund
      RoundedRectangle(cornerRadius: 28)
        .fill(LinearGradient(
          colors: [Color(white: 0.20, opacity: 0.4),
                   Color(white: 0.08, opacity: 0.6)],
          startPoint: .top, endPoint: .bottom))
        .overlay(
          RoundedRectangle(cornerRadius: 28)
            .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 30, y: 0) // inset-shadow Fake
      // Pegel
      Rectangle()
        .fill(LinearGradient(
          stops: [
            .init(color: Color(red: 232/255, green: 178/255, blue: 148/255).opacity(0.85), location: 0),
            .init(color: Color(red: 214/255, green: 138/255, blue: 110/255).opacity(0.85), location: 0.4),
            .init(color: Color(red: 176/255, green: 106/255, blue:  79/255).opacity(0.95), location: 1.0),
          ],
          startPoint: .top, endPoint: .bottom))
        .frame(height: height * (1 - progress))
        .animation(.linear(duration: 1.0), value: progress) // 1-Sek-Ticks
      // Meniskus + Reflex hier overlayen
    }
    .frame(width: width, height: height)
    .clipShape(RoundedRectangle(cornerRadius: 28))
  }
}
```

Inset-Shadow auf iOS am sichersten via overlay einer leicht kleineren `RoundedRectangle` mit Schwarz-Border und Blur, oder über das neuere `.inner​Shadow` (iOS 17+).

### Android / Jetpack Compose

```kotlin
@Composable
fun Vessel(progress: Float) {
  val animatedProgress by animateFloatAsState(
    targetValue = progress,
    animationSpec = tween(durationMillis = 1000, easing = LinearEasing)
  )
  Box(
    modifier = Modifier
      .size(width = 110.dp, height = 360.dp)
      .clip(RoundedCornerShape(28.dp))
      .background(
        Brush.verticalGradient(
          listOf(
            Color(0x66_3A201A), // 0.4 alpha
            Color(0x99_1A0D09)  // 0.6 alpha
          )
        )
      )
      .border(1.dp, Color.White.copy(alpha = 0.10f), RoundedCornerShape(28.dp))
  ) {
    Box(
      modifier = Modifier
        .align(Alignment.BottomStart)
        .fillMaxWidth()
        .fillMaxHeight(animatedProgress)
        .background(
          Brush.verticalGradient(
            0f to Color(0xD9_E8B294),
            0.4f to Color(0xD9_D68A6E),
            1f to Color(0xF2_B06A4F),
          )
        )
    )
    // Meniskus + Reflex via Canvas oder zwei kleine Boxes
  }
}
```

### Pre-Compose Android (View-System)

Custom View mit `onDraw`:

```kotlin
class VesselView : View(...) {
  var progress = 0f // 0..1, animatable
  private val clipPath = Path()
  private val fluidPaint = Paint().apply {
    shader = LinearGradient(0f, 0f, 0f, height.toFloat(), intArrayOf(...), floatArrayOf(0f, 0.4f, 1f), Shader.TileMode.CLAMP)
  }

  override fun onDraw(canvas: Canvas) {
    clipPath.rewind()
    clipPath.addRoundRect(0f, 0f, width.toFloat(), height.toFloat(), 28dpf, 28dpf, Path.Direction.CW)
    canvas.clipPath(clipPath)
    // 1) Glas-Background
    // 2) Pegel-Rechteck
    val top = height * (1 - progress)
    canvas.drawRect(0f, top, width.toFloat(), height.toFloat(), fluidPaint)
    // 3) Meniskus-Oval
    // 4) Glas-Reflex links
  }
}
```

Animation via `ObjectAnimator.ofFloat(view, "progress", 0f, 1f).apply { duration = durationSec*1000L; interpolator = LinearInterpolator() }`.

### Plattform-Übergreifende Punkte

- **Animation:** lineare Interpolation über die gesamte Sitzungsdauer. Keine Easing-Kurve. Nicht in Sekunden-Schritten, sondern kontinuierlich (`durationMillis = durationSec * 1000`).
- **Hintergrund/Resume:** beim App-Resume aus dem `started_at`-Timestamp das aktuelle `progress` berechnen und die Animation mit `(durationSec - elapsedSec)` Restdauer neu starten. **Kein Snap.**
- **Reduced Motion** (`UIAccessibility.isReduceMotionEnabled` / `Settings.Global.ANIMATOR_DURATION_SCALE == 0`): Pegel snappt einmal pro Sekunde an die korrekte Höhe statt kontinuierlich zu sinken. Sieht weiterhin sinnvoll aus, weil die Restzeit ebenfalls im Sekundentakt wechselt.
- **Wake-Lock / Always-On:** der Screen sollte während laufender Sitzung nicht dunkel werden (`UIApplication.shared.isIdleTimerDisabled = true` / `FLAG_KEEP_SCREEN_ON`).
- **Inset-Shadow** (Glas-Innenschatten) auf beiden Plattformen ggf. via Layer-Composition oder einer extra leicht kleineren, schwarz-randigen Form. Kein muss — der Effekt ist subtil.

## Accessibility

- **Hauptanzeige als Live-Region:** Restzeit sollte alle 60 s (nicht jede Sekunde — zu viel Lärm) per VoiceOver/TalkBack angesagt werden können (z.B. „Sieben Minuten noch"). Ggf. nur auf Tap auf den Vessel-Bereich vorlesen.
- **Close-Button** mit Label „Sitzung beenden".
- **Pegel-Visual:** als dekorativ markieren (`accessibilityHidden=true`) — die Information steckt in der Zahl. Doppelte Auslesung vermeiden.
- **Kontrast:** Restzeit (`#ebe2d6` auf Phone-Background `#190c08`) erreicht ~14:1, weit über AA Large. Eyebrow (`#6f6358` auf `#190c08`) erreicht ~3.8:1 — AA Large (18 px+) ist 3:1, hier sind wir bei 11 px **knapp drüber** für AA Large, **darunter** für AA Normal. Bewusst akzeptiert, weil Eyebrow ein subordinates Label ist; die Information ist primär in der großen Zahl.

## Assets

- **Fonts:** Newsreader und Geist von Google Fonts (in der App durch native Pendants ersetzen — z.B. `New York` + `SF Pro` auf iOS, oder Newsreader/Geist als gebündelte TTFs).
- **Icons:** Inline-SVG für das X (Close). Aus `shell.jsx` übernommen oder durch hauseigenes Icon-System ersetzen.
- **Keine Bitmaps**, keine Lizenzfragen.

## Dateien in diesem Bundle

| Datei | Inhalt |
|---|---|
| `Running Timer.html` | Lauffähiger Prototyp (im Browser öffnen — zeigt 0 %, live und 90 %) |
| `timer-running-sanduhr.jsx` | `RunningSanduhr`, `RunningSanduhrStatic`, `Vessel` |
| `shell.jsx` | `StatusBar`, `Phone`-Wrapper (StatusBar wird verwendet) |
| `styles.css` | Alle CSS-Variablen + Klassen (`.phone`, `.icon-btn`, `.press`, `.statusbar`) |

## Out of Scope dieses Handoffs

- **Pre-Roll** ("Komme an") vor der Sitzung. Wurde im aktuellen Re-Design eingestellt — die Entscheidung „keine Atembewegung" gilt auch dort und braucht einen eigenen Pass.
- **Danke-Screen** nach der Sitzung. Bestehendes Design verwendet einen pulsierenden Glow — sollte konsistent zu „still" überarbeitet werden.
- **Pause-/Resume-UI:** wann/wie wird das Pause-Bedienfeld eingeblendet? (Vorschlag: Tap auf den Vessel → 2 s Bedienfeld einblenden, dann ausblenden.)
- **Sound:** Hintergrund-Audio, Gong, Intervall-Glocken. Nicht visuell.
- **End-Übergang:** Übergang vom letzten Frame (progress=1) zum Danke-Screen. Vorschlag: 600 ms Fade auf den Phone-Background.

## Was sich gegenüber dem alten Stand ändert (Kontext)

1. **Keine atmende Animation mehr.** Vorher: Ring skalierte 0,97 → 1,01 in 8-s-Zyklen. Jetzt: still. Argument: die App taktet den Atem nicht.
2. **Visual ist kein Ring mehr, sondern ein Glas.** Räumlicher Verlauf statt zirkulärer Indikator. Stärkere metaphorische Verbindung zu „Zeit, die rinnt".
3. **Restzeit ist groß und prominent**, nicht klein und unten.
4. **Keine Sitzungs-/Phasen-Labels mehr** im Footer („Atem · Geführt" / „Phase 2 von 4 · Bauchatmung"). Wer meditiert, weiß was läuft. Bei geführten Sitzungen gibt die Stimme den Rest. Visuelle Stille = Aufmerksamkeits-Stille.
