# Report-Gliederung

Strukturvorlage fuer den inline Review-Output. **Keine Datei erzeugen** - direkt in der Antwort ausgeben. Felder weglassen wenn leer.

---

## Zusammenfassung

1-2 Saetze: Ist der Code gut? Gibt es Probleme?

## Annahmen (optional)

Nur wenn relevant: Welche Annahmen liegen dem Review zugrunde? Beispiel: "Ich nehme an, dass der `strong self` im Task absichtlich ist, weil der Task die View-Lifetime ueberdauert."

Macht das Review nachvollziehbar und vermeidet "Bug-Findings" die in Wahrheit Design-Entscheidungen sind.

## Geprueft

- **Dateien:** Liste aus `git diff --name-only` (kurz halten - bei vielen Dateien zusammenfassen)
- **Akzeptanzkriterien** (falls Ticket): pro Kriterium ein Checkbox + Status
- **Statische Pruefungen:** `make check` / `./gradlew lint` Ergebnis
- **Tests:** `make test-unit-agent` Ergebnis (PASSED / FAILED + Anzahl)
- **Localization** (bei UI-Code): /review-localization Ergebnis
- **Cross-Platform** (falls Feature auf beiden Plattformen): synchron / Hinweis fuer Follow-up / nicht relevant
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

Architektur / Naming / Design-Entscheidungen. Kein Auto-Fix.

Pro Finding: Kategorie, Datei:Zeile, Grund. **Wenn mehrere Ansaetze sinnvoll sind: Optionen praesentieren, nicht eine Empfehlung durchdruecken.**

Beispiel:
```
Naming `MeditationLibraryStore` vs `LibraryRepository`
Datei: LibraryStore.swift:15
Grund: Doppelte Verantwortung — sowohl Persistenz als auch In-Memory-Cache.
Optionen:
  A) Trennen: `LibraryRepository` (Persistenz) + `LibraryCache` (Memory)
  B) Im Glossar als `LibraryStore` etablieren (Persistenz + Cache als bewusste Einheit)
  C) Verbleibender Name, aber Doc-Kommentar der die Doppelrolle erklaert
```

Nur eine Empfehlung geben, wenn objektiv eine besser ist (z.B. Architekturverletzung). Sonst entscheidet User.

### Scope-Drift / Overengineering

Nur bei Ticket-Reviews relevant. Was wurde ueber das Ticket hinaus gemacht? Empfehlung: im aktuellen Ticket lassen / eigenes Ticket / rueckgaengig.

## Positiv

Nur wenn etwas wirklich bemerkenswert gut geloest wurde.

## Fazit

Freigabe / Freigabe mit Anmerkungen / Nacharbeit erforderlich.
