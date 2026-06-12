# Handoff: Trim-Editor — touch-robuste Punkt-Bedienung

## Overview
Editor zum Setzen eines **Wiedergabe-Bereichs** (Anfang/Ende) auf einer Audiodatei einer
Meditations-App ("Still Moment"). Zusätzlich lässt sich eine **Abspielposition** (Playhead)
setzen, um den Schnitt vorzuhören. Die Datei selbst wird nicht verändert — es werden nur
zwei Zeitmarken (`start`, `end`) gespeichert.

Der Editor öffnet sich als Vollbild-Sheet aus dem Formular "Meditation bearbeiten" (Tippen auf
die Karte "Wiedergabe-Bereich") und schreibt beim Tippen auf **Fertig** die Werte zurück.

**Kernpunkt dieses Handovers — das gelöste Problem:** Auf einer schmalen Timeline konkurrieren
drei ziehbare Elemente (Abspielposition + 2 Trim-Marken) um denselben Fingertipp. Sie kamen sich
bei Touch-Bedienung ins Gehege; Anfang/Ende rutschten übereinander und ließen sich kaum trennen.
Die Lösung (siehe **Interactions & Behavior**) ist der eigentliche Liefergegenstand.

## About the Design Files
Die Dateien unter `reference/` sind **Design-Referenzen in HTML/React (Babel-in-Browser)** —
ein Prototyp, der Aussehen und Verhalten zeigt, **kein** produktiv zu kopierender Code. Aufgabe ist,
dieses Design in der **bestehenden Umgebung der Ziel-App** nachzubauen (React Native / SwiftUI /
Flutter / Web — je nach App) mit deren etablierten Patterns. Falls noch keine Umgebung existiert,
das passendste Framework wählen. Die Interaktions-Logik (Geometrie/Hit-Testing) ist
framework-unabhängig und 1:1 übertragbar.

## Fidelity
**High-fidelity.** Finale Farben, Typografie, Abstände und Interaktionen. UI pixelnah mit den
Libraries/Patterns der Ziel-Codebasis nachbauen. Werte unten sind exakt.

---

## Screens / Views

### 1. Formular "Meditation bearbeiten" (Einstiegspunkt)
- **Purpose:** Metadaten der Meditation ansehen; Einstieg in den Zuschnitt.
- **Layout:** Phone 393×852. Statusbar (54px) → Navbar (44px, "Abbrechen" / Titel zentriert /
  "Speichern") → vertikale Spalte, Padding `8px 18px`, `gap: 14px`.
- **Components:**
  - Zwei Info-Karten (Lehrer:in, Name): `.card`, Padding `13px 16px`. Label = `metaLbl`
    (11px, uppercase, letter-spacing .12em, Farbe `--sm-text-3`), Wert in Serifenschrift 18px.
  - Dateizeile: 11.5px, `--sm-text-3`, Text `evening-wind-down.mp3 · 19:05`.
  - **Karte "Wiedergabe-Bereich"** (Button, öffnet Sheet): `.card`, Padding `14px 16px`.
    - Zustand *ungetrimmt*: Zeile "Ganze Datei · 19:05" (Serif 19px) + rechts Scheren-Icon
      + "Bereich wählen" (`--sm-accent-text`, 13.5px).
    - Zustand *getrimmt*: kompakte, nicht-interaktive `TrimTrack` (height 44, ohne Playhead-Lane)
      + Zeile "`m:ss – m:ss`" (Serif 22px, `--sm-accent-text`) und "`m:ss` hörbar".
  - Hinweistext (12px, `--sm-text-3`).
  - Bei getrimmt: Textbutton "Zuschnitt entfernen".

### 2. Editor-Sheet "Zuschneiden"
- **Purpose:** Anfang, Ende und Abspielposition setzen; Schnitt vorhören.
- **Layout:** Absolut über dem Formular (`position:absolute; inset:0; z-index:20`).
  Einblenden per `transform: translateY(100%→0)`, `transition: transform .4s cubic-bezier(.32,.72,0,1)`.
  Hintergrund radialer Verlauf (siehe Tokens). Statusbar → Navbar ("‹" zurück / "Zuschneiden" /
  "Fertig"). Content-Padding `10px 24px`, Flex-Spalte.
- **Components (von oben):**
  1. Titelblock zentriert: "Evening Wind Down" (Serif 22px), "Tara Goldstein · 19:05" (13px, `--sm-text-2`).
  2. Großer Readout: Label "Anfang/Ende der Wiedergabe" (`metaLbl`); Zeit in Serif **58px**,
     Farbe `--sm-accent-text`, `font-feature-settings:"tnum"`; darunter "Hörbar: a – b · dauer" (13px).
  3. **`TrimTrack`** (Kern, siehe unten), `height = 104`.
  4. Zeitachse darunter: drei Spans `0:00` / aktuelle Playhead-Zeit (Sage wenn spielt) / `19:05` (11px).
  5. Zwei `ReadoutCard` (Anfang / Ende), `gap:10`. Aktive Karte: Hintergrund `--sm-accent-dim`,
     Border `rgba(214,138,110,.4)`; Label `metaLbl`, Wert Serif 26px. Tippen wählt aktive Marke
     **und** setzt Playhead auf deren Wert.
  6. Transport: `−1s` | runder Play/Pause-Button (64px) | `+1s`. Play startet ab der **Abspielposition**.
  7. Hinweistext: "Oben ziehen = Abspielposition · unten ziehen = gewählte Marke / ▶ spielt ab der Abspielposition".
  8. Textbutton "Ganze Datei verwenden" (setzt start=0, end=TOTAL).

---

## Interactions & Behavior  ← **Hauptteil**

### Datenmodell der Spur
- Gesamtlänge `TOTAL = 1145` Sekunden (19:05). `start`, `end`, `head` (Playhead) je in Sekunden.
- Minimal hörbare Dauer `MINGAP = 25` s → `start ≤ end − 25`, `end ≥ start + 25` (Crossing verhindert).
- `head` frei in `[0, TOTAL]` (darf außerhalb der Region liegen, zum Vorhören des Anlaufs).
- `x ↔ Sekunde` linear: `sec = clamp((x − trackLeft)/trackWidth, 0, 1) · TOTAL`.

### Die drei Entkopplungs-Prinzipien (das Wesentliche)

**A) Vertikale Halbierung der Trefferfläche.** Die Spur hat zwei vertikale Zonen über *derselben*
horizontalen Breite:
- **Obere Hälfte (oberste 45 %, `SPLIT = 0.45`) → Abspielposition (Playhead).**
- **Untere Hälfte (55 %) → die aktive Trim-Marke.**
Ein Pointerdown entscheidet allein über die **y-Koordinate** relativ zur Spurhöhe, welche der beiden
Bedienungen greift. Dadurch konkurrieren Playhead und Marken nie um denselben Punkt.
Eine feine Trennlinie bei 45 % und eine zarte Sage-Tönung der oberen Zone zeigen die Grenze.
Zusätzlich gibt es oberhalb der Wellenform eine schmale beschriftete **Playhead-Lane (34px)**, in der
der Sage-Greifer "wohnt" und ebenfalls gezogen werden kann.

**B) Immer nur EINE aktive Marke.** Welche Marke die untere Hälfte bewegt, bestimmt die
Auswahl (`active ∈ {"start","end"}`) — gesetzt über die Readout-Karten *oder* durch direktes
Greifen einer Marke. Liegen Anfang/Ende übereinander (Cluster), **gewinnt immer die aktive Marke**
den Touch → man greift nie versehentlich die falsche. Sind sie auseinander, lässt sich jede direkt anfassen.

**C) Rein geometrisches Hit-Testing** statt überlappender DOM-Hit-Boxen. Alle Griffe sind **rein
visuell** (`pointer-events: none`); ein einziger Pointerdown-Handler auf der Spur berechnet aus
x (und y für die Halbierung) die Aktion. Das ist robust gegen Überlappung und z-index-Konflikte.

### Pointer-Logik (Pseudocode — 1:1 übertragbar)
```
GRAB = 22 px            // so nah am Griff = direkter Griff (relativ, kein Sprung)
SPLIT = 0.45            // y-Grenze obere/untere Hälfte

onPointerDown(e) auf der Spur:
  ly = e.y − trackTop
  if ly < trackHeight * SPLIT:   beginDrag("head", e)     // obere Hälfte → Playhead
  else:                          beginDragMark(e)         // untere Hälfte → Marke

beginDrag("head", e):
  hpx = pxOf(head)
  offset = |e.x − trackLeft − hpx| ≤ GRAB ? (hpx − (e.x−trackLeft)) : 0   // greifen vs. springen
  drag = {kind:"head", offset}
  seek(secAt(e.x, offset))

beginDragMark(e):
  lx = e.x − trackLeft
  sPx = pxOf(start); ePx = pxOf(end)
  dS = |lx − sPx|; dE = |lx − ePx|
  if dS ≤ GRAB && dE ≤ GRAB:  kind = active;  offset = pxOf(active==="start"?start:end) − lx  // Cluster: aktive gewinnt
  else if dS ≤ GRAB && dS ≤ dE: kind = "start"; offset = sPx − lx                              // direkt am Anfang
  else if dE ≤ GRAB:            kind = "end";   offset = ePx − lx                              // direkt am Ende
  else:                         kind = active;  offset = 0                                     // leere Fläche: aktive springt her
  drag = {kind, offset}
  applyMark(kind, secAt(lx, offset))   // setzt active = kind

onPointerMove(e):                       // global (window), nicht nur auf der Spur
  if !drag: return
  t = clamp(((e.x − trackLeft) + drag.offset)/trackWidth, 0,1) * TOTAL
  if drag.kind === "head": seek(t)
  else if drag.kind === "start": setTrim(min(t, end−MINGAP), end, "start")
  else                          setTrim(start, max(t, start+MINGAP), "end")

onPointerUp():
  k = drag.kind; drag = null
  if k !== "head":  head = (k==="start"?start:end); playPreview(head, 2200ms)   // Schnitt kurz vorhören
```
Wichtig: `pointermove`/`pointerup`/`pointercancel` an **window** hängen (nicht nur an die Spur),
damit der Zug auch außerhalb der Spur weiterläuft. Auf der Spur `touch-action: none` setzen.

### Vorhören / Wiedergabe-Engine
- `play(from)`: zählt `head` per Frame-Loop ab `from` hoch bis `TOTAL` (Icon ▶/⏸).
- `preview(from, ms)`: kurze Wiedergabe (z.B. 1400 ms beim Nudge, 2200 ms nach Marken-Drag), lässt den
  Play-Button ruhig. Jeder Seek/Drag pausiert eine laufende Wiedergabe zuerst.
- `−1s/+1s` (Nudge): verschiebt die **aktive** Marke um ±1 s (geklammert), setzt `head` dorthin,
  spielt 1400 ms Vorschau.
- Play-Button: spielt ab `head`; im Spielzustand pausieren.

### Visuelle Greifer (Symmetrie oben/unten)
- **Playhead (Sage):** in der oberen Lane — abgerundeter Greifer 32×20 mit zwei Griff-Rillen +
  nach unten zeigende Dreiecksspitze; dünne Sage-Linie läuft durch die Wellenform (visuell,
  `pointer-events:none`). Beim Ziehen Zeit-Blase darüber.
- **Trim-Marken (Kupfer):** dünne **Schnittkante über volle Höhe** (3–4px) + Griff-Knopf klar in
  der **unteren Hälfte** (`top:74%`), 16×38 (aktiv 20×44), 2 Griff-Rillen. Aktiv = breiter,
  Glow-Ring `0 0 0 2px rgba(214,138,110,.35)` + sanfter Puls (`trimHandlePulse`, nur wenn aktiv & nicht ziehend).
  Region zwischen den Marken: Wellenbalken in `--sm-accent` (außerhalb gedämpft), Highlight-Overlay
  `rgba(196,122,94,.12)` mit beidseitigen Borders.
- Zeit-Blase (beim Ziehen): Pille, Serif 15px; Kupfer-Blase Text `#2a1208`, Sage-Blase Bg
  `#a7c2b1` / Text `#13251c`; `top:-32`, zentriert.

### Darstellungs-Varianten (Tweak "Darstellung der Spur")
- **Wellenform** (Default): 220 statische Balken (deterministisch erzeugt, siehe `WAVE` in der Referenz —
  in Produktion durch echte Hüllkurven-/Peak-Daten ersetzen).
- **Slider:** dünne Schiene (6px, radius 999) statt Balken; Marken als 44px-Knöpfe.
- **Marker:** wie Slider + zwei einrastbare Punkte an erkannten Kanten (`MARKERS = [90, 1105] s`),
  Tippen rastet die aktive Marke dort ein (kurze Vorschau).
Die Halbierungs- und Aktiv-Logik gilt in allen Varianten gleich.

## State Management
- `trim: {start, end} | null` (null = ganze Datei) — im Formular, persistiert beim "Fertig".
- `sheet: boolean` — Editor offen.
- Im Sheet lokal: `start`, `end`, `active ("start"|"end")`, `head`, `playing`, `previewing`.
- Beim Öffnen: Werte aus `trim ?? {0, TOTAL}` übernehmen, `active="start"`, `head=start`, pausieren.
- "Fertig": runden; wenn `start≤1 && end≥TOTAL−1` → `trim=null`, sonst `{start,end}`.

## Design Tokens
**Farben**
- Hintergründe: `--sm-bg-deep #150a07`, `--sm-bg-1 #221310`, `--sm-bg-2 #2c1a15`, `--sm-bg-3 #3a221c`
- Karten: `--sm-card #2a1812`, `--sm-card-hi #341e17`, Linie `--sm-card-line rgba(235,226,214,.06)`
- **Kupfer-Akzent (Marken):** `--sm-accent #c47a5e`, `--sm-accent-soft #b06a4f`, `--sm-accent-glow #d68a6e`,
  `--sm-accent-dim rgba(196,122,94,.18)`, `--sm-accent-text #d99a7e`
- **Sage (Abspielposition):** `#8aa896` (hell `#a7c2b1`) — bewusst andere Farbe als die Marken
- Text: `--sm-text #ebe2d6`, `--sm-text-2 #a89a8c`, `--sm-text-3 #6f6358`, `--sm-text-4 #4a4039`
- Sheet-Hintergrund: `radial-gradient(ellipse 90% 70% at 50% 20%, #3a201a 0%, #2a1610 40%, #190c08 75%, #110705 100%)`

**Typografie**
- Display/Serif: `"Newsreader", Georgia, serif` (Zeiten, Titel)
- UI/Sans: `"Geist", -apple-system, system-ui, sans-serif`
- Zahlen immer `font-feature-settings:"tnum"` (Tabular).

**Radien:** sm 12 · md 18 · lg 24 · xl 32 · pill 999. **Min. Touch-Ziel:** 44px.
**Konstanten:** `TOTAL=1145`, `MINGAP=25`, `GRAB=22`, `SPLIT=0.45`, Lane-Höhe 34, Spur-Höhe 104.

## Assets
Keine Bilddaten. Alle Icons sind Inline-SVG (Play, Pause, Chevrons, Scissor, Statusbar) — in der
Ziel-App durch das vorhandene Icon-Set ersetzen. Schriften Newsreader + Geist via Google Fonts
(oder App-eigene Entsprechungen). Wellenform-Daten in Produktion aus echten Audio-Peaks.

## Files (in `reference/`)
- `Trim Editor.html` — Einstieg, lädt React/Babel + die JSX-Dateien.
- `trim-editor.jsx` — **Kern:** `TrimTrack`, `TrimSheet`, `App`, `usePlayhead`, Pointer-Logik.
- `shell.jsx` — Statusbar/Tabbar/Phone-Hülle + Icons (`window.SM`).
- `styles.css` — Design-Sprache "Still Moment" (Tokens, Karten, Buttons).
- `tweaks-panel.jsx` — nur fürs Prototyp-Tweak-Panel (Darstellungs-Umschalter); in Produktion nicht nötig.
