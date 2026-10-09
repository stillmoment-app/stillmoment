---
name: create-ticket
description: Erstellt neue Tickets mit konsistenter Nummerierung, Frontmatter aus dem Template, Philosophie-Validierung und neu generiertem Index. Aktiviere bei "Erstelle Ticket...", "Neues iOS-Ticket...", oder /create-ticket.
---

# Create Ticket

Interaktive Ticket-Erstellung mit automatischer Nummerierung und Qualitaetspruefung.

## Kernprinzip

**WAS und WARUM, nicht WIE.** Tickets beschreiben das Problem und die Akzeptanzkriterien - nicht die Loesung.

## Wann dieser Skill aktiviert wird

- "Erstelle Ticket fuer Timer Background Audio"
- "Neues iOS-Ticket: Sound stoppt bei App-Wechsel"
- "Create ticket for..."
- `/create-ticket`

## Workflow

### Schritt 1: Beschreibung erfassen

Falls nicht im Trigger enthalten, frage:
> "Was soll das Ticket beschreiben?"

### Schritt 2: Plattform, Prioritaet und Phase ableiten

Versuche alles aus dem Kontext abzuleiten:
- **Plattform:** iOS-spezifische Begriffe (SwiftUI, AudioSession) → iOS. Android-spezifisch → Android. Unklar oder beide → fragen.
- **Prioritaet:** Bug mit Datenverlust/Crash → `kritisch`. Feature defekt → `hoch`. Neues Feature → `mittel`. Kosmetik → `niedrig`. Unklar → fragen.
- **Phase:** `1-Quick Fix` | `2-Architektur` | `3-Feature` | `4-Polish` | `5-QA` (Bedeutung: `dev-docs/tickets/README.md`).

Nur bei Ambiguitaet mit AskUserQuestion nachfragen.

### Schritt 3: Naechste Nummer ermitteln

1. Dateinamen aktiver **und** archivierter Tickets globben:
   - iOS: `dev-docs/tickets/**/ios-*.md`
   - Android: `dev-docs/tickets/**/android-*.md`
   - Shared: `dev-docs/tickets/**/shared-*.md`
2. Hoechste Nummer aus den Dateinamen nehmen (Pattern `<platform>-(\d+)`), Treffer unter `plans/` ignorieren
3. Inkrementiere um 1 (dreistellig, z.B. `ios-057`)

### Schritt 4: Philosophie-Validierung

Pruefe die Beschreibung gegen `validations/philosophy.md`:
- Enthaelt sie Code-Snippets? → Warnung
- Beschreibt sie WIE statt WAS? → Warnung
- Nennt sie spezifische Dateien? → Warnung

Bei Warnungen: Zeige Hinweis und schlage bessere Formulierung vor.

### Schritt 4b: Akzeptanzkriterien-Validierung

Pruefe die Akzeptanzkriterien gegen `validations/acceptance-criteria.md`.
Bei Warnungen: Zeige Hinweis und schlage bessere Formulierung vor.

### Schritt 5: Ticket erstellen

1. Lade passendes Template:
   - Platform: `dev-docs/tickets/TEMPLATE-platform.md`
   - Shared: `dev-docs/tickets/TEMPLATE-shared.md`

2. Erstelle Ticket-Datei:
   - Pfad: `dev-docs/tickets/{platform}/{platform}-{NNN}-{slug}.md` (neue Tickets sind aktiv, nie im Archiv)
   - Slug: Kebab-case aus Titel (max 40 Zeichen)

3. Fuelle das Frontmatter aus (Schema: `dev-docs/tickets/README.md`), Kommentare aus dem Template entfernen:
   - `id`: `{platform}-{NNN}`, identisch mit dem Dateinamen-Prefix
   - `title`: Einzeiler, erscheint so im Index. Enthaelt er `:` oder beginnt er mit einem Anfuehrungszeichen, in `"..."` setzen (sonst ungueltiges YAML)
   - `status`: Plattform-Ticket `todo`; Shared-Ticket `ios: todo` / `android: todo` (nicht betroffene Plattform: `n/a`)
   - `phase`, `priority` aus Ableitung/Abfrage
   - `depends_on`: Ticket-IDs oder `[]`; Freitext-Abhaengigkeiten nach `## Hinweise`
4. Fuelle den Text aus: Was/Warum aus Beschreibung, Akzeptanzkriterien, Manueller Test

### Schritt 6: Index neu erzeugen

`make tickets-index` im Repo-Root ausfuehren. INDEX.md nie von Hand editieren.

Fertig, wenn der Befehl mit Exit 0 endet. Bei Fehler: gemeldetes Problem im Frontmatter der neuen Datei beheben, erneut ausfuehren.

### Schritt 7: Zusammenfassung

Zeige dem User:
```
Ticket erstellt: {platform}-{NNN}

Datei: dev-docs/tickets/{platform}/{filename}.md
Prioritaet: {prioritaet}
INDEX.md: neu erzeugt

Naechste Schritte: `/plan-ticket {platform}-{NNN}` oder `/implement-ticket {platform}-{NNN}`
```

## Validierung

Pruefe Beschreibung und Akzeptanzkriterien gegen die Validierungsdateien:
- `validations/philosophy.md` - WAS/WARUM statt WIE
- `validations/acceptance-criteria.md` - Beobachtbar, testbar, keine Platzhalter

## Beispiel

**Input:**
> "Erstelle Ticket: Wenn User die App wechselt, stoppt der Timer-Sound"

**Output:**
```
Ticket erstellt: ios-023

Datei: dev-docs/tickets/ios/ios-023-app-switch-sound-stop.md
Prioritaet: hoch
INDEX.md: neu erzeugt

Naechste Schritte: `/plan-ticket ios-023` oder `/implement-ticket ios-023`
```

## Referenzen

- `dev-docs/tickets/README.md` - Frontmatter-Schema, Phasen, Konventionen
- `dev-docs/tickets/TEMPLATE-platform.md` - Platform-Template
- `dev-docs/tickets/TEMPLATE-shared.md` - Shared-Template
- `validations/philosophy.md` - Philosophie-Validierung (WAS/WARUM, nicht WIE)
- `validations/acceptance-criteria.md` - Akzeptanzkriterien-Validierung mit Beispielen
