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

### Schritt 2: Plattform ermitteln

Frage mit AskUserQuestion:
- **iOS** - Nur iOS-spezifisch
- **Android** - Nur Android-spezifisch
- **Shared** - Beide Plattformen betroffen

### Schritt 3: Prioritaet abfragen

Frage mit AskUserQuestion:
- **KRITISCH** - Blockiert Release, Sicherheit, Datenverlust
- **HOCH** - Wichtige Funktion defekt, viele User betroffen
- **MITTEL** - Normales Feature, Verbesserung
- **NIEDRIG** - Nice-to-have, Kosmetik

### Schritt 4: Phase abfragen

Frage mit AskUserQuestion:
- **1-Quick Fix** - Kritische Bugs, sofort beheben
- **2-Architektur** - Strukturelle Grundlagen
- **3-Feature** - Neue Funktionalitaet
- **4-Polish** - UX-Verbesserungen, Feinschliff
- **5-QA** - Tests und Qualitaetssicherung

### Schritt 5: Abhaengigkeiten (optional)

Frage:
> "Hat das Ticket Abhaengigkeiten zu anderen Tickets? (z.B. ios-022, oder 'keine')"

### Schritt 6: Naechste Nummer ermitteln

1. Lese `dev-docs/tickets/INDEX.md`
2. Finde hoechste Nummer fuer die gewaehlte Plattform:
   - iOS: Suche Pattern `ios-(\d+)`
   - Android: Suche Pattern `android-(\d+)`
   - Shared: Suche Pattern `shared-(\d+)`
3. Inkrementiere um 1

### Schritt 7: Philosophie-Validierung

Pruefe die Beschreibung gegen `validations/philosophy.md`:
- Enthaelt sie Code-Snippets? → Warnung
- Beschreibt sie WIE statt WAS? → Warnung
- Nennt sie spezifische Dateien? → Warnung

Bei Warnungen: Zeige Hinweis und schlage bessere Formulierung vor.

### Schritt 7b: Akzeptanzkriterien-Validierung

Pruefe die Akzeptanzkriterien gegen `validations/acceptance-criteria.md`.
Bei Warnungen: Zeige Hinweis und schlage bessere Formulierung vor.

### Schritt 8: Ticket erstellen

1. Lade passendes Template:
   - Platform: `dev-docs/tickets/TEMPLATE-platform.md`
   - Shared: `dev-docs/tickets/TEMPLATE-shared.md`

2. Erstelle Ticket-Datei:
   - Pfad: `dev-docs/tickets/{platform}/{platform}-{NNN}-{slug}.md`
   - Slug: Kebab-case aus Titel (max 40 Zeichen)

3. Fuelle Template aus:
   - Status: `[ ] TODO`
   - Prioritaet, Phase, Abhaengigkeiten aus Abfragen
   - Was/Warum aus Beschreibung

### Schritt 9: INDEX.md aktualisieren

1. Finde richtige Tabelle (iOS/Android/Shared)
2. Fuege neue Zeile hinzu (sortiert nach Nummer)
3. Format:
   - Platform: `| [ios-023](ios/ios-023-titel.md) | Titel | Phase | [ ] | - |`
   - Shared: `| [shared-005](shared/shared-005-titel.md) | Titel | Phase | [ ] | [ ] |`

### Schritt 10: Zusammenfassung

Zeige dem User:
```
Ticket erstellt: {platform}-{NNN}

Datei: dev-docs/tickets/{platform}/{filename}.md
Prioritaet: {prioritaet}
Phase: {phase}

Naechste Schritte:
1. Ticket oeffnen und Akzeptanzkriterien verfeinern
2. Manuellen Test ergaenzen falls noetig
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
Phase: 1-Quick Fix

Naechste Schritte:
1. Ticket oeffnen und Akzeptanzkriterien verfeinern
2. Manuellen Test ergaenzen falls noetig
```

## Referenzen

- `dev-docs/TICKET_GUIDE.md` - Vollstaendiger Leitfaden fuer Ticket-Qualitaet
- `dev-docs/tickets/INDEX.md` - Ticket-Uebersicht
- `dev-docs/tickets/TEMPLATE-platform.md` - Platform-Template
- `dev-docs/tickets/TEMPLATE-shared.md` - Shared-Template
- `validations/philosophy.md` - Philosophie-Validierung (WAS/WARUM, nicht WIE)
- `validations/acceptance-criteria.md` - Akzeptanzkriterien-Validierung
