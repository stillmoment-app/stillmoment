# Handoff: Player Screen — Atemkreis

## Overview

Dieses Bundle beschreibt den **aktiven Player** der Meditations‑App **Still Moment** — also den Bildschirm, der zu sehen ist, *während* eine Meditation läuft.

Die zentrale Designentscheidung: Während einer Meditation schaut die Nutzerin nicht auf den Bildschirm. Jede Steuerung, die trotzdem da ist, ist ein Versprechen, dass es etwas zu bedienen gäbe — und reißt aus der Praxis. Daher wurde der Player radikal reduziert auf **eine** primäre Geste: **Pause**. Die Restzeit wird passiv kommuniziert (feiner Bogen + eine Zahl), und der ganze Bildschirm wird zu einem langsam atmenden Kreis, der gleichzeitig Lebenszeichen und Atemführung ist.

Das ersetzt einen vorherigen Player im Stil von Apple Music (Slider, ±10s, Cover‑Art‑Optik mit dominanter Kupfer‑Play‑Taste).

## About the Design Files

Die Dateien in diesem Bundle sind **Design‑Referenzen in HTML/JSX** — Prototypen, die Aussehen und Verhalten zeigen. Sie sind **nicht** als Production‑Code gedacht, der direkt eingebaut wird.

Die Aufgabe ist, dieses Design im Ziel‑Codebase (z. B. SwiftUI, React Native, Flutter, native Android) **mit den dort etablierten Patterns und Bibliotheken nachzubauen**. Falls das Ziel‑Codebase noch keine Player‑Infrastruktur hat, ist das geeignete Framework für das Projekt zu wählen und die Designs dort umzusetzen.

Die HTML/JSX‑Quellen verwenden React + inline JSX nur für die Mock‑Darstellung; dies ist **nicht** der finale Stack.

## Fidelity

**High‑fidelity (hifi).** Alle Maße, Farben, Animationskurven, Easing‑Werte und Typografie sind final abgestimmt und sollen pixelgenau übernommen werden. Sollte das Ziel‑Codebase ein eigenes Design‑System haben, sollen die Tokens (siehe Abschnitt *Design Tokens*) auf dort vorhandene äquivalente Tokens gemappt werden.

## Lifecycle des Players

Der Player läuft durch **drei Phasen** automatisch durch:

1. **Pre‑Roll · Vorbereitung** (0–60 s, in den Sitzungs‑Settings konfigurierbar; Standardwert sollte aus dem Timer‑Spec übernommen werden).
2. **Hauptphase · Atemkreis** (geführte Meditation läuft).
3. **Ende** (Audio fadet aus → Post‑Session‑Screen).

**Auto‑Start:** Sobald der Player‑Screen geöffnet wird, startet die Vorbereitung **sofort**. Es gibt **keinen** initialen Play‑Tap. Nach Ablauf der Vorbereitung geht der Player automatisch und nahtlos in die Hauptphase über (Cross‑Fade 400 ms).

**Während der Vorbereitung gibt es keinen Pause‑Button** — nur den Schließen‑Button oben links. Pause erscheint erst mit Beginn der Hauptphase.

Falls die Nutzerin in den Sitzungs‑Settings „Vorbereitung = 0 s" wählt, entfällt der Pre‑Roll komplett und der Player startet direkt in der Hauptphase.

## Screens / Views

### View · `Pre‑Roll Countdown`

**Zweck.** Eine konfigurierbare Anzahl Sekunden (0–60), in denen sich die Nutzerin setzen, augen‑schließen und ankommen kann, bevor die Audio‑Meditation losgeht. Beim Aufrufen des Player‑Screens startet die Vorbereitung **automatisch**; ein expliziter Play‑Tap ist nicht nötig.

**Layout (von oben nach unten):**

| # | Element | Position | Spezifikation |
|---|---|---|---|
| 1 | Status‑Bar | top: 0, height: 54 | OS‑Standard, hell |
| 2 | Schließen‑Button | top: 64, left: 24, 44 × 44 | wie in Hauptphase |
| 3 | Artist | vertikal mittig, oberhalb Titel | 11 px / 0.3em UPPERCASE / `--sm-text-3` @ 0.55 |
| 4 | Titel der Meditation | unter Artist | Newsreader 22 / line‑height 1.2 |
| 5 | Pre‑Roll‑Kreis | vertikal mittig, 280 × 280 | siehe unten |
| 6 | Hint‑Label | 36 px unter Ring | „GLEICH GEHT'S LOS" — 12 px / 0.18em uppercase / `--sm-text-3` @ 0.45 |

**Hintergrund:** identisch zur Hauptphase.

#### Component · Pre‑Roll Kreis

In der 280 × 280 Box sind drei Layer:

**Layer 1 — Ring‑Hintergrund (statisch).**
- SVG circle, r = 130, kein Fill, stroke `rgba(235,226,214,0.07)`, width 1.

**Layer 2 — Vorbereitungs‑Bogen (entleert sich linear über die Vorbereitungsdauer).**
- SVG circle, r = 130, kein Fill, stroke `#c47a5e` (Token: `--sm-accent`), width 1.2, opacity **0.55** (gedämpfter als der Hauptphasen‑Bogen, der 0.7 nutzt — die Vorbereitung ist visuell „halbvoll").
- `stroke-linecap: round`.
- `stroke-dasharray = ${remaining/total * 2πr} ${2πr}` — der gefüllte Anteil entspricht der **noch verbleibenden** Vorbereitungszeit (also: voll bei Start, leer bei Übergang in die Hauptphase).
- Rotation `-90°` → Start bei 12 Uhr, im Uhrzeigersinn ablaufend.
- Update sekündlich oder feiner.

**Layer 3 — Inneres Glow‑Feld (statisch, nicht atmend).**
- Quadrat 220 × 220 (`inset: 30`), `border-radius: 50%`.
- Background: `radial-gradient(circle at 50% 45%, rgba(217,154,126,0.20), rgba(196,122,94,0.06) 60%, rgba(196,122,94,0) 80%)` — **schwächer** als Hauptphase (0.20 statt 0.35).
- Border: 1 px `rgba(217,154,126,0.18)` (Hauptphase: 0.25).
- **Keine** Atem‑Animation — der Ring atmet erst in der Hauptphase. Das macht den Übergang spürbar.
- Inhalt: vertikal mittig zentriert die Countdown‑Zahl + Label.

**Inhalt im inneren Feld:**

| Element | Stil |
|---|---|
| Countdown‑Zahl | Newsreader, weight 300, 92 px, line‑height 1, `rgba(235,226,214,0.92)`, `font-variant-numeric: tabular-nums` |
| Label „Vorbereitung" | 8 px Abstand zur Zahl, 10 px / 0.28em letter‑spacing, UPPERCASE, `--sm-text-3` @ 0.55 |

**Verhalten:**
- Beim Öffnen des Players: Zahl zeigt initial den vollen Wert (z. B. `15`), Bogen ist voll. Audio‑Engine ist *noch nicht* gestartet, nur ein Timer läuft.
- Sekündliches Update: Zahl zählt herunter, Bogen entleert sich linear.
- Bei `0`: Cross‑Fade (400 ms) zur Hauptphase. Audio startet im selben Moment, in dem das innere Feld zur atmenden Variante wechselt. Optional: leiser Gong (außerhalb dieses Specs).
- Schließen jederzeit erreichbar — Beenden ohne dass die Sitzung als „angehört" gilt.
- **Reduced motion:** Bogen aktualisiert sich weiterhin (Information). Cross‑Fade ersetzt durch instant cut.

#### Übergang Pre‑Roll → Hauptphase

Bei Sekunde 0 des Countdowns:

| Element | Übergang |
|---|---|
| Countdown‑Zahl + Label „Vorbereitung" | fade‑out 400 ms |
| Vorbereitungs‑Bogen (gedämpft) | morph zur Hauptphasen‑Variante (opacity 0.55 → 0.7, dasharray springt auf 0 → wächst dann mit Wiedergabe) |
| Inneres Glow‑Feld | atmen beginnt (16 s Zyklus, ease‑in‑out) — kein Sprung, sondern Easing‑Start ab `scale(1)` |
| Pause‑Button | fade‑in 400 ms, mittig im Glow erscheinend |
| Hint „GLEICH GEHT'S LOS" | fade‑out 400 ms |
| Restzeit‑Label „NOCH …" | fade‑in 400 ms |
| Audio | startet bei Sekunde 0, von 0 % auf 100 % Lautstärke in 600 ms |

### View · `Player` (Hauptphase)

**Zweck.** Audio‑Wiedergabe einer geführten Meditation, kombiniert mit einer atmenden Visualisierung als Atemführung. Wird automatisch erreicht aus dem Pre‑Roll, kein Tap nötig.

**Hinweis zum Auto‑Start.** Auch wenn die Vorbereitung in den Settings auf 0 s gesetzt wurde und der Pre‑Roll entfällt, startet das Audio **sofort** beim Öffnen des Player‑Screens. Es gibt zu keinem Zeitpunkt einen initialen Play‑Button.

**Maße.** Der Mock geht von einem iPhone 15 Pro Logical Frame (393 × 852) aus. Bei anderen Geräten: vertikal mittig, horizontal mittig, mit Safe‑Area‑Berücksichtigung.

### View · `Player`

**Zweck.** Audio‑Wiedergabe einer geführten Meditation, kombiniert mit einer atmenden Visualisierung als Atemführung.

**Maße.** Der Mock geht von einem iPhone 15 Pro Logical Frame (393 × 852) aus. Bei anderen Geräten: vertikal mittig, horizontal mittig, mit Safe‑Area‑Berücksichtigung.

**Layout (von oben nach unten):**

| # | Element | Position | Spezifikation |
|---|---|---|---|
| 1 | Status‑Bar | top: 0, height: 54 | OS‑Standard, Vordergrund hell |
| 2 | Schließen‑Button | top: 64, left: 24, 44 × 44 | Runder Glass‑Button, „×"‑Icon, Zustand → Beenden |
| 3 | Artist (Name der Lehrerin) | vertikal mittig, oberhalb Titel | 11 px / 0.3em letter‑spacing / UPPERCASE |
| 4 | Titel der Meditation | direkt unter Artist | Newsreader 22 / line‑height 1.2, weight 400 |
| 5 | Atemkreis (Ring + Glow) | vertikal mittig, 280 × 280 | siehe unten |
| 6 | Pause‑Button | mittig im Atemkreis, 80 × 80 | siehe unten |
| 7 | Restzeit‑Label | 36 px unter Ring | „NOCH 8:32 MIN", 12 px / 0.18em uppercase |

**Hintergrund.**
```
radial-gradient(
  ellipse 90% 70% at 50% 40%,
  #3a201a 0%,
  #2a1610 38%,
  #170b07 80%,
  #0d0604 100%
)
```
Warme Mahagoni‑/Kakao‑Töne, vertikal mittig der hellste Punkt, zu den Rändern dunkler.

### Component · Atemkreis

Der Atemkreis besteht aus **drei** zusammengelegten Layern in einer 280 × 280 Box, vertikal/horizontal zentriert:

**Layer 1 — Ring‑Hintergrund (statisch).**
- SVG circle, r = 130, kein Fill.
- Stroke: `rgba(235, 226, 214, 0.07)`, width 1.

**Layer 2 — Restzeit‑Bogen (statisch pro Frame, animiert über Sitzungsdauer).**
- SVG circle, r = 130, kein Fill.
- Stroke: `#c47a5e` (Token: `--sm-accent`), width 1.2, opacity 0.7, `stroke-linecap: round`.
- `stroke-dasharray: ${progress * 2πr} ${2πr}` — der gefüllte Anteil entspricht dem **bereits vergangenen** Anteil der Sitzung.
- Rotation `-90°` um den Mittelpunkt → Start bei 12 Uhr, im Uhrzeigersinn.
- Während der Wiedergabe einmal pro Sekunde (oder seltener — 5 s reicht visuell) aktualisieren. Kein Audio‑sample‑genaues Updating nötig.

**Layer 3 — Atem‑Glow (animiert kontinuierlich).**
- Quadrat 220 × 220 (`inset: 30` innerhalb der 280er Box), `border-radius: 50%`.
- Background: `radial-gradient(circle at 50% 45%, rgba(217,154,126,0.35), rgba(196,122,94,0.12) 60%, rgba(196,122,94,0) 80%)`.
- Border: 1 px `rgba(217,154,126,0.25)`.
- Animation: 16 s pro Zyklus, `ease-in-out`, infinite.
  - 0 % / 100 %: `scale(0.86)`, `opacity: 0.7`
  - 50 %: `scale(1.04)`, `opacity: 1.0`
- **Wichtig:** Diese Animation läuft **kontinuierlich, unabhängig vom Audio**. Sie schlägt ein Atemtempo vor, sie visualisiert nicht das Audiosignal.

### Component · Pause/Play‑Button

- 80 × 80, `border-radius: 50%`, exakt zentriert im Atem‑Glow.
- Background: `rgba(15, 8, 5, 0.55)` (matt, semi‑transparent — wirkt wie Glas vor dem Glow).
- Backdrop‑Filter: `blur(8px)` (auf Plattformen ohne Backdrop‑Filter: opaque dunkler Fallback `#1a0d09`).
- Border: 1 px `rgba(217, 154, 126, 0.35)` (Token: `--sm-accent-glow` @ 0.35).
- Glyph (Pause): zwei vertikale Bars, je 4.5 × 18, x = 6 / 15.5, y = 4, radius 1.5. Farbe `#d99a7e` (Token: `--sm-accent-glow`).
- Glyph (Play): einzelnes Dreieck (alternativ: Play‑Symbol des Ziel‑Designsystems), gleiche Farbe, optisch gleichgewichtet zum Pause‑Glyph.

**Tap‑Verhalten:**
- Tap auf den Button → Toggle Play/Pause des Audios.
- Cross‑Fade zwischen Pause‑ und Play‑Glyph: 200 ms.
- **Bei Pause:** Atem‑Animation pausiert im aktuellen Frame (`animation-play-state: paused`). Restzeit‑Bogen friert ein.
- **Bei Resume:** Atem läuft weiter, Audio läuft weiter, Glyph wechselt zurück.
- Sanftes Haptic‑Tap (iOS: `UIImpactFeedbackGenerator(style: .soft)`).

### Component · Schließen‑Button

- 44 × 44, oben links bei (24, 64).
- Runder Button, Glass‑Stil: Background `rgba(235, 226, 214, 0.08)`, Border `rgba(235, 226, 214, 0.10)`.
- Inhalt: SVG „×", 14 × 14, stroke `#ebe2d6`, width 1.5.
- Tap → Audio fadet aus (300 ms), Übergang zurück zum vorherigen Screen.

## Interactions & Behavior

**Während der Wiedergabe:**
- Atem‑Animation läuft kontinuierlich.
- Restzeit‑Bogen aktualisiert sich (Polling alle 1–5 s ist ausreichend).
- Restzeit‑Label aktualisiert sich sekündlich, Format `mm:ss`, Schreibweise `NOCH 8:32 MIN` (komplett uppercase, tabular‑nums).
- Keine weiteren Controls. Tap außerhalb des Pause‑Buttons macht **nichts**.

**Pause:**
- Audio pausiert. Atem friert ein. Glyph wechselt.
- Auch über Lockscreen / Control Center / AirPods auslösbar — der Player‑Zustand muss spiegeln.

**Resume:** umgekehrt.

**Beenden (Schließen):**
- Audio fadet 300 ms aus.
- Übergang zurück zum Library‑/Lehrer‑Screen.
- Sitzungsfortschritt wird gespeichert (außerhalb dieses Specs definiert).

**Ende der Sitzung:**
- Audio fadet aus.
- Optionaler Schluss‑Gong (außerhalb dieses Specs).
- Übergang zum Post‑Session‑Screen (separater Spec, nicht Teil dieses Bundles).

**Reduced motion (`prefers-reduced-motion: reduce` bzw. iOS „Bewegung reduzieren"):**
- Atem‑Animation deaktivieren.
- Glow bleibt sichtbar im neutralen Zustand (`scale(1)`, opacity = 0.85), konstant.
- Restzeit‑Bogen aktualisiert sich weiterhin (das ist Information, keine Dekoration).

## State Management

Benötigte States:

| State | Werte | Trigger |
|---|---|---|
| `phase` | `preRoll` / `playing` / `paused` | Auto‑Wechsel `preRoll` → `playing` bei Countdown‑Ende; Pause‑Tap |
| `prepRemainingSeconds` | `Int` (0 …`prepTotal`) | Timer, sekündlich, nur in Phase `preRoll` |
| `prepTotalSeconds` | `Int` (0…60) | aus Sitzungs‑Settings, einmalig beim Öffnen |
| `playbackStatus` | `playing` / `paused` | Tap auf Pause/Play; externe Events (Lockscreen) |
| `progress` | `0.0` … `1.0` | Player‑Engine, Update mind. alle 5 s |
| `remainingSeconds` | `Int` | Player‑Engine, sekündlich |
| `track` | `{ artist, title, durationSeconds }` | beim Öffnen gesetzt |

Daten kommen aus der bestehenden Audio‑Layer der App. Der Pre‑Roll‑Countdown ist ein reiner UI‑Timer ohne Audio. Audio‑Engine wird beim Phasenwechsel `preRoll → playing` gestartet.

## Design Tokens

Alle Werte sind als CSS‑Variablen in `styles.css` definiert. Mapping ins Ziel‑Codebase:

**Farben:**
| Token | Hex | Verwendung im Player |
|---|---|---|
| `--sm-bg-deep` | `#150a07` | Hintergrund‑Außenrand |
| `--sm-accent` | `#c47a5e` | Restzeit‑Bogen |
| `--sm-accent-soft` | `#b06a4f` | (frei im Player) |
| `--sm-accent-glow` | `#d68a6e` | Atem‑Glow, Pause‑Glyph |
| `--sm-accent-dim` | `rgba(196,122,94,0.18)` | Pause‑Button‑Border |
| `--sm-accent-text` | `#d99a7e` | (Variante des Glow) |
| `--sm-text` | `#ebe2d6` | Titel, Schließen‑Glyph |
| `--sm-text-2` | `#a89a8c` | (frei) |
| `--sm-text-3` | `#6f6358` | Artist, „NOCH … MIN" |

**Typografie:**
- Display: **Newsreader** (Google Fonts), weights 300 / 400 / 500. Verwendet für den Meditations‑Titel.
- UI: **Geist** (Google Fonts), weights 300 / 400 / 500 / 600. Verwendet für alles andere.
- System‑Stack‑Fallback im UI: `-apple-system, "SF Pro Text", system-ui, sans-serif`.

**Spacing & Radien:**
- Phone‑Padding zur Status‑Bar: 18 px top, 32 px horizontal.
- Schließen‑Button: top 64, left 24.
- Atemkreis: 280 × 280 außen, Glow inset 30.
- Pause‑Button: 80 × 80.
- Restzeit‑Label: 36 px Abstand unter dem Ring.

**Animation:**
- Atem: 16 s pro Zyklus, `ease-in-out`, infinite. Skala 0.86 → 1.04, opacity 0.7 → 1.0.
- Pause/Play‑Glyph‑Crossfade: 200 ms.
- Audio‑Fade beim Beenden: 300 ms.

## Acceptance Criteria

1. Player öffnen startet **sofort** (Pre‑Roll falls > 0 s, sonst direkt Hauptphase). Kein initialer Play‑Tap.
2. Pre‑Roll zählt sichtbar herunter (Zahl + Bogen synchron). Audio läuft währenddessen **nicht**.
3. Übergang Pre‑Roll → Hauptphase ist nahtlos (Cross‑Fade 400 ms, Audio fadet von 0 → 100 % in 600 ms).
4. Wenn `prepTotalSeconds == 0`: Pre‑Roll wird übersprungen, Player startet direkt in der Hauptphase.
5. Kein Slider, keine ±10 s, keine vergangene Zeit. Restzeit ist die einzige Zahl auf dem Hauptphasen‑Screen.
6. Atem läuft kontinuierlich in der Hauptphase, nicht ans Audio gekoppelt.
7. Pause‑Button durch den Glaskreis hindurch erreichbar; existiert **nur** in der Hauptphase.
8. Während der Vorbereitung gibt es keinen Pause‑Button — nur Schließen.
9. Schließen‑Knopf jederzeit erreichbar, in jedem Zustand.
10. `prefers-reduced-motion`: Atem‑Animation deaktiviert; Pre‑Roll‑Bogen aktualisiert sich weiterhin.
11. Externe Pause/Play (Lockscreen, AirPods, Control Center) spiegelt im Player‑Zustand (nur in der Hauptphase relevant).

## Was bewusst NICHT enthalten ist

Damit es bei der Implementierung keine Rückfragen gibt: folgende Funktionen wurden bewusst gestrichen und sollen **nicht** ergänzt werden:

- **Slider / Scrub‑Track.** In Meditation eine Falle — landet ungewollt im Outro.
- **±10 Sekunden Skip.** Podcast‑Konvention, in Meditation nicht sinnvoll.
- **Vergangene Zeit (Elapsed).** Buchhaltung, lenkt ab.
- **„Neu starten".** Falls vermisst, in Zukunft hinter Long‑Press auf Pause — bewusst versteckt, kein primärer Pfad.
- **„+1 Min Stille" als Endgeste.** Wurde diskutiert und verworfen.
- **Cover‑Art / Artwork.** Player ist atmosphärisch, nicht visuell‑repräsentativ.

## Files in diesem Bundle

| Datei | Inhalt |
|---|---|
| `Player Optionen.html` | Design‑Canvas mit allen Varianten und Phasen. **Variante B (Atemkreis)** für die Hauptphase, **P1 (Countdown‑Zahl)** für die Vorbereitung. |
| `player-options.jsx` | React‑Mock aller Varianten und der Pre‑Roll‑Phase — Referenz für DOM‑Struktur und exakte Werte. Suchen nach `PlayerB_PrepCountdown`. |
| `Handover - Player.html` | Visuelle Zusammenfassung des Specs (Render der finalen Variante + Begründung). |
| `styles.css` | Vollständige Token‑Definition der App (mehr Tokens als der Player nutzt — relevant ist der Top‑Block `:root`). |
| `shell.jsx` | Phone‑Frame‑Wrapper (Status‑Bar etc.) — zur Orientierung, nicht 1:1 zu portieren. |
| `design-canvas.jsx` | Canvas‑Wrapper für Pan/Zoom in der Mock‑Ansicht — irrelevant für Implementierung. |

## Assets

Es werden keine Bild‑/Icon‑Assets benötigt. Alle Glyphs (Close ×, Pause ‖, Play ▶) sind als Inline‑SVG implementiert und dort 1:1 nachvollziehbar. Falls das Ziel‑Codebase eine Icon‑Library hat (z. B. SF Symbols, Material Symbols), gleichwertige Glyphs verwenden.

## Open Questions for Engineering

1. **Atemtempo.** 16 s Zyklus ist eine erste Setzung. Falls die Lehrer der App ein bestimmtes Atemmuster bevorzugen (4‑7‑8, Box‑Breathing 4‑4‑4‑4, etc.), kann der Zyklus angepasst werden — bitte mit Design abstimmen.
2. **Backdrop‑Filter‑Fallback.** Falls die Plattform `blur(8px)` nicht performant rendern kann (Android low‑end), opaque Fallback verwenden (`#1a0d09` für Pause‑Button) statt das Blur zu reduzieren.
3. **Lockscreen‑Metadaten.** Welche Felder werden ans OS übergeben (Now Playing Info)? Empfehlung: `title` = Meditationstitel, `artist` = Lehrer, `albumTitle` = „Still Moment", kein Artwork.
