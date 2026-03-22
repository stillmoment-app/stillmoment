---
name: close-ticket
description: Schliesst Tickets ab mit Status-Update in Ticket-Datei und INDEX.md. Prueft Akzeptanzkriterien und Dokumentations-Anforderungen. Aktiviere bei "Schliesse Ticket...", "Close ticket...", oder /close-ticket.
---

# Close Ticket

Ticket abschliessen mit Status-Update und Dokumentations-Check.

## Kernprinzip

**Sorgfaeltig abschliessen.** Ein Ticket ist erst DONE wenn alle Akzeptanzkriterien erfuellt sind und die Dokumentation aktualisiert wurde.

## Wann dieser Skill aktiviert wird

- "Schliesse Ticket ios-023"
- "Close ticket android-005"
- "Ticket shared-001 ist fertig"
- `/close-ticket ios-023`

## Workflow

### Schritt 1: Ticket-Nummer extrahieren

Extrahiere aus dem Trigger:
- Pattern: `(ios|android|shared)-(\d+)`
- Beispiel: "Schliesse Ticket **ios-023**" → `ios-023`

Falls nicht im Trigger, frage:
> "Welches Ticket soll geschlossen werden? (z.B. ios-023)"

### Schritt 2: Ticket finden und lesen

**Wichtig:** Ticket-Dateinamen haben Suffixe (z.B. `ios-039-legacy-settings-store-aufraeumen.md`). Nie den Pfad raten — immer per Glob suchen:
- `dev-docs/tickets/{platform}/{ticket-id}*.md`

1. Glob nach Ticket-ID
2. Lese Ticket-Datei
3. Extrahiere:
   - Aktueller Status (`[ ]`, `[~]`, `[x]`)
   - Akzeptanzkriterien
   - Phase/Typ

### Schritt 3: Status pruefen

**Wenn bereits DONE `[x]`:**
> "Ticket {id} ist bereits abgeschlossen."
> Ende.

**Wenn TODO `[ ]`:**
> "Ticket {id} wurde noch nicht begonnen. Soll es trotzdem als DONE markiert werden?"

**Wenn IN PROGRESS `[~]`:**
> Weiter zu Schritt 4.

### Schritt 4: Akzeptanzkriterien pruefen

Pruefe die Akzeptanzkriterien selbst gegen den aktuellen Code/Diff. Zeige das Ergebnis als Tabelle:

| Kriterium | Erfuellt? |
|-----------|-----------|
| ... | Ja/Nein |

Nur bei Zweifeln den User fragen. In der Regel wurde vor dem Close bereits ein Review gemacht.

### Schritt 5: Dokumentations-Check

Basierend auf Ticket-Typ (aus INDEX.md Dokumentations-Regel):

| Ticket-Typ | CHANGELOG.md | CLAUDE.md |
|------------|--------------|-----------|
| Bug Fix | Pruefen | - |
| Feature | Pruefen | Bei Architektur |
| Architektur | Pruefen | Pruefen |
| QA | - | - |

Selbst pruefen ob CHANGELOG.md und ggf. CLAUDE.md aktualisiert werden muessen. Bei Bedarf selbst aktualisieren.

### Schritt 6: Status aktualisieren

1. **Ticket-Datei aktualisieren:**
   - Aendere `**Status**: [~] IN PROGRESS` zu `**Status**: [x] DONE`
   - Oder `**Status**: [ ] TODO` zu `**Status**: [x] DONE`

2. **INDEX.md aktualisieren:**
   - Finde Zeile mit Ticket-ID
   - Aendere `[~]` oder `[ ]` zu `[x]`

### Schritt 7: Zusammenfassung

```
Ticket geschlossen: {ticket-id}

Status: [x] DONE
Datei: dev-docs/tickets/{platform}/{filename}.md
INDEX.md: Aktualisiert

Dokumentation:
- CHANGELOG.md: [Aktualisiert/Nicht noetig]
- CLAUDE.md: [Aktualisiert/Nicht noetig]
```

## Sonderfaelle

### WONTFIX

Falls User sagt "als WONTFIX schliessen":
1. Aendere Status zu `[x] WONTFIX`
2. Frage nach Begruendung
3. Fuege Begruendung ins Ticket ein

### Shared-Tickets

Bei Shared-Tickets:
1. Frage: "Welche Plattform wurde abgeschlossen?"
   - Nur iOS
   - Nur Android
   - Beide

2. Aktualisiere entsprechende Status-Spalten in INDEX.md

## Beispiel

**Input:**
> "Schliesse Ticket ios-020"

**Ablauf:**
```
Ticket ios-020: Timer Reducer Architecture

Akzeptanzkriterien:
| Kriterium | Erfuellt? |
|-----------|-----------|
| TimerReducer extrahiert | Ja |
| Unit Tests vorhanden | Ja |
| ViewModel nutzt Reducer | Ja |

Dokumentation:
- CHANGELOG.md: Aktualisiert
- CLAUDE.md: Aktualisiert (Architektur-Ticket)

Ticket geschlossen: ios-020

Status: [x] DONE
Datei: dev-docs/tickets/ios/ios-020-timer-reducer-architecture.md
INDEX.md: Aktualisiert
```

## Referenzen

- `dev-docs/tickets/INDEX.md` - Ticket-Uebersicht + Dokumentations-Regel
- `CHANGELOG.md` - Aenderungshistorie
- `CLAUDE.md` - Projekt-Dokumentation
