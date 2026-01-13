---
name: review-code
description: Reviewt Code-Implementierungen nach Wartbarkeit, Architektur, Lesbarkeit (DDD) und sinnvoller Testabdeckung. Aktiviere bei Ticket-Abschluss, Code-Review-Anfragen, oder wenn der User nach Qualitaetspruefung fragt. Gibt nur Feedback wenn es wirklich relevant ist - kein Review um des Reviews willen.
---

# Code Review

Systematisches Code-Review mit Fokus auf das Wesentliche.

## Kernprinzip

**Nur relevante Anmerkungen.** Wenn der Code gut ist, sag das - und fertig. Keine kuenstlichen Findings erfinden.

- Kein Review um des Reviews willen
- Keine Stilkritik ohne Substanz
- Keine theoretischen Verbesserungen die praktisch nichts aendern
- Lob wo Lob angebracht ist

## Philosophie

**Keine Coverage-Jagd** - Relevante Tests statt Prozentzahlen.
**DDD wo sinnvoll** - Ubiquitous Language, aussagekraeftige Namen, klare Domaengrenzen.
**Pragmatische Architektur** - Clean Architecture als Leitfaden, nicht als Dogma.

## Wann dieser Skill aktiviert wird

Automatisch bei:
- "Review den Code fuer Ticket ios-025"
- "Pruefe die Implementierung von shared-007"
- "Code Review fuer die neuen Timer-Features"
- "Ist die Architektur von AudioService gut?"

## Workflow

### Schritt 1: Scope ermitteln

**Mit Ticket-Referenz:**
1. Ticket lesen: `dev-docs/tickets/{platform}/{ticket-id}.md`
2. Akzeptanzkriterien extrahieren
3. Zugehoerige Dateien identifizieren

**Ohne Ticket-Referenz:**
1. User nach Scope fragen (Dateien, Feature, Modul)
2. Relevante Dateien mit Glob/Grep finden

### Schritt 2: Code lesen

Alle relevanten Dateien lesen:
- Implementierung (Models, Services, ViewModels, Views)
- Zugehoerige Tests
- Abhaengigkeiten (Protocols, Interfaces)

**Kontext beachten:**
- Wie passt der Code in die bestehende Architektur?
- Welche Patterns werden im Projekt verwendet?

### Schritt 3: Ehrliche Bewertung

Bewerte nach 5 Kategorien - aber nur wenn es etwas zu sagen gibt:

1. **Wartbarkeit** - `checklists/wartbarkeit.md`
2. **Architektur** - `checklists/architektur.md`
3. **Lesbarkeit (DDD)** - `checklists/lesbarkeit.md`
4. **Testabdeckung** - `checklists/tests.md`
5. **Dokumentation** - `checklists/doku.md`

**Wichtig:** Nicht jede Kategorie muss Findings haben. Guter Code ist gut.

### Schritt 4: Ticket-Akzeptanzkriterien pruefen

Falls Ticket vorhanden:
- Jedes Akzeptanzkriterium einzeln pruefen
- Nur dokumentieren was fehlt oder falsch ist

### Schritt 5: Statische Pruefungen ausfuehren

Plattform-spezifisch ausfuehren:
- **iOS**: `cd ios && make check`
- **Android**: `cd android && ./gradlew lint`

Fehler im Report dokumentieren. Kein Finding wenn alles gruen ist.

### Schritt 6: Dokumentation pruefen

Pruefen nach `checklists/doku.md`:
- **GLOSSARY.md**: Neue Domain-Begriffe dokumentiert?
- **Relevante dev-docs**: Bei Architektur-/Pattern-Aenderungen aktualisiert?

Nur dokumentieren was fehlt.

### Schritt 7: Report generieren

Report nach `templates/report.md`:
- Kurze Zusammenfassung
- Nur echte Findings (wenn vorhanden)
- Positives nur wenn wirklich bemerkenswert

**Wenn alles gut ist:**
```
Der Code erfuellt die Anforderungen und ist gut strukturiert.
Keine Anmerkungen.
```

Das ist ein valides Review-Ergebnis.

### Schritt 8: Interaktive Nachfrage

Nach dem Report dem User die Wahl geben:

**Wenn Findings vorhanden:**

Mit AskUserQuestion nachfragen:
- "Soll ich die Findings beheben?"
- Optionen:
  - **Ja, alle fixen** - Alle fixbaren Findings umsetzen
  - **Auswahl fixen** - User waehlt welche Findings
  - **Nein, nur Report** - Keine Aenderungen vornehmen

**Wenn keine Findings:**

Keine Nachfrage noetig, Review ist abgeschlossen.

**Beim Fixen:**

1. TDD-Workflow einhalten (erst Test rot, dann gruen, dann refactor)
2. Nach jedem Fix `make check` ausfuehren
3. Aenderungen dokumentieren

## Was ECHTE Findings sind

| Echtes Finding | Kein Finding |
|----------------|--------------|
| Bug oder Fehler | "Koennte man auch anders machen" |
| Sicherheitsproblem | Stilpraeferenz |
| Architekturverletzung | Theoretische Verbesserung |
| Fehlender Test fuer kritischen Pfad | "Mehr Tests waeren besser" |
| Unverstaendlicher Code | "Ich haette es anders gemacht" |
| Wartbarkeitsproblem | Kosmetik |

## Was NICHT wichtig ist

- 100% Coverage
- Kommentare ueberall
- Maximale Abstraktion
- Perfekte Patterns
- Jede Methode unter 10 Zeilen

## Anti-Patterns (nur wenn sie WIRKLICH problematisch sind)

### Nur melden wenn es schadet:
- Funktionen die wirklich unverstaendlich sind (nicht: "etwas lang")
- Tests die tatsaechlich nutzlos sind (nicht: "koennten besser sein")
- Architektur die das Projekt behindert (nicht: "nicht ganz lehrbuchmaessig")

## Referenzen

- `CLAUDE.md` - Projekt-Standards
- `dev-docs/tickets/INDEX.md` - Ticket-System
