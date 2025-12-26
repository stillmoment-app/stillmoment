# Ticket android-049: CI um ktlint/detekt erweitern

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: android-048
**Phase**: 5-QA

---

## Was

Die GitHub Actions CI soll ktlint und detekt bei jedem PR/Push ausfuehren, damit Code-Quality-Issues frueh erkannt werden.

## Warum

- CI fuehrt aktuell nur `./gradlew lint` (Android Lint) aus
- ktlint (Formatierung) und detekt (statische Analyse) sind konfiguriert, aber nicht in CI integriert
- Code-Quality-Issues werden erst lokal entdeckt statt im PR

---

## Akzeptanzkriterien

- [ ] CI fuehrt `./gradlew ktlintCheck` aus
- [ ] CI fuehrt `./gradlew detekt` aus
- [ ] CI schlaegt fehl wenn ktlint/detekt Fehler findet
- [ ] Beide Checks laufen parallel zum bestehenden Android Lint
- [ ] Optional: MagicNumbers in Konstanten umwandeln (3, 5, 7 Sekunden Countdown, 0.15f Audio-Volumen, 3000L Delay)

---

## Manueller Test

1. PR erstellen mit ktlint-Verletzung (z.B. falsche Einrueckung)
2. Erwartung: CI schlaegt fehl mit aussagekraeftiger Meldung

---

## Referenz

- CI-Workflow: `.github/workflows/ci.yml`
- ktlint Config: `android/.editorconfig`
- detekt Config: `android/config/detekt/detekt.yml`
- Bestehender iOS Lint-Job als Orientierung

---

## Hinweise

Die bestehende Baseline (`config/detekt/baseline.xml`) enthaelt noch Compose-typische Issues (LongMethod, LongParameterList), die bewusst akzeptiert werden. Diese sollen in der Baseline bleiben.

---
