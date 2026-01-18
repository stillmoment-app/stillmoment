# Ticket ios-032: Timer Settings Repository

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: shared-024
**Phase**: 2-Architektur

---

## Was

Timer-Einstellungen sollen über ein Repository-Protokoll geladen und gespeichert werden, statt direkt auf UserDefaults zuzugreifen.

## Warum

Clean Architecture Verletzung: ViewModels (Application Layer) sollen keine direkten Infrastructure-Zugriffe haben. Das `TimerViewModel` greift aktuell mehrfach direkt auf `UserDefaults.standard` zu.

Für GuidedMeditations existiert bereits das Pattern `GuidedSettingsRepository` - ein analoges Repository für Timer-Settings schafft Konsistenz und verbessert die Testbarkeit.

Gefunden im Clean Architecture Review (shared-024).

---

## Akzeptanzkriterien

### Feature
- [ ] TimerViewModel verwendet Repository-Protokoll statt UserDefaults
- [ ] Settings werden korrekt geladen und gespeichert
- [ ] Bestehende Settings-Migration funktioniert weiterhin
- [ ] Keine Regression bei Timer-Einstellungen

### Tests
- [ ] Unit Tests für Repository-Implementierung
- [ ] TimerViewModel Tests mit Mock-Repository
- [ ] Bestehende Tests bleiben grün

### Dokumentation
- [ ] Keine (interne Refaktorierung)

---

## Manueller Test

1. Timer-Einstellungen ändern (Duration, Gong, Background Sound)
2. App beenden und neu starten
3. Erwartung: Alle Einstellungen sind gespeichert

---

## Referenz

- Review-Ticket: shared-024 (Clean Architecture Layer-Review)
- Bestehendes Pattern: `GuidedSettingsRepository`
- Architektur: `dev-docs/architecture/overview.md`

---

## Hinweise

Das neue Repository sollte dem Pattern von `GuidedSettingsRepository` folgen:
- Protokoll im Domain Layer
- Implementierung in Infrastructure
- Injection via Konstruktor im ViewModel
