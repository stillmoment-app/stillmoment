# Ticket ios-037: Langsame Tests durch Time-Injection beschleunigen

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Was

Drei Unit-Tests warten auf echte Zeitablaeufe und verlangsamen die Test-Suite um insgesamt ~16 Sekunden:

- `testGongCompletionPublisher_EmitsOnPlayback` (~10s) — wartet auf echte Audio-Wiedergabe
- `testBackgroundPreviewFadeOut_AfterDuration_StopsAutomatically` (~4s) — wartet auf echte Fade-Out-Dauer
- `testTimerTicking` (~2s) — wartet auf echte Timer-Ticks

## Warum

16 Sekunden Wartezeit auf echte Zeitablaeufe verlangsamt den TDD-Zyklus spuerbar. Tests sollen in unter 1 Sekunde laufen, indem Zeitabhaengigkeiten injizierbar werden.

---

## Akzeptanzkriterien

### Feature
- [ ] Alle drei Tests laufen in unter 1 Sekunde (ohne echte Wartezeiten)
- [ ] Bestehende Funktionalitaet bleibt unveraendert (keine Regression)
- [ ] Zeitabhaengigkeiten sind in Tests steuerbar (keine hard-coded Delays)

### Tests
- [ ] Bestehende Tests bleiben gruen
- [ ] Neue Tests nutzen kontrollierte Zeit statt echte Wartezeiten

### Dokumentation
- [ ] CHANGELOG.md (nicht noetig — nur interne Test-Aenderung)

---

## Manueller Test

1. `make test-unit` ausfuehren
2. Gesamtlaufzeit pruefen — die drei Tests sollen nicht mehr als Ausreisser erscheinen
3. Erwartung: Test-Suite laeuft merklich schneller

---

## Referenz

- Betroffene Tests: `AudioServiceTests`, `TimerServiceTests`
- Verwandte Tickets: ios-003 (Test-Performance Analyse), ios-009 (Parallel Testing)

---

## Hinweise

- `testGongCompletionPublisher` spielt eine echte ~9s Audiodatei ab. Erfordert Audio-Player-Abstraktion.
- `testBackgroundPreviewFadeOut` hat hard-coded `asyncAfter(deadline: .now() + 4.0)`. Preview-Duration muss konfigurierbar werden.
- `TimerService` hat keinen Injection-Punkt fuer Zeit — erfordert Service-Refactor.
- Alle drei Faelle erfordern unterschiedliche Abstraktionen — ggf. in Teilschritten umsetzen.
