# Handover: „Start & Ende" — Gong-Auswahl (Timer)

## Überblick
Dies ist die Neugestaltung des Bildschirms, auf dem der Nutzer den **Klang für Anfang und Ende einer Timer-Meditation** in der App *Still Moment* wählt. Der Screen ersetzt die bisherige flache Liste durch eine gehobene Variante mit Vorhören pro Klang, charaktertragenden Mini-Wellenformen und einer minimalistischen Lautstärke-Einstellung (Beschreibungstexte optional, **standardmäßig aus**). Ein Klang gilt für Anfang **und** Ende.

Erreichbar über: **Tab-Bar → Timer → … → „Start & Ende"** (Push-Navigation, daher „Zurück" oben links).

## Über die Design-Dateien
Die Dateien in diesem Bündel (Ordner `design/`) sind **Design-Referenzen, erstellt in HTML/React (Babel-in-Browser)** — sie zeigen Aussehen und Verhalten, sind **kein produktiver Code zum 1:1-Übernehmen**.

Aufgabe: **Diese Designs in der bestehenden Umgebung der Ziel-App nachbauen** (SwiftUI / Kotlin / React Native / Flutter / o. ä.) mit deren etablierten Mustern, Komponenten und Tokens. Existiert noch keine Umgebung, das für das Projekt passendste Framework wählen und dort umsetzen. Die HTML-Datei dient nur als visuelle und verhaltensbezogene Spezifikation.

> Die Gong-Synthese (`gong-audio.jsx`) ist eine WebAudio-**Attrappe**, damit das Vorhören im Prototyp klingt. In Produktion sollten echte Audio-Samples (oder die plattformeigene Sound-API) verwendet werden — siehe Abschnitt „Audio".

## Fidelity
**High-Fidelity.** Finale Farben, Typografie, Abstände, Radien und Interaktionen sind verbindlich. Pixelgenau mit den vorhandenen Bibliotheken/Patterns des Codebases nachbauen. Bei Konflikt mit einem bestehenden Design-System: System gewinnt bei generischen Primitiven (Slider-Thumb), die hier dokumentierten **Layout-, Farb- und Typo-Werte** sind aber maßgeblich.

## Screenshots
Im Ordner `screenshots/` (Beschreibungstexte sind **standardmäßig aus** — siehe Tweak `descriptions`):
- `01-gong-auswahl.png` — Dunkles Theme (Standard), „Tempelglocke" gewählt; Vorhör-Button der Auswahl mit Verlauf + Glanz (dimensionaler Disc).
- `02-gong-auswahl.png` — Helles Theme „Kerzenschein" (per Tweak `theme: light`).
- `03-gong-auswahl.png` — „Vibration" gewählt: Helper-Text sichtbar, **keine** Lautstärke-Karte.

---

## Screen: „Start & Ende"

### Zweck
Nutzer wählt den Gong-Klang, der die Meditation einläutet und beendet, hört ihn vor und stellt die Lautstärke ein. **Ein** Klang + **eine** Lautstärke für Anfang und Ende.

### Frame & Layout
- Design-Canvas: **393 × 852 px** (iPhone-Logikgröße), Inhalt skaliert sich in den Viewport.
- Vertikaler Aufbau (oben → unten):
  1. **Status-Bar** (Höhe 54px, 16px oben / 32px seitlich Padding)
  2. **Nav-Bar** — 3-Spalten-Grid `1fr auto 1fr`: links „‹ Zurück", Mitte Titel, rechts leer
  3. **Scroll-Bereich** (`.content`) — absolut, `inset: 104px 0 84px 0`, vertikal scrollbar, Padding `6px 18px 28px`
  4. **Tab-Bar** (unten, Höhe 84px, fixiert)
  5. **Home-Indicator** (134×5px, unten zentriert)
- Scroll-Bereich-Reihenfolge: Eyebrow „Klang" → Klangliste → Helper-Text (nur bei Vibration) → Eyebrow „Lautstärke" + Lautstärke-Karte (entfällt bei „Vibration").

### Komponenten

**1. Status-Bar**
- Zeit „16:17" links (SF-Pro / system-ui, 16px, weight 600).
- Rechts: Mobilfunk-Punkte, WLAN, Batterie (Inline-SVGs, `currentColor` = `--ink`).

**2. Nav-Bar**
- „‹ Zurück": Chevron-SVG (22px, stroke 2.2) + Text, Farbe `--accent`, 17px, weight 400. Tippen = zurück navigieren.
- Titel „Start & Ende": **Newsreader** (Serif), 25px, weight 400, Farbe `--ink`, zentriert, nowrap.

**3. Eyebrow** (Sektionslabel) — Text „KLANG" bzw. „LAUTSTÄRKE"
- 11px, letter-spacing 0.18em, uppercase, weight 600, `--ink-3`, padding `0 6px 10px`.

**4. Klangliste** (`.tone-list`) — Karte mit Zeilen
- Karte: `--surface`, 1px `--border`, radius `--r-lg` (22px), `--card-shadow`, `overflow:hidden`.
- Zeile (`.tone`): flex, `gap 14px`, padding `13px 16px`, Trennlinie `1px --divider` zwischen Zeilen. Ausgewählt (`.sel`): Hintergrund `--accent-fill`.
- Pro Zeile, von links:
  - **Vorhör-Button** (`.preview-btn`): 42×42px Kreis, 1px `--border`, Hintergrund `--surface-2`, Icon `--accent`. Play-Dreieck (15px). **Bei ausgewählter Zeile:** gefüllter, dimensionaler Akzent-Disc statt flacher Farbe — vertikaler Verlauf (heller oben → dunkler unten, aus `--accent` via `color-mix`), weicher oberer Glanz (`::before`, Weiß-Verlauf 0.22→0 bis 45 %), Akzent-getönter Schatten (`0 4px 12px`). Icon `--on-accent`, z-index über dem Glanz. (Entspricht dem Play-Button-Material der App, vgl. „Kerzenschein 2.0".) Aktiv-Tap skaliert auf 0.96. Beim Abspielen: weich expandierender Ring (`@keyframes ring`, **1.5s**, dezent) — als visuelles Echo des Klangs gedacht.
  - **Text**: Name (16.5px, `--ink`; ausgewählt 500 + `--accent`). Optionale Beschreibung (12px, `--ink-3`) — **standardmäßig ausgeblendet** (Tweak `descriptions: false`); Name + Wellenform tragen den Charakter.
  - **Mini-Wellenform** (`.tone-wave`): 11 vertikale Balken, 2.5px breit, Höhen 4–20px, Farbe `--ink-4` (ausgewählt `--accent-soft`). **Bedeutungstragend, nicht dekorativ:** je Klang eine feste Abkling-Hüllkurve (links = Anschlag, rechts = Ausklang), die den Charakter abbildet — Balkenhöhe ≈ Tiefe/Fülle, Tail-Länge ≈ Nachhall. Werte siehe `WAVE`-Map in `auswahl-app.jsx` (z. B. „Klarer Anschlag" = kurzer Peak + schneller Abfall, „Tiefe Resonanz" = breit/getragen).
  - **Häkchen** (`.tone-check`, nur bei Auswahl): Check-SVG 20px, `--accent`.
- **Sonderfall „Vibration"** (letzte Zeile, kein Klang): Vorhör-Button zeigt Haptik-Icon statt Play; statt Wellenform 3 Punkte (`.haptic-dots`, 6px); Tap löst `navigator.vibrate([20,40,20])` + Shake-Animation (`@keyframes buzz`) aus; **keine Lautstärke-Karte**.

**Klänge (Reihenfolge & Texte):**
| Name | Beschreibung |
|---|---|
| Tempelglocke *(Default ausgewählt)* | Tiefe, lang ausklingende Bronze |
| Klassisch | Heller Glockenanschlag, ausgewogen |
| Tiefe Resonanz | Sehr tief, sphärisch, langer Nachhall |
| Klarer Anschlag | Trocken, präzise, kurz |
| Vibration | Sanfter Impuls — kein Ton |

**5. Helper-Text** (`.helper`) — Newsreader 13px, `--ink-2`, padding `12px 8px 4px`; `<em>`-Teile in `--accent` (non-italic, font-ui, weight 600). Erscheint **nur**, wenn „Vibration" gewählt ist:
- „Dein Gerät gibt statt eines Klangs einen *sanften Impuls* — lautlos, ideal für stille Räume."

**6. Lautstärke-Karte** (`.vol-card`, entfällt wenn „Vibration" gewählt) — **bewusst minimalistisch**
- Karte: `--surface`, 1px `--border`, radius `--r-lg`, `--card-shadow`, padding `16px 18px 18px`, margin-top 8px.
- **Nur eine Slider-Reihe**, keine Beschriftung, kein Prozentwert, keine Caption, kein Vorhör-Button: kleines Lautsprecher-Icon links (`--ink-3`), `<input type=range min=0 max=100>` (`flex:1`), großes Lautsprecher-Icon rechts.
  - Track: 6px hoch, radius 999px, Hintergrund `--track`. Thumb: 26×26px Kreis, `--thumb` (creme/weiß), 1px `--border-strong`, Schatten. `accent-color: --accent` als Fallback. **Hinweis:** im Zielsystem den nativen Slider-Stil oder die Plattform-Komponente verwenden — die Range-Pseudo-Elemente sind nur Web-spezifisch.
- Default-Lautstärke: **78 %**. Das Vorhören über die Klangliste spielt automatisch in der aktuell eingestellten Lautstärke.

**7. Tab-Bar** (`.tabbar`) — 3 Spalten gleich breit, Höhe 84px, Verlauf zum Hintergrund, Top-Border `--divider`.
- Items: „Meditationen" (Wellen-Icon), „Timer" (Stoppuhr-Icon, **aktiv** = `--accent`), „Einstellungen" (Regler-Icon). Inaktiv `--ink-3`. Icon 22px + Label 11px.

---

## Interaktionen & Verhalten
- **Klang tippen** (ganze Zeile): wählt den Klang **und** spielt ihn sofort vor (in der eingestellten Lautstärke).
- **Vorhör-Button tippen** (`stopPropagation`): nur vorhören, ohne Auswahl zu ändern.
- **Vibration**: löst Haptik aus statt Audio; blendet die Lautstärke-Karte aus.
- **Slider**: aktualisiert Lautstärke live (0–100 %); wirkt sofort auf das nächste Vorhören.
- **Auto-Stop**: Wechsel des Klangs oder Unmount stoppt laufendes Audio (`GongAudio.stopAll()`).
- **Animationen**: weich expandierender Ring beim Vorhören (1.5s, dezent — visuelles Echo des Klangs), Buzz bei Vibration (0.5s), sanfter Press (Scale 0.96). `prefers-reduced-motion: reduce` deaktiviert Animationen.

## State (Prototyp-Referenz)
- `cfg`: `{ tone: string, vol: 0..100 }` — ein gemeinsamer Klang + eine Lautstärke für Start und Ende. Default `{ tone: "Tempelglocke", vol: 78 }`.
- Ephemerer UI-State: `ringing` (welche Zeile gerade klingt).
- Persistenz im Produktcode: gewählter Klang + Lautstärke sollten gespeichert werden.

## Design-Tokens (Dunkel = Default „Kerzenschein · Nacht")
| Token | Wert (Dark) | Wert (Light „Kerzenschein") |
|---|---|---|
| `--bg-top` | `#241712` | `#FBEEDB` |
| `--bg-mid` | `#2E1C14` | `#F6CDA8` |
| `--bg-bot` | `#3B2419` | `#E8A074` |
| `--surface` | `rgba(255,238,224,.045)` | `#FFF6E6` |
| `--surface-2` | `rgba(255,238,224,.085)` | `#FBEAD2` |
| `--surface-strong` | `rgba(255,238,224,.10)` | `#FFF6E6` |
| `--border` | `rgba(240,210,185,.10)` | `rgba(120,55,28,.11)` |
| `--border-strong` | `rgba(240,210,185,.18)` | `rgba(120,55,28,.18)` |
| `--divider` | `rgba(240,210,185,.075)` | `rgba(74,40,24,.08)` |
| `--accent` | `#CC7E5F` | `#CC7E5F` (Light übersteuert `--accent` nicht) |
| `--accent-soft` | `#D98E6E` | `#D98E6E` |
| `--accent-fill` | `rgba(204,126,95,.15)` | `rgba(162,80,62,.10)` |
| `--on-accent` | `#2A1810` | `#FFF6E6` |
| `--ink` | `#F2E6DA` | `#3A2418` |
| `--ink-2` | `#C9B6A6` | `#7A4E3C` |
| `--ink-3` | `#9C8676` | `#9C7762` |
| `--ink-4` | `#6E5B4E` | `#BBA08C` |
| `--track` | `rgba(240,210,185,.14)` | `rgba(120,55,28,.16)` |

**Radien:** sm 12 · md 16 · lg 22 · xl 28 · pill 999 (px)
**Schatten:** `--card-shadow: 0 1px 2px rgba(0,0,0,.22), 0 8px 24px -12px rgba(0,0,0,.5)` (Dark)
**Typografie:** Display = **Newsreader** (Serif, Titel/Intro/Helper/Klangnamen); UI = **Geist** (Listen, Labels). Beide Google Fonts.
**Akzent:** `#CC7E5F` (fix; aktuell nicht per Tweak umschaltbar). Der Play-Button-Verlauf und -Schatten werden per `color-mix` daraus abgeleitet und folgen dem Akzent automatisch.

## Theming / Tweaks
Der Prototyp enthält ein „Tweaks"-Panel (nur Demo-Werkzeug, **nicht** in Produktion übernehmen). Aktuell ausgespielte Regler:
- `theme`: `dark` / `light` („Nacht" / „Kerzenschein")
- `descriptions`: Klang-Beschreibungen ein/aus (**Default: aus**)

`accent` existiert als Token/Default (`#CC7E5F`), wird derzeit aber **nicht** über das Panel verändert. Die Theme-Umschaltung erfolgt über die Klasse `.light` auf dem Wurzel-Element; alle Farben sind CSS-Variablen — im Zielsystem analog als Light/Dark-Variante umsetzen.

## Audio
`design/gong-audio.jsx` synthetisiert die Gongs per WebAudio (inharmonische Partials + Decay-Hüllkurve je Klang, plus Lautstärke-Helfer). Das ist eine **Prototyp-Attrappe**. In Produktion:
- Echte, gemasterte Gong-Samples je Klang verwenden **oder** die Plattform-Sound-API.
- „Vibration" = Haptik-Pattern (kein Audio).
- Lautstärke 0–100 % linear auf die Wiedergabeverstärkung mappen.
Die Decay-/Charakter-Beschreibungen je Klang können als Vorlage für die Sample-Auswahl dienen (siehe `TONES` in `gong-audio.jsx`).

## Dateien in diesem Bündel (`design/`)
- `Start-Ende-Gong-Auswahl.html` — Einstiegspunkt (Fonts, Tweak-Defaults, Skript-Einbindung).
- `auswahl-app.jsx` — Screen-Logik: Klangliste, Lautstärke, Tab-Bar, Texte, State.
- `auswahl.css` — alle Stile + Tokens (Dark default, `.light`-Override). Enthält evtl. noch ungenutzte Klassen (`.seg`, `.sidetabs`, `.vol-head`, `.vol-cap`, `.audition`) aus früheren Iterationen — beim Nachbau ignorierbar.
- `gong-audio.jsx` — WebAudio-Gong-Synthese (Prototyp-Attrappe).
- `tweaks-panel.jsx` — Demo-Tweaks-Panel (nicht produktionsrelevant).

So öffnen: `Start-Ende-Gong-Auswahl.html` in einem Browser (kein Build nötig, Babel läuft im Browser).
