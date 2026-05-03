# Handoff: Ticket shared-039b — Import-Anleitungen im Content Guide

## Overview

Erweiterung des bestehenden „Wo finde ich Meditationen?"-Sheets (aus Ticket shared-039) um **zwei Anleitungs-Karten** und **zwei Detail-Sheets**, die Nutzer:innen die beiden iOS-Import-Wege erklären:

1. **Browser-Import** — über Long-Press auf einen mp3-Link → Teilen → Still Moment.
2. **Datei-Import** — über das `+` in der Bibliothek → „Aus Dateien".

**iOS only** in diesem Ticket.

## Scope (sehr eng halten)

- ✅ Zwei Banner-Karten oben im bestehenden Quellen-Sheet einfügen (oberhalb der Quellenliste).
- ✅ Zwei neue modale Sheets implementieren, die sich aus den Karten öffnen.
- ✅ Lokalisierung DE + EN (Strings + iOS-Labels).
- ❌ **Nicht** verändern: Intro, Quellenliste, Footer, Close-Verhalten des Quellen-Sheets, sonstige App-Bereiche.
- ❌ **Kein** Tracking — auch nicht welche Anleitung geöffnet wird.

## About the Design Files

`import-flow.jsx`, `library-empty.jsx`, `styles.css` sind **HTML/React-Designreferenzen**, nicht zum 1:1-Kopieren gedacht. Implementierungs-Aufgabe: in **SwiftUI** im bestehenden iOS-Codebase nachbauen, mit den existierenden Design-Tokens und Komponenten.

Reference-Komponenten in der Designdatei:
- `GuideSheetWithHowTo` — die zwei Banner sitzen direkt unter dem Intro-Text, in einem `flex-column` mit `gap: 10`.
- `HowToImportSheet({ variant: "browser" | "files" })` — beide Detail-Sheets, parametrisiert durch `variant`.

## Fidelity

**High-fidelity.** Final colors, typography, spacing, copy, icons. An die bestehenden Design-Tokens halten (Card-BG, Akzent-Variablen, Schriftarten, Radien). Light + Dark + alle drei Themes (Kupfer / Salbei / Dämmerung).

## Changes to existing screen

### Sheet: „Wo finde ich Meditationen?" (`GuidedMeditationsSourcesSheet.swift`)

**Was bleibt unverändert:** Header, Close-X, Intro, Quellenliste-Sektion, Footer-Hinweis.

**Was neu eingefügt wird:** Direkt unter dem Intro-Paragraph, vor dem Sektions-Header „Quellen · Deutsch / Sources · English":

```
[ Container — VStack(spacing: 10), padding horizontal 18 ]
  ├── [ Banner 1: Browser-Import ]   → öffnet HowToImportBrowserSheet
  └── [ Banner 2: Datei-Import ]     → öffnet HowToImportFilesSheet
[ Spacer height 18 ]
[ — bestehende Quellen-Sektion folgt — ]
```

Reihenfolge: **Browser oben, Files darunter** (häufigerer Anwendungsfall zuerst).

### Banner-Karte (Komponente, beide Banner identisch im Aufbau)

- **Background**: `rgba(196,122,94,0.10)` (im Theme als `--sm-accent-banner-bg` o.ä.)
- **Border**: 1px `rgba(196,122,94,0.28)`
- **Border-radius**: 18
- **Padding**: 14 horizontal, 14 vertical
- **Layout**: HStack, spacing 14, alignItems center
  - **Icon-Bubble** (links, 36×36, Kreis):
    - Background `var(--sm-accent-dim)` (`rgba(196,122,94,0.18)`)
    - Foreground `var(--sm-accent-text)` (`#d99a7e`)
    - Icon 18×18 zentriert
  - **Text-Spalte** (flex: 1):
    - Titel: Newsreader 14, regular, color `--sm-text` (`#ebe2d6`)
    - Subtext: Geist 11.5, color `--sm-text-2` (`#a89a8c`), line-height 1.45, margin-top 3
  - **Chevron-Right** (rechts, 16×16, color `--sm-text-3`)
- **Tap-Aktion**: präsentiert das jeweilige Detail-Sheet (modal sheet, slide-up).

#### Banner 1 — Browser-Import

| Locale | Icon | Titel | Subtext |
|---|---|---|---|
| DE | `square.and.arrow.up` (SF Symbol „Share") | „So importierst du aus dem Browser" | „Long-Press → Teilen → Still Moment." |
| EN | `square.and.arrow.up` | „How to import from the browser" | „Long-press → Share → Still Moment." |

#### Banner 2 — Datei-Import

| Locale | Icon | Titel | Subtext |
|---|---|---|---|
| DE | `doc.fill` oder `folder` (SF Symbol) | „So importierst du aus deinen Dateien" | „„+" → Aus Dateien → Audio wählen." |
| EN | `doc.fill` / `folder` | „How to import from your files" | „„+" → From Files → Pick audio." |

(Verwende SF Symbol „doc" oder eines, das im bestehenden Iconset bereits etabliert ist.)

## New Sheets

### Sheet 1: HowToImportBrowserSheet (`HowToImportBrowserSheet.swift`)

**Präsentation**: Modal Sheet, slide-up, bottom-anchored, height ≈ 720pt (vergleichbar mit dem Quellen-Sheet).

**Background**: `linear-gradient(180deg, #2a1812 0%, #1d100b 100%)`
**Top corners**: rounded 28
**Top border**: 1px `rgba(235,226,214,0.08)`

**Layout (top-to-bottom):**

1. **Grabber** — 38×4, `rgba(235,226,214,0.18)`, padding `10 0 6`.

2. **Header-Row** — padding `8px 22px 12px`, HStack alignItems flex-start, justifyContent space-between:
   - **Left** (flex 1, paddingRight 16):
     - Eyebrow: Geist 11, weight 500, uppercase, letter-spacing 0.16em, color `--sm-accent-text`
       - DE: „Anleitung"
       - EN: „How-to"
     - Titel: Newsreader 22, line-height 1.2
       - DE: „So importierst du aus dem Browser"
       - EN: „How to import from the browser"
   - **Right**: **Back-Button** (NICHT Close-X) — 30×30 circular, `rgba(235,226,214,0.06)` bg, **Chevron-Left** Icon 16×16, color `--sm-text-2`.
     - **Aktion**: Schließt dieses Sheet → Quellen-Sheet ist wieder sichtbar.
     - **Wichtig**: Da wir aus einem anderen Sheet kommen (Drill-Down), ist `<` semantisch korrekter als `×`. Auf iOS standardmäßig: `Button` mit System-Image `chevron.left`.

3. **Intro-Paragraph** — padding `0 22px 16px`, Geist 13, color `--sm-text-2`, line-height 1.55:
   - DE: „Auf vielen Webseiten kannst du mp3-Aufnahmen direkt zu Still Moment senden — ohne Umweg über die Dateien-App."
   - EN: „On many websites, you can send mp3 recordings directly to Still Moment — without going through the Files app."

4. **Schritte-Liste** (flex 1, scrollable, padding `0 18px 12px`):
   Drei Karten in einem VStack, spacing 10. Jede Karte:
   - Background `var(--sm-card)`
   - Border 1px `var(--sm-card-line)`
   - Border-radius 18
   - Padding 14×16
   - Layout: HStack, spacing 14, alignItems flex-start (oben ausgerichtet — Texte sind unterschiedlich lang)
     - **Linke Spalte** (Step-Indikator, fixed width):
       - Number-Badge: 32×32 circle, `var(--sm-accent-dim)` bg, color `--sm-accent-text`, Newsreader 13 weight 500, zentriert
       - Connector-Linie: 1px breit, `rgba(235,226,214,0.08)`, flex-fill nach unten zwischen Karten — **innerhalb der Karte**, nur zwischen Schritten 1↔2 und 2↔3 sichtbar (nicht nach Schritt 3)
     - **Rechte Spalte** (flex 1):
       - Step-Header: HStack, spacing 10, alignItems center, marginBottom 6
         - Icon 18×18, color `--sm-text-2`
         - Step-Titel: Newsreader 15, color `--sm-text`
       - Step-Body: Geist 12.5, color `--sm-text-2`, line-height 1.55

   **Inhalte (DE):**
   | # | Icon | Titel | Body |
   |---|---|---|---|
   | 1 | `square.and.arrow.up` (Share) | „Im Browser teilen" | „Long-Press auf den mp3-Link → „Teilen…" wählen. Das iOS-Share-Sheet öffnet sich." |
   | 2 | App-Icon o. `flame` | „Still Moment auswählen" | „Tippe Still Moment in der App-Reihe. iOS bestätigt kurz mit „Gespeichert" — tippe OK." |
   | 3 | `play.fill` | „In der App fertigstellen" | „Wechsle zu Still Moment. Du landest direkt im Importieren-Screen — wähle Typ, Lehrer:in und Titel." |

   **Inhalte (EN):**
   | # | Icon | Titel | Body |
   |---|---|---|---|
   | 1 | `square.and.arrow.up` | „Share from the browser" | „Long-press the mp3 link → choose „Share…". The iOS share sheet opens." |
   | 2 | App-Icon / `flame` | „Pick Still Moment" | „Tap Still Moment in the app row. iOS briefly confirms with „Saved" — tap OK." |
   | 3 | `play.fill` | „Finish in the app" | „Switch back to Still Moment. You'll land in the import screen — choose type, teacher and title." |

5. **Optional: Mini-Vorschau des Share-Sheets** (siehe Prototyp `import-flow.jsx`, Zeilen ~770–810). Eine kleine 4-Spalten-Grid-Vorschau mit „AirDrop / Mail / Notizen / Still Moment", wo „Still Moment" mit Kupfer-Glow hervorgehoben ist. **Optional** — wenn der Aufwand gering ist und Designer:in OK gibt; sonst weglassen.

6. **Footer** — padding `12 22 18`, top-border 1px `rgba(235,226,214,0.05)`:
   - Primärer Button (volle Breite):
     - Background `linear-gradient(180deg, var(--sm-accent-glow), var(--sm-accent-soft))` (`#d68a6e` → `#b06a4f`)
     - Color `#2a1208`, weight 600, font-size 15
     - Padding 14, border-radius 999
     - Shadow `0 12px 30px -8px rgba(196,122,94,0.45)`
     - Label DE: „Verstanden"
     - Label EN: „Got it"
     - **Aktion**: Schließt dieses Sheet → Quellen-Sheet sichtbar (gleich wie Back-Button).

### Sheet 2: HowToImportFilesSheet (`HowToImportFilesSheet.swift`)

**Identisch im Aufbau** zu HowToImportBrowserSheet, nur Titel/Intro/Schritte unterscheiden sich.

**Header — Titel:**
- DE: „So importierst du aus deinen Dateien"
- EN: „How to import from your files"

**Intro-Paragraph:**
- DE: „Wenn die Audio-Datei schon auf deinem Gerät liegt, kannst du sie direkt aus der Bibliothek hinzufügen."
- EN: „If the audio file is already on your device, you can add it directly from the library."

**Schritte (DE):**
| # | Icon | Titel | Body |
|---|---|---|---|
| 1 | `plus` | „„+" in der Bibliothek tippen" | „Wähle im Aktionsmenü „Aus Dateien". Der iOS-Datei-Picker öffnet sich." |
| 2 | `doc.fill` / `folder` | „Audio-Datei wählen" | „Navigiere zu iCloud, Downloads oder einem lokalen Ordner und tippe auf die Aufnahme." |
| 3 | `play.fill` | „Fertigstellen" | „Du landest direkt im Importieren-Screen — wähle Typ, Lehrer:in und Titel." |

**Schritte (EN):**
| # | Icon | Titel | Body |
|---|---|---|---|
| 1 | `plus` | „Tap „+" in the library" | „In the action menu, choose „From Files". The iOS file picker opens." |
| 2 | `doc.fill` / `folder` | „Pick an audio file" | „Navigate to iCloud, Downloads or a local folder and tap the recording." |
| 3 | `play.fill` | „Finish" | „You'll land in the import screen — choose type, teacher and title." |

**Optional Mini-Vorschau**: Kann hier weggelassen werden (für den Files-Picker gibt es kein passendes Mock).

**Footer-Button**: identisch (Verstanden / Got it).

## Interactions & Behavior

- **Banner-Tap im Quellen-Sheet** → öffnet das jeweilige Detail-Sheet als modal sheet (über dem Quellen-Sheet).
- **Back-Button im Detail-Sheet** → schließt nur das Detail-Sheet; das Quellen-Sheet bleibt darunter sichtbar und wieder interaktiv.
- **Footer-„Verstanden"-Button** → identische Aktion wie Back-Button.
- **Drag-down auf Detail-Sheet-Grabber** → schließt nur das Detail-Sheet (iOS-Standard).
- **Quellen-Sheet** funktioniert weiter wie bisher (Close-X schließt nur das Quellen-Sheet → User landet wieder in der Library).
- **Kein Telemetrie-Event** für Banner-Taps oder Sheet-Öffnungen.

### Animationen

- Detail-Sheet-Präsentation: iOS-Standard sheet (`presentationDetent` `.large` oder `.medium` — siehe „Detents" unten).
- Banner-Tap-Feedback: 0.98 scale on press, 150ms ease (Pattern bestehender Karten in der App).

### Detents

- **Quellen-Sheet** verwendet bisher `.large` oder eine custom detent — **nicht ändern**.
- **Detail-Sheets**: `.medium` und `.large` beide erlaubt; Default `.medium`. Das gibt Platz für die 3 Karten ohne dass der User scrollen muss.
- Wenn die Texte im Body abgeschnitten würden, soll der Inhalt-Bereich scrollbar sein (siehe Layout-Beschreibung Punkt 4: „flex 1, scrollable").

## State Management

- Quellen-Sheet hat bereits `@State isPresented`.
- Neu: `@State private var presentedHowTo: HowToVariant? = nil` mit `enum HowToVariant { case browser, files }`.
- Banner-Tap setzt `presentedHowTo = .browser` bzw. `.files`.
- `.sheet(item: $presentedHowTo)` rendert das passende Detail-Sheet.

Keine persistierten States. Kein Backend.

## Design Tokens

Alle Werte aus dem bestehenden Token-System. Auszug aus `styles.css`:

```
--sm-bg-deep:        #150a07
--sm-card:           #2a1812
--sm-card-line:      rgba(235,226,214,0.06)

--sm-accent:         #c47a5e
--sm-accent-soft:    #b06a4f
--sm-accent-glow:    #d68a6e
--sm-accent-dim:     rgba(196,122,94,0.18)
--sm-accent-text:    #d99a7e

--sm-text:           #ebe2d6
--sm-text-2:         #a89a8c
--sm-text-3:         #6f6358

Banner-BG:           rgba(196,122,94,0.10)  (neu — als --sm-accent-banner-bg ergänzen)
Banner-Border:       rgba(196,122,94,0.28)  (neu — als --sm-accent-banner-line ergänzen)

--sm-r-md: 18
--sm-r-lg: 24
--sm-r-xl: 28 (Sheet top corners)

display: Newsreader (regular 400)
ui:      Geist (400/500)
```

Für Sage- und Dusk-Themes: nur die `--sm-accent*` Variablen ändern, alles andere bleibt gleich.

## Lokalisierung

**Wichtig**: Alle Strings als Localizable.strings-Keys, **keine** hartcodierten Texte. Vorgeschlagene Key-Struktur:

```
// Banner im Quellen-Sheet
"library.guide.banner.browser.title" = "So importierst du aus dem Browser"
"library.guide.banner.browser.subtitle" = "Long-Press → Teilen → Still Moment."
"library.guide.banner.files.title" = "So importierst du aus deinen Dateien"
"library.guide.banner.files.subtitle" = "„+" → Aus Dateien → Audio wählen."

// Browser-Sheet
"howto.browser.eyebrow" = "Anleitung"
"howto.browser.title" = "So importierst du aus dem Browser"
"howto.browser.intro" = "Auf vielen Webseiten…"
"howto.browser.step1.title" = "Im Browser teilen"
"howto.browser.step1.body" = "Long-Press auf den mp3-Link…"
"howto.browser.step2.title" = "Still Moment auswählen"
"howto.browser.step2.body" = "…"
"howto.browser.step3.title" = "In der App fertigstellen"
"howto.browser.step3.body" = "…"
"howto.browser.cta" = "Verstanden"

// Files-Sheet — analoges Schema
"howto.files.eyebrow" = "Anleitung"
"howto.files.title" = "…"
…
```

DE und EN-Versionen vollständig pflegen.

## Acceptance Criteria

### Quellen-Sheet (Erweiterung)
- [ ] Zwei Banner-Karten erscheinen direkt unter dem Intro, oberhalb der Quellen-Sektion.
- [ ] Browser-Banner steht oben, Files-Banner darunter.
- [ ] Banner-Optik matcht dem Designdokument (Akzent-getöntes BG, Akzent-Border, Icon-Bubble, Chevron rechts).
- [ ] Tap auf Banner öffnet das jeweilige Detail-Sheet.
- [ ] Quellen-Sheet sonst unverändert (Header, Intro, Quellenliste, Footer, Close-X-Verhalten).

### Detail-Sheets
- [ ] Beide Sheets präsentieren sich slide-up als modale Sheets über dem Quellen-Sheet.
- [ ] Header zeigt Eyebrow, Titel, **Back-Pfeil** (nicht X).
- [ ] Drei nummerierte Schritte mit verbindender vertikaler Linie zwischen den Step-Badges.
- [ ] Footer-CTA „Verstanden" / „Got it" schließt das Sheet (gleich wie Back-Pfeil).
- [ ] Drag-down schließt das Detail-Sheet, nicht das Quellen-Sheet.
- [ ] Schließen → Quellen-Sheet ist wieder interaktiv und zeigt unveränderten Zustand.

### Lokalisierung
- [ ] DE und EN für alle neuen Strings vollständig.
- [ ] Keine hartcodierten Texte in Views — alle aus Localizable.strings.

### Privacy
- [ ] Kein Tracking-Event für Banner-Taps oder Sheet-Öffnungen.
- [ ] Kein Logging der gewählten Anleitung.

### Quality
- [ ] Funktioniert in allen 3 Themes (Kupfer/Salbei/Dämmerung), Light + Dark.
- [ ] Accessibility: Banner-Karten sind als `Button` semantisch markiert; Back-Button hat `accessibilityLabel` „Zurück" / „Back"; Schritt-Nummern werden VoiceOver vorgelesen („Schritt 1 von 3").

### Tests
- [ ] Snapshot-Test: Quellen-Sheet mit zwei Bannern (DE + EN, Light + Dark).
- [ ] Snapshot-Test: HowToImportBrowserSheet (DE + EN).
- [ ] Snapshot-Test: HowToImportFilesSheet (DE + EN).
- [ ] Unit/UI-Test: Banner-Tap öffnet das richtige Sheet; Back-Button schließt nur das Detail-Sheet.

### Documentation
- [ ] CHANGELOG.md updated.

## Manual Test Plan

1. Library öffnen → `ⓘ` antippen → Quellen-Sheet erscheint.
2. **Beide Banner** sichtbar oberhalb der Quellen.
3. Browser-Banner antippen → Browser-Anleitung öffnet sich über dem Quellen-Sheet.
4. Drei Schritte sichtbar, Verbindungslinie zwischen den Badges.
5. Back-Pfeil tippen → Detail-Sheet schließt, Quellen-Sheet wieder da.
6. Files-Banner antippen → Files-Anleitung öffnet sich.
7. „Verstanden" tippen → Detail-Sheet schließt, Quellen-Sheet wieder da.
8. Quellen-Sheet `×` tippen → alles geschlossen, User in Library.
9. Locale auf EN umstellen → alle Texte englisch.
10. Theme wechseln → Akzentfarben passen sich an.

## Files in this bundle

- `import-flow.jsx` — **Hauptreferenz**. Enthält:
  - `HowToImportSheet({ variant })` — beide Detail-Sheets als parametrisierte Komponente. **Final design.**
  - `GuideSheetWithHowTo` — das erweiterte Quellen-Sheet mit beiden Bannern. **Final design.**
  - Andere Komponenten (`PlusActionSheet*`, `ImportAsSheet*`, `BreathingLoader`) — gehören zu anderen Tickets, **nicht in diesem Ticket implementieren**.
- `library-empty.jsx` — Original-Komponenten von Ticket shared-039, als Kontext für die bestehende Library/Sheet-Sprache.
- `styles.css` — vollständige Token-Definition. Source of truth für Farben/Type/Radien.

## Bestehende Files-Referenzen im iOS-Codebase

- `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsSourcesSheet.swift` — hier kommen die zwei Banner rein.
- Neue Files (vorgeschlagen):
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/HowToImportBrowserSheet.swift`
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/HowToImportFilesSheet.swift`
  - Optional gemeinsame Sub-Komponenten in `HowToImportComponents.swift` (Step-Badge, Step-Card).

## Notes

- **Android folgt in einem späteren Ticket** — diesmal nicht implementieren.
- **Kein Tracking** ist eine harte Anforderung, keine Verhandlungsbasis.
- Wenn beim Implementieren auffällt, dass ein SF Symbol unpassend ist, gerne bessere Alternative wählen — bitte im PR begründen.
