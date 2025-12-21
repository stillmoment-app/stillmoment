# Ticket shared-007: Dependency Injection Architektur

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h | Android ~1h (bereits Hilt vorhanden)
**Phase**: 2-Architektur

---

## Was

Dependency Injection Pattern vereinheitlichen und dokumentieren, damit ViewModels flexibel mit Mock-Services fuer Tests konfiguriert werden koennen.

## Warum

Aktuell erstellen einige Views ihre ViewModels intern mit Default-Services. Das verhindert die Injection von Mock-Services fuer UI-Tests. Ein einheitliches DI-Pattern ermoeglicht testbare, wartbare Architektur.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

- [x] iOS: Alle Views unterstuetzen ViewModel-Injection via Init (wie TimerView)
- [x] iOS: Mock-Services fuer GuidedMeditationService und AudioPlayerService (im Test-Target)
- [x] Dokumentation in CLAUDE.md: DI Best Practices Sektion
- [ ] Android: Hilt-basierte DI dokumentieren (bereits vorhanden)
- [ ] Android: Test-Module fuer Mock-Injection vorbereiten

**Hinweis:** `-UITestMode` Launch Argument wurde bewusst NICHT implementiert (Anti-Pattern: kein Mock-Code in App).

---

## Manueller Test

1. iOS: UI Test mit `-UITestMode` starten
2. Pruefen: App verwendet Mock-Services statt echter Services
3. Erwartung: Testdaten werden angezeigt, kein echter Dateizugriff

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/` (Views anpassen)
- iOS: `ios/StillMoment/StillMomentApp.swift` (Launch Arguments)
- iOS: `ios/StillMomentTests/Mocks/` (Mock-Services)
- Android: `android/app/src/main/kotlin/com/stillmoment/infrastructure/di/`

---

## Hinweise

iOS Pattern (Constructor Injection):
- TimerView zeigt bereits das Pattern
- GuidedMeditationsListView und PlayerView muessen angepasst werden
- ViewModels haben bereits Protocol-basierte Dependencies im Init

Android:
- Hilt ist bereits konfiguriert
- @TestInstallIn Module fuer Test-Injection nutzen

---
