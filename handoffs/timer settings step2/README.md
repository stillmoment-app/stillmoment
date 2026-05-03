# Handoff: Timer Config Step 2 — "Atemkreis + Feintuning"

## Übersicht

Dies ist der **Konfigurations-Bildschirm Schritt 2** einer Meditations-App ("Still Moment"). Der Bildschirm beantwortet die Frage **"Wie viel Zeit schenkst du dir?"** und lässt den Nutzer die Sitzungsdauer (1–60 Minuten) wählen sowie sekundäre Timer-Optionen (Vorbereitung, Einstimmung, Hintergrund, Gong, Intervall) konfigurieren, bevor er "Beginnen" tippt.

Die Picker-Lösung ist ein **Hybrid aus gestischer Wahl und minutengenauer Präzision**:

- **Im Atemkreis ziehen** → schnelle, atmosphärische Auswahl (der Tropfen wandert auf dem Ring, der Bogen füllt sich)
- **− / + Buttons unten links und rechts vom Kreis** → minutengenaue Korrektur. Halten beschleunigt (Long-Press)
- Beide arbeiten am gleichen `minutes`-State

## Über die Design-Dateien

Die Dateien in diesem Bundle sind **HTML-Design-Referenzen** — Prototypen, die das beabsichtigte Aussehen und Verhalten zeigen, **kein Produktionscode zum direkten Kopieren**. Aufgabe: Diese Designs in der Ziel-Codebase mit deren etablierten Patterns und Bibliotheken nachbauen (SwiftUI für iOS, Jetpack Compose für Android, React Native, Flutter — je nach Stack).

Falls noch keine Codebase existiert, wähle das passendste Framework für eine Mobile-Meditations-App (empfohlen: **SwiftUI** für iOS oder **Jetpack Compose** für Android — die Geste-basierten Animationen und der weiche, gradient-lastige Look profitieren von nativer Render-Pipeline).

## Fidelity

**High-fidelity (hifi).** Alle Maße, Farben, Typografie und Interaktionen sind final. Pixelgenau nachbauen.

## Bildschirm

### Name
**Timer Config — Step 2 (Zeitauswahl + Sekundär-Optionen)**

### Zweck
Nutzer wählt die Sitzungsdauer und konfiguriert Timer-Optionen vor Start einer Meditation.

### Layout (Frame: 393 × 852, iPhone 15/16/17 Pro logical)

```
┌───────────────────────────────────────┐
│ Status Bar (54 px)                    │  09:41 + Signal/Wifi/Battery
├───────────────────────────────────────┤
│                                       │
│      "Wie viel Zeit schenkst du dir?" │  H-Display 22 px, padding 10/32
│                                       │
│              ┌─────────┐              │  Atemkreis-Picker, Höhe 280 px
│           ─  │   18    │  +           │  Drop-Halo pulsiert
│              │ Minuten │              │  − / + radial bei 7- und 5-Uhr
│              └─────────┘              │
│                                       │
│         (44 px Atem-Spacing)          │
│                                       │
│         "Passe den Timer an"          │  H-Display 18 px, text-2 Farbe
│                                       │
│  ┌──────┐  ┌──────┐  ┌──────┐         │  3er-Reihe: Vorbereitung,
│  │ Vor… │  │ Ein… │  │ Hint…│         │  Einstimmung, Hintergrund
│  └──────┘  └──────┘  └──────┘         │
│                                       │
│       ┌──────┐  ┌──────┐              │  2er-Reihe: Gong, Intervall
│       │ Gong │  │ Inte…│              │
│       └──────┘  └──────┘              │
│                                       │
│         (32 px Atem-Spacing)          │
│                                       │
│           [▶ Beginnen]                │  Primary Button, pill, copper
│                                       │
├───────────────────────────────────────┤
│  Tab Bar (96 px reserviert)           │  Timer | Meditationen | Einstellungen
└───────────────────────────────────────┘
```

### Komponenten

#### 1. Atemkreis-Picker (`BreathDialPlusV2`)
Datei: `pickers-hybrid-v2.jsx`

- **Container-Höhe:** 280 px, volle Breite, position: relative
- **Dial-Größe:** 220 × 220 px, zentriert (`left: 50%, transform: translateX(-50%)`)
- **Ring-Geometrie:**
  - Outer Radius: 100 px
  - Inner Radius: 84 px
  - Ring-Strichstärke: 16 px (Differenz)
  - Ring-Mittelradius: 92 px (für Bogen + Tropfen-Position)
- **Hintergrund-Glow:** Radial gradient, Radius 122 px, Mitte `rgba(214,138,110,0.18)` → außen transparent
- **Track-Ring:** `rgba(235,226,214,0.07)`, 16 px Strichstärke
- **Aktiv-Bogen:** Linear gradient `#d99a7e → #c47a5e`, opacity 0.85, `stroke-linecap: round`. Startet bei −90° (12-Uhr), Länge entspricht `(value / 60) * 360°`
- **Drag-Tropfen** (Position auf Ring-Mittelradius am Endwinkel):
  - Pulse-Halo: r animiert 18→26→18, opacity 0.35→0.05→0.35, Dauer 2.6 s, repeatCount=indefinite, fill `rgba(217,154,126,0.18)`
  - Outer-Ring: r=14, fill `#0f0604`, stroke `#d99a7e` 1.8 px
  - Center-Dot: r=6.5, fill `#d99a7e`
- **Zentrale Zahl:** Newsreader 76 px, weight 300, letter-spacing −0.03em, color `#ebe2d6`
- **Label "Minuten" unter Zahl:** 9.5 px, letter-spacing 0.26em, uppercase, color `#6f6358`, margin-top 4 px
- **−/+ Buttons:**
  - Position: radial vom Dial-Zentrum bei 45° (7-Uhr und 5-Uhr-Position), Radius 168 px
  - Berechnung: `dx = cos(45°) * 168 ≈ 118.79`, `dy = sin(45°) * 168 ≈ 118.79`
  - Größe: 44 × 44 px, border-radius 50%
  - Background: `rgba(235,226,214,0.04)`, border `1px rgba(235,226,214,0.10)`
  - Glyph: Newsreader 20 px weight 300, color `#ebe2d6` (− und +)
  - Disabled bei value≤1 bzw. ≥60: opacity 0.3
- **Geste:** mousedown/touchstart auf Dial → `dragging=true`. mousemove/touchmove → `atan2(dy, dx)` → angle → value. Wert klemmt 1–60 (kein 0).
- **Long-Press:** Erstes bump bei mousedown. Nach 320 ms → setInterval alle 80 ms. Cleanup bei mouseup/leave/touchend.

#### 2. Setting Card (`SettingCard_S2V2`)
Datei: `timer-config-step2-v2.jsx`

- **Layout:** Vertikaler Stack — Label (oben), Icon (Mitte), Value (unten), gap 7 px
- **Padding:** 12 12 11
- **Border-radius:** 16 px
- **Background:** `linear-gradient(180deg, rgba(235,226,214,0.045), rgba(235,226,214,0.015))`
- **Border:** 1px `rgba(235,226,214,0.08)`
- **Label:** Newsreader 11 px, weight 400, letter-spacing 0.01em, **NICHT uppercase**, color `#6f6358`. Sentence-Case ("Vorbereitung", "Einstimmung", "Hintergrund", "Gong", "Intervall"). `text-overflow: ellipsis, white-space: nowrap, max-width: 100%`
- **Icon:** 24 × 24, color `#d99a7e`
- **Value:** Newsreader 12 px, color `#a89a8c`, gleiche Truncation-Regeln
- **Disabled-Zustand** (`on === false`): opacity 0.45, transition 0.25s
- **Press-Feedback:** transform scale(0.98) bei `:active` (siehe `.press`-Klasse in `styles.css`)

#### 3. Settings-Liste
- Reihe 1: Grid 1fr/1fr/1fr, gap 8, padding 8/18 — Vorbereitung, Einstimmung, Hintergrund
- Reihe 2: Grid 1fr/1fr, gap 8, padding 8/18 (linksbündig durch Grid 2-spaltig — 2 Karten lassen rechts Lücke) — Gong, Intervall

#### 4. Primary Button "Beginnen"
- text-align center, margin-top 32 px
- Klasse `.btn-primary`:
  - background: `linear-gradient(180deg, #d68a6e, #b06a4f)`
  - color `#2a1208` (auf hellem Copper für AA-Kontrast)
  - font-weight 600, font-size 17 px, font-family ui (Geist)
  - padding 16/36, border-radius pill (999)
  - box-shadow `0 16px 40px -12px rgba(196,122,94,0.5)` + inset-stroke
  - Inhalt: Play-Icon (18×18) + Wort "Beginnen", gap 10

#### 5. Status Bar
Statisch: 09:41, Signal/Wifi/Battery (charging green) — siehe `shell.jsx`. Höhe 54 px.

#### 6. Tab Bar
Floating, bottom 18 px, centered. 3 Tabs: Timer (active), Meditationen, Einstellungen. Aktiv-Tab: background `rgba(196,122,94,0.18)`, color `#c47a5e`. Siehe `shell.jsx`.

## Interaktionen & Verhalten

| Trigger | Effekt |
|---|---|
| Drag im Dial-Ring | `minutes` wird kontinuierlich auf Winkelposition gesetzt (1–60). atan2-basiert. |
| Tap "−" | minutes -= 1 (min 1). Halten: nach 320 ms Long-Press, dann alle 80 ms ein Schritt. |
| Tap "+" | minutes += 1 (max 60). Long-Press wie oben. |
| Drop-Halo | Atmet 2.6 s Loop unabhängig von Interaktion (Affordance). |
| Tap Setting-Card | öffnet ggf. Detail-Sheet (in diesem Mock nicht implementiert — Hook für Engineering). |
| Tap "Beginnen" | startet Sitzungs-Screen (out of scope dieses Handoffs). |
| Tab Bar | wechselt Section. |

**Easing/Animation:**
- Pulse-Halo: linear interpolation animateMotion via SMIL — kann in nativ als Spring oder linear timing gebaut werden.
- Press-Feedback: 150 ms ease, transform scale(0.98).
- Card opacity-Übergang: 250 ms.

## State Management

```ts
type Step2State = {
  minutes: number;             // 1..60
  activeTab: "timer" | "med" | "settings";
  dense: {
    prepOn: boolean;     prepDur: string;     // "15 Sek." | "30 Sek." | "1 Min."
    introOn: boolean;    intro: string;       // "Atem-Anker" | "Body-Scan" | ...
    ambientOn: boolean;  ambient: string;     // "Regen" | "Wald" | "Stille"
    gong: string;                             // "Tempelglocke" | ...
    gongVol: number;                          // 0..100
    intervalOn: boolean; interval: string;    // "5 Min." | "10 Min." | ...
    intervalVol: number;                      // 0..100
  };
};
```

Default im Mock: `minutes=18`, alle Settings vorbelegt. Persistenz in echter App: User-Defaults / Room / SwiftData.

## Design Tokens

### Farben

| Token | Hex |
|---|---|
| `--sm-bg-deep` | `#150a07` |
| `--sm-bg-1` | `#221310` |
| `--sm-bg-2` | `#2c1a15` |
| `--sm-bg-3` | `#3a221c` |
| `--sm-card` | `#2a1812` |
| `--sm-card-hi` | `#341e17` |
| `--sm-card-line` | `rgba(235,226,214,0.06)` |
| `--sm-accent` | `#c47a5e` |
| `--sm-accent-soft` | `#b06a4f` |
| `--sm-accent-glow` | `#d68a6e` |
| `--sm-accent-text` | `#d99a7e` |
| `--sm-accent-dim` | `rgba(196,122,94,0.18)` |
| `--sm-text` | `#ebe2d6` |
| `--sm-text-2` | `#a89a8c` |
| `--sm-text-3` | `#6f6358` |
| `--sm-text-4` | `#4a4039` |
| `--sm-sage` | `#8aa896` |
| Body / "Off-Black" | `#0a0604` |

Phone-Background ist ein radialer Gradient:
`radial-gradient(ellipse 90% 70% at 50% 30%, #3a201a 0%, #2a1610 38%, #190c08 72%, #110705 100%)`

### Spacing
- Card-padding: 12 12 11
- Card-gap (innen): 7
- Setting-Reihen-gap: 8
- Picker → "Passe den Timer an": **44 px** (top-padding der Section)
- Cards-Reihe 1 → Reihe 2: 8 px (innen-gap)
- Cards-Reihe 2 → "Beginnen": **32 px** (margin-top)

### Border-Radius
- `--sm-r-sm` 12 px
- `--sm-r-md` 18 px
- `--sm-r-lg` 24 px
- `--sm-r-xl` 32 px
- `--sm-r-pill` 999 px
- Phone-Bezel: 48 px
- Card: 16 px (lokal in `SettingCard_S2V2`)

### Typografie

- **Display:** Newsreader (Google Fonts), Fallback Georgia, serif. Weights 300/400/500.
- **UI:** Geist (Google Fonts), Fallback `-apple-system, "SF Pro Text", system-ui, sans-serif`. Weights 300/400/500/600.

| Stelle | Family | Size | Weight | Letter-Spacing |
|---|---|---|---|---|
| Big number (im Dial) | Newsreader | 76 | 300 | −0.03em |
| "Wie viel Zeit schenkst du dir?" | Newsreader | 22 | 400 | — |
| "Passe den Timer an" | Newsreader | 18 | 400 | — |
| Card Label | Newsreader | 11 | 400 | 0.01em |
| Card Value | Newsreader | 12 | 400 | — |
| "Minuten" Label | Geist | 9.5 | 400 | 0.26em (uppercase) |
| Button Primary | Geist | 17 | 600 | — |
| Tab-Label | Geist | 11 | 400 | 0.02em |
| Statusbar Time | SF Pro Text | 17 | 600 | — |

### Shadows / Effekte
- Primary Button: `0 16px 40px -12px rgba(196,122,94,0.5)` + inset `0 0 0 1px rgba(214,138,110,0.3)`
- Tab Bar: `backdrop-filter: blur(20px)` + `background: rgba(34,19,16,0.85)` + 1 px border `rgba(235,226,214,0.06)`
- Phone vignette: pseudo-element `radial-gradient(ellipse 80% 70% at 50% 100%, rgba(196,122,94,0.06), transparent 60%)`

## Assets

- **Fonts:** Newsreader und Geist von Google Fonts (in der App durch native Pendants ersetzen — z.B. `New York` + `SF Pro` auf iOS, oder Newsreader/Geist als gebündelte TTFs).
- **Icons:** Inline-SVGs in `shell.jsx` (Glocke, Welle, Refresh, Sanduhr, Sparkle, Play). Bei Bedarf in das hauseigene Icon-System überführen — alle Icons sind mit `stroke-width: 1.6, stroke-linecap: round, stroke-linejoin: round` gezeichnet, currentColor-getrieben.
- **Keine Bitmaps**, keine Lizenzfragen.

## Dateien in diesem Bundle

| Datei | Inhalt |
|---|---|
| `Timer Config Step 2 v2.html` | Lauffähiger Prototyp (im Browser öffnen) |
| `pickers-hybrid-v2.jsx` | `BreathDialPlusV2` — der Atemkreis-Picker mit −/+ Buttons |
| `timer-config-step2-v2.jsx` | `VariantPhoneV2` + `SettingCard_S2V2` — Screen-Composition |
| `shell.jsx` | `StatusBar`, `TabBar`, `Phone`-Wrapper, Icon-Set |
| `styles.css` | Alle CSS-Variablen + Klassen (.phone, .btn-primary, .tabbar, .press, …) |

## Implementations-Hinweise

1. **Geste-Engine:** Auf Touch-Plattformen unbedingt mit nativem Pan-Gesture-Recognizer arbeiten (SwiftUI `DragGesture`, Compose `detectDragGestures`) statt mit Mouse-Polling.
2. **Long-Press-Acceleration:** 320 ms Initial-Delay, dann 80 ms Tick — als Coroutine / Combine-Timer / RxJava-Interval umsetzbar.
3. **Pulse-Animation:** Endlos-Loop, sollte auch im Hintergrund/Idle nicht stoppen, da sie die Affordance "anfassbar" trägt.
4. **Min-Wert ist 1, nicht 0** — der Code clamp'd `value === 0 ? 1 : v`, weil eine 0-Min-Sitzung sinnfrei ist.
5. **Bogen-Geometrie:** SVG-Arc mit `large-arc-flag` basierend auf `(endA - startA + 360) % 360 > 180`. Auf nativ via `Path.addArc` o.ä.
6. **Accessibility:**
   - Buttons haben `aria-label="Eine Minute weniger"` / `"Eine Minute mehr"`.
   - Der Dial sollte als Slider-Rolle exponiert werden (`role="slider"`, `aria-valuemin=1`, `aria-valuemax=60`, `aria-valuenow={minutes}`, `aria-valuetext="${minutes} Minuten"`). Tastatur-Support: ←/→ = ∓1, Shift+←/→ = ∓5.
   - Min Touch-Target ist 44 px (erfüllt für die Buttons; der Drag-Tropfen selbst hat Touch-Target via Dial-Hit-Area, da das ganze Dial draggable ist).
7. **Reduced Motion:** Pulse-Halo ausschalten wenn `prefers-reduced-motion: reduce`.

## Out of Scope dieses Handoffs

- Detail-Sheets der einzelnen Setting-Karten (Vorbereitung-Dauer wählen, Gong-Sound wählen etc.)
- Sitzungs-Screen nach "Beginnen"
- Onboarding / Auth
- Settings-Tab-Inhalt
