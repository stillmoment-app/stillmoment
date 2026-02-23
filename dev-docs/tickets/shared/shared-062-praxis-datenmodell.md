# Ticket shared-062: Praxis-Datenmodell und Persistenz

**Status**: [~] IN PROGRESS
**Prioritaet**: HOCH
**Aufwand**: iOS ~4 | Android ~4
**Phase**: 2-Architektur
**Ursprung**: shared-051 (aufgeteilt)

---

## Was

Domain-Modell "Praxis" einfuehren: eine benannte, speicherbare Timer-Konfiguration. Repository mit CRUD-Operationen. Migration bestehender Einstellungen in eine Default-Praxis "Standard".

## Warum

Aktuell gibt es nur eine einzige globale Timer-Konfiguration. Mit dem Praxis-Modell koennen beliebig viele Konfigurationen gespeichert werden. Dies ist die Grundlage fuer Praxis-Auswahl (shared-063) und Praxis-Editor (shared-064).

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | shared-050    |
| Android   | [ ]    | shared-050    |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Praxis ist ein immutables Domain-Modell (Value Object) mit: id (UUID), name (String), durationMinutes, preparationTimeEnabled, preparationTimeSeconds, startGongSoundId, gongVolume, introductionId, intervalGongsEnabled, intervalMinutes, intervalMode, intervalSoundId, intervalGongVolume, backgroundSoundId, backgroundSoundVolume
- [ ] Dauer (durationMinutes) ist Teil der Praxis und wird beim Laden vorausgefuellt. Auf dem Timer Screen kann die Dauer vor Start angepasst werden (session-only, aendert nicht die gespeicherte Praxis)
- [ ] PraxisRepository-Protokoll mit: alle laden, nach ID laden, speichern, loeschen, aktive Praxis ID setzen/abrufen
- [ ] Persistenz-Implementierung (JSON-Dateien oder geeigneter Mechanismus)
- [ ] Bei Erstinstallation wird automatisch eine "Standard"-Praxis mit Default-Werten angelegt
- [ ] Migration: Bestehende MeditationSettings werden beim ersten Start nach Update in die "Standard"-Praxis uebernommen
- [ ] Aktive Praxis-ID wird separat persistiert und nach App-Neustart wiederhergestellt
- [ ] Praxis hat eine berechnete Kurzbeschreibung (z.B. "Stille · Tempelglocke · 15s Vorbereitung")
- [ ] Mindestens eine Praxis muss immer existieren (Loeschen der letzten wird verhindert)
- [ ] Validierung: Alle Werte innerhalb gueltiger Bereiche (wie bei MeditationSettings)

### Tests
- [ ] Unit Tests iOS: Domain-Model (Immutabilitaet, Defaults, Kurzbeschreibung), Repository (CRUD), Migration
- [ ] Unit Tests Android: Domain-Model, Repository, Migration

### Dokumentation
- [ ] CHANGELOG.md
- [ ] GLOSSARY.md (neuer Begriff: "Praxis")

---

## Manueller Test

1. App mit bestehender Konfiguration aktualisieren (z.B. Temple Bell, 15s Vorbereitung, Intervall alle 5 Min)
2. (Noch keine sichtbare UI-Aenderung — reines Backend-Ticket)
3. Verifizierung ueber Unit Tests: Migration hat "Standard"-Praxis mit den bisherigen Werten erzeugt
4. Neuinstallation: "Standard"-Praxis mit Default-Werten vorhanden

---

## Hinweise

- Die bestehende MeditationSettings-Klasse bleibt zunaechst bestehen — der Timer liest weiterhin von dort. Erst shared-064 verdrahtet den Timer mit dem Praxis-System.
- Praxis-Felder sind 1:1 identisch mit den bestehenden MeditationSettings-Feldern (inklusive durationMinutes). Keine neuen Konfigurationsoptionen in diesem Ticket.
- Die Kurzbeschreibung sollte die wichtigsten Merkmale zeigen: Dauer, Hintergrundklang, Gong, Vorbereitung (z.B. "10 Min · Stille · Tempelglocke · 15s Vorbereitung"). Lokalisiert (DE + EN).
- Architektur-Tickets shared-054 bis shared-060 (Timer-Refactoring) sind orthogonal — sie betreffen die Timer-Statemachine, nicht das Konfigurationsmodell.
