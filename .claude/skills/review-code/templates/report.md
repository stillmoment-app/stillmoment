# Report-Gliederung

Strukturvorlage fuer den inline Review-Output. **Keine Datei erzeugen** - direkt in der Antwort ausgeben. Felder weglassen wenn leer.

---

## Zusammenfassung

1-2 Saetze: Ist der Code gut? Gibt es Probleme?

## Geprueft

- **Dateien:** Liste aus `git diff --name-only` (kurz halten - bei vielen Dateien zusammenfassen)
- **Akzeptanzkriterien** (falls Ticket): pro Kriterium ein Checkbox + Status
- **Statische Pruefungen:** `make check` / `./gradlew lint` Ergebnis
- **Localization** (bei UI-Code): /review-localization Ergebnis
- **Memory-Treffer** (falls themen-relevant): bekannte Stolperfallen die geprueft wurden
- **Dokumentation:** GLOSSARY.md / dev-docs Status, nur wenn Update noetig

## Findings

Nur ausgeben wenn es echte Findings gibt. Sektionen weglassen die leer waeren.

### Mechanisch (Auto-Fix-Kandidaten)

Tabelle - alle in einem Rutsch fixbar via Auto-Fix-Flow.

| # | Finding | Datei:Zeile | Standard-Fix |
|---|---------|-------------|--------------|
| 1 | print() statt Logger | AudioService.swift:42 | `Logger.audio.info(...)` |
| 2 | [weak self] fehlt | TimerViewModel.swift:88 | `[weak self] in self?....` |

### Substanziell

Findings die Diskussion brauchen, aber konkret fixbar sind. Pro Finding: Kategorie, Datei:Zeile, Grund, konkreter Vorschlag.

### Diskutiert

Architektur / Naming / Design-Entscheidungen. Kein Auto-Fix. Pro Finding: Kategorie, Datei:Zeile, Grund, ggf. Optionen.

### Scope-Drift / Overengineering

Nur bei Ticket-Reviews relevant. Was wurde ueber das Ticket hinaus gemacht? Empfehlung: im aktuellen Ticket lassen / eigenes Ticket / rueckgaengig.

## Positiv

Nur wenn etwas wirklich bemerkenswert gut geloest wurde.

## Fazit

Freigabe / Freigabe mit Anmerkungen / Nacharbeit erforderlich.
