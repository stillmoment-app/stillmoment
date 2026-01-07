# Ticket Guide

Leitfaden fuer die Erstellung qualitativ hochwertiger Tickets.

## Philosophie

**WAS und WARUM, nicht WIE.**

Tickets beschreiben:
- Was soll erreicht werden (Ziel)
- Warum ist das wichtig (Motivation)
- Woran erkennt man Erfolg (Akzeptanzkriterien)

Tickets beschreiben NICHT:
- Wie es implementiert wird (das entscheidet Claude Code)
- Welche Dateien geaendert werden
- Welchen Code man schreiben muss

---

## Akzeptanzkriterien

### Eigenschaften guter Kriterien

| Eigenschaft | Beispiel |
|-------------|----------|
| **Beobachtbar** | "Settings zeigt neue Section 'Vorbereitungszeit'" |
| **Messbar** | "Picker zeigt Optionen: 5s, 10s, 15s, 20s, 30s" |
| **Testbar** | "Bei Toggle 'Aus' startet Timer sofort" |
| **User-zentriert** | "Einstellung bleibt nach App-Neustart erhalten" |

### Schlechte vs. gute Kriterien

| Schlecht | Besser |
|----------|--------|
| "Funktioniert richtig" | "Timer zaehlt von 10:00 auf 0:00" |
| "Verwendet DataStore" | "Einstellung wird persistent gespeichert" |
| "Performance verbessert" | "Liste laedt in unter 500ms" |
| "Wie erwartet" | "Sound pausiert wenn andere Audio spielt" |

---

## Beispiel

**ios-029: Konfigurierbare Vorbereitungszeit**

```markdown
## Was

Die Vorbereitungszeit vor der Meditation soll konfigurierbar werden.
User koennen sie an/aus schalten und zwischen 5s bis 45s waehlen.

## Warum

Erfahrene Meditierende moechten direkt starten, andere brauchen
mehr Zeit zum Ankommen.

## Akzeptanzkriterien

### Feature
- [ ] Settings zeigt neue Section "Vorbereitungszeit"
- [ ] Toggle: An/Aus
- [ ] Bei "An": Picker mit 5s, 10s, 15s, 20s, 30s, 45s
- [ ] Bei "Aus": Timer startet direkt
- [ ] Lokalisiert (DE + EN)

### Tests
- [ ] Unit Tests fuer Persistence und Default-Werte

### Dokumentation
- [ ] GLOSSARY.md (bei neuen Begriffen)
```

---

## Anti-Patterns

| Vermeiden | Beispiel |
|-----------|----------|
| Code-Snippets | `func startTimer() { ... }` |
| Dateinamen | "In AudioService.swift..." |
| Impl.-Verben | "Implementiere...", "Refactore..." |
| Platzhalter | "Kriterium 1", "Kriterium 2" |
| Vage Kriterien | "funktioniert richtig" |

---

## Workflow

- **Erstellen**: `/create-ticket` - Validiert automatisch
- **Abschliessen**: `/close-ticket` - Prueft Akzeptanzkriterien

---

## Referenzen

- Templates: `dev-docs/tickets/TEMPLATE-*.md`
- Ticket-Index: `dev-docs/tickets/INDEX.md`
