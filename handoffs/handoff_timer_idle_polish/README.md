# Handoff: Timer Idle / Konfigurations-Screen — Polish

## Overview

Dies ist der **Idle-Zustand des Timer-Tabs** der Meditations-App ("Still Moment" o.ä.) — der Screen, auf dem die Nutzer:in vor dem Start einer Sitzung Dauer und Optionen einstellt. Der Screen war zuvor durch konkurrierende Hierarchie-Ebenen (Karten-Raster + −/+ Stepper + zwei Headlines) visuell unruhig. Diese Iteration **Variante A — Ruhig** beruhigt den Screen radikal:

- Eine klare Hierarchie: **Ring = HERO**, Settings als ruhige Liste, ein primärer Action-Button
- Settings werden zu **flachen Listenzeilen** (Label links, Wert rechts, dezenter Chevron) statt Karten
- Die zweite Headline („Passe den Timer an") ist gestrichen
- **−/+ Stepper sind entfernt** — die Zeit wird ausschließlich per Drag im Ring gesetzt
- Das ehemalige Setting **„Einstimmung" wurde entfernt** (Feature-Cut), wodurch nur 4 Settings übrig bleiben → passt komfortabel auch auf iPhone SE
- Kein Scroll im Setting-Bereich — alles statisch, vorhersehbar, ruhig

## About the Design Files

Die Dateien im Ordner `preview/` sind **Design-Referenzen, in HTML/React/Babel als Prototyp gebaut** — nicht produktiver Code zum Übernehmen. Sie zeigen Look, Maße, Verhalten und Interaktionen. Die Aufgabe ist, **dieses Design im Ziel-Codebase pixelgenau nachzubauen** — in dessen etablierter Sprache (SwiftUI, Kotlin/Compose, React Native, Flutter, etc.) und mit dessen Komponenten-, Token- und Styling-Patterns. Wenn noch keine Code-Basis existiert, das passendste Framework wählen.

Öffne `preview/Variant A — SE.html` in einem Browser, um die finale Variante in beiden Geräte-Größen (iPhone SE und iPhone 15 Pro) nebeneinander zu sehen.

## Fidelity

**High-fidelity (hifi).** Finale Farben, Typografie, Maße und Mikro-Interaktionen sind festgelegt. Werte können direkt aus dieser README oder aus den Quelldateien übernommen werden.

---

## Screen — Timer Idle (Konfiguration)

**Name:** Timer Idle / Set Up Session
**Purpose:** Nutzer:in stellt Sitzungs-Dauer und optionale Begleit-Settings ein, bevor sie auf „Beginnen" tippt.

### Layout (vertikaler Stack, top → bottom)

```
┌─────────────────────────────────┐
│  Status Bar (54 px)             │
├─────────────────────────────────┤
│                                 │
│   Headline (single line)        │
│   "Wie viel Zeit schenkst…"     │
│                                 │
│   ●─── Ring mit Wert ───●       │  ← HERO
│       <Zahl>  Minuten           │
│                                 │
│   ─────────────────────         │
│   Vorbereitung      15 Sek. ›   │
│   ─────────────────────         │
│   Gong         Tempelglocke ›   │
│   ─────────────────────         │
│   Intervall          5 Min. ›   │
│   ─────────────────────         │
│   Hintergrund         Regen ›   │
│   ─────────────────────         │
│                                 │
│         [▶ Beginnen]            │
│                                 │
├─────────────────────────────────┤
│   Tab Bar (Pill, 96 px)         │
└─────────────────────────────────┘
```

### Responsive Breakpoints

Wir liefern zwei Größen-Tunings — **kein** echter Reflow, nur Werte-Skalierung:

| Token            | iPhone SE (375×667) | iPhone Pro (393×852) |
|------------------|---------------------|----------------------|
| Headline padding-top | 12 px           | 18 px                |
| Headline font-size   | 20 px           | 22 px                |
| Ring → headline gap  | 14 px           | 28 px                |
| Ring size            | **196 px**      | **236 px**           |
| List → ring gap      | 18 px           | 32 px                |
| List row padding-Y   | 8 px            | 14 px                |
| List row font-size   | 13 px           | 14 px                |
| Button → list gap    | 18 px           | 28 px                |
| Button padding       | 13 px / 32 px   | 16 px / 36 px        |
| Button font-size     | 16 px           | 17 px                |

**Übergang:** unterhalb von 380 pt logical width = SE-Tuning. Anders gesagt: wenn das Gerät ≤ iPhone SE 2/3-Klasse ist, kompakte Werte; sonst die Pro-Werte.

---

## Components

### 1. Status Bar
- Höhe: 54 px (Padding-Top: 18 px)
- Padding-X: 32 px
- Inhalt: Uhrzeit (links, **17 px, weight 600**, SF Pro Text / system) + Signal/WiFi/Battery-Icons (rechts)
- Farbe Text/Icons: `--sm-text` (#ebe2d6)
- Battery-Icon zeigt **lädt** (grüner Innenteil + Blitz-Glyph)

### 2. Headline
- Font: `Newsreader, Georgia, serif` — weight 400 (regular)
- Größe: 20 px (SE) / 22 px (Pro)
- Letter-spacing: −0.01em
- Color: `--sm-text`
- Alignment: center
- Padding-X: 32 px
- Text: **„Wie viel Zeit schenkst du dir?"** (deutsch — aktive Marktlokalisierung)
- **Nur eine Headline.** Keine zweite Sub-Headline darunter.

### 3. Ring (RingQuiet) — HERO
Atemkreis-Dial, drag-bar zum Setzen der Minuten.

**Geometrie:**
- Outer radius: `0.42 × size` (z.B. bei size=236 → R_OUT = 99 px)
- Track-Strichbreite: 16 px (R_OUT − R_IN)
- Track-Mittellinie-Radius: `(R_OUT + R_IN) / 2`

**Visuelle Schichten** (von hinten nach vorn):
1. **Glow:** Radial-Gradient, Mittelpunkt-Kreis r = R_OUT + 18, Farbe von `rgba(214,138,110,0.14)` → transparent
2. **Track:** Voller Kreis, stroke = `rgba(235,226,214,0.06)`, strokeWidth = 16
3. **Progress-Arc:** Von 12-Uhr (−90°) bis zur aktuellen Position; Linear-Gradient `#d99a7e → #c47a5e`, strokeLinecap=`round`, opacity 0.9
4. **Drop (Indicator)**: Zwei konzentrische Kreise an der Arc-Endposition:
   - Outer: r=9, fill=`#0f0604`, stroke=`#d99a7e` (1.5 px)
   - Inner: r=4, fill=`#d99a7e`

**Zentraler Inhalt** (übereinander, gestapelt):
- **Zahl (aktueller Minuten-Wert):** `Newsreader`, weight 300, fontSize = `Math.round(size × 0.32)` (also ~63 px bei 196er Ring, ~76 px bei 236er Ring), letter-spacing −0.03em, color `--sm-text`, line-height 1
- **Label „Minuten"** darunter mit margin-top 6 px: 9.5 px, letter-spacing 0.28em, uppercase, color `--sm-text-3`

**Interaktion:**
- **Drag** (mouse + touch): Position des Pointers relativ zum Ring-Zentrum wird in Winkel umgerechnet → Wert. Bereich 1…60 (Min/Max konfigurierbar). 0 wird auf 1 hochgezogen, damit der Ring bei value=1 sichtbar bleibt.
- **`touch-action: none`** auf der Drag-Fläche, damit Page-Scroll nicht stört.
- **Keine** −/+ Stepper am Ring (`showInlineSteppers` Prop, default false → für diese Variante immer **false**).
- Cursor während Idle: `grab`; während Drag: `grabbing` (aktuell nicht explizit gesetzt — bitte ergänzen).

### 4. Settings-Liste

Eine flache, ruhige Liste mit 4 Zeilen. Keine Cards, keine Backgrounds, keine Icons.

**Container:**
- Padding-X: 28 px
- `border-top: 1px solid rgba(235,226,214,0.05)` am oberen Rand
- Vertikales Stacking, kein Gap, jede Zeile hat eine `border-bottom` mit derselben Farbe (also durchgehende Trennlinien zwischen Zeilen)

**Zeilen (in dieser Reihenfolge):**

| # | Label          | Default-Wert    | „Aus"-Wert | Aktiv-Flag    |
|---|----------------|-----------------|------------|---------------|
| 1 | Vorbereitung   | 15 Sek.         | „Aus"      | `prepOn`      |
| 2 | Gong           | Tempelglocke    | (immer an) | —             |
| 3 | Intervall      | 5 Min.          | „Aus"      | `intervalOn`  |
| 4 | Hintergrund    | Regen           | „Stille"   | `ambientOn`   |

**Zeilen-Aufbau** (jede Zeile = button-Element, full-width, transparent):
- Padding: 8 px / 4 px (SE) bzw. 14 px / 4 px (Pro), vertikal/horizontal
- `display: flex; justify-content: space-between; align-items: center`
- **Links:** Label
  - Font: `Geist`, weight 400, 13 px (SE) / 14 px (Pro), color `--sm-text`, letter-spacing 0.005em
- **Rechts:** Wert + Chevron
  - Wert-Font: `Newsreader`, weight 400, gleiche Größe wie Label
  - Wert-Color (aktiv): `--sm-accent-text` (#d99a7e)
  - Wert-Color (inaktiv, on=false): `--sm-text-3` (#6f6358)
  - Chevron: 12×12 px, color `--sm-text-3`, opacity 0.6
  - Gap zwischen Wert und Chevron: 8 px

**Inaktiv-State** (z.B. wenn `prepOn=false`):
- Gesamte Zeile: `opacity: 0.4`, transition 0.2s
- Wert-Text wird zu „Aus" / „Stille" (siehe Tabelle)

**Tap-Verhalten:** Tap auf eine Zeile öffnet einen Picker (Bottom-Sheet o.ä.) für genau dieses Setting. Picker-UI ist nicht Teil dieser Iteration — bitte bestehende Picker-Patterns aus dem Codebase verwenden, oder als TODO markieren. Im aktuellen Mock ist `onClick={() => {}}` ein Platzhalter.

### 5. Primary Button — „Beginnen"

- Klassen-äquivalent zu `.btn-primary` (siehe `styles.css`)
- Background: linear-gradient(180deg, `--sm-accent-glow` #d68a6e, `--sm-accent-soft` #b06a4f)
- Color (Text): #2a1208 (sehr dunkles Braun, hoher Kontrast auf dem Gradient)
- Font: weight 600, 16 px (SE) / 17 px (Pro)
- Padding: 13/32 px (SE) bzw. 16/36 px (Pro)
- Border-radius: pill (999 px)
- Box-shadow: `0 16px 40px -12px rgba(196, 122, 94, 0.5), inset 0 0 0 1px rgba(214, 138, 110, 0.3)`
- Inhalt: **▶ Play-Glyph (18×18)** + `gap: 10px` + Text **„Beginnen"**
- Press-State: `.press:active { transform: scale(0.98); }` (siehe styles.css)
- Margin-Top: 18 px (SE) / 28 px (Pro)
- Horizontal: zentriert (Container `text-align: center`)

### 6. Tab Bar
Floating Pill am unteren Bildschirmrand. **Unverändert gegenüber Bestand** — nur erwähnt, weil sie das Höhenbudget mitbestimmt.

- Position: absolute, bottom 18 px, horizontal zentriert
- Background: `rgba(34, 19, 16, 0.85)` mit `backdrop-filter: blur(20px)`
- Border: 1px solid `rgba(235, 226, 214, 0.06)`
- Padding: 8 px
- Border-radius: pill
- 3 Tabs: **Timer**, **Meditationen**, **Einstellungen**
- Aktiver Tab: background `--sm-accent-dim`, color `--sm-accent`
- Tab-Layout: vertikal Icon (22×22) + Label (11 px, letter-spacing 0.02em), gap 2 px
- Icons als Inline-SVGs (siehe `shell.jsx` für die genauen Pfade)

---

## Interactions & Behavior

### Drag im Ring
1. Pointer-Down innerhalb des Ring-Bereichs setzt `dragging = true`, sofortiges Update des Werts (so dass Tap auch ohne Bewegung funktioniert).
2. Während Pointer-Move (Maus oder Touch): Winkel = `atan2(dy, dx)`; Wert = round((winkel/360) × max), geclamped auf [1, 60].
3. Pointer-Up beendet das Dragging.
4. **Wichtig:** Move-Listener am `window`, nicht am Ring — sonst verliert man den Drag, wenn der Pointer den Ring verlässt.
5. **`touchmove`** mit `passive: false` registrieren und `preventDefault()` aufrufen, damit das Ziehen nicht zum Page-Scroll wird.

### Settings-Tap
- Tap auf Listen-Zeile → Picker öffnet sich (Bottom-Sheet bevorzugt).
- Inaktive Zeilen (z.B. Vorbereitung „Aus") sind weiterhin tap-bar — der Picker enthält dann den Toggle „Aus / An" und ggf. den Wert-Picker.

### „Beginnen"-Button
- Tap startet die Session mit dem aktuellen Minuten-Wert + den Setting-Werten.
- Visueller Feedback: scale-Press (0.98).

### Animations
- Listen-Zeile Inaktiv-Übergang: `opacity 0.2s` (siehe styles.css/inline).
- Drag im Ring: keine Animation — der Wert folgt dem Finger 1:1, das ist Teil des direkten Gefühls.
- Button Press: scale-Transition (CSS, 0.15s).

---

## State Management

```ts
type TimerIdleState = {
  minutes: number;            // 1..60, Standardwert z.B. 18
  prepOn: boolean;            // Vorbereitung an/aus
  prepDur: string;            // z.B. "15 Sek."
  gong: string;               // z.B. "Tempelglocke" — kein Off-State
  intervalOn: boolean;
  interval: string;           // z.B. "5 Min."
  ambientOn: boolean;
  ambient: string;            // z.B. "Regen"
};
```

State-Persistenz: Nutzer-Defaults sollten zwischen Sessions erhalten bleiben (vermutlich existierender User-Preferences-Mechanismus im Codebase).

---

## Design Tokens

Vollständige Token-Liste in `preview/styles.css`. Die für diesen Screen relevanten:

### Colors
| Token             | Wert      | Verwendung                              |
|-------------------|-----------|-----------------------------------------|
| `--sm-bg-deep`    | `#150a07` | App-Hintergrund (Vignette-Basis)        |
| `--sm-text`       | `#ebe2d6` | Primärtext, Labels                      |
| `--sm-text-2`     | `#a89a8c` | (nicht in diesem Screen aktiv)          |
| `--sm-text-3`     | `#6f6358` | „Minuten"-Label, Chevrons, Inaktiv-Werte|
| `--sm-accent`     | `#c47a5e` | Tab-Active-Color                        |
| `--sm-accent-text`| `#d99a7e` | Werte rechts in Settings-Liste          |
| `--sm-accent-soft`| `#b06a4f` | Button-Gradient-Bottom                  |
| `--sm-accent-glow`| `#d68a6e` | Button-Gradient-Top, Ring-Indicator     |
| `--sm-accent-dim` | `rgba(196,122,94,0.18)` | Tab-Active-BG               |

**Phone Background (Vignette):**
Innerhalb des Phone-Frames:
```css
background: radial-gradient(ellipse 90% 70% at 50% 30%,
  #3a201a 0%, #2a1610 38%, #190c08 72%, #110705 100%);
```
Plus eine zusätzliche Bottom-Vignette-Layer:
```css
::before {
  background: radial-gradient(ellipse 80% 70% at 50% 100%,
    rgba(196, 122, 94, 0.06), transparent 60%);
}
```

### Typography
| Token              | Wert                                           |
|--------------------|------------------------------------------------|
| `--sm-font-display`| `"Newsreader", Georgia, serif`                 |
| `--sm-font-ui`     | `"Geist", -apple-system, "SF Pro Text", system-ui, sans-serif` |

**Wichtig:** Die App benutzt zwei Schriftarten:
- **Newsreader** (variable Serif, weights 300/400/500) für Display-Headlines, Werte, große Zahlen
- **Geist** (Sans, weights 300/400/500/600) für UI-Labels, Buttons, Listen-Labels

Wenn diese Schriften noch nicht im Projekt sind: Newsreader und Geist sind beide auf Google Fonts verfügbar; alternativ aus dem Bestand des Projekts ähnliche Pendants wählen, aber **das Serif/Sans-Mix-Prinzip beibehalten** — die ruhige Atmosphäre lebt davon.

### Border Radii
- Pill: 999 px (Buttons, Tab Bar)
- Phone-Edge im Mock: 48 px (Pro), 32 px (SE) — produktiv kommt vom OS

### Shadows
- Primary Button: `0 16px 40px -12px rgba(196, 122, 94, 0.5), inset 0 0 0 1px rgba(214, 138, 110, 0.3)`
- Ring Glow: kein klassischer Box-Shadow, sondern ein Radial-Gradient-Kreis im SVG (s.o.)

---

## Was sich gegenüber dem alten Design geändert hat

Eine knappe Diff-Liste, die Reviewer und QA hilft:

1. ❌ **„Einstimmung"-Setting entfernt** (Feature-Cut → war zuvor 5. Listenzeile, oft inaktiv)
2. ❌ **−/+ Stepper neben/unter dem Ring entfernt** — Zeit nur per Drag
3. ❌ **Sub-Headline „Passe den Timer an" entfernt**
4. ❌ **Karten-Raster (3+2) entfernt** → flache Liste
5. ❌ **Setting-Icons entfernt** (waren in der Karten-Variante; in der Liste keine)
6. ✅ **Reihenfolge: Vorbereitung · Gong · Intervall · Hintergrund** (von „was passiert vor der Sitzung" → „während der Sitzung" → „dauerhaft im Hintergrund")
7. ✅ **Inaktive Zeile**: opacity 0.4 (statt nur Wert-Color-Wechsel) — klarer als „aus"
8. ✅ **Listen-Zeile clickable als Ganzes** (kein separater Toggle in der Zeile sichtbar — der Toggle steckt im Picker)

---

## Assets

Keine externen Bild-Assets in diesem Screen. Alle Icons sind Inline-SVGs (definiert in `preview/shell.jsx`, `Icons` Object). Bestehende Icon-Library im Codebase verwenden — die SVG-Definitionen hier sind nur Referenz für Stil und Strichstärke (alle 1.6 px stroke, round caps/joins).

---

## Files in This Bundle

```
handoff_timer_idle_polish/
├── README.md                  ← du bist hier
├── screenshots/
│   ├── 01-overview.png        ← gesamtes Vergleichs-Canvas
│   ├── 02-iphone-se.png       ← SE-Variante isoliert
│   └── 03-iphone-pro.png      ← Pro-Variante isoliert
└── preview/
    ├── Variant A — SE.html    ← Einstiegspunkt: SE + Pro nebeneinander
    ├── variant-a-ruhig.jsx    ← Screen-Komposition (Headline + Ring + Liste + Button)
    ├── ring-quiet.jsx         ← Ring-Komponente (Drag-Logik + SVG-Rendering)
    ├── shell.jsx              ← StatusBar, TabBar, Phone-Frame, Icons
    └── styles.css             ← Design-Tokens, Phone-Frame, gemeinsame Styles
```

**So preview ich es lokal:**
1. Beide HTML-Datei + alle .jsx + die styles.css müssen im selben Ordner liegen.
2. Mit einem statischen Server öffnen (`python -m http.server`, `npx serve`, oder einfach Doppelklick auf die HTML — die Babel-CDN-Skripte funktionieren auch von file://).
3. Im Browser scrollen, um beide Geräte-Größen nebeneinander zu sehen.
4. Den Ring kannst du mit der Maus drehen — der Wert ändert sich live.

---

## Open Questions / Empfohlene Folgearbeiten (außerhalb dieser Iteration)

- **Picker-Sheets** für jede Listen-Zeile (Vorbereitungs-Dauer, Gong-Sound, Intervall, Hintergrund-Sound) — bitte bestehende Bottom-Sheet-Patterns nutzen.
- **Haptic feedback** beim Drag im Ring (light tick alle Minuten) — wir haben das hier nicht modelliert, würde aber zur Atmosphäre passen.
- **Min/max für die Minuten-Range:** aktuell 1–60. Soll es höhere Werte für lange Sessions geben? Wenn ja: ggf. zweite Skalierung (60–120 Min) als zweiter Ring-Modus.
- **Accessibility:** Drag-only ist für motorisch eingeschränkte Nutzer:innen problematisch. Bitte ergänzen:
  - VoiceOver-Label am Ring mit Wert + „adjustable" trait
  - Bei Stepper-Geste (Wisch hoch/runter mit VoiceOver) `value ± 1`
  - Hardware-Tastatur: Pfeiltasten für ±1
