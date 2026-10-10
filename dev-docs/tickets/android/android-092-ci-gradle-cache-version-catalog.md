---
id: android-092
title: "CI-Gradle-Cache erneuert sich bei Änderungen am Version-Catalog"
status: todo
phase: 5-QA
priority: niedrig
depends_on: []
---

# Ticket android-092: CI-Gradle-Cache erneuert sich bei Änderungen am Version-Catalog

## Was

**Beobachtet:** Ändert ein Pull Request nur Versionen im Version-Catalog (`android/gradle/libs.versions.toml`), stellt der Android-Job der CI trotzdem den alten Gradle-Cache wieder her. Ein neuer Cache-Eintrag entsteht nicht.
**Erwartet:** Ändert sich der Version-Catalog, legt die CI einen neuen Cache-Eintrag an.
**Umstände:** Das betrifft jeden Dependabot-Update-PR für Android, denn Dependabot ändert fast ausschließlich den Version-Catalog. Aufgefallen ist es beim ersten Dependabot-Lauf am 2026-10-10.

## Warum

Ein veralteter Cache macht jeden Update-PR langsamer: Die neuen Abhängigkeiten werden jedes Mal frisch geladen und nie dauerhaft gespeichert. Wahrscheinlich hat der veraltete Cache auch den CI-Fehler in PR #9 begünstigt. Dort meldete die CI die neuen JUnit-6- und mockito-kotlin-Versionen als nicht vorhanden, obwohl sie auf Maven Central lagen und lokal problemlos luden. Bewiesen ist dieser Zusammenhang nicht.

---

## Akzeptanzkriterien

- [ ] Ein Pull Request, der nur den Version-Catalog ändert, erzeugt im Android-Job einen neuen Gradle-Cache-Eintrag (sichtbar im Log des Cache-Schritts bzw. unter Actions → Caches)
- [ ] Ein Pull Request, der weder Gradle-Dateien noch den Version-Catalog ändert, nutzt weiterhin den vorhandenen Cache

---

## Manueller Test

1. Einen Branch anlegen, der nur eine Version im Version-Catalog ändert, und einen Pull Request öffnen
2. Im Android-Job der CI den Cache-Schritt öffnen
3. Erwartung: Der Cache-Schlüssel ist neu, und am Ende des Jobs wird ein neuer Cache-Eintrag gespeichert

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
