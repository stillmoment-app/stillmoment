---
name: create-ticket
description: Erstellt neue Tickets mit konsistenter Nummerierung, Template-Auswahl und Philosophie-Validierung. Aktiviere bei "Erstelle Ticket...", "Neues iOS-Ticket...", oder /create-ticket.
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

### Schritt 2: Plattform und Prioritaet ableiten

Versuche beides aus dem Kontext abzuleiten:
- **Plattform:** iOS-spezifische Begriffe (SwiftUI, AudioSession) → iOS. Android-spezifisch → Android. Unklar oder beide → fragen.
- **Prioritaet:** Bug mit Datenverlust/Crash → KRITISCH. Feature defekt → HOCH. Neues Feature → MITTEL. Kosmetik → NIEDRIG. Unklar → fragen.

Nur bei Ambiguitaet mit AskUserQuestion nachfragen.

### Schritt 3: Naechste Nummer ermitteln

1. Lese `dev-docs/tickets/INDEX.md`
2. Finde hoechste Nummer fuer die gewaehlte Plattform:
   - iOS: Suche Pattern `ios-(\d+)`
   - Android: Suche Pattern `android-(\d+)`
   - Shared: Suche Pattern `shared-(\d+)`
3. Inkrementiere um 1

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
   - Pfad: `dev-docs/tickets/{platform}/{platform}-{NNN}-{slug}.md`
   - Slug: Kebab-case aus Titel (max 40 Zeichen)

3. Fuelle Template aus:
   - Status: `[ ] TODO`
   - Prioritaet aus Ableitung/Abfrage
   - Was/Warum aus Beschreibung

### Schritt 6: INDEX.md aktualisieren

1. Finde richtige Tabelle (iOS/Android/Shared)
2. Fuege neue Zeile hinzu (sortiert nach Nummer)
3. Format:
   - Platform: `| [ios-023](ios/ios-023-titel.md) | Titel | Phase | [ ] | - |`
   - Shared: `| [shared-005](shared/shared-005-titel.md) | Titel | Phase | [ ] | [ ] |`

### Schritt 7: Zusammenfassung

Zeige dem User:
```
Ticket erstellt: {platform}-{NNN}

Datei: dev-docs/tickets/{platform}/{filename}.md
Prioritaet: {prioritaet}

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
Prioritaet: HOCH

Naechste Schritte: `/plan-ticket ios-023` oder `/implement-ticket ios-023`
```

## Referenzen

- `dev-docs/tickets/INDEX.md` - Ticket-Uebersicht
- `dev-docs/tickets/TEMPLATE-platform.md` - Platform-Template
- `dev-docs/tickets/TEMPLATE-shared.md` - Shared-Template
- `validations/philosophy.md` - Philosophie-Validierung (WAS/WARUM, nicht WIE)
- `validations/acceptance-criteria.md` - Akzeptanzkriterien-Validierung mit Beispielen
