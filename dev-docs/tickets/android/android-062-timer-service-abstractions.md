# Ticket android-062: Timer Service Abstraktionen

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: shared-024
**Phase**: 2-Architektur

---

## Was

TimerViewModel soll Services ueber Protokolle nutzen statt direkt auf konkrete Implementierungen zuzugreifen.

## Warum

Clean Architecture Verletzung: ViewModels (Application Layer) sollen gegen Protokolle programmieren, nicht gegen konkrete Implementierungen. Das `TimerViewModel` importiert und verwendet aktuell:

1. `AudioService` (konkrete Klasse statt Protokoll)
2. `TimerForegroundService` (statische Methoden statt injiziertes Protokoll)

Dies erschwert Testing und verletzt die Dependency Inversion.

Gefunden im Clean Architecture Review (shared-024).

---

## Akzeptanzkriterien

### Feature
- [ ] TimerViewModel importiert keine Infrastructure-Klassen mehr
- [ ] AudioService wird ueber bestehendes oder neues Protokoll injiziert
- [ ] TimerForegroundService-Aufrufe werden ueber Protokoll abstrahiert
- [ ] Bestehende Funktionalität bleibt erhalten (Audio, Notifications, Background)
- [ ] Keine Regression bei Timer-Betrieb

### Tests
- [ ] TimerViewModel Tests mit Mock-Services
- [ ] Bestehende Tests bleiben gruen

### Dokumentation
- [ ] Keine (interne Refaktorierung)

---

## Manueller Test

1. Timer starten mit Background-Sound
2. Erwartung: Sound spielt, Notification erscheint
3. Timer pausieren
4. Erwartung: Sound pausiert, Notification aktualisiert
5. Timer fortsetzen und ablaufen lassen
6. Erwartung: Gong spielt, Notification verschwindet

---

## Referenz

- Review-Ticket: shared-024 (Clean Architecture Layer-Review)
- iOS-Pendant: ios-033 (SettingsView Dependency Injection)
- Bestehende Protokolle: `AudioPlayerServiceProtocol`, `AudioSessionCoordinatorProtocol`

---

## Hinweise

Fuer `TimerForegroundService` gibt es zwei Ansaetze:

1. **Protokoll mit Wrapper**: Ein `TimerForegroundServiceProtocol` das die statischen Methoden kapselt
2. **Integration in AudioService**: Die Foreground-Service-Logik koennte Teil eines erweiterten Audio-Protokolls werden

Der erste Ansatz ist sauberer fuer die Testbarkeit, der zweite reduziert die Anzahl der Dependencies.
