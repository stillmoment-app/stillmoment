# Handoff: Soundscape (Hintergrundklang) — Timer

## Overview
Der Timer-Screen **„Hintergrundklang"** (Timer → Einstellungen → *Hintergrundklang*) legt einen
**dauerhaften Hintergrundklang unter die Sitzung** (Stille, Waldatmosphäre, Regen oder eine eigene
Datei). Der Screen wird — wie zuvor **„Start & Ende"** (Gong-Auswahl) und **„Intervall-Gongs"** —
auf das gehobene Muster mit **Klang-Auswahl als Karten-Picker** umgestellt: runder Vorhör-Button,
charakteristische Mini-Wellenform, Auswahl-Häkchen — statt der bisherigen schlichten Icon-Listen­zeilen.

Ziel: Die Klang-Auswahl sieht **überall in der App gleich aus**. Der einzige bewusste Unterschied
zum Gong: Hintergrundklänge **loopen** — der Vorhör-Button ist deshalb ein **Play/Stop-Schalter**
und die Wellenform **animiert beim Abspielen**.

## About the Design Files
Die Dateien sind **Design-Referenzen, in HTML/React (Babel-im-Browser) gebaut** — Prototypen, die
Aussehen und Verhalten zeigen, **kein** produktiv zu übernehmender Code. Laut Design-System
(`uploads/design-system/`) ist die App **iOS (SwiftUI)** und **Android (Jetpack Compose)** — beide
verhalten sich identisch. Die HTML-Prototypen sind die visuelle Vorlage; umgesetzt wird in
SwiftUI/Compose mit den vorhandenen Theme-/Komponenten-Strukturen und den **semantischen
Farb-/Type-Tokens** der App (nicht den hier hartkodierten CSS-Variablen).

## Fidelity
**High-fidelity.** Finale Farben, Typografie, Abstände, Radien und Interaktionen. Nur
**Nacht-Theme (dunkel)** ist gefragt (wie die App-Screenshots); der helle „Kerzenschein"-Pfad liegt
im CSS bei, ist aber für diesen Screen nicht aktiviert.

---

## Screen / View

### Timer → Hintergrundklang
- **Name:** Hintergrundklang (Soundscape).
- **Purpose:** Nutzer wählt einen dauerhaften Hintergrundklang für die Sitzung und stellt die
  **Lautstärke** ein; kann **eigene Audiodateien importieren**.
- **Navigation:** Standard-Detail-Screen mit Zurück-Button und serifenbasiertem Titel
  „Hintergrundklang". Unten die App-Tab-Bar (Meditationen / **Timer** aktiv / Einstellungen).
- **Scroll-Container:** vertikal scrollbar zwischen Nav (oben, 104px) und Tab-Bar (unten, 84px),
  Padding `6px 18px 28px`.

#### Layout (von oben nach unten)
1. **Intro-Text** (serif, `ink-2`): „Lege einen sanften Klang unter deine Sitzung — oder wähle
   *Stille* für vollkommene Ruhe."
2. Eyebrow `KLANG` → **Klang-Liste als Karte** (Karten-Picker, eingebaute Klänge).
3. Eyebrow `MEINE KLÄNGE` → eigene importierte Dateien **oder** Leer-Zustand; darunter der
   **Import-Button** „Eigene Datei importieren".
4. Eyebrow `LAUTSTÄRKE` → **Lautstärke-Karte** (Slider). *Entfällt bei „Stille"*; dann stattdessen
   ein Hinweistext.

---

## Components

### 1. Klang-Liste (`.tone-list`) — Karten-Picker *(identisch zu „Start & Ende" / „Intervall-Gongs")*
- **Container:** `surface`, 1px `border`, Radius **22px** (`r-lg`), Schatten (hell)/Rahmen (dunkel),
  `overflow:hidden`.
- **Zeile** (`.tone`): Flex-Row, `align-items:center`, `gap:14px`, Padding **13px 16px**, volle
  Breite, transparent. Zwischen Zeilen 1px `divider`. Ausgewählt (`.sel`): Hintergrund `accent-fill`.
- **Vorhör-Button** (`.preview-btn`) links: Kreis **42×42**, 1px `border`, Hintergrund `surface-2`,
  Glyph in `accent`.
  - Ausgewählt: Verlauf aus `accent`, Glyph `on-accent`, Glanz-Highlight oben (`::before`).
  - **Abspielend** (`.looping`): Glyph wird zu **Stop** (Quadrat); ein ruhiger atmender Glow-Ring
    (`::after`, Keyframe `loop-pulse`, **1.6s**, dauerhaft — kein einmaliger Ring wie beim Gong).
  - **„Stille"-Zeile:** statt Play ein **Mute-Glyph** (durchgestrichener Lautsprecher); der Button
    spielt nichts ab (parallel zur „Vibration"-Zeile in der Gong-Liste).
- **Mitte** (`.tone-main`, flex:1):
  - **Name** (`.tone-name`): 16.5px, `ink`. Ausgewählt: `accent`, Weight 500.
  - **Beschreibung** (`.tone-desc`): Tweak „Beschreibungen", **Default an**, 12px, `ink-3`.
- **Mini-Wellenform** (`.scape-wave`), rechts vor dem Häkchen: 13 vertikale Balken, `gap:2px`,
  Höhe-Box 22px. Balken: Breite **2.5px**, Radius 2px, Farbe `ink-4`; ausgewählt `accent-soft`.
  Balkenhöhe je Index = `4 + round(env * 16)` px aus der SWAVE-Tabelle.
  - **Abspielend** (`.playing`): Balken animieren als **Equalizer** (`scaleY` 0.4↔1, Keyframe `eq`,
    0.9s, gestaffelt per `--i`).
  - **„Stille"** hat keine Wellenform, sondern eine **ruhige flache Linie** (`.scape-flat`, 26×2.5px).
- **Häkchen** (`.tone-check`), ganz rechts, nur bei ausgewählter Zeile: Check-Glyph in `accent`.

**Eingebaute Klänge (`SCAPES`):**
1. **Stille** — „Vollkommene Ruhe — kein Klang" (kein Audio, flache Linie, Mute-Glyph)
2. **Waldatmosphäre** *(Default-Auswahl)* — „Sanftes Blätterrauschen, ferne Vögel"
3. **Regen** — „Gleichmäßiger, beruhigender Regen"

**SWAVE-Hüllkurven** (13 Werte 0..1, nur für die *visuelle* Wellenform — Loop-Muster, nicht
abklingend wie beim Gong):
```
Waldatmosphäre [0.30,0.55,0.40,0.70,0.50,0.62,0.45,0.72,0.52,0.60,0.42,0.58,0.36]
Regen          [0.62,0.74,0.58,0.80,0.66,0.78,0.60,0.82,0.64,0.76,0.58,0.72,0.60]
```

### 2. Meine Klänge — eigene Dateien
- **Leer-Zustand** (`.empty-card`): `surface`, **1px gestrichelter** `border-strong`, Radius `r-lg`,
  Padding `20px 18px`, zentriert, Serifen-Font 14px, `ink-3`: „Du kannst auch eigene Hintergrundklänge importieren".
- **Befüllt:** Eigene Dateien als normale `.tone`-Zeilen (Vorhören + Wellenform + Häkchen) in einer
  zweiten `.tone-list`. Rechts in der Zeile ein **Mehr-Button** (`.tone-act`, Kebab „⋮") — er öffnet
  ein **Action-Sheet** (`.sheet`, iOS-Stil, von unten) mit **Umbenennen** und **Entfernen**
  (destruktiv) + **Abbrechen**. Bei ausgewählter Zeile steht das Häkchen links vom Kebab.
  Im Prototyp über Tweak „Eigene Dateien (Beispiel)" sichtbar (Beispiele: `Meeresrauschen.m4a`,
  `Tibet Bowls.mp3`).
  - **Umbenennen** öffnet einen kleinen Dialog (`.dialog` mit `.dialog-input`, Feldwert = aktueller
    Name, Enter = Sichern) → Datei bekommt den neuen Namen.
  - **Entfernen** öffnet den Bestätigungs-Dialog „Datei entfernen?".
  - *Lange Namen* werden mit Ellipsis abgeschnitten (`.tone-name`/`.tone-desc`:
    `white-space:nowrap; overflow:hidden; text-overflow:ellipsis`), damit sie **nicht** mit der
    Mini-Wellenform überlappen.
- **Import-Button** (`.import-btn`): volle Breite, Pill (`r-pill`), `surface-2`, 1px `border`,
  `accent`, Plus-Glyph + „Eigene Datei importieren". `:active` → `accent-fill` + leichtes `scale`.
  In der App öffnet er den **Dateiimport** (Document Picker / Files).

### 3. Lautstärke-Karte (`.vol-card`)
- **Container:** `surface`, 1px `border`, Radius `r-lg`, Schatten, Padding `16px 18px 18px`.
- **Zeile** (`.vol-row`): Lautsprecher-leise-Icon (`ink-3`) — **Slider** — Lautsprecher-laut-Icon.
- **Slider** (`.slider`): Track 6px, `track`-Farbe; Thumb **26×26**, `thumb`, 1px `border-strong`.
  Bereich 0–100, **Default 60**. Ändert in Echtzeit die Vorhör-Lautstärke.
- **Bei „Stille"** entfällt die Karte; stattdessen Hinweis (`.helper`): „*Stille* bedeutet
  vollkommene Ruhe — nur deine Atmung und der Raum um dich."

### Nav, Status-Bar, Tab-Bar (unverändert aus dem App-Muster)
- **Nav** (`.nav`): 3-Spalten-Grid; links Zurück (Chevron + „Zurück", `accent`, 17px),
  Mitte Titel (`.nav-title`, Serifen-Font 25px, `ink`).
- **Tab-Bar** (`.tabbar`): 3 Spalten, 84px. Aktiv hier: **Timer**.
- **Home-Indicator** (`.home-ind`): 134×5, `ink-4`, opacity 0.6.

---

## Interactions & Behavior
- **Zeile antippen** (`.tone`): wählt den Klang **und** startet (bei einem echten Klang) sofort die
  Loop-Vorschau. „Stille" stoppt jegliche Wiedergabe.
- **Vorhör-Button antippen** (`.preview-btn`): **toggelt** Play/Stop der Loop-Vorschau **ohne** die
  Auswahl zu ändern (Klick-Propagation gestoppt). Es spielt immer nur **ein** Klang gleichzeitig.
- **Slider ziehen:** ändert die Lautstärke und — falls eine Vorschau läuft — sofort deren Pegel.
- **Import-Button:** öffnet in der App den Dateiimport; danach erscheint die Datei unter „Meine Klänge".
- **Mehr-Button (⋮) an eigenen Dateien:** öffnet das Action-Sheet → **Umbenennen** (Dialog mit
  Textfeld) oder **Entfernen** (Bestätigung). Das Sheet ändert die Auswahl **nicht**.
- **Reduced motion:** Bei `prefers-reduced-motion: reduce` sind Animationen praktisch deaktiviert
  (Equalizer/Glow stehen still).

## State Management
- `scape: string` — gewählter Klang (Default `"Waldatmosphäre"`).
- `playing: string|null` — welcher Klang gerade die Loop-Vorschau abspielt (genau einer oder keiner).
- `vol: int 0..100` — Lautstärke (Default `60`).
- `ownList: [{id, desc}]` — die eigenen importierten Dateien.
- `menuFor: item|null` — für welche eigene Datei das Action-Sheet (⋮) offen ist.
- `pendingRename: item|null` + `renameText: string` — Umbenennen-Dialog und Eingabewert.
- `pendingDelete: item|null` — Entfernen-Bestätigung.
- Beim Umbenennen wird zusätzlich der Auswahl-/Wiedergabe-Zustand (`scape`/`playing`) und die
  visuelle Wellenform-Zuordnung auf den neuen Namen übertragen.
- Theme: über das vorhandene reaktive Theme-Environment (hier nur Nacht).

## Design Tokens
Semantische Rollen — die App nutzt diese, **nicht** direkte Werte. Werte aus `soundscape.css`.
Nur **Nacht** ist für diesen Screen aktiv; die Hell-Spalte (Kerzenschein) ist der Vollständigkeit
halber dabei und gilt 1:1 für „Start & Ende" / „Intervall-Gongs".

| Rolle | Nacht (Default) | Hell (Kerzenschein) | Verwendung |
|------|------|------|------|
| `bg-top` → `bg-bot` | `#241712` → `#3B2419` | `#FBEEDB` → `#E8A074` | Screen-Verlauf (oben→unten) |
| `surface` | `rgba(255,238,224,.045)` | `#FFF6E6` | Karten (Klang-Liste, Lautstärke) |
| `surface-2` | `rgba(255,238,224,.085)` | `#FBEAD2` | Vorhör-Button-Fläche, Import-Button |
| `border` | `rgba(240,210,185,.10)` | `rgba(120,55,28,.11)` | Karten-/Button-Rahmen |
| `border-strong` | `rgba(240,210,185,.18)` | `rgba(120,55,28,.18)` | Leer-Zustand (gestrichelt), Slider-Thumb |
| `divider` | `rgba(240,210,185,.075)` | `rgba(74,40,24,.08)` | Trennlinien zwischen Zeilen |
| `accent` | `#CC7E5F` | `#A2503E` | Play/Stop, Name aktiv, Häkchen, Import-Text |
| `accent-soft` | `#D98E6E` | `#B85F46` | Wellenform aktiv |
| `accent-fill` | `rgba(204,126,95,.15)` | `rgba(162,80,62,.10)` | Zeile aktiv (Hintergrund) |
| `on-accent` | `#2A1810` | `#FFF6E6` | Glyph auf accent-Fläche |
| `danger` | `#DD6A52` | `#C0432E` | Entfernen-Symbol (`.tone-remove`) |
| `ink` | `#F2E6DA` | `#3A2418` | Klangname |
| `ink-2` | `#C9B6A6` | `#7A4E3C` | Intro-Text, Hinweise |
| `ink-3` | `#9C8676` | `#9C7762` | Beschreibung, Leer-Zustand, Lautstärke-Icons |
| `ink-4` | `#6E5B4E` | `#BBA08C` | Wellenform inaktiv, Home-Indicator |
| `track` | `rgba(240,210,185,.14)` | `rgba(120,55,28,.16)` | Slider-Bahn |
| `thumb` | `#FBF1E6` | `#ffffff` | Slider-Thumb |

- **Radien:** `r-sm 12` · `r-md 16` · **`r-lg 22`** (Karten) · `r-xl 28` · `r-pill 999` (Import-Button).
- **Schatten/Rahmen:** Hell = `card-shadow` (`0 1px 2px rgba(50,32,20,.05), 0 4px 14px rgba(50,32,20,.07)`);
  **Dunkel = kein Schatten, 1px Rahmen** (Design-Regel „Hell = Schatten, Dunkel = Rahmen").
- **Typografie:** Name 16.5px (Geist) · Beschreibung 12px (Geist, `ink-3`) · Eyebrows (`KLANG`,
  `MEINE KLÄNGE`, `LAUTSTÄRKE`) 11px, letter-spacing 0.22em, uppercase · Titel 25px (Newsreader Light).
  Mapping auf die App-Type-Tokens (`uploads/design-system/still-moment-design.md`): Name → `body`,
  Beschreibung → `caption`, Eyebrow → `eyebrow`, Titel → `screenTitle`, Intro → `body`.

> Die hier gelisteten Hex-Werte sind die CSS-Variablen des Prototyps. In der App stattdessen die
> **semantischen Tokens** verwenden: `accent` → `interactive`, `ink` → `textPrimary`,
> `ink-2`/`ink-3` → `textSecondary`, `surface` → `cardBackground`, `border` → `cardBorder`,
> `track` → `controlTrack`, `danger` → `error` (siehe Design-System).

- **Neu in diesem Screen:** `.scape-wave` (animierter Equalizer), `.scape-flat` (ruhige Linie für
  Stille), `.preview-btn.looping` (atmender Glow), `.empty-card` (gestrichelter Leer-Zustand),
  `.import-btn`, `.tone-act` (Kebab-Mehr-Button) + `.sheet` (Action-Sheet) + `.dialog-input`
  (Umbenennen-Feld).

## Assets
Keine Bilddateien. Alle Glyphen (Zurück, Check, Play, Stop, Mute, Plus, Mehr/Kebab „⋮", Stift,
Papierkorb, Lautstärke, Tab-Icons) sind **Inline-SVG** (siehe `soundscape-app.jsx`, Objekt `I`). Hintergrundklänge in der App:
die echten **Loop-Audiodateien** der jeweiligen Szenen + die importierten Dateien des Nutzers.

> Die HTML-Prototypen synthetisieren die Ambience zur Vorschau per WebAudio (`ambient-audio.jsx`,
> gefiltertes Rauschen). In der App durch das **echte Abspielen der Loop-Audiodateien** ersetzen.

## Files
- `Hintergrundklang.html` — Prototyp-Shell (React + Babel via CDN), lädt Fonts + Skripte.
- `soundscape-app.jsx` — der Screen: Klang-Karten-Liste (`ScapeWave` + SWAVE), Meine Klänge (Leer-
  Zustand / Beispiel-Dateien), Import-Button, Lautstärke. Enthält `SCAPES`, `OWN`, Icons.
- `soundscape.css` — alle Styles (basiert auf `intervall.css`; ergänzt um die Soundscape-Bausteine).
- `ambient-audio.jsx` — WebAudio-Ambience-Synthese (nur Prototyp; in der App durch echte
  Loop-Wiedergabe ersetzen).
- `tweaks-panel.jsx` — nur Prototyp-Hilfsmittel (Beschreibungen, Eigene-Dateien-Beispiel,
  Akzentfarbe), **nicht** Teil der App.

**Referenz-Vorlagen (gleiche Optik):** `design_handoff_gong_klang_auswahl/` (Start & Ende),
`design_handoff_intervall_gongs/` (Intervall-Gongs) sowie das Design-System unter
`uploads/design-system/` (`still-moment-design.md`, Screenshot `screens/soundscape.png` = alter
Zustand, `screens/gong-selection.png` = Ziel-Optik).
