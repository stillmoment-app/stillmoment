# Ticket android-054: TimerRepository Interface erweitern

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Was

Das `TimerRepository` Interface um die Methoden `tick()` und `markIntervalGongPlayed()` erweitern, damit das `TimerViewModel` gegen das Interface statt gegen die Implementierung programmiert.

## Warum

Aktuell importiert `TimerViewModel` direkt `TimerRepositoryImpl` statt das Interface `TimerRepository`. Der Grund: Die Methoden `tick()` und `markIntervalGongPlayed()` existieren nur in der Implementierung. Das verletzt das Dependency Inversion Principle und erschwert das Mocken in Unit-Tests.

---

## Akzeptanzkriterien

- [ ] `TimerRepository` Interface enthaelt `tick(): MeditationTimer?`
- [ ] `TimerRepository` Interface enthaelt `markIntervalGongPlayed()`
- [ ] `TimerViewModel` verwendet `TimerRepository` statt `TimerRepositoryImpl`
- [ ] Alle bestehenden Tests laufen weiterhin
- [ ] Konsistent mit anderen ViewModels (GuidedMeditationsListViewModel, GuidedMeditationPlayerViewModel)

---

## Manueller Test

1. App starten
2. Timer starten und laufen lassen
3. Timer pausieren und fortsetzen
4. Erwartung: Timer funktioniert wie bisher

---

## Referenz

- Interface: `domain/repositories/TimerRepository.kt`
- Implementierung: `data/repositories/TimerRepositoryImpl.kt`
- ViewModel: `presentation/viewmodel/TimerViewModel.kt:73`
- Vorbild: `GuidedMeditationPlayerViewModel` nutzt `AudioPlayerServiceProtocol`

---

## Hinweise

Die Methoden `tick()` und `markIntervalGongPlayed()` sind synchron (nicht suspend). Das sollte beibehalten werden, da sie aus dem Timer-Loop aufgerufen werden.

---
