# Handoff: Player — Kerzenschein 2.0 · Anpassung

## Übersicht

Dies ist ein **Update des Player-Screens** der Meditations-App **Still Moment**, im Zuge des Theme-Refinements auf **Kerzenschein 2.0**. Die zugrunde liegende Designentscheidung (Player radikal reduziert auf Pause + Restzeit-Bogen, keine Slider/Skip/Restart-Gesten) **bleibt unverändert** — wir liefern hier nur das Delta gegenüber dem vorherigen Handoff (`design_handoff_player/`):

1. **Hintergrund** wechselt vom radialen Mahagoni-Verlauf auf das KS-2.0-**Linear**-Gradient (Lifted Warm im Dark / Sunrise Confident im Light).
2. **Der atmende Halo um den Pause-Button ist entfernt.** Keine Animation, keine Skalierung, kein Opazitäts-Puls. An seiner Stelle: eine statische, sehr dezente Glühscheibe als reiner visueller Anker.
3. **Ring übernimmt die KS-2.0-Ring-Norm** — 1 px Base @ 0,32 und 1,5 px Arc @ 0,72 in `interactive` (Akzent), plus die wandernde Knubbel-Perle an der Vorderkante.
4. **Pre-Roll zeigt keinen Sitzungs-Fortschritt mehr im Ring** — nur die Base-Ring-Linie und die Countdown-Zahl. Der Sitzungs-Arc beginnt erst, wenn die Meditation tatsächlich läuft.
5. **Light-Variante** ist erstmals spezifiziert (vorher Dark-only). Beide Modi nutzen dieselbe Geometrie + Animation-Profil; nur die Tokens flippen.

Wir liefern bewusst **keine** weiteren Verhaltensänderungen — Auto-Start, Cross-Fade Pre-Roll → Haupt, Pause/Resume-Toggle, Schließen-Verhalten, Lockscreen-Spiegelung, alles bleibt wie im ursprünglichen Player-Spec.

## Über die Design-Dateien

`Theme Pair Preview.html` ist eine **HTML-Design-Referenz**, kein Produktionscode. In SwiftUI mit den etablierten Patterns nachbauen. Der ursprüngliche Spec aus `design_handoff_player/README.md` gilt weiter — die Abschnitte unten überschreiben ihn nur dort, wo sich etwas ändert.

## Fidelity

**High-fidelity.** Alle Hex-Werte, Opacities, Radien und Stroke-Widths sind final. Pixelgenau übernehmen.

---

## Was sich ändert — fünf konkrete Punkte

### 1. Hintergrund: radial → linear

**Vorher** (alter Spec):
```
radial-gradient(
  ellipse 90% 70% at 50% 40%,
  #3a201a 0%,
  #2a1610 38%,
  #170b07 80%,
  #0d0604 100%
)
```
Die hellste Stelle lag genau über der Ring-Mitte — der Player „glühte von innen".

**Jetzt** — KS-2.0-Linear, beide Modi:
```
linear-gradient(180deg,
  var(--backgroundPrimary)   0%,
  var(--backgroundSecondary) 55%,
  var(--accentBackground)    100%)
```
Das untere Drittel ist warm angehoben (Mahagoni-Stop im Dark, Apricot-Stop im Light), die Ring-Mitte bleibt ruhig.

| Token | Dark | Light |
|---|---|---|
| `backgroundPrimary` (top) | `#1A100C` | `#FBEEDB` |
| `backgroundSecondary` (mid) | `#321F19` | `#F6CDA8` |
| `accentBackground` (bot) | `#5D3A2F` | `#E8A074` |

> Das sind identisch dieselben Tokens wie im KS-2.0-Hauptthemes-Handoff — kein eigenes Player-Mapping nötig.

### 2. Atemkreis-Glow: weg

**Vorher:** 220 × 220 Halo-Scheibe mit `radial-gradient` @ 0,35, animiert mit `scale(.86) → scale(1.04)` und `opacity 0,7 → 1` über 16 s, infinite.

**Jetzt:** **keine Animation** — der atmende Halo ist gestrichen. Reduced-motion-Pfad entfällt damit ebenfalls (es bewegt sich nichts mehr, das man abschalten müsste).

An seiner Stelle: eine **statische** Glühscheibe als reiner visueller Anker hinter dem Pause-Button. Größe und Position wie vorher, aber dramatisch reduzierte Opacities und keine Bewegung:

| Modus | Center-Disc (statisch) |
|---|---|
| Dark | `radial-gradient(50% 50%, rgba(214,138,110,0.10) 0%, rgba(199,125,99,0.04) 50%, transparent 80%)` |
| Light | `radial-gradient(50% 50%, rgba(162, 80, 62,0.07) 0%, rgba(162, 80, 62,0.03) 50%, transparent 80%)` |

> Wenn das Engineering-Team die Scheibe komplett rausziehen möchte, ist das in Ordnung — sie ist ein **kosmetischer Anker**, kein semantisches Element. Pause-Button trägt sich auch ohne sie. Standardspur ist „statische Scheibe drin".

### 3. Ring übernimmt KS-2.0-Norm

| Element | Vorher (alter Player-Spec) | Jetzt (KS 2.0) |
|---|---|---|
| Ring-Base | 1 px `rgba(235,226,214,0.07)` (neutral, fast unsichtbar) | 1 px `interactive` @ `0.32` (warme leise Linie) |
| Restzeit-Arc | 1,2 px `#c47a5e` @ 0,7 | 1,5 px `interactive` @ `0.72`, `stroke-linecap: round` |
| Knubbel | — (existierte nicht) | r = 6, Fill `interactive`, `filter: drop-shadow(0 0 9px interactive)`, sitzt an der Vorderkante des Arcs |

Geometrie sonst unverändert: Ring r = 130 in einer 280 × 280 Box, Rotation `-90°` (Start bei 12 Uhr, im Uhrzeigersinn).

> Das ist exakt dieselbe Ring-Sprache wie im **Timer Idle** und **Running Timer** — gleicher Stroke-Stack, gleiche Perle, gleicher Glow-Token. Der Player schließt sich damit ans Ring-Vokabular der App an.

### 4. Pre-Roll zeigt keinen Sitzungs-Fortschritt mehr im Ring

**Vorher:** ein gedämpfter Arc füllte sich während der Vorbereitung (Opazität 0,55 statt 0,72, sonst identisch zum Haupt-Arc).

**Jetzt:** Pre-Roll zeigt **nur** die Base-Ring-Linie — keinen Arc, keinen Knubbel. Die Countdown-Zahl in der Mitte trägt die ganze Information. Beim Übergang Pre-Roll → Haupt taucht der Arc + Knubbel auf.

> Begründung: der Restzeit-Arc steht semantisch für „Sitzungs-Fortschritt". Vor der Sitzung ist null Sitzungs-Fortschritt vergangen — die Ring-Bühne soll leer sein. Den Bogen für die Pre-Roll-Sekunden zweckzuentfremden lädt zur Verwechslung ein.

**Übergangs-Animation** beim Wechsel (unverändert in Dauer + Gesamtstruktur, leicht angepasste Elemente):

| Element | Übergang |
|---|---|
| Countdown-Zahl + Label „Vorbereitung" | fade-out 400 ms |
| Ring-Base | bleibt sichtbar, kein Wechsel |
| Restzeit-Arc + Knubbel | **fade-in 400 ms**, beginnt bei `dasharray = 0` |
| Pause-Button | fade-in 400 ms, mittig im Center-Disc erscheinend |
| Hint „GLEICH GEHT'S LOS" | fade-out 400 ms |
| Restzeit-Label „NOCH …" | fade-in 400 ms |
| Audio | startet bei Sekunde 0, von 0 % auf 100 % Lautstärke in 600 ms |

### 5. Pause-State zeigt Zustand im Restzeit-Label (optional)

**Vorher:** nur das Glyph wechselt (Pause-Bars → Play-Dreieck), Atem friert ein, Restzeit-Arc friert ein.

**Jetzt** (optional): das Restzeit-Label wird zusätzlich auf `PAUSIERT · NOCH 8:32 MIN` umgestellt. Klein, dezent — aber wer beim Glyph nicht hinschaut, weiß trotzdem, was los ist. Wenn euer Team das nicht haben will, weglassen — Glyph-Wechsel allein ist als Pause-Indikator akzeptabel.

---

## Token-Map (alt → neu)

Die alten `--sm-*`-Tokens aus dem ursprünglichen Player-Handoff werden vollständig auf die **gemeinsamen** `--t-*`-Tokens aus dem KS-2.0-Theme-Refinement umgestellt — der Player hat keine eigenen Farben mehr.

| Alter Slot (Player) | Neuer Slot (Theme) | Hex Dark | Hex Light |
|---|---|---|---|
| `--sm-bg-deep` | `backgroundPrimary` | `#1A100C` | `#FBEEDB` |
| (radial mid) | `backgroundSecondary` | `#321F19` | `#F6CDA8` |
| (radial outer) | `accentBackground` | `#5D3A2F` | `#E8A074` |
| `--sm-accent` | `interactive` | `#C77D63` | `#A2503E` |
| `--sm-accent-glow` | (im Player = `interactive` im Light, `#D68A6E` im Dark als Helligkeits-Variante des Akzents) | `#D68A6E` | `#A2503E` |
| `--sm-accent-dim` | abgeleitet als `interactive @ 0.35` | — | — |
| `--sm-text` | `textPrimary` | `#E5DCCD` | `#3A2418` |
| `--sm-text-3` | `textSecondary` (im Player als Eyebrow-Tinte verwendet — entspricht dort `textSecondary`, nicht `-3`) | `#A68A80` | `#7A4E3C` |

> **`textTertiary`** (im Player für Artist, Restzeit-Label, „GLEICH GEHT'S LOS") ist im KS-2.0-Haupt-Handoff nicht spezifiziert. Vorschlag — falls noch nicht im Theme: Dark `#6F6358`, Light `#9C7762`. Beides sind leise warme Mid-Tones, abgeleitet aus derselben Akzent-Hue-Familie. Falls euer Theme schon einen passenden Tertiär-Slot hat, mappt den.

---

## Swift-Snippet (Vorschlag — anpassen an euer Pattern)

```swift
// Hintergrund (beide Modi, dieselbe Mechanik) — als ViewModifier oder Background
LinearGradient(
    colors: [
        Color.themeBackgroundPrimary,
        Color.themeBackgroundSecondary,
        Color.themeAccentBackground
    ],
    startPoint: .top,
    endPoint: .bottom
)

// Ring (genauso wie Timer Idle)
struct PlayerRing: View {
    let progress: Double            // 0…1 — bereits vergangener Sitzungsanteil
    let radius: CGFloat = 130

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.themeInteractive.opacity(0.32), lineWidth: 1)

            // Arc (clockwise from 12 o'clock)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    Color.themeInteractive.opacity(0.72),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Knubbel an der Vorderkante des Arcs
            BeadAtArcEnd(progress: progress, radius: radius)
                .fill(Color.themeInteractive)
                .frame(width: 12, height: 12)
                .shadow(color: Color.themeInteractive, radius: 4.5)
        }
        .frame(width: 2 * radius, height: 2 * radius)
    }
}

// Center-Disc (statisch — KEINE Animation, KEIN Scale)
struct PlayerCenterDisc: View {
    let isDark: Bool
    var body: some View {
        let inner = isDark ? Color(red: 214/255, green: 138/255, blue: 110/255, opacity: 0.10)
                           : Color(red: 162/255, green:  80/255, blue:  62/255, opacity: 0.07)
        let mid   = isDark ? Color(red: 199/255, green: 125/255, blue:  99/255, opacity: 0.04)
                           : Color(red: 162/255, green:  80/255, blue:  62/255, opacity: 0.03)
        Circle()
            .fill(RadialGradient(
                colors: [inner, mid, .clear],
                center: .center,
                startRadius: 0,
                endRadius: 110
            ))
            .frame(width: 220, height: 220)
            .allowsHitTesting(false)
    }
}

// Pause-Button — Glas, Modus-abhängig
struct PausePlayGlass: View {
    let isPaused: Bool
    let isDark: Bool
    let action: () -> Void

    var body: some View {
        let bg = isDark
            ? Color.black.opacity(isPaused ? 0.62 : 0.55)
            : Color(red: 255/255, green: 246/255, blue: 230/255,
                    opacity: isPaused ? 0.70 : 0.55)
        let borderAlpha: Double = isPaused ? (isDark ? 0.50 : 0.65)
                                           : (isDark ? 0.35 : 0.45)
        let border = isDark
            ? Color(red: 214/255, green: 138/255, blue: 110/255, opacity: borderAlpha)
            : Color(red: 162/255, green:  80/255, blue:  62/255, opacity: borderAlpha)
        let glyphColor = Color.themeInteractive

        Button(action: action) {
            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(glyphColor)
                .frame(width: 80, height: 80)
                .background(.ultraThinMaterial)
                .background(bg)
                .clipShape(Circle())
                .overlay(Circle().stroke(border, lineWidth: 1))
        }
    }
}
```

---

## Was zu zeigen ist (Validierung)

### Pre-Roll-Phase
- **Status-Bar + Schließen-Button + Titel/Artist** wie vorher.
- **Im Ring:** nur die hauchdünne Base-Linie (`interactive @ 0.32`). **Kein** Bogen, **kein** Knubbel. Die Countdown-Zahl (Newsreader 88, weight 300) trägt die Information.
- **Hint „GLEICH GEHT'S LOS"** an der bisherigen Position (36 px unter Ring), in `textTertiary`.
- **Audio läuft nicht** — Player-Engine ist noch ungestartet.
- **Kein Pause-Button** in dieser Phase.

### Haupt-Phase (laufende Sitzung)
- **Im Ring:** Base-Linie + Restzeit-Arc + Knubbel an der Arc-Vorderkante (mit Drop-Shadow-Glow in `interactive`).
- **Center-Disc** statisch hinter dem Pause-Button (KEINE Animation, kein Pulsen).
- **Pause-Button** mittig im Ring, 80 × 80, Glas-Effekt (`backdrop-filter: blur(8px)` / `.ultraThinMaterial`), Hue-getöntes Glas (dunkel im Dark, hell im Light).
- **Restzeit-Label** „NOCH 8:32 MIN" 36 px unter Ring.

### Pause-State
- **Arc + Knubbel** frieren ein.
- **Glyph** wechselt zu Play-Dreieck, Cross-Fade 200 ms.
- **Center-Disc** unverändert (war ja schon statisch).
- **Optional:** Restzeit-Label wird auf `PAUSIERT · NOCH 8:32 MIN` umgestellt.

### Akzeptanzkriterium (Player)

> Bei laufender Sitzung bewegt sich **nichts** auf dem Bildschirm außer dem Restzeit-Arc + Knubbel, die einmal pro Sekunde (oder seltener) ihre Position aktualisieren. Keine Atem-Animation, kein Opazitäts-Puls, kein Skalieren. Pause-Tap pausiert Audio und friert den Arc — der Glyph wechselt mit 200 ms Cross-Fade.

---

## Implementierungs-Reihenfolge

1. **Atem-Animation komplett entfernen** — Code-Stelle, die den 16-s-Skalierungs-Loop antreibt, samt zugehöriger Properties und reduced-motion-Verzweigung.
2. **Center-Disc anlegen** (statisch, modus-abhängig, hinter dem Pause-Button). Falls Engineering die Scheibe rauslassen will: in Ordnung, Pause-Button trägt sich auch ohne.
3. **Hintergrund** auf das `LinearGradient` aus dem KS-2.0-Theme umstellen.
4. **Ring** auf 1 px / 1,5 px Strokes umbauen, beide in `interactive` (Akzent), `linecap: round`. Knubbel an der Arc-Vorderkante anbringen — identische Komponente wie im Timer Idle.
5. **Pre-Roll** umbauen: Arc + Knubbel **entfernen**, nur Base-Ring lassen. Countdown-Zahl bleibt.
6. **Pause-Button** auf Glas-Material mit modus-abhängiger Tönung umstellen. Glyph in `interactive`.
7. **Optional:** Restzeit-Label um `PAUSIERT · `-Prefix erweitern wenn im Pause-State.
8. **Light-Variante** visuell prüfen — Pause-Button-Glas muss hell sein, nicht der Dark-Wert.

---

## Was wir _nicht_ in diesem Handover ändern

- **Geste-Set** — bleibt: Pause, Schließen, sonst nichts. Kein Slider, kein ±10 s, kein „Neu starten", keine vergangene Zeit.
- **Auto-Start** — Player startet sofort beim Öffnen (Pre-Roll falls > 0 s, sonst direkt Haupt).
- **Lockscreen / Control Center / AirPods** — Pause/Play von außen muss in den Player-Zustand spiegeln.
- **Audio-Fade-Verhalten** — Cross-Fade 400 ms Pre-Roll → Haupt, Audio-Lautstärke-Ramp 600 ms, Schließen-Fade-out 300 ms. Alles unverändert.
- **Sitzungs-Settings** — Pre-Roll-Dauer (0–60 s) bleibt konfigurierbar.

---

## Dateien in diesem Bundle

| Datei | Zweck |
|---|---|
| `README.md` | Dieses Dokument |
| `Theme Pair Preview.html` | HTML-Referenz mit beiden Modi · Pre-Roll, Haupt und Pause in Dark und Light nebeneinander |

Im Browser öffnen für visuelle Referenz. Tokens und Mechanismen aus diesem README sind die Lieferung — das HTML ist nur die Anschauung.

---

## Vorgängerdokumente

- `design_handoff_player/README.md` — ursprünglicher Player-Spec (Dark-only, mit Atem-Glow). Bleibt als Referenz für die Teile, die sich nicht ändern (Lifecycle, Auto-Start, Schließen-Verhalten, was bewusst nicht enthalten ist).
- `claude_code_handoff_kerzenschein_2/README.md` — Theme-Refinement, aus dem die `--t-*`-Tokens stammen.
