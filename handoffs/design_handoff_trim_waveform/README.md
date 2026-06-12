# Handoff: Wiedergabe-Bereich — Waveform-Trim-Editor

## Übersicht

Feature für die Meditations-App **„Still Moment"**: Geführte Meditationen haben oft eine **Einleitung, Schlussworte oder Werbung**, die der Nutzer nicht hören möchte. Im Bearbeiten-Dialog einer importierten Meditation kann er deshalb optional festlegen, dass die **Wiedergabe erst bei Zeitmarke X beginnt und bei Y endet**.

Dieser Handoff beschreibt, wie man die passende Zeitmarke **schnell und intuitiv findet**: über einen Vollbild-Editor mit **Wellenform-Darstellung**. Die dichten Sprach-Blöcke am Anfang/Ende heben sich sichtbar von der stillen Meditation in der Mitte ab — der Nutzer zieht die Griffe direkt an die Kante, ohne sich durchhören zu müssen.

**Wichtig:** Die Audiodatei selbst bleibt **unverändert**. Gespeichert werden nur zwei Zeitmarken (`start`, `end`); die Wiedergabe wird zur Laufzeit auf dieses Intervall begrenzt.

> In der Design-Exploration gab es drei Spur-Darstellungen (Wellenform / Marker / nackter Slider). **Gewählt wurde die Wellenform** — diese Handoff-Version enthält ausschließlich diese (Slider-/Marker-Code wurde entfernt).

## Über die Design-Dateien

Die Dateien in diesem Bundle sind **HTML-Design-Referenzen** — ein lauffähiger Prototyp, der Aussehen und Verhalten zeigt, **kein Produktionscode zum direkten Kopieren**. Aufgabe: Diese Designs in der Ziel-Codebase mit deren etablierten Patterns nachbauen (SwiftUI für iOS, Jetpack Compose für Android, React Native, Flutter — je nach Stack).

Falls noch keine Codebase existiert: empfohlen **SwiftUI** (iOS) oder **Jetpack Compose** (Android) — die Audio-Dekodierung und der weiche, gradient-lastige Look profitieren von nativen Pipelines.

## Fidelity

**High-fidelity (hifi).** Maße, Farben, Typografie und Interaktionen sind final und pixelgenau nachzubauen. Die einzige bewusst „simulierte" Stelle ist die Audio-Wiedergabe (im Prototyp ein requestAnimationFrame-Playhead) — in der App durch echtes Audio zu ersetzen (siehe „Audio & Wiedergabe").

## Screenshots

Im Ordner `screenshots/` (rein als visuelle Referenz; maßgeblich sind der Prototyp + die Specs unten):

| Datei | Zustand |
|---|---|
| `01-formular-ungetrimmt.png` | Bearbeiten-Formular, Zeile „Wiedergabe-Bereich" = „Ganze Datei" |
| `02-editor-wellenform.png` | Vollbild-Editor offen, Wellenform mit Griffen, Zeit-Blase, Transport |
| `03-formular-getrimmt.png` | Formular nach dem Zuschneiden: Mini-Wellenform + Zeitraum + „Zuschnitt entfernen" |

---

## Screens / Views

Das Feature besteht aus **(1)** einer Zeile im Bearbeiten-Formular und **(2)** dem Vollbild-Editor, der als Sheet von unten einfährt.

### View 1 — Formular-Zeile „Wiedergabe-Bereich"

Eine tippbare Karte im bestehenden „Meditation bearbeiten"-Screen (zwischen den Metadaten-Feldern und dem Gong-Toggle).

**Zwei Zustände:**

- **Ungetrimmt (Default):** Zeigt „Ganze Datei · 19:05" (Newsreader 19 px) links, rechts „Bereich wählen" (`--sm-accent-text`, 13.5 px) mit Scheren-Icon (15×15). Tippen öffnet den Editor.
- **Getrimmt:** Zeigt eine **statische Mini-Wellenform** (Höhe 44 px, nicht interaktiv, hervorgehobener Bereich) und darunter den Zeitraum „1:24 – 18:30" (Newsreader 22 px, `--sm-accent-text`) links sowie „17:02 hörbar" (12.5 px, `--sm-text-2`) rechts. Zusätzlich darunter ein Textlink **„Zuschnitt entfernen"** (13 px, `--sm-text-2`), der auf den ungetrimmten Zustand zurücksetzt.

Karte: `.card`-Stil (`--sm-card`, 1 px `--sm-card-line`, `border-radius: var(--sm-r-lg)` = 24 px), Padding 14/16. Kopfzeile: Label „WIEDERGABE-BEREICH" (siehe `metaLbl`) + Chevron-rechts (18×18, `--sm-text-3`).

Erläuternder Hilfetext darunter (12 px, `--sm-text-3`, line-height 1.5):
> „Überspringe Einleitung oder Schlussworte — die Wiedergabe läuft nur zwischen diesen Punkten. Die Datei selbst bleibt unverändert."

### View 2 — Vollbild-Editor „Zuschneiden" (Sheet)

Fährt als Sheet von unten ein (`transform: translateY(100% → 0)`, `transition: 0.4s cubic-bezier(0.32, 0.72, 0, 1)`), `position: absolute; inset: 0; z-index: 20`. Hintergrund = derselbe radiale Phone-Gradient (siehe Tokens).

**Layout (oben → unten), Frame 393 × 852:**

```
┌───────────────────────────────────────┐
│ Status Bar (54 px)                    │
├───────────────────────────────────────┤
│  ‹            Zuschneiden      Fertig  │  Nav, height 44
│                                       │
│           Evening Wind Down           │  Newsreader 22, zentriert
│         Tara Goldstein · 19:05        │  13 px, --sm-text-2
│                                       │
│              BEGINNT BEI              │  metaLbl (aktiver Punkt)
│                1:24                   │  Newsreader 60, --sm-accent-text
│      Hörbar: 1:24 – 18:30 · 17:02     │  13 px, --sm-text-2
│                                       │
│  ▕░░░▌█████████████████████▐░░░▏      │  Wellenform, height 108
│  0:00          3:12          19:05    │  Achsen-Labels 11 px
│                                       │
│  ┌────────────┐  ┌────────────┐       │  Readout-Karten Anfang/Ende
│  │ ANFANG     │  │ ENDE       │       │  aktive Karte glüht (accent-dim)
│  │ 1:24       │  │ 18:30      │       │
│  └────────────┘  └────────────┘       │
│                                       │
│       −1s     ( ▶ )     +1s           │  Transport, gap 16
│      Ab dem markierten Punkt vorhören │  12 px, --sm-text-3
│                                       │
│          Ganze Datei verwenden        │  13 px Textlink, unten
└───────────────────────────────────────┘
```

---

## Komponenten (Editor)

### 1. Navigation
- **Zurück** (`‹`): Chevron-left 22×22, `--sm-text-2`. Schließt Sheet ohne zu speichern (Werte verwerfen).
- **Titel** „Zuschneiden": Newsreader 17 px, `--sm-text`, absolut zentriert.
- **Fertig**: Geist 15 px, weight 500, `--sm-accent-text`. Schreibt `{start, end}` zurück und schließt.

### 2. Großer Wert-Readout
- Label (metaLbl): „BEGINNT BEI" wenn der aktive Punkt der Anfang ist, sonst „ENDET BEI".
- Zahl: **Newsreader 60 px**, `--sm-accent-text`, line-height 1, `font-feature-settings: "tnum"`. Zeigt immer den **aktiven** Punkt.
- Unterzeile: „Hörbar: {start} – {end} · {dauer}", 13 px, `--sm-text-2`.
- Section `margin-top: 26 px`.

### 3. Wellenform (`TrimTrack`, variant `"wave"`) — Kernkomponente
Datei: `trim-editor.jsx`. Container: `position: relative; width: 100%; height: 108px; touch-action: none; user-select: none`.

- **Balken:** Genau **`N` Balken** (Prototyp: `N = 220`), als Flex-Row, `gap: 1px`, `padding: 0 1px`, vertikal zentriert. Jeder Balken: `flex: 1`, `height = max(2px, amplitude * 108px)`, `border-radius: 2px`.
  - **Innerhalb** des Bereichs `[start, end]`: Farbe `--sm-accent` (`#c47a5e`).
  - **Außerhalb:** `rgba(168,154,140,0.18)`. Übergang `background 0.12s ease`.
  - Amplituden-Quelle siehe **„Wellenform berechnen"** unten.
- **Bereichs-Highlight:** Box von `start%` bis `end%`, `top/bottom: -4px`, `background: rgba(196,122,94,0.12)`, linke/rechte Kante `1px rgba(214,138,110,0.35)`, `border-radius: 4px`, `pointer-events: none`.
- **Playhead:** Senkrechte Linie an Position `head`, `width: 2px`, `--sm-accent-glow`, `box-shadow: 0 0 8px rgba(214,138,110,0.8)`. Nur sichtbar während Wiedergabe/Vorschau bzw. beim Ziehen.
- **Zwei Griffe** (Anfang/Ende):
  - Hit-Area: `width: 30px` (zentriert per `margin-left: -15px`), volle Höhe + 12 px oben/unten, `cursor: ew-resize`. Mindest-Touch-Target 44 px in der App sicherstellen.
  - Sichtbarer Pill: `width: 7px`, volle Höhe, `border-radius: 5px`, `linear-gradient(180deg, --sm-accent-glow, --sm-accent-soft)`, `box-shadow: 0 2px 8px rgba(0,0,0,0.45), inset 0 0 0 1px rgba(255,255,255,0.18)`. Innere Kerbe: `2 × 16px`, `rgba(42,18,8,0.5)`.
  - **Aktiver Griff pulsiert:** Animation `trimHandlePulse` 1.8 s ease-out infinite (Box-Shadow-Ring 0→7 px, siehe `<style>` in der HTML). Puls **stoppt während des Ziehens** (dann zählt Präzision).
  - **Zeit-Blase:** Über dem aktiven bzw. gerade gezogenen Griff. `top: -30px`, zentriert, `background: --sm-accent-glow`, `color: #2a1208`, Newsreader 15 px weight 500, `padding: 3px 9px`, `border-radius: 8px`, `box-shadow: 0 4px 12px rgba(0,0,0,0.4)`, `tnum`. Zeigt `fmt(value)`.
- **Achsen-Labels** darunter (`margin-top: 12px`): „0:00", aktuelle `head`-Zeit (mittig, glüht bei Wiedergabe), „19:05" — 11 px, `--sm-text-3`, `tnum`.
- **Mindestabstand:** `onChange` klemmt so, dass zwischen Anfang und Ende **immer ≥ 25 s** liegen.

### 4. Readout-Karten „Anfang" / „Ende"
- Flex, `gap: 10px`, `margin-top: 24px`. Wählen den **aktiven** Punkt (steuert großen Readout, Nudges, Vorschau-Ziel).
- Karte: `border-radius: 14px`, `padding: 10px 14px`. Aktiv: `background: --sm-accent-dim`, Border `rgba(214,138,110,0.4)`. Inaktiv: `background: rgba(235,226,214,0.04)`, Border `--sm-card-line`.
- Label (metaLbl) + Wert (Newsreader 26 px, aktiv `--sm-accent-text` sonst `--sm-text`, `tnum`).

### 5. Transport-Reihe
- Flex, zentriert, `gap: 16px`, `margin-top: 24px`.
- **−1s / +1s:** `min-width: 58px`, `height: 46px`, `border-radius: 999px`, Border `--sm-card-line`, `background: rgba(235,226,214,0.05)`, Geist 15 px, `tnum`. Verschieben den **aktiven** Punkt um exakt 1 s und lösen eine kurze Vorschau aus (1.5 s).
- **Play/Pause (Mitte):** `66 × 66px` Kreis, `linear-gradient(180deg, --sm-accent-glow, --sm-accent-soft)`, `color: #2a1208`, `box-shadow: 0 12px 30px -8px rgba(196,122,94,0.6), inset 0 0 0 1px rgba(214,138,110,0.3)`. Icon 28 px (Play hat `margin-left: 3px` zur optischen Zentrierung). Spielt durchgehend ab dem aktiven Punkt; erneutes Tippen pausiert.
- Caption darunter (`margin-top: 12px`, 12 px, `--sm-text-3`): „Ab dem markierten Punkt vorhören".

### 6. „Ganze Datei verwenden"
Textlink unten zentriert (Geist 13 px, `--sm-text-2`). Setzt `start = 0`, `end = TOTAL`. Wird beim „Fertig" als „kein Zuschnitt" interpretiert (siehe State).

---

## Wellenform berechnen (der eigentliche Engineering-Teil)

Im Prototyp ist die Wellenform synthetisch. In der App wird sie **einmalig beim Import** aus der Audiodatei berechnet und gecacht:

1. Datei dekodieren — Web: `AudioContext.decodeAudioData(arrayBuffer)`; iOS: `AVAudioFile` → PCM-Buffer; Android: `MediaCodec`/`AudioTrack` bzw. eine Audio-Lib.
2. Erste Kanal-Samples (oder Mono-Mix) in **`N` gleich große Buckets** aufteilen (Prototyp: `N = 220`).
3. Pro Bucket den **Peak** (max. Absolutwert) — alternativ RMS — berechnen → ein Array aus `N` Werten in `[0, 1]`, ggf. auf das Maximum normalisiert.
4. Dieses Array **zusammen mit dem Meditations-Datensatz speichern/cachen** (SQLite/Room/SwiftData/Core Data). Dann ist die Spur ohne erneutes Dekodieren sofort verfügbar.

`TOTAL` = Gesamtdauer der Datei in Sekunden (hier 1145 s = 19:05). Balken-Index → Zeit: `sec = (i / N) * TOTAL`.

**Performance:** Dekodieren ist der teure Schritt — im Hintergrund/Off-Main-Thread beim Import erledigen, mit Ladezustand. Das Zeichnen ist trivial.

**Fallback:** Schlägt die Dekodierung fehl (DRM, exotisches Format), zeigt der Editor statt Balken eine schlichte Linie (Slider-Look) — Funktion bleibt voll erhalten, nur der visuelle Hinweis fehlt.

---

## Audio & Wiedergabe

Im Prototyp simuliert ein `requestAnimationFrame`-Loop (`usePlayhead`) den Playhead. **In der App durch echtes Audio ersetzen** (`<audio>` / `AVPlayer` / `ExoPlayer`):

- **Durchgehende Wiedergabe** (Play-Button): ab aktivem Punkt abspielen, Icon zeigt Pause.
- **Kurze Vorschau** (Nudge & Loslassen eines Griffs): ab dem Punkt **~1.5–2.6 s** abspielen, dann stoppen und Playhead zurück auf den Punkt setzen.

**Zwei getrennte Zustände** (`usePlayhead` gibt `playing` und `previewing` zurück):
- `playing` = durchgehende Wiedergabe → **steuert allein das ▶/⏸-Icon**.
- `previewing` = kurze Vorschau → zeigt nur Playhead/Glühen, **lässt den Play-Button ruhig** (kein Flackern). Konvention: ein Aufruf mit Zeitlimit (`ms`) ist Vorschau, ohne Limit ist durchgehend.

**Eigentliches Feature-Verhalten zur Laufzeit (außerhalb des Editors):** Beim Abspielen der Meditation startet die Wiedergabe bei `start` und endet (Stopp oder sanftes Ausblenden) bei `end`. Die Datei wird **nicht** geschnitten.

---

## Interaktionen & Verhalten

| Trigger | Effekt |
|---|---|
| Tap auf Formular-Zeile „Wiedergabe-Bereich" | Editor-Sheet fährt von unten ein. Ungetrimmt startet er bei `0:00–19:05`. |
| Tap „Anfang" / „Ende"-Karte | Wechselt den aktiven Punkt (großer Readout, Nudges, Vorschau folgen ihm); aktive Karte glüht. |
| Griff ziehen | Setzt Anfang bzw. Ende kontinuierlich (`x → Zeit`), Playhead + große Zahl + Zeit-Blase folgen live. **Beim Loslassen:** kurze Vorschau (2.6 s). Mindestabstand 25 s. |
| `−1s` / `+1s` | Aktiven Punkt um 1 s verschieben (klemmt 0…TOTAL) + kurze Vorschau (1.5 s). |
| Play/Pause | Durchgehende Wiedergabe ab aktivem Punkt / Pause. |
| „Ganze Datei verwenden" | `start=0`, `end=TOTAL`. |
| „Fertig" | Schreibt `{start, end}` zurück ins Formular und schließt. Ist der Bereich praktisch die ganze Datei (`start ≤ 1` **und** `end ≥ TOTAL−1`), wird als `null` (kein Zuschnitt) gespeichert. |
| „Zurück" (‹) | Schließt ohne zu speichern. |
| „Zuschnitt entfernen" (Formular) | Setzt Trim auf `null` zurück. |

**Animationen:** Sheet-Slide 0.4 s `cubic-bezier(0.32, 0.72, 0, 1)`. Griff-Puls 1.8 s ease-out infinite (nur aktiver Griff, nicht beim Ziehen). Balken-Farbwechsel 0.12 s. Press-Feedback `scale(0.98)` (`.press`).

---

## State Management

```ts
// Pro Meditation gespeichert:
type Trim = { start: number; end: number } | null;  // Sekunden; null = ganze Datei

// Editor-intern (TrimSheet):
type EditorState = {
  start: number;          // Sek
  end: number;            // Sek, immer ≥ start + 25
  active: "start" | "end";
  head: number;           // Playhead-Position (Sek)
  playing: boolean;       // durchgehende Wiedergabe → steuert ▶/⏸
  previewing: boolean;    // kurze Vorschau → lässt Button ruhig
};
```

- Editor-Werte werden beim Öffnen aus dem gespeicherten `Trim` initialisiert (oder `{0, TOTAL}` wenn `null`).
- „Fertig" committet; „Zurück" verwirft.
- Persistenz: User-Defaults / Room / SwiftData o. Ä., am Meditations-Datensatz.

---

## Design Tokens

Alle Tokens stammen aus `styles.css` (vollständig im Bundle). Auszug:

### Farben
| Token | Hex / Wert |
|---|---|
| `--sm-card` | `#2a1812` |
| `--sm-card-line` | `rgba(235,226,214,0.06)` |
| `--sm-accent` | `#c47a5e` |
| `--sm-accent-soft` | `#b06a4f` |
| `--sm-accent-glow` | `#d68a6e` |
| `--sm-accent-text` | `#d99a7e` |
| `--sm-accent-dim` | `rgba(196,122,94,0.18)` |
| `--sm-text` | `#ebe2d6` |
| `--sm-text-2` | `#a89a8c` |
| `--sm-text-3` | `#6f6358` |
| „Auf-Akzent"-Text (Button/Blase) | `#2a1208` |
| Body / Off-Black | `#0a0604` |

Phone-Hintergrund (auch Sheet): `radial-gradient(ellipse 90% 70% at 50% 20%, #3a201a 0%, #2a1610 40%, #190c08 75%, #110705 100%)`.

### Border-Radius
`--sm-r-sm` 12 · `--sm-r-md` 18 · `--sm-r-lg` 24 · `--sm-r-pill` 999 · Readout-Karten 14 · Zeit-Blase 8 · Phone-Bezel 48.

### Typografie
- **Display:** Newsreader (Google Fonts), Fallback Georgia, serif — Zahlen, Titel.
- **UI:** Geist (Google Fonts), Fallback `-apple-system, "SF Pro Text", system-ui, sans-serif` — Labels, Buttons, Captions.
- Alle Zeit-Zahlen mit `font-feature-settings: "tnum"` (gleiche Ziffernbreite, kein Springen).

| Stelle | Family | Size | Weight |
|---|---|---|---|
| Großer Readout (Zeit) | Newsreader | 60 | 400 |
| Readout-Karten-Wert | Newsreader | 26 | 400 |
| Zeit-Blase | Newsreader | 15 | 500 |
| Editor-Titel / Track-Titel | Newsreader | 17 / 22 | 400 |
| Label (`metaLbl`) | Geist | 11 | 500, ls 0.12em, uppercase |
| Captions / Achsen | Geist | 11–13 | 400 |
| Nudge / „Fertig" | Geist | 15 | 400 / 500 |

`metaLbl` = `{ fontSize: 11, letterSpacing: 0.12em, textTransform: uppercase, color: --sm-text-3, fontWeight: 500 }`.

---

## Assets
- **Fonts:** Newsreader + Geist (Google Fonts). In der App durch native Pendants ersetzbar (z. B. New York + SF Pro auf iOS).
- **Icons:** Inline-SVGs in `trim-editor.jsx` (Play, Pause, Chevron-left/right, Lautsprecher, Schere) und `shell.jsx` (Statusbar). `stroke-width: ~1.6–1.8`, `currentColor`. In das hauseigene Icon-System überführen.
- **Keine Bitmaps**, keine Lizenzfragen.

---

## Dateien in diesem Bundle

| Datei | Inhalt |
|---|---|
| `Trim Editor (Waveform).html` | Lauffähiger Prototyp (im Browser öffnen). Tap auf „Wiedergabe-Bereich" öffnet den Editor. |
| `trim-editor.jsx` | `TrimTrack` (Wellenform + Griffe + Blase + Puls), `TrimSheet` (Editor), `App` (Formular + Flow), `usePlayhead` (Playhead-/Vorschau-Engine), `WAVE`-Generator. |
| `shell.jsx` | `StatusBar`, `Phone`-Wrapper, Icon-Set. |
| `styles.css` | Alle CSS-Variablen + Basisklassen (`.phone`, `.card`, `.press`, `.btn-primary` …). |

---

## Implementations-Hinweise

1. **Geste:** Auf Touch nativen Pan-Recognizer verwenden (SwiftUI `DragGesture`, Compose `detectDragGestures`), nicht Pointer-Polling. Griff-Hit-Area auf ≥ 44 px aufweiten.
2. **`tnum` für alle Zeit-Zahlen** — sonst springt das Layout beim Zählen.
3. **Play-Button ruhig halten:** Nur durchgehende Wiedergabe steuert das ▶/⏸-Icon. Kurze Vorschauen (Nudge/Drag) dürfen es nicht umschalten (sonst Flackern).
4. **Mindestabstand 25 s** zwischen Anfang und Ende erzwingen.
5. **Wellenform off-main-thread** berechnen und cachen; Ladezustand beim Import zeigen.
6. **Reduced Motion:** Griff-Puls und Sheet-Animation bei `prefers-reduced-motion: reduce` reduzieren/abschalten.
7. **Accessibility:**
   - Griffe als Slider exponieren (`role="slider"`, `aria-valuemin/now/max`, `aria-valuetext="1 Minute 24 Sekunden"`). Tastatur: ←/→ = ∓1 s.
   - Anfang/Ende-Karten und Transport als beschriftete Buttons („Eine Sekunde früher" / „Vorhören").
8. **Eigentlicher Trim wirkt nur auf die Wiedergabe** — niemals die Originaldatei verändern.

---

## Out of Scope dieses Handoffs

- Restliche Felder des Bearbeiten-Formulars (Lehrer:in, Name, Gong-Toggle) — bestehen bereits.
- Automatische Kanten-Erkennung / Smart-Vorschläge (separate Exploration „Marker"/„Smart").
- Import-Flow und Audio-Dekodierungs-Pipeline jenseits der oben skizzierten Schritte.
- Der Sitzungs-/Player-Screen, der den Trim zur Laufzeit anwendet (nur Verhalten beschrieben).
