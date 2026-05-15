# Scope-Treue

Tut der Code nur das, was das Ticket verlangt? Macht er nicht zu viel?

Inspiriert von Karpathys "Surgical Changes" und "Simplicity First". Beim Reviewen besonders relevant fuer Ticket-Implementierungen.

## Kernfrage

> Laesst sich jede geaenderte Zeile direkt aus den Akzeptanzkriterien des Tickets ableiten?

Wenn nein → potenzielles Scope-Finding.

## Surgical Changes (Scope-Drift)

### Nur melden wenn wirklich problematisch

**Drive-by-Refactorings:**
- Bestehender Code wurde "verbessert" obwohl er nicht zum Ticket gehoert
- Imports umsortiert ohne sachlichen Grund
- Whitespace/Formatierung in unveraenderten Bereichen geaendert
- Existierende Funktion umbenannt obwohl Ticket das nicht fordert
- Architektur "nebenher" angepasst

**Style-Drift:**
- Existierender Stil wird nicht gematcht
- Mischung aus alten und neuen Patterns in der gleichen Datei
- Quote-Style / Type-Hints / Naming-Konventionen weichen ab

**Orphan-Hygiene falsch herum:**
- Pre-existierender Dead Code wurde mitgeloescht (gehoert in eigenes Ticket)
- Neuer Code laesst Orphans zurueck (Imports, Variablen, Funktionen die durch die Aenderung unbenutzt wurden)

### Beispiele

```swift
// Ticket: "Fuege Pause-Button zum Timer hinzu"

// BAD: Drive-by-Refactoring
func startCountdown() { ... }
func resumeFromPause() { ... }
// + 50 Zeilen Refactoring von Helper-Methoden die nicht zum Ticket gehoeren

// GOOD: Nur was im Ticket steht
func startCountdown() { ... }  // unveraendert
func pauseCountdown() { ... }  // NEU
func resumeCountdown() { ... } // NEU
```

## Overengineering (Simplicity First)

### Nur melden wenn wirklich problematisch

**Speculative Features:**
- Funktionalitaet, die im Ticket nicht steht, "fuer spaeter" eingebaut
- Konfigurierbarkeit ohne aktuellen Anwendungsfall
- "Flexibility" die niemand angefordert hat

**Premature Abstractions:**
- Protocol/Interface fuer Single-Use-Code
- Strategy-Pattern wo if/else reicht
- Factory fuer einen einzigen Typ
- Generics wo konkreter Typ reicht

**Defensive Overkill:**
- Error-Handling fuer Faelle die nicht eintreten koennen
- Validierung fuer interne, vertrauenswuerdige Daten
- Fallbacks die nie greifen werden

### Karpathys Test

> "Wuerde ein Senior-Engineer sagen, dass das overcomplicated ist?"

Wenn 200 Zeilen reichen wuerden 50 → Finding.

### Beispiele

```swift
// Ticket: "Speichere zuletzt gewaehlte Timer-Dauer"

// BAD: Overengineering
protocol DurationPersistenceStrategy { ... }
class UserDefaultsStrategy: DurationPersistenceStrategy { ... }
class FilePersistenceStrategy: DurationPersistenceStrategy { ... }  // unbenutzt
class DurationPersistenceFactory { ... }

// GOOD: Was gebraucht wird
UserDefaults.standard.set(duration, forKey: "lastDuration")
```

## Was NICHT als Scope-Finding zu melden ist

- Zwingend notwendige Refactorings die durch das Ticket induziert werden (z.B. Methode muss aufgeteilt werden um neue Variante einzubauen)
- Bug-Fixes die auf dem Weg entdeckt UND dokumentiert wurden
- Orphan-Cleanup das durch die Aenderung selbst entstanden ist (Imports von geloeschten Symbolen)
- Style-Anpassungen die durch `make check`/linter erzwungen wurden

## Pruef-Heuristik fuer Reviewer

1. Akzeptanzkriterien des Tickets lesen
2. `git diff --stat` → Welche Dateien wurden geaendert?
3. Pro Datei: Welche Kriterien rechtfertigen die Aenderung?
4. Unklare Aenderungen? → Scope-Finding-Kandidat
5. Premature-Abstraction-Check: Gibt es im Diff Klassen/Protocols mit nur einem Aufrufer und ohne offensichtlichen Erweiterungspunkt im Ticket?
