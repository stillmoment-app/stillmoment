# Handoff: Waveform Player — „Tonkopf"

## Übersicht

Dies ist der **Wiedergabe-Screen** einer geführten Meditation in der App **„Still Moment"**. Er ersetzt/erweitert den bisherigen Player (dünner horizontaler Slider mit Punkt-Griff + `−10s / Pause / +10s`). Statt eines generischen Sliders, der „genauso gut ein Timer sein könnte", zeigt der neue Player die **echte Waveform der Audiodatei** — damit ist sofort klar: *das hier ist eine gesprochene Audio-Sitzung*.

**Kerngedanke — Tonkopf.** Die Mitte des Bildschirms ist eine feste, leuchtende **Jetzt-Linie**. Die Waveform scrollt daran vorbei (wie das Band an einem Tonkopf). Links der Linie liegt Vergangenes (in Kupfer ausgefüllt), rechts Kommendes (blass). Ein sichtbares Fenster zeigt einen Ausschnitt von typ. **±30 s** um die aktuelle Position.

**Spulen per Drag.** Man greift die Welle und zieht sie nach links (vorwärts) oder rechts (zurück). Beim Greifen **pausiert** die Wiedergabe, beim **Loslassen läuft sie weiter** (sofern sie vorher lief). Während des Ziehens zeigt die Mitte live `Position / Gesamtlänge`. Es gibt **keine** `±10s`-Buttons mehr — Drag-Scrub ersetzt sie.

**Dezente Restzeit.** Eine zentrale Zeile unter der Welle („Noch 15:35"), unaufgeregt, kein Doppel-Counter.

**Visuelle Sprache:** dunkles Mahagoni-Theme (identisch zum bestehenden Player und zur Trim-Editor-Wellenform), Kupfer-Akzent, Newsreader für Display, Geist für UI.

## Zustände (Screenshots)

Im Ordner `screens/` (gerendert aus dem Prototyp, 393×852):

| Bild | Zustand |
|---|---|
| `01-ruhe-mini.png` | **Ruhe**, Wiedergabe läuft — Fenster mit Tonkopf, „Noch 17:08", Mini-Übersicht, Spul-Hinweis. |
| `02-spulen-drag.png` | **Beim Spulen** (Welle gegriffen) — Wiedergabe pausiert, zentrale Zeile wird zur Live-Position `13:31 / 26:00`, Puls/Hinweis aus. |
| `03-fortschritt-bar.png` | Fortschritts-Option **`bar`** (schlanker Balken statt Mini-Übersicht). |
| `04-fortschritt-keiner.png` | Fortschritts-Option **`keiner`** (nur die Wellenfärbung trägt den Fortschritt). |

## Über die Design-Dateien

Die Dateien in diesem Bundle sind **HTML-Design-Referenzen** — ein lauffähiger Prototyp, der Aussehen und Verhalten zeigt, **kein Produktionscode zum direkten Kopieren**. Aufgabe: Dieses Design in der Ziel-Codebase mit deren etablierten Patterns nachbauen (SwiftUI für iOS, Jetpack Compose für Android, React Native, Flutter — je nach Stack).

Die einzige bewusst „simulierte" Stelle ist die Audio-Wiedergabe: im Prototyp treibt ein `requestAnimationFrame`-Loop den Playhead (mit einstellbarem Demo-Tempo, damit man das Scrollen sieht). In der App durch echtes Audio ersetzen (`AVPlayer` / `ExoPlayer` / `<audio>`). Ebenso ist die Waveform synthetisch erzeugt — in der App **einmalig beim Import** aus der Datei berechnen und cachen (siehe „Waveform berechnen").

## Fidelity

**High-fidelity (hifi).** Maße, Farben, Typografie, Fenster-Mechanik und Scrub-Verhalten sind final und pixelgenau nachzubauen.

## Bildschirm

### Name
**Waveform Player — Tonkopf**

### Zweck
Eine geführte Meditation abspielen; jederzeit per Drag intuitiv vor-/zurückspulen; Restzeit und Gesamtfortschritt ruhig im Blick.

### Layout (Frame: 393 × 852, iPhone 15/16/17 Pro logical)

```
┌───────────────────────────────────────┐
│ Status Bar (54 px)                    │  9:41 + Signal/Wifi/Battery
│  (×)                                  │  CloseBtn 40×40, top 60 / left 20
│                                       │
│             Jon Salzberg              │  Newsreader italic 18, accent-text, top 132
│        Present Moment Awareness       │  Newsreader 33, --sm-text, balance
│                                       │
│                  ▼                    │  Jetzt-Marker (Dreieck), Spitze der Linie
│         ▕▏▕▏ ▏▕▏█▌▐█▌▐▏ ▏▕▏ ▏        │  WAVE-FENSTER (Canvas), top 366, h 188
│      ░░▏▕░▏░ ▏░│█▌▐█▌▐░▏ ▏░▏ ▏░░     │  Mitte = leuchtende Jetzt-Linie
│                  ●                    │  Puls-Punkt (unten an der Linie)
│             ←→  ziehen zum spulen     │  Hint, 10.5px uppercase, bottom −30
│                                       │
│            NOCH 20:16                 │  zentral, 12.5px/0.22em, top 600
│        ▁▂▃▅█▆▃▂▁▁ ▁▂▁▁ ▁▁▂▃▅█▆       │  Mini-Übersicht (ganze Spur), top 650
│                                       │
│               ( ❚❚ )                  │  Play/Pause 74×74, bottom 76
│                                       │
└───────────────────────────────────────┘
```

Vertikale Anker (absolute Positionen im 393×852-Frame):

| Element | Position |
|---|---|
| Close-Button | `top: 60, left: 20`, 40×40 |
| Titelblock (Artist + Titel) | `top: 132`, zentriert, `padding: 0 36` |
| Atem-Hinweis (optional, nur `progress < 0.04`) | `top: 300`, zentriert |
| Wave-Fenster (Wrapper) | `top: 366`, `left/right: 0`, Canvas-Höhe **188** |
| Jetzt-Dreieck | im Wrapper `top: −2`, `left: 50%` |
| Puls-Punkt | im Wrapper `bottom: −3`, `left: 50%` |
| Spul-Hinweis | im Wrapper `bottom: −30`, zentriert |
| Restzeit / Live-Position | `top: 600`, zentriert |
| Fortschritt (Mini / Bar) | `top: 650` (mini) bzw. `top: 666` (bar) |
| Play/Pause | `bottom: 76`, `left: 50%`, 74×74 |

---

## Komponenten

### 1. Wave-Fenster (`WaveWindow`) — Kernkomponente
Datei: `waveform-player.jsx`. Gezeichnet auf einem **`<canvas>`** (volle Breite 393 px, Höhe **188 px**), neu gezeichnet bei jeder Änderung von `now`. Device-Pixel-Ratio-Scaling (gedeckelt bei 2.5) für scharfe Balken.

**Mathematik des Fensters:**
- `pxPerSec = canvasBreite / windowSec` — bei `windowSec = 60` und 393 px Breite ≈ **6.55 px/s**.
- Mitte `cx = breite/2`. Für jeden Balken an Bildschirm-x: `sec = now + (x − cx) / pxPerSec`. Balken **links** der Mitte sind also früher, **rechts** später.
- Balken-Raster: `barStep = 3.2 px` (Abstand der Balkenmittelpunkte), Balkenbreite `barW = 2.0 px`, abgerundet (radius = barW/2). → ~123 Balken im Fenster.
- Amplitude → Höhe: symmetrisch um die vertikale Mitte. `half = max(0.8, amp * maxHalf)` mit `maxHalf = h * 0.40`; gezeichnet von `cy − half` bis `cy + half`.

**Färbung:**
- **Vergangen** (`sec ≤ now`): Fill `--sm-accent` (#c47a5e), `globalAlpha = 0.55 + 0.45 * amp` (lautere Stellen kräftiger).
- **Kommend** (`sec > now`): Fill `--sm-text` (#ebe2d6), `globalAlpha = 0.16` (blass).
- **Außerhalb der Spur** (`sec < 0` oder `> total`): kein Balken.
- **Kanten-Ausblendung** (Tweak `edgeFade`, default an): innerhalb der letzten 56 px links/rechts skaliert Alpha linear auf 0 — die Welle „löst sich auf", statt hart abzuschneiden.

**Jetzt-Linie (Playhead):** auf dem Canvas ein 2 px breites Rechteck an `cx`, von `y=6` bis `y=h−6`, Fill `--sm-accent-glow` (#d68a6e) mit `shadowBlur: 12` in derselben Farbe (Glühen).

**Marker (DOM, über dem Canvas):**
- **Dreieck** an der Spitze der Linie: 10 px breit, 6 px hoch, `border-top: 6px solid var(--sm-accent-glow)`, `top: −2`.
- **Puls-Punkt** am unteren Ende: 7×7 px Kreis, `--sm-accent-glow`, `bottom: −3`. Pulsiert via `@keyframes nowPulse` (1.8 s ease-out infinite, Box-Shadow-Ring 0→9 px) **nur wenn `playing && !dragging`**.

### 2. Drag-Scrub (auf dem Wave-Fenster-Wrapper)
Pointer-Events auf dem Wrapper-Div (`touchAction: none`, Pointer-Capture):

| Phase | Verhalten |
|---|---|
| `pointerdown` | `pxPerSec` aus aktueller Wrapper-Breite & `windowSec` berechnen. `startX`, `startNow = now`, `wasPlaying` merken. **`setPlaying(false)`** (Greifen pausiert). |
| `pointermove` | `dx = clientX − startX`. **`newNow = startNow − dx / pxPerSec`** (Welle nach rechts ziehen = zurück), geklemmt `0…total`. `now` setzen. |
| `pointerup` / `cancel` | Pointer-Capture lösen. Wenn `wasPlaying && now < total`: **`setPlaying(true)`** (Loslassen läuft weiter). |

Presses auf `button` oder `[data-no-scrub]` (Statusbar, Close, Fortschritts-Indikator) lösen **kein** Scrub aus.

> **Hit-Target:** Im Prototyp ist die Greif-Fläche das ganze 188 px hohe Band über volle Breite. Das ist üppig — auf nativ unverändert großzügig lassen.

### 3. Zentrale Restzeit / Live-Position
- **Ruhend** (`!dragging`): `NOCH 20:16` — Geist 12.5 px, `letter-spacing: 0.22em`, uppercase, `--sm-text-3`; die Zahl in `--sm-accent-text`. Sonderzustände: `Pausiert` (wenn `!playing`), `Beendet` (wenn `completed`). `font-variant-numeric: tabular-nums`.
- **Während Drag**: ersetzt durch große Live-Position — Newsreader 30 px, `--sm-text`, dahinter `/ {gesamt}` in `--sm-text-3` (18 px). So sieht man beim Spulen exakt, wo man landet.

### 4. Fortschritts-Indikator (Tweak `progressStyle`) — **3 Optionen zur Auswahl**
Zusätzlicher Gesamtfortschritt neben dem Fenster. Im Prototyp per Tweak umschaltbar; **eine** Variante final wählen.

- **`mini` (Default) — Mini-Übersicht.** Ein `<canvas>` (321×30) zeigt die **gesamte Spur** komprimiert: 1-px-Balken im 2-px-Raster, gespielter Teil in `--sm-accent` (alpha 0.85), Rest in `--sm-text` (alpha 0.14). Marker = senkrechte Glow-Linie + 2.4-px-Punkt an der aktuellen Position. **Selbst ziehbar** = absolutes Seek (Tap/Drag an Position p → `now = p * total`). `top: 650`.
- **`bar` — Schlanker Balken.** `left/right: 36`, Höhe 3 px, Track `rgba(235,226,214,0.10)`, Fill `--sm-accent` mit `width: progress%`. `top: 666`. (Nicht interaktiv.)
- **`keiner` — Nur Wellenfarbe.** Kein Zusatz-Element; allein die kupfern/blasse Färbung im Fenster trägt die Information.

### 5. Play/Pause (`PlayPause`)
- 74×74 Kreis, `linear-gradient(180deg, --sm-accent-glow, --sm-accent-soft)`, Glyph-Farbe `#2a1208`.
- `box-shadow: 0 16px 38px -12px rgba(196,122,94,0.6), inset 0 0 0 1px rgba(214,138,110,0.35)`.
- Play-Glyph: Dreieck `M8 4.5 L21 13 L8 21.5 Z`. Pause: zwei Rundrechtecke (4.2×16, rx 1.4).
- Press-Feedback `scale(0.95)`. Bei `completed` startet ein Tap die Sitzung neu.

### 6. Close-Button (`CloseBtn`)
- `top: 60, left: 20`, 40×40, kreisrund, `background: rgba(235,226,214,0.05)`, Border `1px rgba(235,226,214,0.08)`. X-Glyph 16×16, `stroke-width 1.6`.
- Im Prototyp setzt er den Player auf `0.22 * total` zurück (Demo). In der App: Sitzung schließen.

### 7. Status Bar
Inline im `waveform-player.jsx` (Zeit 9:41 + Signal/Wifi/Battery). Durch hauseigene System-Statusbar ersetzen. `data-no-scrub`, damit Presses hier kein Scrub auslösen.

---

## Waveform berechnen (der eigentliche Engineering-Teil)

Im Prototyp ist die Welle synthetisch (`buildWave()` — dichte Sprache am Anfang/Ende, ruhige Mitte mit gestreuten gesprochenen „Cue-Inseln"). In der App **einmalig beim Import** aus der Audiodatei berechnen und cachen:

1. **Datei dekodieren** — Web: `AudioContext.decodeAudioData(arrayBuffer)`; iOS: `AVAudioFile` → PCM-Buffer; Android: `MediaCodec`/`MediaExtractor` bzw. Audio-Lib.
2. **Mono-Mix** (oder erster Kanal) in gleich große **Buckets** aufteilen. Prototyp: **`BUCKETS_PER_SEC = 4`** → bei 26 min ≈ 6240 Werte. 4–10 Buckets/s sind ein guter Bereich (genug Detail fürs Fenster, klein genug zum Cachen).
3. Pro Bucket den **Peak** (max. Absolutwert) — alternativ RMS — berechnen → Array aus Werten in `[0, 1]`, auf das Maximum normalisiert.
4. Array **mit dem Meditations-Datensatz speichern/cachen** (SwiftData/Core Data/Room/SQLite). Dann ist die Welle ohne erneutes Dekodieren sofort da.

`total` = Gesamtdauer in Sekunden. Bucket-Index → Zeit: `sec = i / BUCKETS_PER_SEC`. Sampling im Fenster: `i = round(sec * BUCKETS_PER_SEC)`, außerhalb `[0, len)` = kein Balken.

**Performance:** Dekodieren ist der teure Schritt — off-main-thread beim Import, mit Ladezustand. Das Zeichnen ist trivial (nur die ~120 sichtbaren Balken pro Frame). Auf nativ idealerweise in einen `CADisplayLink`/`Choreographer`-getriebenen Canvas/`Canvas`-Draw, nicht via Layout.

**Fallback:** Schlägt die Dekodierung fehl (DRM, exotisches Format), das Fenster auf eine schlichte Mittellinie + blasses Raster reduzieren — Funktion (Scrub, Zeiten) bleibt voll erhalten, nur die Amplituden fehlen.

---

## Audio & Wiedergabe

Im Prototyp simuliert ein `requestAnimationFrame`-Loop den Playhead: `now += dt * demoSpeed`, gestoppt bei `total` (→ `completed`). **In der App durch echtes Audio ersetzen:**

- **Play/Pause** steuert die Wiedergabe ab `now`.
- **Drag** setzt die Abspielposition (Seek). Greifen pausiert, Loslassen nimmt die Wiedergabe wieder auf (wenn vorher aktiv). Während des Drags **kein** Audio (kein Scrubbing-Sound gewünscht — bewusste Entscheidung „Greifen pausiert, Loslassen weiter").
- **Source of truth:** Abspielposition aus dem Audio-Player ableiten (`currentTime`), nicht aus einem eigenen Frame-Counter, damit Hintergrund/Suspend sauber recovern.

---

## Interaktionen & Verhalten

| Trigger | Effekt |
|---|---|
| Wiedergabe läuft | Welle scrollt nach links (Zeit läuft), Jetzt-Punkt pulsiert. |
| Play/Pause tippen | Wiedergabe ab `now` / Pause. Bei `completed` → Neustart. |
| Welle greifen (`pointerdown`) | Pausiert. Live-Position erscheint zentral. Puls stoppt. |
| Welle ziehen (`pointermove`) | `now` folgt: links = vor, rechts = zurück (`now = startNow − dx/pxPerSec`). |
| Loslassen (`pointerup`) | War vorher Wiedergabe aktiv → läuft weiter. Sonst bleibt pausiert. |
| Mini-Übersicht tippen/ziehen | Absolutes Seek auf die getippte Position (nur bei `progressStyle = mini`). |
| Close (×) | Sitzung schließen (im Prototyp: Demo-Reset). |
| Ende erreicht | `completed`, Wiedergabe stoppt, Restzeile zeigt „Beendet". |

**Animationen:** Puls 1.8 s ease-out infinite (nur aktiv & nicht ziehend). Press-Feedback `scale(0.95)`. Kanten-Fade ist statisch (Alpha-Rampe im Draw). **Reduced Motion** (`prefers-reduced-motion`): Puls aus, Scroll ggf. ruckweise pro Sekunde statt kontinuierlich — die Information steckt in Zahl + Position.

---

## State Management

```ts
type PlayerState = {
  total: number;        // Gesamtdauer (s) — aus der Audiodatei
  now: number;          // aktuelle Position (s), 0..total
  playing: boolean;     // läuft die Wiedergabe?
  completed: boolean;   // Ende erreicht
  dragging: boolean;    // wird gerade gescrubbt?
};

// Drag-Snapshot (während einer Geste):
type DragRef = {
  startX: number;       // clientX bei pointerdown
  startNow: number;     // now bei pointerdown
  pxPerSec: number;     // breite / windowSec
  wasPlaying: boolean;  // lief vor dem Greifen?
};

const remaining = total - now;
const progress  = now / total; // 0..1
```

- `dragging` **pausiert den Ticker** (kein Auto-Advance während Scrub).
- Beim Loslassen: `playing = wasPlaying && now < total`.
- Waveform-Array ist **abgeleiteter/gecachter** State pro Meditation (nicht pro Frame neu berechnen).

---

## Design Tokens

Alle Tokens aus `styles.css` (im Bundle). Auszug:

### Farben
| Token | Verwendung | Hex / Wert |
|---|---|---|
| `--sm-accent` | Vergangene Wellenbalken, Mini-Fill, Bar-Fill | `#c47a5e` |
| `--sm-accent-soft` | Play-Button-Gradient (unten) | `#b06a4f` |
| `--sm-accent-glow` | Jetzt-Linie, Marker, Play-Gradient (oben) | `#d68a6e` |
| `--sm-accent-text` | Artist, Restzeit-Zahl | `#d99a7e` |
| `--sm-text` | Titel, kommende Balken (alpha 0.16), Live-Position | `#ebe2d6` |
| `--sm-text-2` | (Hilfstexte) | `#a89a8c` |
| `--sm-text-3` | Restzeit-Label, Hinweise, „/ gesamt" | `#6f6358` |
| Auf-Akzent (Glyph) | Play/Pause-Icon | `#2a1208` |

Phone-Hintergrund: `radial-gradient(ellipse 90% 70% at 50% 28%, #3a201a 0%, #2a1610 38%, #190c08 72%, #110705 100%)`.

### Typografie
| Stelle | Family | Size | Weight | Letter-Spacing |
|---|---|---|---|---|
| Titel | Newsreader | 33 | 400 | −0.015em |
| Artist | Newsreader Italic | 18 | 400 | — |
| Live-Position (Drag) | Newsreader | 30 | 400 | — |
| Restzeit-Label | Geist | 12.5 | 400 | 0.22em (uppercase) |
| Spul-Hinweis | Geist | 10.5 | 400 | 0.16em (uppercase) |
| Atem-Hinweis | Newsreader Italic | 15 | 400 | — |
| Statusbar-Zeit | SF Pro Text | 15 | 600 | — |

Alle Zeit-Zahlen mit `font-variant-numeric: tabular-nums`.

### Maße / Spacing
- Wave-Fenster: Höhe **188**, `barStep 3.2`, `barW 2.0`, `maxHalf = h*0.40`, Kanten-Fade 56 px.
- `pxPerSec = breite / windowSec` (Default `windowSec = 60` → ±30 s sichtbar).
- Mini-Übersicht: 321×30, 1-px-Balken im 2-px-Raster.
- Play/Pause 74×74; Close 40×40; Radius durchgehend kreisrund bzw. Phone-Bezel 48.

---

## Tweaks (Prototyp-Parameter → finale Defaults wählen)

Der Prototyp exponiert diese Stellschrauben (Panel „Tweaks"). Sie sind **Design-Parameter**, keine Endnutzer-Einstellungen:

| Tweak | Range | Default | Bedeutung |
|---|---|---|---|
| Demo-Tempo | 1–30× | 3× | **nur Prototyp** (damit man das Scrollen sieht). In der App = 1× Echtzeit. |
| Gesamtlänge | 10–40 min | 26 | Demo-Spurlänge. In der App = echte Dateilänge. |
| `windowSec` | 20–120 s | 60 | sichtbare Zeitspanne im Fenster (= ±30 s bei 60). |
| `edgeFade` | bool | true | Kanten der Welle weich ausblenden. |
| `progressStyle` | mini / bar / keiner | mini | **Hier final entscheiden** (siehe Komponente 4). |
| `showDragHint` | bool | true | „← → ziehen zum spulen" unter dem Fenster. |
| `showBreathHint` | bool | true | „atme tief ein …" nur ganz am Anfang (`progress < 0.04`). |

---

## Plattform-Implementations-Hinweise

### iOS / SwiftUI
- Welle in einem **`Canvas`** zeichnen (oder `TimelineView(.animation)` für kontinuierliches Scrollen). Pro Balken `sec = now + (x − cx)/pxPerSec`, Amplitude aus dem gecachten Array, symmetrisch um die Mitte mit `RoundedRectangle`-Pfaden bzw. `addPath`.
- Jetzt-Linie als separater `Capsule`/`Rectangle` mit `.shadow(color: glow, radius: 12)`.
- Scrub: `DragGesture` → `now = startNow − gesture.translation.width / pxPerSec`, `onChanged` pausiert, `onEnded` nimmt ggf. wieder auf. Bei `DragGesture(minimumDistance: 0)` reagiert auch ein Tap.
- Mini-Übersicht ebenfalls als `Canvas` + eigene `DragGesture` (absolutes Seek).

### Android / Jetpack Compose
- Welle in einem `Canvas { … }`; `drawRoundRect` pro Balken. `now` als animierbarer/aus dem Player abgeleiteter Float.
- Scrub via `Modifier.pointerInput { detectDragGestures(onDragStart = { pause() }, onDrag = { _, delta -> now -= delta.x / pxPerSec }, onDragEnd = { resumeIfWasPlaying() }) }`.
- DPI: in `dp` rechnen, `pxPerSec` aus der gemessenen Canvas-Breite.

### Plattform-übergreifend
- **Echtzeit:** Demo-Tempo entfällt; `now` = `player.currentTime`.
- **Sampling-Auflösung** (Buckets/s) und **`windowSec`** bestimmen die wahrgenommene „Geschwindigkeit" der Welle — Defaults aus den Tweaks übernehmen und auf echtem Gerät gegenchecken.
- **Wake-Lock** während Wiedergabe sinnvoll (`isIdleTimerDisabled` / `FLAG_KEEP_SCREEN_ON`), falls der Screen sichtbar bleibt.

---

## Accessibility

- **Scrub als Slider exponieren:** `role="slider"` / `accessibilityValue`, `aria-valuemin/now/max`, `accessibilityValueText` als Zeit („zwölf Minuten dreißig"). Tastatur/Rotor: ←/→ = ∓5 s o. ä.
- **Play/Pause** & **Close** mit klaren Labels („Wiedergabe pausieren", „Sitzung schließen").
- **Restzeit** als (sparsame) Live-Region — nicht jede Sekunde vorlesen.
- **Welle ist dekorativ** (`accessibilityHidden`) — die Information steckt in Zeit + Slider-Wert; doppelte Auslesung vermeiden.
- **Kontrast:** Titel/Restzeit-Zahl auf dem dunklen BG > AA. Die blassen kommenden Balken (alpha 0.16) sind bewusst niedrigkontrastig (dekorativ).

---

## Assets
- **Fonts:** Newsreader + Geist (Google Fonts) — in der App durch native Pendants ersetzbar (z. B. New York + SF Pro auf iOS).
- **Icons:** Inline-SVG (Play, Pause, Close, Pfeil-Hinweis, Statusbar). In das hauseigene Icon-System überführen.
- **Keine Bitmaps**, keine Lizenzfragen. Die Waveform ist Vektor/Canvas, keine Bilddatei.

---

## Dateien in diesem Bundle

| Datei | Inhalt |
|---|---|
| `Waveform Player.html` | Lauffähiger Prototyp (im Browser öffnen). Welle ziehen zum Spulen; „Tweaks" oben justiert Parameter. |
| `waveform-player.jsx` | `buildWave`/`sampleWave` (Wellen-Generator), `WaveWindow` (Canvas-Tonkopf), `MiniOverview`, `WaveformPlayer` (Komposition + Scrub + Ticker), `PlayPause`, `StatusBar`, `CloseBtn`, Tweaks-Mount. |
| `tweaks-panel.jsx` | Tweaks-Shell + Controls (nur Prototyp-Infrastruktur, nicht Teil des Produkts). |
| `styles.css` | Alle CSS-Variablen + Basisklassen (`--sm-*`-Tokens, `.phone`, `.press`, …). |

---

## Out of Scope dieses Handoffs
- **Trim/Wiedergabe-Bereich** (Start/Ende-Zuschnitt) — eigener Handoff (`design_handoff_trim_waveform`). Falls ein Trim gesetzt ist, sollte der Player das Fenster sinnvollerweise auf `[start, end]` begrenzen — Detail-Pass nötig.
- **Geschwindigkeits-/Sleep-Timer/AirPlay**-Steuerungen — nicht Teil dieses Screens.
- **Library-/Detail-Screen**, von dem aus der Player geöffnet wird.
- **Audio-Decoding-Pipeline** jenseits der oben skizzierten Schritte.
- **Haptik** beim Spulen (bewusst weggelassen; bei Bedarf separat).

## Was sich gegenüber dem alten Player ändert (Kontext)
1. **Slider → echte Waveform.** Der dünne Punkt-Slider wird durch das scrollende Wellen-Fenster ersetzt — unverkennbar Audio statt generischer Timer.
2. **`±10s`-Buttons entfallen.** Spulen geschieht durch direktes Ziehen der Welle (plus optional Tap auf die Mini-Übersicht). Weniger Chrome, direktere Geste.
3. **Restzeit bleibt dezent & zentral** („Noch 15:35"), wird beim Spulen kurz zur präzisen Live-Position.
4. **Gesamtfortschritt** optional als Mini-Übersicht der ganzen Spur — Kontext „wo bin ich insgesamt", den ein reines Fenster nicht zeigt.
