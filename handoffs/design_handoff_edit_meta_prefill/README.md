# Handoff: Meditation bearbeiten — Prefill-Kaskade

## Overview

Diese Übergabe beschreibt eine Überarbeitung des **Meditation bearbeiten**-Screens (Import-Edit-Maske) in der **Still Moment** App. Der Screen erscheint, sobald eine Audiodatei in die Mediathek importiert wird — sei es via iOS-Share-Sheet, Dateien-App oder Direkt-Link — und lässt die Nutzer:in **Lehrer:in** und **Titel** vor dem Speichern setzen.

Die zentrale Neuerung ist eine **dreistufige Prefill-Kaskade**, die das Feld-Vorausfüllen aus verfügbaren Quellen ableitet — die heutige Maske präsentiert dort UUID-Müll bzw. den String „Unknown Artist", was Nutzer:innen zwingt, sinnloses zu löschen.

## About the Design Files

Die HTML-Dateien in diesem Bundle sind **Design-Referenzen** — sie zeigen Look, Spacing, Copy und Verhalten. Sie sind **kein produktionsfertiger Code zum 1:1-Kopieren**. Die Aufgabe ist, die gezeigten Screens in der bestehenden Still-Moment-Codebasis (vermutlich React Native / SwiftUI / Flutter — bitte im Projekt prüfen) mit den dort etablierten Komponenten und Patterns zu rekonstruieren.

Wenn die App native iOS-Modal-Komponenten verwendet (`UINavigationController` + `UITableView`-Form bzw. SwiftUI `Form`), folge diesen Konventionen — die HTML-Mocks nutzen einen warm-dunklen Look, der mit dem bestehenden Still-Moment-Vokabular übereinstimmt.

## Fidelity

**Hifi.** Die Mocks sind pixel-genau mit finalen Farben, Typografie, Spacings und Interaktionen. Recreate exakt, mit Anpassungen nur dort wo das Ziel-Framework eigene Konventionen erzwingt (z.B. iOS-Standard-NavBar-Heights, native Tastatur-Verhalten).

## Bezugs-Screens (in `Still Moment.html`, Section `edit-meta`)

| ID | Beschreibung | Datei-Beispiel |
|---|---|---|
| 1. ID3-Tags | Bestfall: TPE1 + TIT2 sind eingebettet | `bodyscan-mbsr.mp3` |
| 2. Lehrer im Dateinamen erkannt (Bonus) | Bekannte:r Lehrer:in als Substring gefunden | `bodyscan-tara_brach.mp3` |
| 3. Nur Titel aus Dateiname | Parsebarer Dateiname, keine Tags | `anleitung-bodyscan-deutsch-mbsr.mp3` |
| 4. Müll-Dateiname | UUID-Schrott, keine Tags | `d067c0ea-2c04-…-94b2dc2f13dd.mp3` |
| 5. Autocomplete offen | Fokus auf Lehrer-Dropdown beim Tippen | (Query "T") |

Alle fünf Screens nutzen die identische Maske — nur die **vorausgefüllten Werte** unterscheiden sich.

---

## Prefill-Kaskade (Kern-Logik)

Reihenfolge der Quellen, von oben nach unten ausgewertet. Beim ersten Treffer mit nicht-leerem Wert wird das Feld vorausgefüllt; ggf. nicht abgedeckte Felder bleiben leer.

### 1. ID3-Tags (höchste Priorität)

Aus der mp3 die ID3v2-Tags lesen:
- `TPE1` (Artist) → **Lehrer:in**
- `TIT2` (Title) → **Name der Meditation**

Wenn **beide** Tags da sind: Quelle = `id3`, beide Felder gefüllt.

Wenn nur **eines** da ist: das eine Feld nutzt ID3, das andere fällt auf nächste Stufen durch.

**Edge-Cases:**
- Wenn ID3 wörtlich `"Unknown Artist"` oder leer/whitespace-only liefert → wie nicht vorhanden behandeln.
- ID3 in UTF-8/UTF-16 dekodieren, BOMs entfernen.

### 2. Lehrer:in im Dateinamen erkannt (Bonus-Erkennung)

Wenn Lehrer:in noch leer, gleiche die Liste bekannter Lehrer:innen (`teachers`-Tabelle in der lokalen DB) gegen den Dateinamen ab.

**Algorithmus:**
1. Dateiname normalisieren: Endung weg, Trennzeichen `_`, `-`, `.`, ` ` → einheitliche Spaces, lowercased.
2. Liste der bekannten Namen ebenso normalisieren, nach Länge **absteigend** sortieren (damit "Tara Brach" vor "Tara" matcht).
3. Erste:n Lehrer:in, deren normalisierter Name als zusammenhängender Substring im normalisierten Dateinamen vorkommt, übernehmen.
4. Den gematchten Teil aus dem Dateinamen entfernen, Rest als **Titel-Vorschlag** weiterverarbeiten (siehe Token-Cleanup unten).

**Beispiel:**
- Datei: `bodyscan-tara_brach.mp3`
- Bekannt: `Tara Brach` (12 vorh. Meditationen)
- → Normalisiert: `"bodyscan tara brach"` enthält `"tara brach"` als Substring.
- → Lehrer = "Tara Brach", Rest = "bodyscan" → Titel-Vorschlag = "Bodyscan".
- Quelle = `teacherInFilename`.

**Edge-Cases:**
- Nur matchen, wenn der bekannte Name **mindestens 2 Worte** ODER **≥6 Zeichen** hat — sonst false positives bei kurzen Vornamen wie "Tara" im Wort "Tarantino".
- Wenn der Rest nach Entfernen weniger als 3 Zeichen ist, Titel-Feld leer lassen.

### 3. Titel aus parsebarem Dateinamen

Wenn Titel noch leer und Dateiname **nicht Müll** ist (siehe Garbage-Detection unten):
- Dateiname → Tokens via `[ _\-.]+`, Endung weg, Title-Case, bekannte Akronyme groß lassen (`MBSR`, `MSC`, `LMHC`, …).
- Quelle = `filename`.

**Beispiele:**
- `anleitung-bodyscan-deutsch-mbsr.mp3` → "Anleitung Bodyscan Deutsch MBSR"
- `morning_meditation.mp3` → "Morning Meditation"

### 4. Garbage-Detection (keine Suggestion)

Wenn keiner der Schritte 1–3 greift bzw. der Dateiname als Schrott erkannt wird → beide Felder leer. Quelle = `none`.

**Heuristiken für "Müll-Dateiname"** (ODER-verknüpft, irgendeine reicht):

```ts
function isGarbageFilename(stem: string): boolean {
  // UUID v4 (case-insensitive)
  if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(stem)) {
    return true;
  }
  // ≥75 % hex characters and ≥16 chars long
  const hexChars = (stem.match(/[0-9a-f]/gi) ?? []).length;
  if (stem.length >= 16 && hexChars / stem.length >= 0.75) {
    return true;
  }
  // very long single-token without delimiters
  if (stem.length >= 24 && !/[ _\-.]/.test(stem)) {
    return true;
  }
  // pure timestamps like 20250515-143242
  if (/^\d{8,14}([-_]\d{4,8})?$/.test(stem)) {
    return true;
  }
  return false;
}
```

---

## UI — Layout & Komponenten

### Screen-Container

- iOS-Modal (Sheet-Presentation), vollflächig.
- Hintergrund: radial-gradient warm dark (`#3a201a` → `#2a1610` → `#190c08` → `#110705` — bzw. der App-Standard `bg-vignette`).
- Padding: nichts außen, Inhalts-Container mit `16px 18px 18px`.

### NavBar (oben)

Native iOS-NavBar-Pattern, **keine Pill-Buttons** wie in der jetzigen Production (die führen zur „Meditation b…"-Truncation).

- Höhe: 44 px, Padding `8px 18px 12px`.
- Bottom-Border: `1px solid rgba(235,226,214,0.05)`.
- **Links**: „Abbrechen" — `--sm-accent-text` (`#d99a7e`), 15 px, regular weight.
- **Mitte (absolute)**: „Meditation bearbeiten" — Newsreader 17 px, `--sm-text` (`#ebe2d6`).
- **Rechts**: „Speichern" — 15 px, weight 500, `--sm-accent-text` wenn aktiv, sonst `--sm-text-3` (`#6f6358`) bei Opacity 0.45.

**Save-Validation:** „Speichern" ist gedimmt + disabled solange `name.trim().length === 0`. Lehrer:in darf leer bleiben (wird beim Speichern als „Unbekannt" interpretiert oder dem `teachers`-Eintrag „Unbekannt" zugeordnet — interne Sache, nicht im UI sichtbar).

### Prefill-Indikatoren

Keine Banner, keine Badges. Die Tatsache dass ein Wert vorausgefüllt wurde wird nicht visuell hervorgehoben — der Wert steht einfach da. Wenn er falsch ist, tippt die Nutzer:in das kleine × im Feld (siehe „Clear-Button" unten) und gibt selbst etwas ein. Wenn er stimmt, weiter zum Save.

### Clear-Button (×)

iOS-Standard-Pattern (`clearButtonMode = whileEditing` äquivalent). Erscheint rechts im Input sobald das Feld einen Wert enthält; ein Tap leert das Feld komplett.

- Position: rechts im Input-Feld, 10 px Gap zum Text.
- Größe: 20 × 20 px Kreis.
- Background: `rgba(235,226,214,0.18)` (gedimmtes Hellgrau).
- Icon: 10 × 10 px X, 3 px Strichstärke, dunkle Füllung `#1a0e0a`.
- Sichtbarkeit: nur wenn `value.length > 0`. (In Production-iOS: zusätzlich nur während `isEditing` — in der HTML-Referenz immer sichtbar wenn Wert da ist, weil Focus-State in statischen Mocks nicht abbildbar.)
- Klick-Verhalten: setzt Feld auf `""`. Bei Lehrer:in: öffnet daraufhin den Autocomplete-Dropdown mit der vollen bekannten-Liste.

### FieldCard (für Lehrer:in und Name)

Stapelbare Karten, je 14 px Gap.

- Background: `--sm-card` (`#2a1812`).
- Border: `1px solid --sm-card-line` (`rgba(235,226,214,0.06)`).
- Border-Radius: 18.
- Padding: `14px 16px 12px`.

Inner-Layout:
- **Label-Zeile** (margin-bottom 8): nur das Label.
  - Label (10–11 px, uppercase, letter-spacing 0.12em, `--sm-text-3`, weight 500): „Lehrer:in" / „Name der Meditation"
- **Input-Zeile**: flex-Container.
  - Input (Newsreader, 18 px, `--sm-text`, transparent bg, kein Border, `flex: 1`)
  - Optional **Clear-Button (×)** rechts (siehe oben), erscheint wenn Wert non-empty
- Optional **Hint-Zeile** unten (11.5 px, `--sm-text-3`).

### File-Footer

Unter den Feldern, **kompakt** (im Gegensatz zur Production-Maske, die den Dateinamen ein zweites Mal als großen Block zeigt).

- `padding: 10px 4px 0`, 11 px, `--sm-text-3`, tabular nums.
- Ein-Zeiler: `[i] {filename} · {duration} · {filesize}` (ellipsize Dateiname).
- Icon: 12 px Info-Punkt.

### Lehrer-Autocomplete-Dropdown

Wird unter dem Input-Feld in der FieldCard angezeigt sobald `teacher.length > 0` ODER bei expliziter Focus-Trigger. Liste der bekannten Lehrer:innen (Substring-Match, case-insensitive).

- Innerhalb der FieldCard: separater Block mit `margin-left/right: -16` und `margin-bottom: -12` (zieht bis an die Card-Kante), `border-bottom-radius: 18`, `overflow: hidden`.
- Top-Border `1px solid rgba(235,226,214,0.07)` zur Trennung vom Input.
- Background: `rgba(0,0,0,0.18)`.

Pro Eintrag (Button, voll breit, padding `12px 16px`):
- Links: 28 px Avatar-Kreis mit Person-Icon (oder Initialen) auf `rgba(235,226,214,0.05)`.
- Zeile 1 (Newsreader 14 px): **Lehrer-Name** mit Match-Substring in `--sm-accent-text` + weight 500 highlighted.
- Zeile 2 (11 px, `--sm-text-3`): `{count} Meditation{en} · zuletzt {relativeTime}`.

Trenner zwischen Einträgen: `border-top: 1px solid rgba(235,226,214,0.04)`.

**Footer-Eintrag** (falls Query nicht exakt einem bestehenden Namen entspricht): kupfer-akzentuierter Text „„{query}" als neue:n Lehrer:in anlegen", 13 px, plus-Icon links.

### Tastatur-Verhalten

- Bei `none`-Szenario (beide Felder leer): Name-Feld autofocus, damit die Tastatur sofort aufgeht und die Nutzer:in tippen kann.
- Bei `id3`-Szenario: kein autofocus (Nutzer:in soll erstmal sehen was übernommen wurde).
- Bei `filename` / `teacherInFilename`: Name-Feld autofocus, damit ggf. korrigiert werden kann.
- Return-Taste im Lehrer-Feld → Fokus zum Name-Feld.
- Return-Taste im Name-Feld → Save (falls valid).

---

## Design-Tokens (aus `styles.css`)

### Farben (warm dark)
```
--sm-bg-deep:        #150a07
--sm-bg-1:           #221310
--sm-bg-2:           #2c1a15
--sm-bg-3:           #3a221c
--sm-card:           #2a1812
--sm-card-hi:        #341e17
--sm-card-line:      rgba(235, 226, 214, 0.06)

--sm-accent:         #c47a5e  /* copper */
--sm-accent-soft:    #b06a4f
--sm-accent-glow:    #d68a6e
--sm-accent-dim:     rgba(196, 122, 94, 0.18)
--sm-accent-text:    #d99a7e

--sm-text:           #ebe2d6
--sm-text-2:         #a89a8c
--sm-text-3:         #6f6358
--sm-text-4:         #4a4039

--sm-sage:           #8aa896  /* "alles gut"-Signal für ID3-Quelle */
```

### Spacing
- Karten-Gap: 12–14 px
- Karten-Padding: `14px 16px 12px`
- Screen-Padding: `16px 18px 18px`

### Radii
```
--sm-r-sm: 12  --sm-r-md: 18  --sm-r-lg: 24  --sm-r-xl: 32  --sm-r-pill: 999
```

### Typografie
- **Display**: Newsreader (Google Font), 300/400/500
- **UI**: Geist (Google Font), 300/400/500/600
- Größen siehe Komponenten oben.

---

## State Management

```ts
type PrefillSource = "id3" | "teacherInFilename" | "filename" | "none";

interface ImportEditState {
  // The prefill we computed on file open
  prefill: {
    source: PrefillSource;
    teacher: string | null;   // matched teacher or extracted from id3/filename
    name: string | null;      // suggested title
  };

  // What the user has in the fields now (may diverge from prefill)
  teacher: string;
  name: string;

  // File metadata (read-only display)
  file: {
    originalName: string;     // for footer display
    durationSec: number;
    sizeBytes: number;
  };
}
```

**Lifecycle:**
1. Auf File-Open: `prefill = computePrefill(file, knownTeachers)`; `teacher = prefill.teacher ?? ""`; `name = prefill.name ?? ""`.
2. Auf Save: validiere `name.trim().length > 0`, dann persistiere.

---

## Known-Teachers — Datenquelle

Die Liste bekannter Lehrer:innen kommt aus der lokalen DB (`teachers`-Tabelle, alle bisher importierten Aufnahmen aggregiert):

```sql
SELECT teacher_name, COUNT(*) AS count, MAX(last_played_at) AS last_used
FROM meditations
WHERE teacher_name IS NOT NULL AND teacher_name != ''
GROUP BY teacher_name
ORDER BY count DESC, last_used DESC;
```

Diese Liste wird sowohl für die **Autocomplete-Suggestions** als auch für die **Filename-Detection** verwendet.

`zuletzt verwendet`-Anzeige im Dropdown soll relativ formatiert sein („Gestern", „Letzte Woche", „vor 3 Wochen", „vor 4 Monaten"). Nutze die Lokalisierungs-Bibliothek der App (`date-fns` formatDistanceToNow oder `RelativeDateTimeFormatter` in Swift).

---

## Interactions & Behavior

- **Abbrechen** → Modal schließt, Datei wird **nicht** importiert (oder verbleibt im Inbox-State, je nach Architektur).
- **Speichern** (wenn `canSave`) → schreibt `{teacher, name}` in die DB, schließt Modal, zeigt kurzen Toast „Hinzugefügt zur Bibliothek".
- **Lehrer-Input bearbeiten** → triggert Substring-Match gegen `knownTeachers`, Dropdown öffnet/schließt entsprechend (öffnet wenn `value.length > 0` UND `matches.length > 0`, ODER bei Focus + leerem Wert wenn `knownTeachers.length > 0`).
- **Lehrer-Dropdown-Eintrag tippen** → fillt Feld, schließt Dropdown, Fokus zu Name-Feld.
- **„Neue:n Lehrer:in anlegen"** → Bestätigt das aktuelle Query, schließt Dropdown, Fokus zu Name-Feld. Beim Save wird sie als neuer Teacher persistiert.
- **Name-Input editieren** → keine Seiteneffekte.
- **Hardware-Back / Modal-Swipe-Down** = Abbrechen.

---

## Acceptance Criteria

- [ ] NavBar zeigt vollständigen Titel „Meditation bearbeiten" ohne Truncation
- [ ] Bei UUID-Dateinamen ist das Name-Feld leer (nicht mit dem UUID gefüllt)
- [ ] Bei ID3-Tag-Datei: beide Felder zeigen den Tag-Wert
- [ ] Bei `bodyscan-tara_brach.mp3` mit bekanntem „Tara Brach": Lehrer = „Tara Brach", Name = „Bodyscan"
- [ ] Speichern-Button ist gedimmt + nicht tappbar wenn Name leer
- [ ] Lehrer-Autocomplete zeigt Anzahl Meditationen + relativen Zeitstempel
- [ ] Match-Substring im Dropdown ist akzentfarben hervorgehoben
- [ ] Wenn Query keinen exakten Match hat: Footer-Eintrag „„X" als neue:n Lehrer:in anlegen"
- [ ] Es gibt **keine Banner und keine Badges** — Prefill ist still
- [ ] Felder mit nicht-leerem Wert zeigen rechts ein kleines ×; Tap leert das Feld
- [ ] „Unknown Artist" erscheint **nirgendwo** im UI (auch nicht als Default oder Suggestion)

---

## Out of Scope

- **Audio-Preview** im Edit-Screen: bewusst nicht enthalten, soll als dediziertes Feature an anderer Stelle implementiert werden (vorgesehen: Library Long-Press → „Vorschau" mit Inline-Waveform, siehe `library-actions.jsx` im Hauptprojekt).
- **Typ-Auswahl** (Geführte Meditation / Klangkulisse / Einstimmung) wird bereits **vor** diesem Screen erledigt im „Importieren als…"-Sheet (`ImportAsSheet`).
- **Cover/Glyph-Auswahl** und **Tags**: noch nicht spezifiziert, Designer:in entscheidet später ob diese in den Edit-Screen aufgenommen werden oder als separates Curate-Feature.

---

## Files in this bundle

| Datei | Zweck |
|---|---|
| `README.md` | Diese Datei. |
| `screens.html` | **Hier starten.** Standalone-Seite mit allen fünf Reference-Screens nebeneinander. Im Browser öffnen. |
| `import-edit.jsx` | Die fünf Screens als React-Komponenten. Alle nutzen das gemeinsame `EditMeta`-Component, das die Prefill-Logik in der UI abbildet. |
| `styles.css` | Design-Tokens und shared Styles (warm-dark Palette, Phone-Frame, Status-Bar). |
| `shell.jsx` | Phone-Wrapper, StatusBar — werden gebraucht damit die Mocks rendern. |

**So startest du:**
1. Öffne `screens.html` lokal im Browser (Doppelklick reicht — keine Build-Tools nötig).
2. Du siehst alle fünf Eingangssituationen nebeneinander, jede mit kurzer Erklärung.
3. Lies dieses README für die Implementierungs-Details.
