# Dokumentation

Wurde die Dokumentation aktualisiert?

## Nur pruefen wenn relevant

Nicht jede Code-Aenderung erfordert Doku-Updates. Nur pruefen bei:
- Neuen Domain-Begriffen
- Architektur-Aenderungen
- Neuen Patterns oder Konventionen

## GLOSSARY.md

**Pfad**: `dev-docs/reference/glossary.md`

### Prueffragen
- Neue Domain-Begriffe eingefuehrt? -> Im Glossar dokumentieren
- Begriffe umbenannt? -> Glossar aktualisieren
- Cross-Platform konsistent? -> Gleiche Namen auf iOS und Android

### Was dokumentiert werden muss
- Typ (Value Object, Entity, Enum, etc.)
- Pattern (State Machine, Command/Event, etc.)
- Kurzbeschreibung
- Datei-Referenzen (iOS + Android)

### Referenz
Siehe `dev-docs/reference/glossary.md` Abschnitt "Wartungshinweise" fuer Details.

## Relevante dev-docs

Bei groesseren Aenderungen pruefen ob betroffen:

| Dokument | Wann aktualisieren? |
|----------|---------------------|
| `architecture/overview.md` | Neue Layer, Module, Abhaengigkeiten |
| `architecture/ddd.md` | Neue DDD-Patterns, Reducer-Aenderungen |
| `architecture/audio-system.md` | Audio-Service-Aenderungen |
| `reference/color-system.md` | Neue Farben oder semantische Rollen |
| `guides/tdd.md` | Test-Konventionen geaendert |

## NICHT melden

- Fehlende Kommentare im Code (wenn Code selbsterklaerend ist)
- Fehlende README in Unterordnern
- Doku die "nice to have" waere
