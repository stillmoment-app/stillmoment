# Handoff: Vorbereitungszeit (Einstimm-Zeit) — Timer

## Overview
Der Timer-Screen **„Vorbereitungszeit"** (erreichbar über Timer → Einstellungen →
*Vorbereitungszeit*) legt eine kurze Stille **vor dem Start** der Sitzung fest — Zeit zum Ankommen,
Augen schließen, bewusst zur Ruhe kommen. Der Screen wird auf dasselbe gehobene Muster wie die
anderen überarbeiteten Timer-Screens („Start & Ende", „Intervall-Gongs") gebracht:
**Master-Schalter** oben, darunter — nur wenn an — die Dauer-Auswahl.

Die Dauer wird über einen **großen Wert-Hero** (Serif-Zahl + Einheit) und einen **gerasterten
Slider** (5-Sekunden-Schritte) eingestellt. Bewusst ruhig, ein einziges primäres Stellelement.

## About the Design Files
Die Dateien sind **Design-Referenzen in HTML/React (Babel-im-Browser)** — Prototypen, die Aussehen
und Verhalten zeigen, **kein** produktiv zu übernehmender Code. Laut Design-System
(`uploads/design-system/`) ist die App **iOS (SwiftUI)** und **Android (Jetpack Compose)** — beide
verhalten sich identisch. Die HTML-Prototypen sind die visuelle Vorlage; die Umsetzung erfolgt in
SwiftUI/Compose mit den vorhandenen Theme-/Komponenten-Strukturen.

## Fidelity
**High-fidelity.** Finale Farben, Typografie, Abstände, Radien und Interaktionen — aber mit den
existierenden semantischen Tokens der App (siehe `uploads/design-system/still-moment-design.md`),
nicht mit den hier hartkodierten CSS-Variablen. Nur **Nacht-Theme (dunkel)** ist gefragt; der helle
„Kerzenschein"-Pfad liegt im CSS bei, ist aber für diesen Screen nicht aktiviert.

---

## Screen / View

### Timer → Vorbereitungszeit
- **Zweck:** Optionale Einstimm-Zeit vor dem Timer-Start; Nutzer schaltet sie an/aus und wählt die
  Dauer.
- **Navigation:** Standard-Detail-Screen mit Zurück-Button und Serif-Titel „Vorbereitungszeit".
  Unten die App-Tab-Bar (Meditationen / **Timer** aktiv / Einstellungen).
- **Scroll-Container:** vertikal zwischen Nav (oben, 104px) und Tab-Bar (unten, 84px),
  Padding `6px 18px 28px`.

#### Layout (oben → unten)
1. **Master-Karte** „Vorbereitungszeit" mit Schalter (immer sichtbar).
2. *Nur wenn Schalter AN:*
   - Eyebrow `DAUER`
   - **Wert-Hero** (große Serif-Zahl + Einheit „Sekunden")
   - **Slider-Karte** (gerasterter Slider + End-Labels „5 Sek." / „1 Min.")
3. *Wenn Schalter AUS:* nur ein einleitender Hilfetext.

---

## Components

### 1. Master-Karte (`.master-card`) — Vorbereitungszeit an/aus
- **Container:** Hintergrund `surface`, 1px `border`, Radius **22px** (`r-lg`), Schatten (hell) /
  nur Rahmen (dunkel). Flex-Row, `align-items:center`, `gap:14px`, Padding `16px 18px`.
- **Icon** (`.master-ico`), links: Kreis **40×40**, Hintergrund `surface-2`, 1px `border`, Glyph in
  `accent` — ein **Sanduhr-Symbol** (Hourglass).
- **Mitte** (`.master-main`, flex:1):
  - **Titel** „Vorbereitungszeit": 16.5px, `ink`, letter-spacing −0.005em.
  - **Untertitel** (`.master-sub`): 12.5px, `ink-3` — **trägt die einzige Zweck-Erklärung**
    (kein doppelter Text an anderer Stelle):
    - AN: „Eine kurze Stille vor dem Start"
    - AUS: „Aus — der Timer startet sofort"
- **Schalter** (`.switch`), rechts: iOS-Stil **51×31**, Radius 999px. Aus: Track `track`. An: Track
  `accent`. Knopf (`::after`) **27×27**, `thumb`, Schatten `0 1px 3px rgba(0,0,0,.3)`, verschiebt
  sich an um **+20px** (transition 0.22s `cubic-bezier(0.3,0.7,0.3,1)`).

### 2. Wert-Hero (`.prep-hero`) — nur bei AN
- Flex-Spalte, zentriert, Padding `30px 0 26px`.
- **Wert** (`.prep-val`): Serif-Font (`Newsreader`), **72px**, line-height 0.9, `ink`,
  `font-variant-numeric: tabular-nums`, letter-spacing −0.02em. Zeigt die gewählte Sekundenzahl.
- **Einheit** (`.prep-unit`): 12px, letter-spacing 0.2em, uppercase, `ink-3`, margin-top 12px.
  Text „Sekunden" (bzw. „Sekunde" bei 1 — kommt durch den 5er-Raster faktisch nicht vor).

### 3. Slider-Karte (`.vol-card` + `.slider`) — nur bei AN
- **Container** (`.vol-card`): `surface`, 1px `border`, Radius `r-lg`, Schatten, Padding
  `16px 18px 18px`.
- **Slider** (`.slider`): volle Breite. Track 6px, Radius 999px, `track`-Farbe; Thumb **26×26** rund,
  `thumb`, 1px `border-strong`, Schatten `0 2px 6px rgba(0,0,0,.35)`.
- **Bereich:** `min=5`, `max=60`, **`step=5`** → gerastet auf 5-Sekunden-Werte (5,10,…,60).
  **Default 10.**
- **End-Labels** (`.slider-ends`): Flex-Row space-between unter dem Slider, 12px `ink-3` —
  links „5 Sek.", rechts „1 Min.".

### 4. Aus-Zustand (Hilfetext)
- Bei Schalter AUS statt der Dauer-Auswahl ein Absatz (`.helper`): „Schalte die *Vorbereitungszeit*
  ein, um vor dem Start kurz innezuhalten und anzukommen." (`em` = `accent`, Weight 600.)

### Nav, Status-Bar, Tab-Bar (App-Standard, unverändert)
- **Nav** (`.nav`): 3-Spalten-Grid; links Zurück (Chevron + „Zurück", `accent`, 17px), Mitte Titel
  (`.nav-title`, Serif 25px, `ink`).
- **Tab-Bar** (`.tabbar`): 3 Spalten, 84px, Verlauf transparent→`bg-bot`, 1px `divider` oben. Tabs
  11px `ink-3`, aktiv `accent`. Aktiv hier: **Timer**.
- **Home-Indicator** (`.home-ind`): 134×5, `ink-4`, opacity 0.6.

---

## Interactions & Behavior
- **Schalter antippen:** an/aus. AUS blendet Wert-Hero + Slider aus, zeigt den Hilfetext.
- **Slider ziehen:** rastet auf 5-Sekunden-Schritte; der Wert-Hero aktualisiert sich live.
- **Gemerkte Dauer:** aus→wieder an stellt die zuletzt gewählte Dauer wieder her (kein Reset).
- **Reduced motion:** keine essenziellen Animationen auf diesem Screen.

> **Designentscheidung (bewusst):** Switch **und** Slider statt eines einzelnen 0–60-Sliders mit
> „0 = Aus". Begründung: klarer Aus-Zustand, gemerkte Dauer, und Konsistenz mit den anderen
> Timer-Screens, die alle dasselbe Master-Switch-Muster nutzen. Der Zweck-Text steht **nur** im
> Switch-Untertitel (nicht zusätzlich unter dem Slider), um Doppelung zu vermeiden.

## State Management
- `on: bool` — Master-Schalter (Default `true`); steuert Sichtbarkeit von Hero + Slider.
- `sel: int` — gewählte Dauer in Sekunden, gerastet auf 5 (Default `10`, Bereich 5–60).
- Theme: über das vorhandene reaktive Theme-Environment der App (hier nur Nacht).

## Design Tokens
Semantische Rollen (App nutzt diese, nicht direkte Werte). Werte aus `vorbereitung.css`:

| Rolle | Nacht (dunkel, Default) | Kerzenschein (hell, nicht genutzt) |
|------|------|------|
| `bg-top → bg-bot` (Verlauf) | `#241712 → #2E1C14 → #3B2419` | `#FBEEDB → #F6CDA8 → #E8A074` |
| `surface` (Karte) | `rgba(255,238,224,.045)` | `#FFF6E6` |
| `surface-2` (Icon-/Slider-Fläche) | `rgba(255,238,224,.085)` | `#FBEAD2` |
| `border` | `rgba(240,210,185,.10)` | `rgba(120,55,28,.11)` |
| `border-strong` (Slider-Thumb) | `rgba(240,210,185,.18)` | `rgba(120,55,28,.18)` |
| `divider` | `rgba(240,210,185,.075)` | `rgba(74,40,24,.08)` |
| `accent` (Icon, Schalter an, Thumb-Akzent) | `#CC7E5F` | `#A2503E` |
| `ink` (Titel, Wert-Hero) | `#F2E6DA` | `#3A2418` |
| `ink-3` (Untertitel, Eyebrow, Einheit, End-Labels) | `#9C8676` | `#9C7762` |
| `track` (Schalter aus, Slider-Track) | `rgba(240,210,185,.14)` | `rgba(120,55,28,.16)` |
| `thumb` (Schalter-/Slider-Knopf) | `#FBF1E6` | `#ffffff` |

- **Radien:** `r-sm 12 · r-md 16 · r-lg 22 · r-xl 28 · r-pill 999`. Karten = `r-lg` (22px).
- **Schatten (Hell):** `card-shadow` = `0 1px 2px rgba(50,32,20,.05), 0 4px 14px rgba(50,32,20,.07)`.
  **Dunkel:** kein Schatten — Rahmen statt Schatten.
- **Eyebrow** (`DAUER`): 11px, letter-spacing 0.18em, uppercase, Weight 600, `ink-3`,
  Padding `0 6px 10px`.
- **Typografie:** Display = `Newsreader` (Titel 25px, Wert-Hero 72px); UI = `Geist`
  (Karten-Titel 16.5px, Untertitel 12.5px).

## Assets
Keine Bilddateien. Alle Glyphen (Zurück, Sanduhr, Tab-Icons) sind **Inline-SVG** (siehe
`vorbereitung-app.jsx`, Objekt `I`).

## Files
- `Vorbereitungszeit.html` — Prototyp-Shell (React + Babel via CDN), lädt Fonts + Skripte.
- `vorbereitung-app.jsx` — der Screen: Master-Schalter, Wert-Hero, gerasterter Slider, Aus-Hilfetext.
  Konstanten `MIN_S=5, MAX_S=60, STEP_S=5`, Default `sel=10`.
- `vorbereitung.css` — alle Styles inkl. `.master-card`, `.switch`, `.prep-hero`, `.prep-val`,
  `.prep-unit`, `.vol-card`, `.slider`, `.slider-ends`, Nav/Tab-Bar/Status-Bar.
- `tweaks-panel.jsx` — nur Prototyp-Hilfsmittel (Akzentfarbe), **nicht** Teil der App.

**Referenz / Kontext:** `prototypen/gong-start-ende/` und `prototypen/intervall-gongs/` (gleiche
Designsprache, bereits als Handoff dokumentiert) sowie das Design-System unter
`uploads/design-system/` (`still-moment-design.md`, Screenshot `screens/preparation.png` = alter
Zustand).
