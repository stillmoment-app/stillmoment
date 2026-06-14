# Handoff: Klang-Auswahl in der Gong-Konfiguration (Karten-Picker)

## Overview
In der **Gong-Konfiguration** (Screen „Meditation bearbeiten" → Abschnitt *Zusätzlicher Gong*)
wählt der Nutzer den Klang für den Start-/End-Gong einer geführten Meditation. Bisher war das
eine schlichte Liste aus Tonnamen mit Häkchen. Diese Auswahl wird jetzt auf das **Karten-Muster
des Timer-Screens „Start & Ende"** umgestellt: pro Klang eine Zeile mit Vorhör-Button,
Beschreibung, charakteristischer Mini-Wellenform und Auswahl-Häkchen.

Ziel des Handoffs: dieses Klang-Auswahl-Muster in der echten App nachbauen, sodass die
Gong-Klang-Auswahl an *beiden* Stellen (Timer „Start & Ende" **und** Meditation-Bearbeiten)
identisch aussieht und sich gleich verhält.

## About the Design Files
Die Dateien in diesem Bundle sind **Design-Referenzen, in HTML/React (Babel-im-Browser) gebaut** —
Prototypen, die Aussehen und Verhalten zeigen, **kein** produktiv zu übernehmender Code. Die
Aufgabe ist, dieses Design in der Zielumgebung der App **mit deren etablierten Mustern**
nachzubauen. Laut Design-System (`uploads/design-system/`) ist die App **iOS (SwiftUI)** und
**Android (Jetpack Compose)** — beide Plattformen verhalten sich identisch. Die HTML-Prototypen
sind die visuelle Vorlage; die Umsetzung erfolgt in SwiftUI/Compose mit den vorhandenen
Theme-/Komponenten-Strukturen.

## Fidelity
**High-fidelity.** Finale Farben, Typografie, Abstände, Radien und Interaktionen. Die Optik soll
pixelgenau nachgebaut werden — aber mit den existierenden semantischen Farb-Tokens und
Type-Tokens der App (siehe `uploads/design-system/still-moment-design.md`), nicht mit den hier
hartkodierten CSS-Variablen.

---

## Screen / View

### Meditation bearbeiten — Abschnitt „Zusätzlicher Gong" → „Klang"
- **Name:** Klang-Auswahl (Gong) im Bearbeiten-Screen einer importierten Meditation.
- **Purpose:** Nutzer aktiviert optional einen Gong am Anfang/Ende und wählt dafür *einen* Klang
  (derselbe Klang für Anfang und Ende). Die Klang-Liste erscheint nur, wenn mindestens einer der
  beiden Schalter („Gong am Anfang" / „Gong am Ende") an ist.
- **Layout (von oben):**
  1. `Informationen` (Lehrer/Guide, Name) — unverändert.
  2. `Wiedergabebereich` — unverändert.
  3. `Zusätzlicher Gong` (Section-Header, Newsreader Light 20px) → Karte mit zwei Schalter-Zeilen
     *Gong am Anfang* / *Gong am Ende*.
  4. **NEU:** Eyebrow-Label `KLANG` (11px, tracked uppercase) → **Klang-Liste als Karte**.

#### Komponente: Klang-Liste (die Änderung)
Eine einzelne Karte (`.tone-list`), die alle Klänge als Zeilen enthält:

- **Container** (`.tone-list`): Hintergrund `surface`, 1px Rahmen `border`, Radius **22px**,
  im Hell-Theme Schatten `card-shadow`, im Dunkel-Theme **kein** Schatten (Rahmen statt Schatten),
  `overflow: hidden`.
- **Zeile** (`.tone`): Flex-Row, `align-items:center`, `gap:14px`, Padding **13px 16px**,
  volle Breite, transparenter Hintergrund, Cursor pointer. Zwischen Zeilen 1px Trennlinie
  (`divider`). Ausgewählte Zeile: Hintergrund `accent-fill`.
- **Vorhör-Button** (`.preview-btn`), links: Kreis **42×42**, 1px `border`, Hintergrund
  `surface-2`, Play-Glyph in `accent`.
  - Ausgewählt: Hintergrund `accent`, Glyph `on-accent`, kein Rahmen.
  - Beim Vorhören: expandierender Ring (`::after`, 2px `accent`, Keyframe `ring`, **0.9s ease-out**,
    Skalierung 0.85→1.7, Opazität 0.7→0).
  - `:active` → `scale(0.92)`.
- **Mitte** (`.tone-main`, `flex:1`):
  - **Name** (`.tone-name`): Geist 16px, Farbe `ink`. Ausgewählt: `accent`, Weight 500.
  - *Keine Beschreibungszeile* — bewusst weggelassen, nur der Klangname steht in der Zeile.
- **Mini-Wellenform** (`.tone-wave`), rechts vor dem Häkchen: 11 vertikale Balken, `gap:2px`,
  Höhe-Box 22px. Balken (`i`): Breite **2.5px**, Radius 2px, Farbe `ink-4`; ausgewählt
  `accent-soft`. Balkenhöhe je Index = `4 + round(env * 16)` px, `env` aus der WAVE-Tabelle unten.
  Die Wellenform ist **statisch** und kodiert den Charakter des Klangs (Anschlag links →
  Ausklang rechts).
- **Häkchen** (`.tone-check`), ganz rechts, nur bei ausgewählter Zeile: Check-Glyph in `accent`.

**Reihenfolge der Klänge** (`TONE_ORDER`) — nur der Name wird angezeigt, keine Beschreibung:

1. Tempelglocke *(Default)*
2. Klangschale
3. Klassisch
4. Tiefe Resonanz
5. Klarer Anschlag

**WAVE-Hüllkurven** (11 Werte 0..1, ergeben die Balkenhöhen):

```
Tempelglocke    [0.35, 0.90, 1.00, 0.85, 0.78, 0.68, 0.60, 0.50, 0.42, 0.34, 0.26]
Klangschale     [0.30, 0.60, 0.85, 1.00, 0.90, 0.82, 0.74, 0.66, 0.56, 0.46, 0.36]
Klassisch       [0.30, 0.95, 0.80, 0.65, 0.55, 0.45, 0.40, 0.32, 0.28, 0.22, 0.18]
Tiefe Resonanz  [0.45, 0.70, 0.90, 1.00, 0.92, 0.86, 0.80, 0.72, 0.64, 0.54, 0.44]
Klarer Anschlag [0.25, 1.00, 0.70, 0.45, 0.30, 0.20, 0.14, 0.10, 0.08, 0.06, 0.05]
```

> Die HTML-Prototypen synthetisieren den Gong-Ton zur Vorschau per WebAudio (`gong-audio.jsx`).
> In der App ist das durch das **echte Abspielen der jeweiligen Gong-Audiodatei** zu ersetzen.
> Die WAVE-Werte dienen nur der *visuellen* Mini-Wellenform und können in der App z.B. aus den
> echten Sample-Hüllkurven oder als feste Design-Konstante übernommen werden.

---

## Interactions & Behavior
- **Zeile antippen** (`.tone`): wählt diesen Klang aus *und* spielt eine kurze Vorschau.
- **Vorhör-Button antippen** (`.preview-btn`): spielt nur die Vorschau, **ohne** die Auswahl zu
  ändern (Klick-Propagation wird gestoppt). Ring-Animation 900 ms; danach Ring zurückgesetzt.
- **Sichtbarkeit:** Die ganze Klang-Liste erscheint nur, wenn „Gong am Anfang" *oder* „Gong am
  Ende" aktiv ist. Sind beide aus, wird sie ausgeblendet.
- **Ein Klang für beides:** Es gibt genau eine Auswahl — derselbe Klang für Anfang und Ende.
- **Lautstärke ist automatisch:** kein Lautstärke-Slider in diesem Screen. Die Gong-Lautstärke
  wird aus der Lautheit (RMS) der Sprachaufnahme abgeleitet (Prototyp: `autoGongLevel`, Gong sitzt
  ca. +6 dB über der mittleren Sprachlautstärke). Hinweistext im Screen:
  *„Die Lautstärke folgt den Gong-Einstellungen des Timers."*
- **Reduced motion:** Animationen werden bei `prefers-reduced-motion: reduce` praktisch
  deaktiviert.

## State Management
- `tone: string` — aktuell gewählter Klang (Default `"Tempelglocke"`).
- `startOn: bool`, `endOn: bool` — die beiden Gong-Schalter; `anyOn = startOn || endOn` steuert die
  Sichtbarkeit der Klang-Liste.
- `ringing: string|null` — welcher Vorhör-Button gerade die Ring-Animation zeigt (transient,
  ~900 ms).
- Theme: hell/dunkel (in der App über das vorhandene reaktive Theme-Environment).

## Design Tokens
Semantische Rollen (App nutzt diese, nicht direkte Werte). Werte aus `gong.css`:

| Rolle | Hell | Dunkel |
|------|------|--------|
| `surface` (Karte) | `#FFF6E6` | `#2E211A` |
| `surface-2` (Vorhör-Button-Fläche) | `#FBEAD2` | `#3A2A21` |
| `border` | `rgba(120,55,28,.11)` | `#4E382C` |
| `divider` | `rgba(120,55,28,.14)` | `rgba(242,228,211,.10)` |
| `accent` (Play, Name aktiv, Häkchen) | `#A2503E` | `#C77D63` |
| `accent-soft` (Wellenform aktiv) | `#B85F46` | `#D68A6E` |
| `accent-fill` (Zeile aktiv) | `rgba(162,80,62,.10)` | `rgba(199,125,99,.12)` |
| `on-accent` (Glyph auf accent) | `#FFF6E6` | `#1A100C` |
| `ink` (Name) | `#3A2418` | `#E5DCCD` |
| `ink-4` (Wellenform inaktiv) | `#BBA08C` | `#6E574B` |

- **Radius:** Karte `r-lg` = **22px**.
- **Schatten:** Hell = `card-shadow` (`0 1px 2px rgba(50,32,20,.05), 0 4px 14px rgba(50,32,20,.07)`);
  Dunkel = **kein Schatten**, stattdessen 1px Rahmen (Design-Regel „Hell = Schatten, Dunkel = Rahmen").
- **Typografie:** Name 16px (Geist); Eyebrow `KLANG` 11px, letter-spacing 0.22em, uppercase,
  Weight 500. (Keine Beschreibungszeile.)

## Assets
Keine Bilddateien. Alle Glyphen (Play, Check, Wellenform) sind Inline-SVG (siehe `gong-sheet.jsx`).
Gong-Klänge in der App: die echten Audiodateien der jeweiligen Töne.

## Files
In diesem Bundle:
- `Gong-Konfiguration.html` — Einstieg / Prototyp-Shell (React + Babel via CDN).
- `gong-app.jsx` — der Bearbeiten-Screen (Informationen, Wiedergabebereich, Zusätzlicher Gong,
  Einbindung der Klang-Liste). **Hier** sitzt der Eyebrow `KLANG` + `<GongKlang>`.
- `gong-sheet.jsx` — **die geänderte Komponente** `GongKlang` (die Klang-Karten-Liste, **ohne**
  Beschreibungszeile) inkl. `ToneWave` und der WAVE-Hüllkurven.
- `gong-audio.jsx` — WebAudio-Gong-Synthese + Sprach-RMS-Modell (nur Prototyp; in der App durch
  echte Audiowiedergabe ersetzen). Enthält `TONE_ORDER` und die Beschreibungen.
- `gong.css` — alle Styles inkl. `.tone-list`, `.tone`, `.preview-btn`, `.tone-wave`,
  `.tone-name`, `.tone-desc`, `.tone-check`.
- `tweaks-panel.jsx` — nur Prototyp-Hilfsmittel (Theme/Recording umschalten), **nicht** Teil der App.

Referenz für dieselbe Optik am Timer (Vorlage): `prototypen/gong-start-ende/` im selben Projekt
(`Start-Ende-Gong-Auswahl.html`, `auswahl-app.jsx`, `auswahl.css`).
