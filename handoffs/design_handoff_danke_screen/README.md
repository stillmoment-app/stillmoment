# Handoff: Danke-Screen (Still Moment)

## Overview

Redesign des „Vielen Dank"-Screens, der nach einer abgeschlossenen Meditation
(geführt **oder** frei) angezeigt wird. Ziel: den bestehenden,
etwas transaktional wirkenden Screen warmherziger zu machen, **ohne**
Statistiken, Streaks oder Zahlen — die App erhebt bewusst keine.

Der neue Screen besteht aus drei Elementen:

1. Ein ruhig pulsierender, warmer **Glow-Kreis** (dasselbe Atem-Vokabular,
   das die App am Sitzungs-Anfang verwendet).
2. Eine **warme Botschaft**: „Danke, dass du dir diesen Moment genommen hast."
3. Ein **„Fertig"-Button**, der zurück zur Startansicht führt.

## About the Design Files

Die Dateien in diesem Bundle sind **Design-Referenzen, gebaut als HTML/React-
Prototyp**. Sie zeigen Look & Verhalten — sie sind **nicht** dazu gedacht,
1:1 in die Produktion übernommen zu werden.

Aufgabe: Den hier dokumentierten Screen in der **bestehenden Codebase** von
Still Moment nachbauen, in deren etablierten Patterns (Komponenten,
Theme-Tokens, Animations-System). Wenn noch keine Umgebung existiert,
das passende Framework wählen und dort umsetzen.

## Fidelity

**High-Fidelity.** Farben, Typografie, Abstände, Radien, Glow-Werte und
Animations-Timings sind final. Bitte pixel-genau umsetzen — Abweichungen
nur dort, wo das Design-System der Codebase äquivalente Tokens vorgibt.

## Screen

### Name
`ThankYouScreen` (oder gemäss interner Namenskonvention, z. B. `SessionComplete`).

### Purpose
Schliesst eine Sitzung wärmehaltig ab. Wird automatisch angezeigt, sobald
eine geführte oder freie Meditation endet (Timer abgelaufen oder Audio
fertig). Antippen von „Fertig" navigiert den User zurück zum Home/Library-
Screen.

### Layout

Vollflächiger Screen über die gesamte Safe Area, vertikal zentrierter Stack:

```
┌─────────────────────────────────┐
│   Status Bar (System)           │
│                                 │
│                                 │
│             ╭─────╮             │
│            │ Glow │              │   ← Glow-Kreis, 160×160 px Bounding-Box
│             ╰─────╯             │
│                                 │
│      Danke, dass du dir         │   ← Headline, max-width 320, balance
│      diesen Moment              │
│      genommen hast.             │
│                                 │
│                                 │
│           ┌────────┐            │
│           │ Fertig │            │   ← Primary Button
│           └────────┘            │
│                                 │
│                                 │
│         Home Indicator          │
└─────────────────────────────────┘
```

- Container: full bleed, `display: flex; flex-direction: column;
  align-items: center; justify-content: center;` mit horizontalem Padding
  von **40 px**.
- Stack-Abstände: Glow → Headline **44 px**, Headline → Button **92 px**.
- Alles vertikal zentriert; auf kleinen Geräten (≤ 667 px Höhe) ggf.
  Abstände proportional reduzieren.

### Components

#### 1. Background

- Radial Gradient, vom warmen Braun ausgehend nach innen,
  fast schwarz zum Rand:
  ```
  background: radial-gradient(
    ellipse 90% 70% at 50% 35%,
    #3a201a 0%,
    #2a1610 38%,
    #190c08 72%,
    #110705 100%
  );
  ```

#### 2. Glow Orb

Zwei konzentrische Kreise — **statisch**, nicht animiert. Die Sitzung
ist vorbei; ein pulsierender Atem würde fälschlich Aktivität suggerieren.
Stattdessen ein ruhiges, nachglimmendes Licht.

**Bounding-Box:** 180 × 180 px, zentriert.

**Äusserer Halo** (180 × 180 px, absolute fill):
```
border-radius: 50%;
background: radial-gradient(
  circle at 50% 50%,
  rgba(217, 154, 126, 0.22),
  rgba(196, 122,  94, 0.05) 55%,
  transparent 78%
);
```

**Innerer Kern** (96 × 96 px, zentriert):
```
border-radius: 50%;
background: radial-gradient(
  circle at 50% 45%,
  rgba(232, 178, 148, 0.9),
  rgba(217, 154, 126, 0.55) 38%,
  rgba(196, 122,  94, 0.18) 68%,
  transparent 88%
);
box-shadow: 0 0 70px 10px rgba(217, 154, 126, 0.22);
```

Keine Keyframes, keine Animation auf dem Glow.

#### 3. Headline

- Copy (exakt): **„Danke, dass du dir diesen Moment genommen hast."**
- Manueller Zeilenumbruch nach „diesen": die Headline soll auf
  Standard-iPhone-Breite **zwei Zeilen** ergeben:
  ```
  Danke, dass du dir diesen
  Moment genommen hast.
  ```
- Font: **Newsreader** (Google Font), Regular (400)
- Size: **28 px**
- Line-Height: **1.3**
- Letter-Spacing: **−0.005em**
- Color: **#ebe2d6**
- `text-wrap: balance;`
- `max-width: 320 px`, horizontal zentriert
- `text-align: center`

#### 4. Primary Button — „Fertig"

- Copy: **Fertig**
- Padding: **16 px 56 px**
- Border-Radius: **999 px** (Pill)
- Background: linearer Verlauf `linear-gradient(180deg, #d68a6e, #b06a4f)`
- Color (Text): **#1a0d09**
- Font: **Geist** (Google Font), 600 (Semibold)
- Size: **17 px**
- Letter-Spacing: **0.01em**
- Border: keine
- Shadow: `0 16px 40px -12px rgba(196, 122, 94, 0.5)` (warmer Glow)
- Cursor: pointer
- Hit-Target: mindestens 44 × 44 pt

##### Button-States
- **Default**: wie oben
- **Pressed**: scale `0.97`, Shadow-Intensität auf `0.35` reduzieren,
  Transition 120 ms `ease-out`
- **Disabled**: nicht vorgesehen — der Button ist immer aktiv
- **Focus** (Keyboard, falls Web): 2 px Outline in `#d99a7e`,
  Offset 3 px

## Interactions & Behavior

- **Auftritt**: Der Screen erscheint ohne Animation — direkter Schnitt
  vom Sitzungs-Ende auf den Danke-Screen. Bewusst: die Stille soll nicht
  durch UI-Bewegung gestört werden.

- **Glow**: statisch, keine Loop-Animation. Die Sitzung ist zu Ende;
  ein atmender Kreis würde fälschlich „die App arbeitet noch" suggerieren.

- **„Fertig" Tap**: navigiert zurück zum Startscreen / zur Library
  (analog zum heutigen „Zurück"-Verhalten). Beim Verlassen 200 ms
  Fade-out des gesamten Screens.

- **Hardware-Back** (Android) / **Swipe-back** (iOS): identisch zum
  Tap auf „Fertig".

## State Management

Der Screen ist zustandslos. Er bekommt keine Props ausser ggf. einen
`onDone`-Callback. Keine Daten-Fetches, keine persistenten Werte.

```ts
type ThankYouScreenProps = {
  onDone: () => void;
};
```

## Design Tokens

### Colors

| Token              | Wert        | Verwendung                          |
|--------------------|-------------|-------------------------------------|
| `bg.deep`          | `#150a07`   | Hintergrund-Außenring               |
| `bg.0`             | `#110705`   | Hintergrund-äusserer Stop           |
| `bg.1`             | `#190c08`   | Hintergrund-Stop                    |
| `bg.2`             | `#2a1610`   | Hintergrund-Stop                    |
| `bg.3`             | `#3a201a`   | Hintergrund-Stop (zentral)          |
| `accent.core`      | `#e8b294`   | Glow-Kern (heisser Punkt)           |
| `accent`           | `#d99a7e`   | Glow Mid · Button-Highlight         |
| `accent.warm`      | `#c47a5e`   | Glow Outer · Button-Schatten        |
| `accent.deep`      | `#b06a4f`   | Button-Verlauf unten                |
| `accent.glow`      | `#d68a6e`   | Button-Verlauf oben                 |
| `text`             | `#ebe2d6`   | Headline                            |
| `text.on-accent`   | `#1a0d09`   | Button-Label                        |

### Typography

- **Display** (Headline): `Newsreader`, Regular (400), 28 px / 1.3,
  letter-spacing −0.005em
- **UI** (Button): `Geist`, Semibold (600), 17 px, letter-spacing 0.01em

Beide Fonts via Google Fonts importiert. In der Codebase die existierende
Font-Loading-Strategie verwenden (Self-host empfohlen).

### Spacing

| Token | Wert  | Verwendung                       |
|-------|-------|----------------------------------|
| `sp.lg`  | 40 px | Horizontales Screen-Padding   |
| `sp.xl`  | 44 px | Glow → Headline               |
| `sp.2xl` | 92 px | Headline → Button             |

### Radii

| Token   | Wert     | Verwendung      |
|---------|----------|-----------------|
| `r.full`| `999 px` | Button (Pill)   |
| `r.orb` | `50 %`   | Glow-Kreise     |

### Shadows

- **Button**: `0 16px 40px -12px rgba(196, 122, 94, 0.5)`
- **Glow Inner**: `0 0 60px 8px rgba(217, 154, 126, 0.25)`

### Animation

Keine. Der Screen ist statisch — Glow, Headline und Button erscheinen
ohne Fade oder Stagger. Begründung: nach einer Meditation soll die
Stille fortgesetzt werden, nicht durch UI-Bewegung unterbrochen.

## Assets

Keine externen Bild- oder Icon-Assets nötig. Der gesamte Screen ist
mit CSS-Gradients und Web-Typografie umgesetzt.

Status-Bar im Prototyp ist nur eine visuelle Hülle — bitte die native
System-Status-Bar verwenden.

## Files

In diesem Bundle:

- **`index.html`** — Einstiegspunkt, im Browser öffnen, um den
  finalen Screen + ein direktes Vorher/Nachher-Vergleichsbild zu sehen.
- **`danke-final.jsx`** — React-Komponenten der Referenz (StatusBar, GlowOrb,
  DankeFinal, ComparePanel).
- **`styles.css`** — Design-Tokens als CSS Custom Properties + Keyframes
  (`dk-breathe`, `dk-glow-pulse`).
- **`design-canvas.jsx`** — Wrapper-Komponente, die den Prototyp im Browser
  layoutet. **Wird nicht für die Implementierung gebraucht.**

## Was sich gegenüber dem alten Screen geändert hat

Damit klar ist, warum welcher Wert so gewählt wurde:

1. **Herz-Icon raus** → ruhiger, **statischer** Glow-Kreis. Greift das
   warme Licht-Vokabular der App auf, pulsiert aber bewusst nicht: die
   Sitzung ist zu Ende, Bewegung würde Aktivität suggerieren.
2. **„Vielen Dank" → „Danke, dass du dir diesen Moment genommen hast."**
   Aktive, warme Aussage statt transaktionale Floskel. Die separate
   Subline aus dem alten Screen entfällt.
3. **Subline gestrichen** — der eine Satz trägt allein.
4. **„Zurück" → „Fertig"**. Wärmerer Abschluss, kein Rückzugs-Wording.
5. **Keine Zahlen, keine Streaks, keine Statistiken.** Bewusste
   Produkt-Entscheidung. Identisch nach geführter wie freier Sitzung.
