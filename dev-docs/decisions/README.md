# Architecture Decision Records

Dieses Verzeichnis dokumentiert wichtige Architekturentscheidungen fuer Still Moment.

## Was ist ein ADR?

Ein ADR (Architecture Decision Record) dokumentiert eine signifikante Architekturentscheidung zusammen mit ihrem Kontext und Konsequenzen. ADRs helfen zukuenftigen Entwicklern zu verstehen, WARUM bestimmte Entscheidungen getroffen wurden.

## Wann schreiben wir ein ADR?

- Die Entscheidung ist nicht offensichtlich
- Es gab Alternativen, die verworfen wurden
- Zukuenftige Entwickler werden sich fragen "warum so?"
- Die Entscheidung hat signifikante Auswirkungen auf die Codebasis

## Format

Jedes ADR folgt dem Format von Michael Nygard:

```markdown
# ADR-XXX: Titel

## Status
Akzeptiert | Abgelehnt | Ersetzt durch ADR-YYY

## Kontext
Welches Problem mussten wir loesen?

## Entscheidung
Was haben wir entschieden?

## Konsequenzen
Positiv, Negativ, Mitigationen
```

---

## Index

| ADR | Titel | Status |
|-----|-------|--------|
| [ADR-001](adr-001-audio-session-coordinator-singleton.md) | AudioSessionCoordinator als Singleton | Akzeptiert |
| [ADR-002](adr-002-immutable-domain-models.md) | Immutable Domain Models mit Reducer Pattern | Akzeptiert |
| [ADR-003](adr-003-combine-over-async-await.md) | Combine statt async/await fuer Reactive Streams | Akzeptiert |

---

**Last Updated**: 2026-01-11
