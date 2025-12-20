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

### Schritt 2: Ticket lesen

1. Konstruiere Pfad: `dev-docs/tickets/{platform}/{ticket-id}.md`
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

Zeige alle Akzeptanzkriterien und frage:
> "Sind alle Akzeptanzkriterien erfuellt?"
> - [ ] Kriterium 1
> - [ ] Kriterium 2
> - [ ] ...

Optionen:
- **Ja, alle erfuellt** → Weiter
- **Nein, noch nicht** → Zeige was fehlt, Ende

### Schritt 5: Dokumentations-Check

Basierend auf Ticket-Typ (aus INDEX.md Dokumentations-Regel):

| Ticket-Typ | CHANGELOG.md | CLAUDE.md | README.md |
|------------|--------------|-----------|-----------|
| Bug Fix | Pruefen | - | - |
| Feature | Pruefen | Bei Architektur | Bei Major |
| Architektur | Pruefen | Pruefen | - |
| QA | - | - | - |

Frage bei relevanten Typen:
> "Wurde die Dokumentation aktualisiert?"
> - CHANGELOG.md: [Ja/Nein]
> - CLAUDE.md: [Ja/Nein/Nicht noetig]

### Schritt 6: Status aktualisieren

1. **Ticket-Datei aktualisieren:**
   - Aendere `**Status**: [~] IN PROGRESS` zu `**Status**: [x] DONE`
   - Oder `**Status**: [ ] TODO` zu `**Status**: [x] DONE`

2. **INDEX.md aktualisieren:**
   - Finde Zeile mit Ticket-ID
   - Aendere `[~]` oder `[ ]` zu `[x]`

### Schritt 7: Statistik aktualisieren

In INDEX.md, Statistik-Sektion:
- Erhoehe "Done" um 1
- Verringere "TODO" um 1

### Schritt 8: Zusammenfassung

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
- [x] TimerReducer extrahiert
- [x] Unit Tests vorhanden
- [x] ViewModel nutzt Reducer

Sind alle Akzeptanzkriterien erfuellt? → Ja

Dokumentation:
- CHANGELOG.md aktualisiert? → Ja
- CLAUDE.md aktualisiert? → Ja (Architektur-Ticket)

Ticket geschlossen: ios-020

Status: [x] DONE
Datei: dev-docs/tickets/ios/ios-020-timer-reducer-architecture.md
INDEX.md: Aktualisiert
```

## Referenzen

- `dev-docs/tickets/INDEX.md` - Ticket-Uebersicht + Dokumentations-Regel
- `CHANGELOG.md` - Aenderungshistorie
- `CLAUDE.md` - Projekt-Dokumentation
