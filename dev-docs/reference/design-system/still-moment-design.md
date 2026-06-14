# Still Moment — Design-Referenz

> *Deine Meditationen, dein Raum.*

Konsolidierte Design-Referenz für Still Moment: App-Beschreibung, Screens, Farb-Tokens,
Typografie und Richtlinien. Aus dem Code extrahiert — bei Code-Änderungen aktualisieren.

Die zugehörigen Screenshots liegen in `screens/` (iPhone 17 Pro Max, de-DE, Dark Mode) und
decken alle 15 dokumentierten Screens ab.

Quellen: `ThemeColors+Palettes.swift`, `TextStyle.swift`, `CLAUDE.md`, `ux-conventions.md`.

---

## Was die App ist

Still Moment ist eine App für **geführte Meditationen aus eigenen MP3s** und für **stille
Meditation mit anpassbarem Timer** (iOS & Android). Die **Bibliothek** — der Aufbau einer
persönlichen Sammlung aus eigenen Audiodateien — ist das Kern-Feature; der Stille-Meditations-Timer
ist die Ergänzung. Alles läuft lokal: kein Konto, keine Cloud, keine Ablenkung.

**Standard-Use-Case:** Meditation starten, Handy weglegen, der Sperrbildschirm geht an —
währenddessen passiert nichts anderes.

### Produkt-Werte

| Wert | Bedeutung |
|------|-----------|
| Privacy ist nicht verhandelbar | Kein Tracking, keine Analytics, keine Server |
| Kein Monetarisierungsdruck | Keine Ads, kein Abo, keine In-App-Käufe |
| Einfachheit vor Features | Keine Gamification, keine Streaks, kein Social |
| Eine Pause, keine Notification | Die App soll sich wie ein Innehalten anfühlen |

> Im Zweifel: Würde ein Mönch zustimmen? Weniger ist mehr.

---

## Screens

Screenshots in `screens/` (iPhone 17 Pro Max, de-DE, Dark Mode) — 15 Screens.

### Bibliothek (Tab 1 — Kern-Feature)

| Screen | Datei | Rolle |
|--------|-------|-------|
| Bibliothek | `library.png` | Persönliche Sammlung eigener Audios, nach Lehrer gruppiert |
| Leere Bibliothek | `empty-library.png` | Erststart vor dem ersten Import |
| Suche | `library-search.png` | Volltextsuche über die Sammlung |
| Import-Anleitung | `import-guide.png` | Woher eigene MP3s kommen (Browser/Dateien + Quellen) |
| Player | `player.png` | Wiedergabe: scrollendes Waveform, Restzeit, Mini-Übersicht, Pause |
| Bearbeiten | `edit.png` | Metadaten (Titel, Lehrer), Dateibezug |
| Trim-Editor | `trim-editor.png` | Wiedergabebereich (Anfang/Ende) zuschneiden |

### Timer (Tab 2 — Stille Meditation)

| Screen | Datei | Rolle |
|--------|-------|-------|
| Timer | `timer-idle.png` | 1–60 Min, Atemkreis, Konfig-Zeilen |
| Timer läuft | `timer-running.png` | Großer Countdown + Mondphasen-Fortschritt |
| Vorbereitungszeit | `preparation.png` | Einstimm-Zeit vor dem Start |
| Gong-Auswahl | `gong-selection.png` | Start-/End-Gong: Klang-Karten + Lautstärke |
| Intervall-Gongs | `interval-gongs.png` | Wiederkehrende Gongs während der Sitzung |
| Soundscape | `soundscape.png` | Hintergrundklang (Stille, Wald, Regen, eigene) |

### Einstellungen (Tab 3) & Übergreifend

| Screen | Datei | Rolle |
|--------|-------|-------|
| Einstellungen | `app-settings.png` | Erscheinungsbild (System/Hell/Dunkel), Vorbereitung, Info |
| Abschluss | `completion.png` | Dank-Bildschirm nach Ende einer Sitzung (Timer & Player) |

---

## Farb-Tokens

Eine warme Palette („Candlelight") in zwei Varianten — **Hell** und **Dunkel**. Views referenzieren
ausschließlich semantische Rollen, nie direkte Werte. Das Theme kommt reaktiv über
`@Environment(\.themeColors)` (statische `Color`-Properties wären nicht reaktiv).

### Text & Interaktiv

| Rolle | Hell | Dunkel | Verwendung |
|-------|------|--------|------------|
| `textPrimary` | `#3A2418` | `#E5DCCD` | Haupttext, Überschriften |
| `textSecondary` | `#7A4E3C` | `#A68A80` | Nebentext, Section-Header, Hinweise |
| `interactive` | `#A2503E` | `#C77D63` | Buttons, Icons, Slider, Links, Lehrer-Name |
| `textOnInteractive` | `#FFF6E6` | `#1A100C` | Text auf farbigen Buttons |
| `progress` | `#A2503E` | `#C77D63` | Timer-Ring, Fortschritt (= `interactive`) |
| `controlTrack` | `#949379` | `#826F60` | Inaktive Toggle-/Slider-Bahn (≥ 3:1) |
| `error` | `#BA1A1A` | `#E06161` | Fehlermeldungen |

### Flächen & Hintergründe

| Rolle | Hell | Dunkel | Verwendung |
|-------|------|--------|------------|
| `backgroundPrimary` | `#FBEEDB` | `#1A100C` | Primärer Screen-Hintergrund |
| `backgroundSecondary` | `#F6CDA8` | `#321F19` | Sekundär, Gradient-Stop |
| `cardBackground` | `#FFF6E6` | `#2E211A` | Karten, TabBar (= `tabBarBackground`) |
| `cardBorder` | `rgba(120,55,28,.11)` | `#4E382C` | Karten-Rahmen |
| `ringTrack` | `#C8B5A1` | `#A16C4E` | Timer-Ring Hintergrund |
| `accentBackground` | `#E8A074` | `#5D3A2F` | Dekorativer Akzent, Gradient-Stop |

### Refinement-Tokens

| Rolle | Hell | Dunkel | Verwendung |
|-------|------|--------|------------|
| `divider` | `rgba(120,55,28,.14)` | `rgba(242,228,211,.10)` | Trennlinien (Akzent-Familie) |
| `playGradientTop` | `#B85F46` | `#D68A6E` | Play-Button Gradient oben |
| `playGradientBot` | `#7E3A2D` | `#B06A4F` | Play-Button Gradient unten |
| `playheadAccent` | `#5E7A6B` | `#8AA896` | Sage-Akzent Abspielposition (Trim) |
| `playheadAccentHi` | `#7FA08E` | `#A7C2B1` | Heller Sage-Akzent (Greifer, Linie) |

### Abgeleitete Tokens (zur Laufzeit berechnet)

| Token | Formel |
|-------|--------|
| `accentBannerBackground` | `interactive` @ .10 |
| `accentBannerBorder` | `interactive` @ .28 |
| `accentBubbleBackground` | `interactive` @ .18 |
| `dialActiveArc` / `dialDropletCore` / `settingsValueAccent` | = `interactive` |
| `dialDropletHalo` | `interactive` @ .18 |
| `settingsDivider` | = `divider` |
| `tabBarBackground` | = `cardBackground` |
| `playheadTrack` | `playheadAccent` @ .18 |
| `textOnPlayhead` | `#132E1C` (hardcoded) |
| `backgroundGradient` | `backgroundPrimary` → `backgroundSecondary` → `accentBackground` |

### Opacity-Skala

`overlay .20` · `shadow .30` · `secondary .50` · `tertiary .70` · `cardShadow .08`

Alle Text-auf-Hintergrund-Kombinationen erfüllen **WCAG 2.1 AA** (automatisiert getestet in
`WCAGContrastTests.swift`).

---

## Typografie

**Typografie 2.1** — zehn Tokens, niemals mehr. Hierarchie über **Farbe**, nicht über neue Tokens.
Jeder Token bindet über `UIFontMetrics` an einen System-TextStyle und skaliert mit Dynamic Type.

| Token | Font | Größe* | TextStyle | Tracking | Casing | Verwendung |
|-------|------|--------|-----------|----------|--------|------------|
| `display` | Newsreader Light | 88pt** | largeTitle | 0 | — | Timer-Countdown, Dial |
| `title` | Newsreader Light | 30pt | largeTitle | −0.4 | — | Player-Track-Titel |
| `screenTitle` | Newsreader Light | 26pt | title | −0.4 | — | Screen-Header |
| `section` | Newsreader Light | 20pt | title3 | 0 | — | Sektions-/Dialog-Titel |
| `body` | Geist Regular | 17pt | body | 0 | — | Standardtext |
| `bodyEmphasis` | Geist Medium | 17pt | body | 0 | — | Primäre CTAs, Tab aktiv |
| `bodyItalic` | Newsreader Italic | 17pt | body | 0 | — | Lehrer-Name, Eigennamen |
| `caption` | Geist Regular | 14pt | subheadline | 0 | — | Untertitel, Beschreibungen |
| `micro` | Geist Regular | 11pt | caption2 | 0 | — | Timestamps, Einheiten |
| `eyebrow` | Geist Regular | 11pt | caption2 | 2.4 | UPPERCASE | Tracked-Caps-Labels |

\* bei Dynamic-Type-Stufe „Large". \*\* `display` ist container-relativ, nicht an feste pt gebunden.

**Schriften:** Newsreader (Serif) für ruhige, große Flächen · Geist (Sans) für funktionale Texte.

### Bold-Text-Mapping (Accessibility)

| Standard | bei „Fetter Text" | Tokens |
|----------|-------------------|--------|
| Geist Regular | Geist Medium | body, caption, micro, eyebrow |
| Geist Medium | Geist SemiBold | bodyEmphasis |
| Newsreader Light | Newsreader Regular | display, title, screenTitle, section |
| Newsreader Italic | Newsreader Italic | bodyItalic (kein Bold-Italic-Schnitt) |

---

## Design-Richtlinien

- **Eine Fläche, eine Aufgabe.** Kein Modal-im-Modal, keine überladenen Screens. Zustandsübergänge explizit und sichtbar.
- **Lock-Screen-First.** Standard-Use-Case: starten, Handy weglegen. Features müssen mit gesperrtem Bildschirm funktionieren — Vordergrund-only reicht nicht.
- **Kein Tab-Wechsel während einer Meditation.** Läuft Timer oder Wiedergabe, ist Navigation gesperrt. Immer nur eine View vorne.
- **Hierarchie via Farbe, nicht via Token.** Zehn Typo-Tokens genügen. Braucht ein Screen einen elften, ist der Screen falsch entworfen.
- **Semantische Farben, nie direkte Werte.** `.textPrimary` statt `.warmBlack`. Theme reaktiv über das Environment.
- **Hell = Schatten, Dunkel = Rahmen.** Im Dark Mode sind Schatten wirkungslos; Karten bekommen einen feinen Border.
- **Sanfte, lineare Bewegung.** Timer-Ring ohne Easing, kein Bounce. Ruhe vor Effekt.
- **Warme, nicht-technische Sprache.** Zielgruppe ist nicht technisch. Keine Dringlichkeit — eine Pause, keine Notification.
- **Beide Plattformen verhalten sich identisch.** Gleiche Features, UX, Edge-Cases (iOS SwiftUI ↔ Android Compose).
