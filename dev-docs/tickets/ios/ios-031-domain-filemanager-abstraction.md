# Ticket ios-031: Domain FileManager-Abstraktion

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: Klein
**Abhaengigkeiten**: shared-024
**Phase**: 2-Architektur

---

## Was

Das GuidedMeditation Domain Model soll keine direkten System-API-Aufrufe enthalten. Die URL-Auflösung für Meditationsdateien muss aus dem Domain Layer entfernt werden.

## Warum

Clean Architecture Verletzung: Domain Models dürfen keine Infrastructure-Abhängigkeiten haben. Das `fileURL` Computed Property ruft aktuell `FileManager.default.urls()` direkt auf - das gehört in die Infrastructure-Schicht.

Gefunden im Clean Architecture Review (shared-024).

---

## Akzeptanzkriterien

### Feature
- [ ] Domain Model enthält keine FileManager-Aufrufe
- [ ] URL-Auflösung erfolgt über Service/Repository
- [ ] Bestehende Funktionalität bleibt erhalten
- [ ] Keine Regression beim Laden/Abspielen von Meditationen

### Tests
- [ ] Bestehende Tests bleiben grün
- [ ] Neue Unit Tests für URL-Auflösungs-Logik

### Dokumentation
- [ ] Keine (interne Refaktorierung)

---

## Manueller Test

1. Meditation importieren
2. Meditation abspielen
3. Erwartung: Audio wird korrekt geladen und abgespielt

---

## Referenz

- Review-Ticket: shared-024 (Clean Architecture Layer-Review)
- Architektur: `dev-docs/architecture/overview.md`

---

## Hinweise

Die URL-Auflösung könnte in `GuidedMeditationService` oder ein dediziertes Repository verlagert werden. Das Pattern aus `GuidedSettingsRepository` kann als Orientierung dienen.
