# Ticket shared-007: Dependency Injection Architektur

**Status**: [x] DONE
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
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

- [x] iOS: Alle Views unterstuetzen ViewModel-Injection via Init (wie TimerView)
- [x] iOS: Mock-Services fuer GuidedMeditationService und AudioPlayerService (im Test-Target)
- [x] Dokumentation in CLAUDE.md: DI Best Practices Sektion
- [x] Android: Hilt-basierte DI dokumentieren (bereits vorhanden)
- [x] Android: Test-Strategie dokumentiert (Fakes in Unit Tests, UiState in Compose Tests)

**Hinweis:** `-UITestMode` Launch Argument wurde bewusst NICHT implementiert (Anti-Pattern: kein Mock-Code in App).

**Hinweis:** `@TestInstallIn`-Module wurden bewusst NICHT verwendet - manuelle Konstruktion ist einfacher und die Tests sind bereits gut strukturiert.

---

## Manueller Test

Kein manueller Test noetig - Dokumentation und Architektur-Ticket.

Verifizierung:
1. CLAUDE.md enthaelt DI-Dokumentation fuer iOS und Android
2. Unit Tests verwenden Fakes/Mocks (im Test-Target, nicht in App)
3. Kein Mock-Code im Haupt-App-Target

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/` (Constructor Injection)
- iOS: `ios/StillMomentTests/Mocks/` (Mock-Services)
- Android: `android/app/src/main/kotlin/com/stillmoment/infrastructure/di/AppModule.kt`
- Android: `android/app/src/test/kotlin/.../viewmodel/` (Tests mit Fakes)

---

## Hinweise

**iOS Pattern (Constructor Injection):**
- Views akzeptieren optionalen ViewModel im Init
- ViewModels akzeptieren Protocol-basierte Services
- Mocks nur im Test-Target

**Android Pattern (Hilt + Manuelle Konstruktion):**
- Hilt fuer Prod-DI (AppModule bindet Interfaces zu Implementierungen)
- Unit Tests: Manuelle Konstruktion mit Fakes (einfacher, schneller)
- Compose Tests: UiState direkt an Composables uebergeben

**Learnings:**
- UI Tests (XCUITest/Espresso) sind Black-Box - kein DI moeglich
- Mock-Code im App-Target ist Anti-Pattern
- Manuelle Konstruktion oft besser als DI-Framework in Tests

---
